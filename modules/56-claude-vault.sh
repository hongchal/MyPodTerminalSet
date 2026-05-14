#!/usr/bin/env bash
# Build vault/rules/*.md into ~/.claude/CLAUDE.user.md.
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BUILD="${REPO_DIR}/vault/scripts/build.sh"

[[ -x "${BUILD}" ]] || { echo "[vault] no build script — skip"; exit 0; }

REPO_DIR="${REPO_DIR}" bash "${BUILD}"

# OMC가 CLAUDE.md를 관리하므로, @CLAUDE.user.md 참조 자동 추가는 하지 않음.
# 사용자가 처음 한 번 ~/.claude/CLAUDE.md 끝에 다음 한 줄 추가:
#   @CLAUDE.user.md
# 그 이후로는 부트스트랩이 알아서 build만 함.

GLOBAL="${HOME}/.claude/CLAUDE.md"
USER_FILE="${HOME}/.claude/CLAUDE.user.md"
if [[ -f "${GLOBAL}" ]] && ! grep -qF '@CLAUDE.user.md' "${GLOBAL}"; then
  cat << EOF

[vault] tip: vault 룰을 글로벌 CLAUDE.md에 포함시키려면 ~/.claude/CLAUDE.md 끝에 한 줄 추가:
  @CLAUDE.user.md

또는 zero-config로 가려면 CLAUDE.user.md를 프로젝트별로 따로 reference.
EOF
fi
