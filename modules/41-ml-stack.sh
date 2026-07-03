#!/usr/bin/env bash
set -euo pipefail

# Common ML / LLM tooling — CPU-safe baseline for ALL machines.
# Targets python3.12 (installed by 40-python.sh). Not quantization-specific.
#
# - torch                 (CPU wheel — keeps CPU-only pods from pulling CUDA)
# - transformers / accelerate / datasets / huggingface_hub (+ hf_transfer)
# - lm-evaluation-harness (editable install from NFS clone) + IFEval task extras
# - nltk data (punkt, punkt_tab) into NFS-persistent NLTK_DATA dir
#
# GPU-only backends are split out and gated on nvidia-smi:
#   - vLLM            → 43-gpu-vllm.sh
#   - nvidia-modelopt → 44-gpu-quant.sh
# On GPU pods, 43 upgrades the CPU torch installed here to the matching CUDA build.

PERSIST_ROOT="${CLAUDE_PERSIST_ROOT:-/DATA1/hongcheol}"
QUANT_ROOT="${PERSIST_ROOT}/quantization"
LM_EVAL_DIR="${QUANT_ROOT}/lm-evaluation-harness"
NLTK_DIR="${PERSIST_ROOT}/nltk_data"

log()  { printf '\033[1;36m[ml-stack]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[ml-stack]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[ml-stack error]\033[0m %s\n' "$*" >&2; exit 1; }

command -v python3.12 >/dev/null 2>&1 || die "python3.12 not found — run 40-python.sh first"

PY=python3.12
PIP=("${PY}" -m pip install -U --no-input)

# Network resilience for large wheels on flaky pod egress. The torch CPU wheel
# is ~192MB and the transformers stack is also non-trivial; on a slow/resetting
# link pip's default resume budget (6 attempts) gets exhausted mid-download and
# aborts the whole module (-> bootstrap exit 1, skipping 43-99). Bump resume +
# connection retries and timeout for every pip call in this module.
export PIP_RESUME_RETRIES=50 PIP_RETRIES=10 PIP_DEFAULT_TIMEOUT=120

# torch CPU wheel first — without this, transformers pulls the default CUDA
# torch (+nvidia-* libs, multiple GB) even on CPU-only pods. On GPU pods,
# 43-gpu-vllm.sh replaces this with the matching CUDA build.
# Outer retry loop on top of --resume-retries: if pip exhausts its resume
# budget and exits, restart the install (it resumes from the partial cache).
log "torch (CPU wheel)"
for _i in 1 2 3; do
  "${PIP[@]}" --index-url https://download.pytorch.org/whl/cpu "torch" && break
  warn "torch install failed (attempt ${_i}/3) — retrying"; sleep 5
done
"${PY}" -c "import torch" 2>/dev/null || die "torch install failed after retries (network?)"

log "core HF + accel stack"
# transformers floor is >=5.5.3: vLLM >=0.24 dropped Transformers v4 support and
# hard-fails at import ("Support for Transformers v4 ... removed in vLLM v0.24.0")
# if it finds v4. Keeping this floor below vLLM's requirement lets a pod drift
# into a v4/vLLM-0.24 mismatch (transformers stuck at 4.x while vLLM upgrades),
# which breaks every vLLM serve. Pin at vLLM 0.24's floor so the two stay in sync.
"${PIP[@]}" \
  "transformers>=5.5.3" \
  "accelerate>=1.13" \
  "datasets>=3.0" \
  "huggingface_hub>=0.27" \
  "hf_transfer"

log "IFEval task extras (langdetect, immutabledict, nltk)"
"${PIP[@]}" "langdetect" "immutabledict" "nltk>=3.9.1"

# lm-evaluation-harness — clone if missing, then editable install
mkdir -p "${QUANT_ROOT}"
if [[ ! -d "${LM_EVAL_DIR}/.git" ]]; then
  log "cloning lm-evaluation-harness into ${LM_EVAL_DIR}"
  # Retry: a single timed-out clone on slow egress would abort the chain.
  for _i in 1 2 3; do
    rm -rf "${LM_EVAL_DIR}"
    git clone https://github.com/EleutherAI/lm-evaluation-harness.git "${LM_EVAL_DIR}" && break
    warn "lm-eval clone failed (attempt ${_i}/3) — retrying"; sleep 3
  done
  [[ -d "${LM_EVAL_DIR}/.git" ]] || { warn "lm-eval clone failed — aborting module"; exit 1; }
fi
log "editable install: ${LM_EVAL_DIR}"
"${PY}" -m pip install -e "${LM_EVAL_DIR}"

# nltk data → NFS-persistent (NLTK_DATA env var is set in bashrc.snippet)
mkdir -p "${NLTK_DIR}"
log "nltk data dir: ${NLTK_DIR}"
NLTK_DATA="${NLTK_DIR}" "${PY}" - <<PY 2>&1 | tail -5 || warn "nltk download failed"
import nltk, os
for pkg in ("punkt", "punkt_tab"):
    nltk.download(pkg, download_dir=os.environ["NLTK_DATA"], quiet=False)
PY

log "done"
