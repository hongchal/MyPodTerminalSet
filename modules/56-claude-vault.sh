#!/usr/bin/env bash
# Build vault/rules/*.md into ~/.claude/CLAUDE.user.md.
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BUILD="${REPO_DIR}/vault/scripts/build.sh"

[[ -x "${BUILD}" ]] || { echo "[vault] no build script — skip"; exit 0; }

REPO_DIR="${REPO_DIR}" bash "${BUILD}"

# Claude Code auto-loads ~/.claude/CLAUDE.md (not CLAUDE.user.md), so we
# ensure CLAUDE.md exists and imports vault rules via `@CLAUDE.user.md`.
# The import line coexists safely with any other content (e.g. OMC additions).
GLOBAL="${HOME}/.claude/CLAUDE.md"
mkdir -p "$(dirname "${GLOBAL}")"
if [[ ! -f "${GLOBAL}" ]]; then
  echo "@CLAUDE.user.md" > "${GLOBAL}"
  echo "[vault] created ${GLOBAL} with @CLAUDE.user.md import"
elif ! grep -qF '@CLAUDE.user.md' "${GLOBAL}"; then
  printf '\n@CLAUDE.user.md\n' >> "${GLOBAL}"
  echo "[vault] appended @CLAUDE.user.md import to ${GLOBAL}"
fi
