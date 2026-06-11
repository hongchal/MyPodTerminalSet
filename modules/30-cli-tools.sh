#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

log()  { printf '\033[1;34m[cli]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[cli]\033[0m %s\n' "$*"; }

# Single-binary CLI tools (delta, lazygit) come from GitHub releases. On the B200
# pod workflow egress is slow/flaky: a raw `curl | tar` cannot retry (the stream
# is half-consumed) and one timeout aborts the entire dotfile chain via
# `set -euo pipefail`. Mirror the claude module: cache the extracted binary on
# /DATA1 (host-local, persists across pods) and restore it on every fresh pod
# with ZERO network. Network is touched only on a cache miss — it downloads to a
# file with retries, then reseeds. These tools are non-essential, so a failure
# warns instead of killing the chain. Opt into upgrades with CLI_FORCE_LATEST=1.

CLI_CACHE=/DATA1/hongcheol/.cache/cli-tools
ARCH="$(uname -m)"

# --- core apt tools (essential; apt has its own retry/mirror resilience) ---
apt install -y --no-install-recommends \
  tmux ripgrep bat fd-find htop ncdu tree jq \
  bash-completion direnv less

# --- cache helpers --------------------------------------------------------
is_bin() { [ -f "$1" ] && [ "$(stat -c%s "$1" 2>/dev/null || echo 0)" -gt 100000 ]; }

cli_newest_cached() { ls -1 "$CLI_CACHE" 2>/dev/null | grep -E "^$1-[0-9]" | sort -V | tail -1; }

# Copy an installed binary into the cache (atomic; keep 2 newest versions).
cli_seed() { # $1=bin $2=version
  local src dst tmp
  src="$(command -v "$1" 2>/dev/null)" || return 0
  [ -n "${2:-}" ] || return 0
  dst="$CLI_CACHE/$1-$2-$ARCH"
  [ -f "$dst" ] && return 0
  mkdir -p "$CLI_CACHE"
  tmp="$dst.tmp.$$"
  cp "$src" "$tmp" && chmod +x "$tmp" && mv -f "$tmp" "$dst" && log "seeded cache: $(basename "$dst")"
  ls -1 "$CLI_CACHE" 2>/dev/null | grep -E "^$1-[0-9]" | sort -V | head -n -2 \
    | while read -r o; do [ -n "$o" ] && rm -f "$CLI_CACHE/$o"; done
  return 0
}

# Install newest cached binary over /usr/local/bin (no network). Non-zero on miss.
cli_restore() { # $1=bin
  local f
  f="$(cli_newest_cached "$1")"
  [ -n "$f" ] && is_bin "$CLI_CACHE/$f" || return 1
  install -m755 "$CLI_CACHE/$f" "/usr/local/bin/$1"
  warn "restored $1 from cache ($f)"
}

# Resilient download to a file (retries; no fragile curl|tar pipe).
cli_fetch() { # $1=url $2=dest
  curl -fL --retry 5 --retry-all-errors --retry-delay 3 \
       --connect-timeout 20 --max-time 600 -o "$2" "$1"
}

# Resolve latest release tag (network; only on cache miss).
cli_latest_tag() { # $1=repo
  curl -fsSL --retry 3 --retry-all-errors --connect-timeout 20 --max-time 60 \
    "https://api.github.com/repos/$1/releases/latest" 2>/dev/null \
    | grep -Po '"tag_name": "\K[^"]*' | head -1
}

# Extract a version via temp file (dodges set -u / pipefail SIGPIPE quirks).
extract_version() { # $1=bin $2=PCRE
  local t; t="$(mktemp)"
  "$1" --version >"$t" 2>&1 || true
  grep -oP "$2" "$t" | head -1
  rm -f "$t"
}

# --- git-delta ------------------------------------------------------------
ensure_delta() {
  if command -v delta >/dev/null 2>&1; then
    cli_seed delta "$(extract_version delta 'delta \K[0-9.]+')" || true
    return 0
  fi
  if [ -z "${CLI_FORCE_LATEST:-}" ] && cli_restore delta; then return 0; fi
  if apt install -y git-delta 2>/dev/null; then log "git-delta via apt"; return 0; fi
  local tag dir tb
  tag="$(cli_latest_tag dandavison/delta)" || tag=""
  if [ -n "$tag" ]; then
    dir="delta-$tag-x86_64-unknown-linux-gnu"; tb="/tmp/delta-$tag.tgz"
    if cli_fetch "https://github.com/dandavison/delta/releases/download/$tag/$dir.tar.gz" "$tb" \
       && tar xzf "$tb" -C /tmp; then
      install -m755 "/tmp/$dir/delta" /usr/local/bin/delta && cli_seed delta "$tag" || true
    fi
    rm -rf "$tb" "/tmp/$dir"
  fi
  command -v delta >/dev/null 2>&1 || cli_restore delta || warn "git-delta unavailable (non-fatal)"
  return 0
}

# --- lazygit --------------------------------------------------------------
ensure_lazygit() {
  if command -v lazygit >/dev/null 2>&1; then
    cli_seed lazygit "$(extract_version lazygit 'version=\K[0-9.]+')" || true
    return 0
  fi
  if [ -z "${CLI_FORCE_LATEST:-}" ] && cli_restore lazygit; then return 0; fi
  local tag ver tb
  tag="$(cli_latest_tag jesseduffield/lazygit)" || tag=""
  ver="${tag#v}"
  if [ -n "$ver" ]; then
    tb="/tmp/lazygit-$ver.tgz"
    if cli_fetch "https://github.com/jesseduffield/lazygit/releases/download/v$ver/lazygit_${ver}_Linux_x86_64.tar.gz" "$tb" \
       && tar xzf "$tb" -C /tmp lazygit; then
      install -m755 /tmp/lazygit /usr/local/bin/lazygit && cli_seed lazygit "$ver" || true
    fi
    rm -f "$tb" /tmp/lazygit
  fi
  command -v lazygit >/dev/null 2>&1 || cli_restore lazygit || warn "lazygit unavailable (non-fatal)"
  return 0
}

ensure_delta
ensure_lazygit

# --- bat/fd name normalization (Debian installs as batcat/fdfind) ---------
mkdir -p "${HOME}/.local/bin"
[ -x "$(command -v batcat 2>/dev/null)" ] && ln -sf "$(command -v batcat)" "${HOME}/.local/bin/bat" || true
[ -x "$(command -v fdfind 2>/dev/null)" ] && ln -sf "$(command -v fdfind)" "${HOME}/.local/bin/fd" || true

# --- gh CLI (apt repo; non-fatal so a slow keyring fetch can't kill the chain) ---
if ! command -v gh >/dev/null 2>&1; then
  ghkey="$(mktemp)"
  if curl -fsSL --retry 3 --retry-all-errors --connect-timeout 20 --max-time 60 \
       https://cli.github.com/packages/githubcli-archive-keyring.gpg -o "$ghkey" && [ -s "$ghkey" ]; then
    install -m644 "$ghkey" /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list
    apt update && apt install -y gh || warn "gh install failed (non-fatal)"
  else
    warn "gh keyring fetch failed (non-fatal)"
  fi
  rm -f "$ghkey"
fi
