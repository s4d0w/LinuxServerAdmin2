#!/bin/bash
set -e

echo "[INFO] 디스크 이름을 ID_PATH 기준으로 /dev/sda부터 고정합니다."

# 현재 디스크 목록 수집
DISKLIST=($(lsblk -dno NAME,TYPE | awk '$2 == "disk"' | sort))

# 디스크의 ID_PATH 가져오기
declare -A IDPATH_MAP
for dev in "${DISKLIST[@]}"; do
    ID_PATH=$(udevadm info -q property --name="/dev/$dev" | grep ^ID_PATH= | cut -d= -f2)
    if [ -n "$ID_PATH" ]; then
        IDPATH_MAP["$ID_PATH"]="$dev"
    else
        echo "[WARN] /dev/$dev 의 ID_PATH 값을 찾을 수 없습니다." >&2
    fi
done

# ID_PATH 기준으로 정렬된 목록 생성
SORTED_PATHS=($(printf "%s\n" "${!IDPATH_MAP[@]}" | sort))

# /dev/sda, /dev/sdb, ... 순서로 이름 할당
TARGET_NAMES=()
for i in $(seq 0 $(( ${#SORTED_PATHS[@]} - 1 ))); do
    LETTER=$(echo {a..z} | awk "{print \$$((i+1))}")
    TARGET_NAMES+=("sd${LETTER}")
done

# udev 규칙 파일 생성
RULE_FILE="/etc/udev/rules.d/99-force-disk-names.rules"
> "$RULE_FILE"

for i in "${!SORTED_PATHS[@]}"; do
    ID_PATH="${SORTED_PATHS[$i]}"
    TARGET="${TARGET_NAMES[$i]}"
    echo "SUBSYSTEM==\"block\", ENV{ID_PATH}==\"$ID_PATH\", NAME=\"$TARGET\"" >> "$RULE_FILE"
done

# 결과 출력
echo
echo "[INFO] udev 규칙 파일 생성 완료: $RULE_FILE"
echo "---------------------------------------------"
cat "$RULE_FILE"
echo "---------------------------------------------"
echo "udev 적용 방법:"
echo "  sudo udevadm control --reload"
echo "  sudo udevadm trigger"
echo "또는 시스템 재부팅 후 적용됨"

