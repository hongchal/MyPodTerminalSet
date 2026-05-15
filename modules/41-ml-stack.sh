#!/usr/bin/env bash
set -euo pipefail

# Common ML / LLM tooling — inference, fine-tuning, evaluation.
# Not quantization-specific. Used by any LLM workflow on this pod.
#
# - transformers / accelerate / datasets / huggingface_hub (+ hf_transfer)
# - vLLM                  (high-throughput inference backend)
# - lm-evaluation-harness (editable install from NFS clone) + IFEval task extras
# - nltk data (punkt, punkt_tab) into NFS-persistent NLTK_DATA dir
#
# For quantization-specific deps (nvidia-modelopt) see 42-quant-tools.sh.

PERSIST_ROOT="${CLAUDE_PERSIST_ROOT:-/DATA1/hongcheol}"
QUANT_ROOT="${PERSIST_ROOT}/quantization"
LM_EVAL_DIR="${QUANT_ROOT}/lm-evaluation-harness"
NLTK_DIR="${PERSIST_ROOT}/nltk_data"

log()  { printf '\033[1;36m[ml-stack]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[ml-stack]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[ml-stack error]\033[0m %s\n' "$*" >&2; exit 1; }

command -v python3 >/dev/null 2>&1 || die "python3 not found"

PIP=(pip install --break-system-packages -U --no-input)

log "core HF + accel stack"
"${PIP[@]}" \
  "transformers>=4.57" \
  "accelerate>=1.13" \
  "datasets>=3.0" \
  "huggingface_hub>=0.27" \
  "hf_transfer"

log "vLLM (inference backend)"
"${PIP[@]}" "vllm>=0.18" || warn "vllm install failed — workflows depending on vllm will need fallback"

log "IFEval task extras (langdetect, immutabledict, nltk)"
"${PIP[@]}" "langdetect" "immutabledict" "nltk>=3.9.1"

# lm-evaluation-harness — clone if missing, then editable install
mkdir -p "${QUANT_ROOT}"
if [[ ! -d "${LM_EVAL_DIR}/.git" ]]; then
  log "cloning lm-evaluation-harness into ${LM_EVAL_DIR}"
  git clone https://github.com/EleutherAI/lm-evaluation-harness.git "${LM_EVAL_DIR}"
fi
log "editable install: ${LM_EVAL_DIR}"
pip install --break-system-packages -e "${LM_EVAL_DIR}"

# nltk data → NFS-persistent (NLTK_DATA env var is set in bashrc.snippet)
mkdir -p "${NLTK_DIR}"
log "nltk data dir: ${NLTK_DIR}"
NLTK_DATA="${NLTK_DIR}" python3 - <<PY 2>&1 | tail -5 || warn "nltk download failed"
import nltk, os
for pkg in ("punkt", "punkt_tab"):
    nltk.download(pkg, download_dir=os.environ["NLTK_DATA"], quiet=False)
PY

log "done"
