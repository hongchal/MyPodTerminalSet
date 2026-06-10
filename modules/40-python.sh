#!/usr/bin/env bash
set -euo pipefail

# Python 3.12 on Ubuntu 22.04 (which ships 3.10).
#
# Source strategy (robust across pods with flaky egress):
#   1. deadsnakes PPA  → system python3.12 under /usr/bin   (preferred)
#   2. uv-managed CPython → /usr/local/bin/python3.12 symlink (fallback)
#
# Some pods have near-dead egress to launchpad (ppa.launchpadcontent.net),
# which makes the deadsnakes path hang/time out. In that case we fall back to
# uv's GitHub-hosted standalone CPython, which downloads in seconds.
#
# Env knobs:
#   PY_SKIP_DEADSNAKES=1     → skip PPA entirely, go straight to uv
#   PY_DEADSNAKES_TIMEOUT=N  → per-step timeout for the PPA path (default 420s)
#
# Also installs (into python3.12): pip, uv, nvitop, ipython, hf_transfer.
# `python` alternative → python3.12 (system `python3` stays 3.10 for apt).

export DEBIAN_FRONTEND=noninteractive

log()  { printf '\033[1;36m[python]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[python]\033[0m %s\n' "$*"; }

# uv (Rust-based pip/python manager). Installed early so it can also serve as
# the python3.12 source when the deadsnakes PPA is unreachable.
ensure_uv() {
  if ! command -v uv >/dev/null 2>&1; then
    log "installing uv"
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
  export PATH="${HOME}/.local/bin:${PATH}"
  command -v uv >/dev/null 2>&1
}

# Preferred path: deadsnakes PPA → /usr/bin/python3.12. Bounded by a timeout
# because launchpad egress is unreliable on some pods.
try_deadsnakes_py312() {
  local t="${PY_DEADSNAKES_TIMEOUT:-420}"
  timeout "$t" apt-get update || return 1
  timeout "$t" apt-get install -y --no-install-recommends \
    software-properties-common ca-certificates || return 1
  timeout "$t" add-apt-repository -y ppa:deadsnakes/ppa || return 1
  timeout "$t" apt-get update || return 1
  timeout "$t" apt-get install -y --no-install-recommends \
    python3.12 python3.12-venv python3.12-dev || return 1
  command -v python3.12 >/dev/null 2>&1
}

# Fallback path: uv-managed standalone CPython, exposed as python3.12 in PATH.
install_py312_via_uv() {
  ensure_uv || { warn "uv unavailable — cannot fall back"; return 1; }
  uv python install 3.12 || return 1
  local py
  py="$(UV_PYTHON_PREFERENCE=only-managed uv python find 3.12 2>/dev/null)" || return 1
  [ -x "$py" ] || return 1
  ln -sf "$py" /usr/local/bin/python3.12
  hash -r
  command -v python3.12 >/dev/null 2>&1
}

# 1. python3.12 (deadsnakes preferred, uv fallback)
if ! command -v python3.12 >/dev/null 2>&1; then
  log "installing python3.12"
  ensure_uv || warn "uv install failed (will retry inside fallback)"

  if [ "${PY_SKIP_DEADSNAKES:-0}" != "1" ] && try_deadsnakes_py312; then
    log "python3.12 ← deadsnakes PPA ($(command -v python3.12))"
  else
    warn "deadsnakes PPA unavailable/slow — falling back to uv-managed python3.12"
    install_py312_via_uv || { warn "python3.12 install failed (both paths)"; exit 1; }
    log "python3.12 ← uv ($(command -v python3.12))"
  fi
fi

PY312_BIN="$(command -v python3.12)"

# uv-managed CPython ships a PEP 668 EXTERNALLY-MANAGED marker that blocks
# `pip install`. We use python3.12 as the primary interpreter for the ML stack
# (downstream modules run `python3.12 -m pip install ...`), so drop the marker
# to make it behave like a normal pip-managed python. No-op on a deadsnakes
# system python (no marker), and idempotent across re-runs.
EM="$("${PY312_BIN}" -c 'import sysconfig,os;print(os.path.join(sysconfig.get_path("stdlib"),"EXTERNALLY-MANAGED"))' 2>/dev/null || true)"
if [ -n "${EM}" ] && [ -f "${EM}" ]; then
  rm -f "${EM}" && warn "removed EXTERNALLY-MANAGED marker (uv-managed python) to allow pip"
fi

# 2. pip into python3.12 (uv-managed builds already bundle pip)
if ! python3.12 -m pip --version >/dev/null 2>&1; then
  log "bootstrapping pip into python3.12 (ensurepip)"
  python3.12 -m ensurepip --upgrade
fi
python3.12 -m pip install --no-input -U pip setuptools wheel

# 3. `python` → python3.12 (system `python3` stays 3.10 for apt's sake)
update-alternatives --install /usr/bin/python python "${PY312_BIN}" 100 >/dev/null 2>&1 || \
  warn "update-alternatives for 'python' failed (non-fatal)"

# 4. nvitop + ipython + hf_transfer into python3.12
log "nvitop / ipython / hf_transfer → python3.12"
python3.12 -m pip install --no-input -U nvitop ipython hf_transfer
