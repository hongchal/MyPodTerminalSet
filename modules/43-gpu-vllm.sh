#!/usr/bin/env bash
set -euo pipefail

# GPU-only inference backend. Targets python3.12.
#
# - vLLM (high-throughput inference backend)
#
# vLLM pulls the CUDA build of torch (+nvidia-* libs), replacing the CPU torch
# installed by 41-ml-stack.sh. Gated on nvidia-smi so CPU-only pods skip it.
# Depends on 41-ml-stack.sh (transformers/accelerate already present).

log()  { printf '\033[1;36m[gpu-vllm]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[gpu-vllm]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[gpu-vllm error]\033[0m %s\n' "$*" >&2; exit 1; }

command -v python3.12 >/dev/null 2>&1 || die "python3.12 not found — run 40-python.sh first"

if ! command -v nvidia-smi >/dev/null 2>&1; then
  warn "no GPU (nvidia-smi not found) — skipping vLLM"
  exit 0
fi

PY=python3.12

log "vLLM (inference backend) → pulls CUDA torch"
"${PY}" -m pip install -U --no-input "vllm>=0.18" \
  || warn "vllm install failed — workflows depending on vllm will need fallback"

log "done"
