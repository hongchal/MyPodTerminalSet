# Shared cache locations on persistent /DATA1 so large downloads survive pod
# churn. Sourced by bootstrap.sh (every module inherits it during install) and
# by bashrc.snippet (interactive shells). Safe under `set -euo pipefail` and in
# a plain interactive shell: only `:`-defaults + a tolerant mkdir.
#
# Without this, pip wheels (/root/.cache/pip) and HF models (~/.cache/huggingface)
# live on the ephemeral pod fs and every fresh pod re-downloads multi-GB of
# torch/vllm/model weights over slow B200 egress.

_mts_data_root=/DATA1/hongcheol
if [ -d "${_mts_data_root}" ]; then
  export PIP_CACHE_DIR="${PIP_CACHE_DIR:-${_mts_data_root}/.cache/pip}"
  export HF_HOME="${HF_HOME:-${_mts_data_root}/.cache/huggingface}"
  export NLTK_DATA="${NLTK_DATA:-${_mts_data_root}/nltk_data}"
  mkdir -p "${PIP_CACHE_DIR}" "${HF_HOME}" "${NLTK_DATA}" 2>/dev/null || true
fi
# Faster, more resilient HF downloads (hf_transfer is installed in 40-python).
export HF_HUB_ENABLE_HF_TRANSFER="${HF_HUB_ENABLE_HF_TRANSFER:-1}"
unset _mts_data_root
