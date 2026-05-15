#!/usr/bin/env bash
set -euo pipefail

# Quantization-specific tooling.
# Currently:
# - nvidia-modelopt[hf]==0.43.0  (NVFP4 / INT4 / INT8 PTQ on B200 etc.)
#
# Depends on 41-ml-stack.sh having installed transformers/accelerate/datasets.

log()  { printf '\033[1;36m[quant-tools]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[quant-tools error]\033[0m %s\n' "$*" >&2; exit 1; }

command -v python3 >/dev/null 2>&1 || die "python3 not found"

log "nvidia-modelopt 0.43 (NVFP4 PTQ)"
pip install --break-system-packages -U --no-input "nvidia-modelopt[hf]==0.43.0"

log "done"
