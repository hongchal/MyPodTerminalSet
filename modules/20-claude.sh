#!/usr/bin/env bash
set -euo pipefail

log()  { printf '\033[1;34m[claude]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[claude]\033[0m %s\n' "$*"; }

# claude-code (2.x) ships as a small npm wrapper + a large (~250MB) native
# binary delivered as a platform optionalDependency
# (@anthropic-ai/claude-code-linux-x64, ...). On pods with slow/flaky egress the
# optional download is silently skipped (optional deps are non-fatal in npm),
# leaving a non-functional `claude` that errors "native binary not installed".
#
# Strategy: install, then GUARANTEE the native binary is present and on PATH —
# fetching the platform package explicitly and symlinking its self-contained
# binary if the wrapper still can't find one.

# Platform package name for the current arch/libc.
native_pkg() {
  local arch libc=""
  case "$(uname -m)" in
    x86_64|amd64)  arch=x64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) return 1 ;;
  esac
  ldd --version 2>&1 | grep -qi musl && libc="-musl"
  printf '@anthropic-ai/claude-code-linux-%s%s' "$arch" "$libc"
}

if ! claude --version >/dev/null 2>&1; then
  log "installing @anthropic-ai/claude-code"
  # --include=optional overrides any env that omits optional deps.
  npm install -g @anthropic-ai/claude-code --include=optional --foreground-scripts || \
    warn "npm install reported an error (will verify and self-heal below)"
fi

# If the wrapper still can't run (native binary missing/unlinked), ensure the
# platform package exists and link its binary directly. This is the only path
# that reliably works on constrained-egress pods.
if ! claude --version >/dev/null 2>&1; then
  pkg="$(native_pkg)" || { warn "unsupported platform: $(uname -m)"; exit 1; }
  bin="$(npm root -g)/${pkg}/claude"
  if [ ! -x "${bin}" ]; then
    log "fetching native binary ${pkg} (~250MB — may be slow on constrained egress)"
    npm install -g "${pkg}" --foreground-scripts || true
  fi
  if [ -x "${bin}" ]; then
    ln -sf "${bin}" /usr/local/bin/claude
    hash -r
    warn "linked native binary directly → /usr/local/bin/claude"
  fi
fi

claude --version || { warn "claude install failed (native binary unavailable)"; exit 1; }
