#!/bin/bash

set -e

# 현재 디스크 배열 목록 정의(ex: DISKLIST=(sda sdb sdc))
DISKLIST=($(lsblk -dno NAME,TYPE | awk '$2 == "disk" {print $1}' | sort))
# 현재 디스크의 장치 위치를 배열 목록 정의(ex: DEVICELIST=(pci-0000:00:10.0-scsi-0:0:0:0 ...))
DEVICELIST=($(for i in ${DISKLIST[@]} ; do udevadm info -q property /dev/$i | grep ^ID_PATH= | cut -d = -f 2 ; done | sort))

# 디스크 목록을 저장할 파일 생성
DEV_RULE_FILE=/etc/udev/rules.d/99-persistent-disk.rules
> $DEV_RULE_FILE

# 디스크 개수
DISKCNT=$(( ${#DISKLIST[@]} - 1 ))

# DEV_RULE_FILE에 정보 저장
for i in $(seq 0 $DISKCNT)
do
    echo "SUBSYSTEM==\"block\", ENV{ID_PATH}==\"${DEVICELIST[$i]}\", NAME=\"${DISKLIST[$i]}\"" >> $DEV_RULE_FILE
done

# 설정을 적용하기 위해서 재부팅
cat << EOF
===============================================================================
$(cat $DEV_RULE_FILE)
===============================================================================
A Reboot is required for the changes to take effect.
===============================================================================
EOF
echo -n "Would you like to reboot now? (y/n): "
read ANSWER
[ "$ANSWER" = "y" ] && reboot

