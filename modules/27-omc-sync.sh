#!/usr/bin/env bash
set -euo pipefail

PERSIST_ROOT="${CLAUDE_PERSIST_ROOT:-/DATA1/hongcheol}"
PERSIST="${PERSIST_ROOT}/.omc"
LOCAL="${HOME}/.omc"
STAMP="$(date +%Y%m%d-%H%M%S)"

log()  { printf '\033[1;36m[omc-sync]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[omc-sync]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[omc-sync error]\033[0m %s\n' "$*" >&2; exit 1; }

if [[ ! -d "${PERSIST_ROOT}" ]]; then
  warn "${PERSIST_ROOT} 없음 — /DATA1 마운트 / 노드 핀 확인. omc-sync 건너뜀."
  exit 0
fi

if [[ -L "${LOCAL}" ]]; then
  target="$(readlink -f "${LOCAL}")"
  if [[ "${target}" == "$(readlink -f "${PERSIST}" 2>/dev/null || echo "${PERSIST}")" ]]; then
    log "이미 연결됨 → ${target}"
    exit 0
  fi
  die "${LOCAL} 가 다른 곳으로 링크돼 있음 (${target}). 수동 점검 필요."
fi

if [[ -d "${PERSIST}" && -d "${LOCAL}" && -n "$(ls -A "${LOCAL}" 2>/dev/null || true)" ]]; then
  log "양쪽 다 데이터 존재 — 로컬 백업 후 /DATA1 채택"
  mv "${LOCAL}" "${LOCAL}.bak.${STAMP}"
  log "백업: ${LOCAL}.bak.${STAMP}"
  ln -s "${PERSIST}" "${LOCAL}"
  log "심볼릭 링크: ${LOCAL} → ${PERSIST}"
  exit 0
fi

if [[ ! -d "${PERSIST}" && -d "${LOCAL}" ]]; then
  log "초기 마이그레이션: ${LOCAL} → ${PERSIST}"
  mkdir -p "${PERSIST_ROOT}"
  command -v rsync >/dev/null || apt install -y rsync
  rsync -aHAX --info=progress2 \
    --exclude='cache/' --exclude='*.log' \
    "${LOCAL}/" "${PERSIST}/"
  mv "${LOCAL}" "${LOCAL}.migrated.${STAMP}"
  ln -s "${PERSIST}" "${LOCAL}"
  log "완료. 원본 백업: ${LOCAL}.migrated.${STAMP} (확인 후 수동 삭제)"
  exit 0
fi

if [[ -d "${PERSIST}" && ! -e "${LOCAL}" ]]; then
  ln -s "${PERSIST}" "${LOCAL}"
  log "복원: ${LOCAL} → ${PERSIST}"
  exit 0
fi

if [[ ! -d "${PERSIST}" && ! -e "${LOCAL}" ]]; then
  mkdir -p "${PERSIST}"
  ln -s "${PERSIST}" "${LOCAL}"
  log "신규: 빈 ${PERSIST} 생성 후 링크"
  exit 0
fi

die "예상치 못한 상태 — 수동 점검 필요"
