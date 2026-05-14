#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt update
apt install -y --no-install-recommends \
  ca-certificates curl wget git build-essential \
  rsync unzip less openssh-client locales tzdata gnupg \
  vim-tiny nano

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
