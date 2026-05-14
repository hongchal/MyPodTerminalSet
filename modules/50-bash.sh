#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SRC="${REPO_DIR}/config/bashrc.snippet"
MARKER_BEGIN="# >>> MyPodTerminalSet bootstrap >>>"
MARKER_END="# <<< MyPodTerminalSet bootstrap <<<"
RC="${HOME}/.bashrc"

touch "${RC}"

# 기존 블록 제거 — 현재 마커 + 옛날 마커(MyTerminalSet → MyPodTerminalSet 리네임 이전) 둘 다
STAMP="$(date +%Y%m%d-%H%M%S)"
NEEDS_BACKUP=0
for begin in "${MARKER_BEGIN}" "# >>> MyTerminalSet bootstrap >>>"; do
  end="$(echo "${begin}" | sed 's/>>>/<<</g' | sed 's/^# >>>/# <<</')"
  if grep -qF "${begin}" "${RC}" 2>/dev/null; then
    if [[ "${NEEDS_BACKUP}" -eq 0 ]]; then
      cp "${RC}" "${RC}.mts.bak.${STAMP}"
      echo "bashrc 백업: ${RC}.mts.bak.${STAMP}"
      NEEDS_BACKUP=1
    fi
    sed -i "/$(printf '%s' "${begin}" | sed 's:[][\\/.^$*]:\\&:g')/,/$(printf '%s' "${end}" | sed 's:[][\\/.^$*]:\\&:g')/d" "${RC}"
    echo "기존 블록 제거: ${begin}"
  fi
done

# Docker 베이스 이미지의 .profile에 'exec /usr/bin/bash'가 있으면 Claude Code의 persistent
# bash가 깨짐. CLAUDECODE env var이 set일 때만 skip하는 가드로 무력화.
PROFILE="${HOME}/.profile"
if [[ -f "${PROFILE}" ]] && grep -qE '^\[ -x /usr/bin/bash \] && exec /usr/bin/bash' "${PROFILE}"; then
  cp "${PROFILE}" "${PROFILE}.mts.bak.${STAMP}"
  sed -i 's|^\[ -x /usr/bin/bash \] && exec /usr/bin/bash|# MyPodTerminalSet: Claude Code의 persistent bash와 충돌 방지\n[ -z "${CLAUDECODE:-}" ] \&\& [ -x /usr/bin/bash ] \&\& exec /usr/bin/bash|' "${PROFILE}"
  echo ".profile의 exec bash에 CLAUDECODE 가드 추가 (백업: ${PROFILE}.mts.bak.${STAMP})"
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
