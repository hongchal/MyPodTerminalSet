#!/usr/bin/env bash
set -euo pipefail

# k9s — Kubernetes TUI, installed from a GitHub release (~120MB, not in apt).
# Same problem as the claude/cli-tools modules: a raw `curl | tar` cannot retry a
# half-consumed stream, so on slow B200 egress a timeout truncated the tarball
# and `set -euo pipefail` aborted the dotfile chain. Cache the binary on /DATA1
# (persists across pods) and restore it on every fresh pod with zero network;
# hit the network only on a cache miss (download to file, with retries, then
# reseed). k9s is non-essential, so failure warns instead of killing the chain.
# Opt into upgrades with CLI_FORCE_LATEST=1.

log()  { printf '\033[1;34m[k9s]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[k9s]\033[0m %s\n' "$*"; }

CLI_CACHE=/DATA1/hongcheol/.cache/cli-tools

case "$(dpkg --print-architecture 2>/dev/null || uname -m)" in
  amd64|x86_64)  ARCH=amd64 ;;
  arm64|aarch64) ARCH=arm64 ;;
  *) warn "unsupported arch — k9s skip"; exit 0 ;;
esac

newest_cached() { ls -1 "$CLI_CACHE" 2>/dev/null | grep -E "^k9s-[0-9].*-$ARCH$" | sort -V | tail -1; }
is_bin() { [ -f "$1" ] && [ "$(stat -c%s "$1" 2>/dev/null || echo 0)" -gt 100000 ]; }

seed_cache() { # $1=version
  local src dst tmp
  src="$(command -v k9s 2>/dev/null)" || return 0
  [ -n "${1:-}" ] || return 0
  dst="$CLI_CACHE/k9s-$1-$ARCH"
  [ -f "$dst" ] && return 0
  mkdir -p "$CLI_CACHE"
  tmp="$dst.tmp.$$"
  cp "$src" "$tmp" && chmod +x "$tmp" && mv -f "$tmp" "$dst" && log "seeded cache: $(basename "$dst")"
  ls -1 "$CLI_CACHE" 2>/dev/null | grep -E "^k9s-[0-9].*-$ARCH$" | sort -V | head -n -2 \
    | while read -r o; do [ -n "$o" ] && rm -f "$CLI_CACHE/$o"; done
  return 0
}

restore_cache() { # install newest cached k9s, zero network. non-zero on miss.
  local f
  f="$(newest_cached)"
  [ -n "$f" ] && is_bin "$CLI_CACHE/$f" || return 1
  install -m755 "$CLI_CACHE/$f" /usr/local/bin/k9s
  warn "restored k9s from cache ($f)"
}

k9s_version() { # current installed version (first match via bash expansion; pipefail-safe)
  local t all; t="$(mktemp)"
  k9s version -s >"$t" 2>&1 || true
  all="$(grep -oP '[0-9]+\.[0-9]+\.[0-9]+' "$t" 2>/dev/null || true)"
  rm -f "$t"
  printf '%s' "${all%%$'\n'*}"
}

# 1. Already installed → keep cache warm, done.
if command -v k9s >/dev/null 2>&1; then
  seed_cache "$(k9s_version)" || true
  log "k9s present ($(k9s_version)) — skip"
  exit 0
fi

# 2. Restore from cache (the common, network-free path).
if [ -z "${CLI_FORCE_LATEST:-}" ] && restore_cache; then
  log "k9s $(k9s_version) ready (from cache)"
  exit 0
fi

# 3. Cache miss: download to a file with retries, then reseed.
URL="https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${ARCH}.tar.gz"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
log "downloading k9s → $URL"
if curl -fL --retry 5 --retry-all-errors --retry-delay 3 \
        --connect-timeout 20 --max-time 600 -o "$TMP/k9s.tgz" "$URL" \
   && tar xzf "$TMP/k9s.tgz" -C "$TMP" k9s; then
  install -m755 "$TMP/k9s" /usr/local/bin/k9s
  seed_cache "$(k9s_version)" || true
  log "k9s $(k9s_version) installed"
  exit 0
fi

# 4. Network failed → any cached version beats nothing; else warn (non-fatal).
restore_cache || warn "k9s unavailable (download failed, no cache) — non-fatal"
exit 0
