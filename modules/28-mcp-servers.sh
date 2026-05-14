#!/usr/bin/env bash
# Register standalone MCP servers from config/mcp-servers.json.
# Plugin-bundled MCPs are NOT here (handled by 26-claude-plugins).
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MANIFEST="${REPO_DIR}/config/mcp-servers.json"

log()  { printf '\033[1;36m[mcp]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[mcp]\033[0m %s\n' "$*"; }

[[ -f "${MANIFEST}" ]] || { warn "manifest 없음 — skip"; exit 0; }
command -v jq >/dev/null || { warn "jq 없음 — 00-base 먼저"; exit 0; }
command -v claude >/dev/null || { warn "claude CLI 없음 — 20-claude 먼저"; exit 0; }

count=$(jq -r '.servers | length' "${MANIFEST}")
if [[ "${count}" -eq 0 ]]; then
  log "manifest 비어 있음 — 추가 MCP 없음. skip."
  exit 0
fi

log "${count}개 MCP 서버 처리"

# 각 서버 등록 시도. 'claude mcp add' 문법은 버전마다 다를 수 있으므로 graceful.
jq -c '.servers | to_entries[]' "${MANIFEST}" | while read -r entry; do
  name=$(echo "${entry}" | jq -r '.key')
  type=$(echo "${entry}" | jq -r '.value.type // "stdio"')
  cmd=$(echo "${entry}" | jq -r '.value.command // ""')
  args=$(echo "${entry}" | jq -r '.value.args // [] | join(" ")')
  url=$(echo "${entry}" | jq -r '.value.url // ""')

  log "register: ${name} (${type})"
  if [[ "${type}" == "http" ]]; then
    claude mcp add "${name}" --transport http "${url}" 2>/dev/null \
      || warn "  실패 — claude 안에서 수동: /mcp add ${name} http ${url}"
  else
    claude mcp add "${name}" -- ${cmd} ${args} 2>/dev/null \
      || warn "  실패 — claude 안에서 수동: /mcp add ${name} -- ${cmd} ${args}"
  fi
done
