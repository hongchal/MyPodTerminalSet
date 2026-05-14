#!/usr/bin/env bash
# Deploy Claude plugin/marketplace declarations into ~/.claude/settings.json.
# Claude Code fetches the actual plugin code on first run.
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TEMPLATE="${REPO_DIR}/config/claude-settings.template.json"
TARGET_DIR="${HOME}/.claude"
TARGET="${TARGET_DIR}/settings.json"

log()  { printf '\033[1;36m[claude-plugins]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[claude-plugins]\033[0m %s\n' "$*"; }

[[ -f "${TEMPLATE}" ]] || { warn "템플릿 없음 — skip"; exit 0; }

# jq 필요
if ! command -v jq >/dev/null 2>&1; then
  command -v apt >/dev/null && apt install -y jq || {
    warn "jq 설치 실패 — claude-plugins skip"
    exit 0
  }
fi

# ~/.claude는 25-claude-sync 이후 symlink. 디렉터리 존재 보장.
mkdir -p "${TARGET_DIR}"

if [[ -f "${TARGET}" ]]; then
  STAMP="$(date +%Y%m%d-%H%M%S)"
  cp "${TARGET}" "${TARGET}.bak.${STAMP}"
  log "기존 settings.json 백업 → ${TARGET}.bak.${STAMP}"

  # jq deep-merge: 우측(template) 우선
  if jq -s '.[0] * .[1]' "${TARGET}" "${TEMPLATE}" > "${TARGET}.tmp"; then
    mv "${TARGET}.tmp" "${TARGET}"
    log "settings.json deep-merged"
  else
    rm -f "${TARGET}.tmp"
    warn "merge 실패 — 원본 유지"
    exit 1
  fi
else
  cp "${TEMPLATE}" "${TARGET}"
  log "settings.json 신규 deploy"
fi

# 결과 요약
log "─── 활성화될 플러그인 ───"
jq -r '.enabledPlugins | to_entries[] | "  • " + .key + " = " + (.value|tostring)' "${TARGET}" 2>/dev/null || true
log "─── 등록된 마켓플레이스 ───"
jq -r '.extraKnownMarketplaces | to_entries[] | "  • " + .key' "${TARGET}" 2>/dev/null || true

cat << 'EOF'

다음에 'claude' 처음 실행하면 활성 플러그인을 자동 fetch합니다.
- 인터넷 필요 (private repo는 git 인증 필요 — SUPERSKILLRET 등)
- fetch 안 되면: 'claude' 대화 안에서 /plugin add-marketplace <src> 또는 /plugin install <name>
EOF
