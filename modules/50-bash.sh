#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SRC="${REPO_DIR}/config/bashrc.snippet"
MARKER_BEGIN="# >>> MyTerminalSet bootstrap >>>"
MARKER_END="# <<< MyTerminalSet bootstrap <<<"
RC="${HOME}/.bashrc"

touch "${RC}"

# 기존 블록이 있으면 제거 후 재적용 (idempotent update)
if grep -qF "${MARKER_BEGIN}" "${RC}"; then
  cp "${RC}" "${RC}.mts.bak.$(date +%Y%m%d-%H%M%S)"
  sed -i "/$(printf '%s' "${MARKER_BEGIN}" | sed 's:[][\\/.^$*]:\\&:g')/,/$(printf '%s' "${MARKER_END}" | sed 's:[][\\/.^$*]:\\&:g')/d" "${RC}"
  echo "bashrc 기존 스니펫 제거 (백업: ${RC}.mts.bak.*)"
fi

{
  echo ""
  echo "${MARKER_BEGIN}"
  cat "${SRC}"
  echo "${MARKER_END}"
} >> "${RC}"
echo "bashrc 스니펫 적용됨"

# git-prompt.sh (PS1에서 사용)
if [[ ! -f "${HOME}/.git-prompt.sh" ]]; then
  curl -fsSL https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh \
    -o "${HOME}/.git-prompt.sh"
fi
