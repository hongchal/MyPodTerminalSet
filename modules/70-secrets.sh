#!/usr/bin/env bash
set -euo pipefail

PERSIST_ROOT="${SECRETS_PERSIST_ROOT:-/DATA1/hongcheol}"
SECRETS_DIR="${PERSIST_ROOT}/.secrets"
PLACEHOLDER="REPLACE_ME"

log()  { printf '\033[1;36m[secrets]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[secrets]\033[0m %s\n' "$*"; }

if [[ ! -d "${PERSIST_ROOT}" ]]; then
  warn "${PERSIST_ROOT} 없음 — /DATA1 마운트 / 노드 핀 확인. secrets 건너뜀."
  exit 0
fi

mkdir -p "${SECRETS_DIR}"
chmod 700 "${SECRETS_DIR}"

# 파일명 | env var | 발급처 메모
TEMPLATES=(
  "anthropic.env|ANTHROPIC_API_KEY|console.anthropic.com/settings/keys"
  "wandb.env|WANDB_API_KEY|wandb.ai/authorize"
  "huggingface.env|HF_TOKEN|huggingface.co/settings/tokens (Read 권한)"
  "openai.env|OPENAI_API_KEY|platform.openai.com/api-keys"
  "github-hongchal.env|GH_TOKEN_HONGCHAL|github.com/settings/tokens (hongchal 계정, repo+workflow)"
  "github-thakicloud.env|GH_TOKEN_THAKICLOUD|github.com/settings/tokens (chohongcheol-thakicloud)"
  "notion.env|NOTION_TOKEN|notion.so/my-integrations"
)

for entry in "${TEMPLATES[@]}"; do
  IFS='|' read -r file var note <<< "${entry}"
  target="${SECRETS_DIR}/${file}"
  if [[ ! -f "${target}" ]]; then
    cat > "${target}" << EOF
# ${var}
# Where: ${note}
# Fill in the value below, then remove the leading '#' on the export line.

# export ${var}=${PLACEHOLDER}
EOF
    chmod 600 "${target}"
    log "생성 → ${target}"
  else
    chmod 600 "${target}"
  fi
done

# README
README="${SECRETS_DIR}/README.md"
if [[ ! -f "${README}" ]]; then
  cat > "${README}" << 'EOF'
# Secrets — 평문 보관소

이 디렉터리의 모든 `.env` 파일은 **평문**입니다.
- 권한: dir 700, files 600 (소유자만 읽기)
- 위치: 호스트 영속 디스크 (/DATA1) — pod 재생성에도 보존
- **Git에 commit 금지** — 어디에도 push 안 됨
- 키 노출 의심 시 즉시 콘솔에서 revoke + 재발급

## 파일 목록
- `anthropic.env`         — Claude API
- `wandb.env`             — WandB 학습 로깅
- `huggingface.env`       — HF 모델/데이터셋
- `openai.env`            — OpenAI API
- `github-hongchal.env`   — hongchal 계정 PAT
- `github-thakicloud.env` — thakicloud 계정 PAT
- `notion.env`            — Notion Integration

## 사용
각 파일 편집 → 실제 값 입력 → export 줄의 `#` 제거 → 저장.
```
source /DATA1/hongcheol/.secrets/anthropic.env
```
혹은 ~/.bashrc 자동 로드 (bootstrap이 anthropic만 자동 source). 나머지는
프로젝트별 direnv `.envrc`에서 필요한 것만 source 권장.

## 상태 확인
```
secrets-status
```
EOF
  chmod 600 "${README}"
  log "생성 → ${README}"
fi

# bashrc 자동 source (anthropic만, 나머지는 direnv 권장)
RC="${HOME}/.bashrc"
LINE="[ -f ${SECRETS_DIR}/anthropic.env ] && source ${SECRETS_DIR}/anthropic.env"
if ! grep -qF "${SECRETS_DIR}/anthropic.env" "${RC}" 2>/dev/null; then
  echo "${LINE}" >> "${RC}"
  log "bashrc에 anthropic.env 자동 source 추가"
fi

# 점검
log "─── 점검 ───"
unfilled=()
for entry in "${TEMPLATES[@]}"; do
  IFS='|' read -r file _ _ <<< "${entry}"
  target="${SECRETS_DIR}/${file}"
  if grep -q "^# export .*${PLACEHOLDER}" "${target}" 2>/dev/null; then
    unfilled+=("${file}")
  fi
done

if (( ${#unfilled[@]} > 0 )); then
  warn "아직 placeholder 상태:"
  for f in "${unfilled[@]}"; do echo "  - ${SECRETS_DIR}/${f}"; done
  echo ""
  echo "편집:  vi ${SECRETS_DIR}/anthropic.env"
  echo "그 안에서 '# export VAR=REPLACE_ME' 줄의 # 제거 + REPLACE_ME → 실제 키"
  echo "그 다음:  source ~/.bashrc"
else
  log "✅ 모든 시크릿 파일 채워짐"
fi
