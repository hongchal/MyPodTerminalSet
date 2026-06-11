#!/usr/bin/env bash
set -euo pipefail

# fzf — installed from git (apt's 0.29 is too old). ~/.fzf lives on the ephemeral
# pod fs, so every fresh pod re-clones; on slow B200 egress a bare `git clone`
# can time out and abort the dotfile chain. Retry the clone and keep the whole
# module non-fatal (fzf is a convenience, not essential).

warn() { printf '\033[1;33m[fzf]\033[0m %s\n' "$*"; }

apt purge -y fzf 2>/dev/null || true

clone_fzf() {
  local i
  for i in 1 2 3; do
    rm -rf "${HOME}/.fzf"
    if git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.fzf"; then
      return 0
    fi
    warn "git clone failed (attempt ${i}/3) — retrying"
    sleep 3
  done
  return 1
}

if [[ ! -d "${HOME}/.fzf/.git" ]]; then
  clone_fzf || { warn "fzf clone failed — skipping (non-fatal)"; exit 0; }
fi

"${HOME}/.fzf/install" --key-bindings --completion --no-update-rc || {
  warn "fzf install script failed — skipping (non-fatal)"; exit 0;
}

# bashrc source line (idempotent)
if ! grep -q '~/.fzf.bash' "${HOME}/.bashrc" 2>/dev/null; then
  echo '[ -f ~/.fzf.bash ] && source ~/.fzf.bash' >> "${HOME}/.bashrc"
fi
