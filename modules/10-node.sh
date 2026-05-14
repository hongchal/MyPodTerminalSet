#!/usr/bin/env bash
set -euo pipefail

if command -v node >/dev/null 2>&1; then
  cur="$(node -v 2>/dev/null || echo v0)"
  if [[ "${cur}" =~ ^v(2[0-9]|[3-9][0-9])\. ]]; then
    echo "node already ${cur} — skip"
    exit 0
  fi
fi

curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
node -v
npm -v
