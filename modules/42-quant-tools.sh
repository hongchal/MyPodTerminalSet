#!/usr/bin/env bash
set -euo pipefail

# Quantization-specific tooling. Targets python3.12.
# Currently:
# - nvidia-modelopt[hf]==0.43.0  (NVFP4 / INT4 / INT8 PTQ on B200 etc.)
#
# Depends on 41-ml-stack.sh having installed transformers/accelerate/datasets
# into python3.12.

log()  { printf '\033[1;36m[quant-tools]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[quant-tools error]\033[0m %s\n' "$*" >&2; exit 1; }

command -v python3.12 >/dev/null 2>&1 || die "python3.12 not found — run 40-python.sh first"

log "nvidia-modelopt 0.43 (NVFP4 PTQ) → python3.12"
python3.12 -m pip install -U --no-input "nvidia-modelopt[hf]==0.43.0"

log "done"
