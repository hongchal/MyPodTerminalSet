#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="${REPO_DIR}/modules"
MARKER="${HOME}/.pod_bootstrap_done"
export REPO_DIR

log()  { printf '\033[1;32m[bootstrap]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; }

SELECTED="${1:-all}"

run_module() {
  local m_path="$1"
  local m_name
  m_name="$(basename "${m_path}" .sh)"
  log "▶ ${m_name}"
  if ! bash "${m_path}"; then
    err "module failed: ${m_name}"
    exit 1
  fi
}

modules_all=$(find "${MODULES_DIR}" -maxdepth 1 -type f -name '*.sh' | sort)

if [[ "${SELECTED}" == "all" ]]; then
  for m in ${modules_all}; do run_module "${m}"; done
else
  IFS=',' read -ra picks <<< "${SELECTED}"
  for p in "${picks[@]}"; do
    match=$(echo "${modules_all}" | grep -E "/[0-9]+-${p}\.sh$" || true)
    if [[ -z "${match}" ]]; then
      err "no module matches: ${p}"
      echo "available:"
      for m in ${modules_all}; do
        echo "  - $(basename "${m}" .sh | sed -E 's/^[0-9]+-//')"
      done
      exit 1
    fi
    run_module "${match}"
  done
fi

touch "${MARKER}"
log "✅ bootstrap finished — open a new shell or 'source ~/.bashrc'"
