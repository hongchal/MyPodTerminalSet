#!/usr/bin/env bash
set -euo pipefail

# Python 3.12 on Ubuntu 22.04 (which ships 3.10).
#
# Installs:
#   - python3.12 + venv + dev headers (via deadsnakes PPA)
#   - pip for python3.12 (via ensurepip)
#   - `python` alternative → python3.12
#     (keep `/usr/bin/python3` = 3.10 untouched so apt internals stay intact)
#   - uv (Rust-based pip replacement)
#   - nvitop (GPU 모니터), ipython, hf_transfer (HF 다운로드 가속) — into 3.12

export DEBIAN_FRONTEND=noninteractive

log()  { printf '\033[1;36m[python]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[python]\033[0m %s\n' "$*"; }

# 1. python3.12 (deadsnakes PPA)
if ! command -v python3.12 >/dev/null 2>&1; then
  log "installing python3.12 from deadsnakes PPA"
  apt update
  apt install -y --no-install-recommends software-properties-common ca-certificates
  add-apt-repository -y ppa:deadsnakes/ppa
  apt update
  apt install -y --no-install-recommends \
    python3.12 python3.12-venv python3.12-dev
fi

# 2. pip into python3.12
if ! python3.12 -m pip --version >/dev/null 2>&1; then
  log "bootstrapping pip into python3.12 (ensurepip)"
  python3.12 -m ensurepip --upgrade
fi
python3.12 -m pip install --no-input -U pip setuptools wheel

# 3. `python` → python3.12 (system `python3` stays 3.10 for apt's sake)
update-alternatives --install /usr/bin/python python /usr/bin/python3.12 100 >/dev/null 2>&1 || \
  warn "update-alternatives for 'python' failed (non-fatal)"

# 4. uv (Rust-based pip replacement)
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# 5. nvitop + ipython + hf_transfer into python3.12
log "nvitop / ipython / hf_transfer → python3.12"
python3.12 -m pip install --no-input -U nvitop ipython hf_transfer
