#!/usr/bin/env bash
set -euo pipefail

log()  { printf '\033[1;34m[claude]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[claude]\033[0m %s\n' "$*"; }

# claude-code (2.x) ships as a small npm wrapper plus a large (~238MB) native
# binary delivered as a platform optionalDependency
# (@anthropic-ai/claude-code-linux-x64, ...). The wrapper's postinstall
# (install.cjs) copies that native binary over a 500-byte `bin/claude.exe`
# placeholder; after that `claude` execs the native binary directly.
#
# On this B200 pod workflow egress is slow-but-usable: a fresh pod re-running
# this dotfile must NOT re-download 238MB every time (it times out / stalls
# startup, and `set -euo pipefail` then aborts the whole install chain).
#
# Strategy — seed-once / restore-always, keyed on /DATA1 (host-local, persists
# across every pod on this node):
#   1. If a working `claude` already exists, refresh the cache from it and stop.
#   2. Otherwise install the wrapper only (no network postinstall), then copy
#      the cached native binary over the placeholder — ZERO large download.
#   3. Cache miss (first ever, or a new version) is the only path that hits the
#      network, and it patiently fetches then seeds the cache for next time.
#   4. If even that fails, fall back to the newest cached version so a working
#      (possibly slightly stale) claude survives and the chain does not abort.
#
# To upgrade claude: set CLAUDE_FORCE_LATEST=1 (cold-fetches latest + reseeds).

PKG='@anthropic-ai/claude-code'
CACHE='/DATA1/hongcheol/.cache/claude-native'

# Platform suffix for the current arch/libc (matches the optionalDependency
# naming and the cache key).
platform() {
  local arch libc=''
  case "$(uname -m)" in
    x86_64|amd64)  arch=x64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) return 1 ;;
  esac
  ldd --version 2>&1 | grep -qi musl && libc='-musl'
  printf 'linux-%s%s' "$arch" "$libc"
}

wrapper_bin() { printf '%s/@anthropic-ai/claude-code/bin/claude.exe' "$(npm root -g)"; }

installed_version() {
  node -p "require('$(npm root -g)/@anthropic-ai/claude-code/package.json').version" 2>/dev/null
}

# A real native binary is an ELF and far larger than the 500B placeholder.
is_native_binary() {
  local f="$1"
  [ -f "$f" ] || return 1
  [ "$(head -c4 "$f" 2>/dev/null | xxd -p 2>/dev/null)" = '7f454c46' ] || return 1
  [ "$(stat -c%s "$f" 2>/dev/null || echo 0)" -gt 104857600 ]
}

cache_path() { printf '%s/claude-%s-%s' "$CACHE" "$1" "$(platform)"; }

# Copy a verified-good wrapper binary into the cache (atomic; never stores a stub).
seed_cache() {
  local ver="$1" src dst tmp
  src="$(wrapper_bin)"
  is_native_binary "$src" || return 0
  dst="$(cache_path "$ver")"
  [ -f "$dst" ] && [ "$(stat -c%s "$dst")" = "$(stat -c%s "$src")" ] && return 0
  mkdir -p "$CACHE"
  tmp="${dst}.tmp.$$"
  cp "$src" "$tmp" && chmod +x "$tmp" && mv -f "$tmp" "$dst"
  log "seeded cache: $(basename "$dst")"
  # keep the 3 newest versions; older ones are dead weight
  ls -1 "$CACHE" 2>/dev/null | sort -V | head -n -3 | while read -r old; do
    [ -n "$old" ] && rm -f "$CACHE/$old"
  done
}

# Restore the cached binary for $1 over the placeholder. Returns non-zero on miss.
restore_cache() {
  local ver="$1" src dst
  src="$(cache_path "$ver")"
  is_native_binary "$src" || return 1
  dst="$(wrapper_bin)"
  cp "$src" "$dst" && chmod +x "$dst"
  claude --version >/dev/null 2>&1
}

newest_cached_version() {
  ls -1 "$CACHE" 2>/dev/null | sort -V | tail -1 \
    | sed -E 's/^claude-(.*)-linux-[^-]+(-musl)?$/\1/'
}

# A live claude memory-maps its binary from the global node_modules tree, so an
# interrupted npm install leaves a non-empty `.claude-code-<hash>` backup dir
# that makes every later install fail with ENOTEMPTY on the rename. Unlink those
# staging leftovers first — safe even while claude runs, since Linux keeps the
# inode alive for the running process until it exits.
clean_staging() {
  rm -rf "$(npm root -g)"/@anthropic-ai/.claude-code-* 2>/dev/null || true
}

# Install the wrapper at the given version (or latest) WITHOUT the doomed
# network postinstall. Small + fast; just refreshes install.cjs + placeholder.
install_wrapper() {
  local spec="$PKG${1:+@$1}"
  clean_staging
  npm install -g "$spec" --ignore-scripts --omit=optional --no-fund --no-audit
}

# --- 1. Already working: just keep the cache warm. -------------------------
if [ -z "${CLAUDE_FORCE_LATEST:-}" ] && claude --version >/dev/null 2>&1; then
  v="$(installed_version || true)"
  [ -n "$v" ] && seed_cache "$v" || true
  claude --version
  exit 0
fi

platform >/dev/null || { warn "unsupported platform: $(uname -m)"; exit 1; }

# --- 2. Pick a target version. ---------------------------------------------
# Default: pin to newest cached (zero large download). Opt into latest with
# CLAUDE_FORCE_LATEST=1, or when the cache is empty (first-ever pod).
cached_v="$(newest_cached_version || true)"
if [ -n "${CLAUDE_FORCE_LATEST:-}" ] || [ -z "$cached_v" ]; then
  target=''            # latest
else
  target="$cached_v"
fi

log "installing wrapper (${target:-latest})"
install_wrapper "$target" || warn "wrapper install reported an error (will verify below)"
v="$(installed_version || true)"

# --- 3. Restore from cache (the common, network-free path). ----------------
if [ -n "$v" ] && restore_cache "$v"; then
  warn "restored native binary from cache (claude $v)"
  claude --version
  exit 0
fi

# --- 4. Cache miss: patient network fetch, then seed. ----------------------
log "cache miss for ${v:-latest}; fetching native binary (~238MB, slow egress — patient)"
clean_staging
npm install -g "$PKG" --include=optional --foreground-scripts --no-fund --no-audit \
  --fetch-timeout=1800000 --fetch-retries=5 \
  --fetch-retry-mintimeout=20000 --fetch-retry-maxtimeout=600000 \
  || warn "network install reported an error"
v="$(installed_version || true)"
if claude --version >/dev/null 2>&1; then
  [ -n "$v" ] && seed_cache "$v" || true
  claude --version
  exit 0
fi

# --- 5. Graceful fallback: any cached version beats a broken claude. --------
fallback="$(newest_cached_version || true)"
if [ -n "$fallback" ]; then
  warn "network fetch failed; falling back to cached claude $fallback"
  install_wrapper "$fallback" || true
  if restore_cache "$fallback"; then
    claude --version
    exit 0
  fi
fi

warn "claude install failed: no cached binary and network unavailable"
exit 1
