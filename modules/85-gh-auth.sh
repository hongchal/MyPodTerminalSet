#!/usr/bin/env bash
# .secrets에 채워진 GH 토큰으로 gh CLI 로그인 + git credential helper 셋업.
# 두 계정(thakicloud=회사, hongchal=개인) 모두 시도. 마지막 로그인이 active가 되므로
# hongchal을 마지막에 두어 dotfiles repo(hongchal/MyPodTerminalSet) push 기본값으로 둔다.
set -euo pipefail

PERSIST_ROOT="${SECRETS_PERSIST_ROOT:-/DATA1/hongcheol}"
SECRETS_DIR="${PERSIST_ROOT}/.secrets"

log()  { printf '\033[1;36m[gh-auth]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[gh-auth]\033[0m %s\n' "$*"; }

if ! command -v gh >/dev/null 2>&1; then
  warn "gh 미설치 — 30-cli-tools.sh가 먼저 실행되어야 함. skip."
  exit 0
fi

if [[ ! -d "${SECRETS_DIR}" ]]; then
  warn "${SECRETS_DIR} 없음 — skip."
  exit 0
fi

# (file, var) — 마지막 로그인이 active. hongchal을 마지막에.
ENTRIES=(
  "github-thakicloud.env|GH_TOKEN_THAKICLOUD"
  "github-hongchal.env|GH_TOKEN_HONGCHAL"
)

login_one() {
  local file="$1" var="$2" target="${SECRETS_DIR}/${file}"
  if [[ ! -f "${target}" ]]; then
    warn "${file} 없음 — skip"
    return 0
  fi

  # subshell에서 source → 토큰값을 셸 히스토리/transcript에 노출하지 않고 사용
  local token
  token="$(set -a; source "${target}" 2>/dev/null; printf '%s' "${!var:-}")"

  if [[ -z "${token}" || "${token}" == *REPLACE_ME* ]]; then
    warn "${file}의 ${var} placeholder/빈값 — skip"
    return 0
  fi

  if printf '%s' "${token}" | gh auth login --with-token --hostname github.com 2>/dev/null; then
    log "✅ ${file} 로그인 OK (${var})"
  else
    warn "${file} 로그인 실패 (${var})"
  fi
}

for entry in "${ENTRIES[@]}"; do
  IFS='|' read -r file var <<< "${entry}"
  login_one "${file}" "${var}"
done

# git이 https push 시 gh credential 사용
if gh auth status >/dev/null 2>&1; then
  gh auth setup-git 2>/dev/null && log "git credential helper → gh"
else
  warn "활성 gh 세션 없음 — setup-git skip"
fi

log "─── 현재 로그인 ───"
gh auth status 2>&1 | grep -E "Logged in|Active account" || true
