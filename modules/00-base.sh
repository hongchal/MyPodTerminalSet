#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt update
apt install -y --no-install-recommends \
  ca-certificates curl wget git build-essential \
  rsync unzip less openssh-client locales tzdata gnupg

# UTF-8 로케일
locale-gen en_US.UTF-8 || true
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 || true
