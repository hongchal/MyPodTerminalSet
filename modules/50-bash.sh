#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SRC="${REPO_DIR}/config/bashrc.snippet"
MARKER_BEGIN="# >>> MyTerminalSet bootstrap >>>"
MARKER_END="# <<< MyTerminalSet bootstrap <<<"
RC="${HOME}/.bashrc"

touch "${RC}"

if ! grep -qF "${MARKER_BEGIN}" "${RC}"; then
  {
    echo ""
    echo "${MARKER_BEGIN}"
    cat "${SRC}"
    echo "${MARKER_END}"
  } >> "${RC}"
  echo "bashrc 스니펫 추가됨"
else
  echo "bashrc 스니펫 이미 존재 — skip"
fi

# git-prompt.sh (PS1에서 사용)
if [[ ! -f "${HOME}/.git-prompt.sh" ]]; then
  curl -fsSL https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh \
    -o "${HOME}/.git-prompt.sh"
fi
