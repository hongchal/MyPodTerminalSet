#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt update
apt install -y --no-install-recommends \
  ca-certificates curl wget git build-essential \
  rsync unzip less openssh-client locales tzdata gnupg \
  vim nano jq

# vim-tiny가 이미 깔려 있으면 제거 (정상 vim에 자리 양보)
if dpkg -l vim-tiny >/dev/null 2>&1; then
  apt remove -y vim-tiny 2>/dev/null || true
fi

# 최소 .vimrc — vim-tiny 깔린 적 있는 경우 잔존 설정 무력화
VIMRC="${HOME}/.vimrc"
if [[ ! -f "${VIMRC}" ]]; then
  cat > "${VIMRC}" << 'EOF'
set nocompatible
set backspace=indent,eol,start
set showmode
set showcmd
set ruler
set number
set mouse=a
syntax on
filetype plugin indent on
set expandtab
set tabstop=2
set shiftwidth=2
set hlsearch
set incsearch
EOF
  echo "최소 .vimrc 생성"
fi

# UTF-8 로케일 — /etc/locale.gen에 라인 보장 후 generate
if [[ -f /etc/locale.gen ]]; then
  if ! grep -qE '^[[:space:]]*en_US\.UTF-8 UTF-8' /etc/locale.gen; then
    echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
  fi
fi
locale-gen en_US.UTF-8 || true
update-locale LANG=en_US.UTF-8 || true

# 실제로 컴파일됐는지 확인
if locale -a 2>/dev/null | grep -qi '^en_US\.utf-\?8$'; then
  echo "locale en_US.UTF-8 OK"
else
  echo "locale en_US.UTF-8 미생성 — bashrc는 C.UTF-8 fallback 사용"
fi
