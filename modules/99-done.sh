#!/usr/bin/env bash
set -euo pipefail

cat << 'EOF'

────────────────────────────────────────
✅ MyTerminalSet 부트스트랩 완료

다음 단계:
  1) 새 셸 열거나:  source ~/.bashrc
  2) 시크릿 채우기:
       vi /DATA1/hongcheol/.secrets/anthropic.env
       secrets-status   # 상태 확인
  3) tmux 시작:
       tmux new -s work
  4) claude 실행:
       claude

GitHub 계정 push (메모리 패턴):
  hongchal:    env -u GITHUB_TOKEN -u GITHUB_USERNAME bash -c 'gh auth switch -u hongchal && git push'
  thakicloud:  그냥 git push

────────────────────────────────────────
EOF
