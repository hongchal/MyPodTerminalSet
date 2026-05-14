#!/usr/bin/env bash
set -euo pipefail

# uv (Rust 기반 pip 대체)
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# nvitop (GPU 모니터) + ipython + hf_transfer (HF 다운로드 가속)
if command -v pip3 >/dev/null 2>&1; then
  pip3 install --no-input -U nvitop ipython hf_transfer 2>/dev/null || \
    python3 -m pip install --no-input -U --break-system-packages nvitop ipython hf_transfer
elif command -v python3 >/dev/null 2>&1; then
  python3 -m pip install --no-input -U --break-system-packages nvitop ipython hf_transfer || true
fi
