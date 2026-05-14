#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SRC="${REPO_DIR}/config/tmux.conf"
DST="${HOME}/.tmux.conf"

# 기존 설정이 있으면 백업
if [[ -f "${DST}" && ! -L "${DST}" ]]; then
  if ! cmp -s "${SRC}" "${DST}"; then
    cp "${DST}" "${DST}.bak.$(date +%Y%m%d-%H%M%S)"
    echo "기존 tmux.conf 백업"
  fi
fi

cp -f "${SRC}" "${DST}"
echo "tmux.conf 적용 → ${DST}"

# 실행 중인 tmux 서버 있으면 reload
if command -v tmux >/dev/null && tmux info >/dev/null 2>&1; then
  tmux source-file "${DST}" 2>/dev/null && echo "running tmux server reloaded"
fi
