#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# git 글로벌 별칭/페이저
git config --global core.pager 'delta' 2>/dev/null || git config --global core.pager less
git config --global interactive.diffFilter 'delta --color-only' 2>/dev/null || true
git config --global delta.line-numbers true 2>/dev/null || true
git config --global pull.rebase true
git config --global init.defaultBranch main
git config --global push.autoSetupRemote true

git config --global alias.st 'status -sb'
git config --global alias.co 'checkout'
git config --global alias.br 'branch -vv'
git config --global alias.ci 'commit'
git config --global alias.lg 'log --oneline --graph --decorate --all -30'
git config --global alias.last 'log -1 HEAD --stat'
git config --global alias.unstage 'reset HEAD --'

echo "git config applied. user.name/user.email은 환경마다 다르므로 수동 설정 권장:"
echo "  git config --global user.name 'hongchal'"
echo "  git config --global user.email 'chal405@naver.com'"

# gitconfig snippet 적용 (PR alias 등)
SNIPPET="${REPO_DIR}/config/gitconfig.snippet"
if [[ -f "${SNIPPET}" ]]; then
  # Include 방식으로 보호 (덮어쓰기 회피)
  TARGET="${HOME}/.gitconfig.myterminalset"
  cp -f "${SNIPPET}" "${TARGET}"
  if ! git config --global --get-all include.path | grep -qx "${TARGET}"; then
    git config --global --add include.path "${TARGET}"
    echo "git include.path 추가 → ${TARGET}"
  fi
fi
