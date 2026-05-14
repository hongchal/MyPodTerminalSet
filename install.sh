#!/usr/bin/env bash
# Remote installer for MyPodTerminalSet.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/hongchal/MyPodTerminalSet/master/install.sh | bash
#
# Env overrides:
#   MTS_REPO     — git URL (default: https://github.com/hongchal/MyPodTerminalSet.git)
#   MTS_BRANCH   — branch/ref (default: master)
#   MTS_DEST     — clone destination (default: /DATA1/hongcheol/dotfiles, fallback: ~/MyPodTerminalSet)
#   MTS_MODULES  — comma-separated module shortnames (default: all)

set -euo pipefail

REPO="${MTS_REPO:-https://github.com/hongchal/MyPodTerminalSet.git}"
BRANCH="${MTS_BRANCH:-master}"
DEFAULT_DEST="/DATA1/hongcheol/dotfiles"
FALLBACK_DEST="${HOME}/MyPodTerminalSet"
DEST="${MTS_DEST:-${DEFAULT_DEST}}"
MODULES="${MTS_MODULES:-all}"

log()  { printf '\033[1;32m[install]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[install]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[install error]\033[0m %s\n' "$*" >&2; }

# 1. /DATA1 마운트 확인 (없으면 home으로 fallback)
if [[ "${DEST}" == "${DEFAULT_DEST}" && ! -d "/DATA1/hongcheol" ]]; then
  warn "/DATA1/hongcheol 없음 — fallback: ${FALLBACK_DEST}"
  DEST="${FALLBACK_DEST}"
fi

# 2. preflight — git 없으면 설치
if ! command -v git >/dev/null 2>&1; then
  log "git 없음 — 설치 시도"
  if command -v apt >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    apt update && apt install -y git
  elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache git
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y git
  elif command -v yum >/dev/null 2>&1; then
    yum install -y git
  else
    err "git을 자동 설치할 패키지 매니저 없음 (apt/apk/dnf/yum). 수동 설치 후 재시도."
    exit 1
  fi
fi

# 3. curl도 확인 (이미 install.sh 다운로드했으니 있을 가능성 큼)
if ! command -v curl >/dev/null 2>&1; then
  command -v apt >/dev/null && apt install -y curl ca-certificates
fi

# 4. clone 또는 update
mkdir -p "$(dirname "${DEST}")"
if [[ -d "${DEST}/.git" ]]; then
  log "기존 repo 갱신 → ${DEST}"
  ( cd "${DEST}" && git fetch --depth 1 origin "${BRANCH}" && git checkout "${BRANCH}" && git reset --hard "origin/${BRANCH}" )
elif [[ -e "${DEST}" ]]; then
  err "${DEST} 가 비어 있지 않음 (git repo도 아님). 다른 MTS_DEST 지정 필요."
  exit 1
else
  log "clone → ${DEST} (branch=${BRANCH})"
  git clone --depth 1 --branch "${BRANCH}" "${REPO}" "${DEST}"
fi

# 5. bootstrap 실행
cd "${DEST}"
log "▶ bootstrap.sh ${MODULES}"
bash "./bootstrap.sh" "${MODULES}"

log "✅ install 끝 — 'source ~/.bashrc' 후 'tmux new -s work'"
