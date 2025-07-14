#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main() {
    pid_t pid = fork();

    if (pid > 0) {
        // 부모 프로세스 - 자식이 종료되어도 수거하지 않음
        printf("부모 프로세스: PID=%d, 자식 PID=%d\n", getpid(), pid);
        sleep(600);  // 부모가 10분간 살아 있음
    } else if (pid == 0) {
        // 자식 프로세스
        printf("자식 프로세스 종료: PID=%d\n", getpid());
        exit(0);  // 자식은 즉시 종료 → 좀비 상태
    } else {
        perror("fork 실패");
        exit(1);
    }

    return 0;
}
