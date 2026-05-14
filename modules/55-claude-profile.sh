#!/usr/bin/env bash
# Deploy custom agents/commands/skills from profile/ into ~/.claude/.
# Uses symlinks so editing in repo immediately reflects.
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SRC_DIR="${REPO_DIR}/profile"
DST_BASE="${HOME}/.claude"

log()  { printf '\033[1;36m[profile]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[profile]\033[0m %s\n' "$*"; }

[[ -d "${SRC_DIR}" ]] || { warn "${SRC_DIR} 없음 — skip"; exit 0; }
mkdir -p "${DST_BASE}"

for sub in agents commands skills; do
  src="${SRC_DIR}/${sub}"
  dst="${DST_BASE}/${sub}"

  [[ -d "${src}" ]] || continue

  # 플러그인이 ~/.claude/skills 같은 디렉터리에 이미 파일을 둘 수 있음.
  # 직접 디렉터리 자체를 symlink로 바꾸면 플러그인 콘텐츠 가려짐.
  # → 디렉터리는 유지, 파일/하위디렉터리 단위 symlink.
  mkdir -p "${dst}"

  shopt -s nullglob dotglob
  for item in "${src}"/*; do
    name=$(basename "${item}")
    # README/gitkeep은 deploy 대상 아님
    case "${name}" in
      README.md|.gitkeep) continue ;;
    esac

    target="${dst}/${name}"
    if [[ -L "${target}" ]] && [[ "$(readlink "${target}")" == "${item}" ]]; then
      continue  # 이미 올바른 link
    fi
    if [[ -e "${target}" ]] && [[ ! -L "${target}" ]]; then
      warn "${target} 가 일반 파일 — 백업 후 교체"
      mv "${target}" "${target}.bak.$(date +%s)"
    fi
    ln -sfn "${item}" "${target}"
    log "link: ${sub}/${name}"
  done
  shopt -u nullglob dotglob
done
