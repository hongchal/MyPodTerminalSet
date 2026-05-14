#!/usr/bin/env bash
set -euo pipefail

# apt 버전은 너무 옛날 (0.29) — git에서 직접 설치
apt purge -y fzf 2>/dev/null || true

if [[ ! -d "${HOME}/.fzf" ]]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.fzf"
fi

"${HOME}/.fzf/install" --key-bindings --completion --no-update-rc

# bashrc에 source 라인 (중복 방지)
if ! grep -q '~/.fzf.bash' "${HOME}/.bashrc" 2>/dev/null; then
  echo '[ -f ~/.fzf.bash ] && source ~/.fzf.bash' >> "${HOME}/.bashrc"
fi
