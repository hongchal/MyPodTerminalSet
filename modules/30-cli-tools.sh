#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt install -y --no-install-recommends \
  tmux ripgrep bat fd-find htop ncdu tree jq \
  bash-completion direnv less

# git-delta — apt에 없을 수 있음(Jammy 22.04 등). 시도 후 실패하면 GitHub release.
if ! command -v delta >/dev/null 2>&1; then
  if apt install -y git-delta 2>/dev/null; then
    echo "git-delta apt 설치 성공"
  else
    DV=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" \
          | grep -Po '"tag_name": "\K[^"]*')
    curl -fsSL "https://github.com/dandavison/delta/releases/download/${DV}/delta-${DV}-x86_64-unknown-linux-gnu.tar.gz" \
      | tar xz -C /tmp
    install "/tmp/delta-${DV}-x86_64-unknown-linux-gnu/delta" /usr/local/bin/
    rm -rf "/tmp/delta-${DV}-x86_64-unknown-linux-gnu"
    echo "git-delta v${DV} GitHub release 설치"
  fi
fi

# bat/fd 이름 정규화 (Debian 패키지는 batcat/fdfind로 깔림)
mkdir -p "${HOME}/.local/bin"
[ -x "$(command -v batcat 2>/dev/null)" ] && ln -sf "$(command -v batcat)" "${HOME}/.local/bin/bat"
[ -x "$(command -v fdfind 2>/dev/null)" ] && ln -sf "$(command -v fdfind)" "${HOME}/.local/bin/fd"

# gh CLI (apt 저장소 추가)
if ! command -v gh >/dev/null 2>&1; then
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg status=none
  chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list
  apt update
  apt install -y gh
fi

# lazygit (GitHub release)
if ! command -v lazygit >/dev/null 2>&1; then
  V=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
        | grep -Po '"tag_name": "v\K[^"]*')
  curl -fsSL "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${V}_Linux_x86_64.tar.gz" \
    | tar xz -C /tmp lazygit
  install /tmp/lazygit /usr/local/bin/
  rm -f /tmp/lazygit
fi
