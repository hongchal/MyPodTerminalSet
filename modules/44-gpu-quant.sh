#!/usr/bin/env bash
set -euo pipefail

# GPU-only quantization tooling. Targets python3.12.
#
# - nvidia-modelopt[hf]==0.43.0  (NVFP4 / INT4 / INT8 PTQ on B200 etc.)
#
# Gated on nvidia-smi so CPU-only pods skip it. Depends on 41-ml-stack.sh
# (transformers/accelerate/datasets) and a CUDA torch from 43-gpu-vllm.sh.

log()  { printf '\033[1;36m[gpu-quant]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[gpu-quant]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[gpu-quant error]\033[0m %s\n' "$*" >&2; exit 1; }

command -v python3.12 >/dev/null 2>&1 || die "python3.12 not found — run 40-python.sh first"

if ! command -v nvidia-smi >/dev/null 2>&1; then
  warn "no GPU (nvidia-smi not found) — skipping nvidia-modelopt"
  exit 0
fi

log "nvidia-modelopt 0.43 (NVFP4 PTQ) → python3.12"
python3.12 -m pip install -U --no-input "nvidia-modelopt[hf]==0.43.0"

log "done"
