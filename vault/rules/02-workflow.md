# Workflow

## Verification
- 코드 변경 후 build/test 통과 확인 전에는 "완료" 선언 금지
- 외부 시스템 의존 (DB, API, K8s) 작업은 dry-run 우선

## Git
- destructive 명령 (`git reset --hard`, `git push --force`, `rm -rf`) 전 사용자 확인
- commit 메시지는 conventional commits (`fix:`, `feat:`, `refactor:`, `docs:`, ...)
- 첫 줄 70자 이내, 본문은 *왜* 중심
