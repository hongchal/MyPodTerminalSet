#!/usr/bin/env bash
set -euo pipefail

# k9s — Kubernetes TUI. GitHub release 바이너리 설치 (apt에 없음).
# idempotent: 이미 있으면 skip.

if command -v k9s >/dev/null 2>&1; then
  echo "k9s 이미 설치됨 ($(k9s version -s 2>/dev/null | head -1 || echo present)) — skip"
  exit 0
fi

# dpkg arch → k9s asset arch 매핑
case "$(dpkg --print-architecture 2>/dev/null || uname -m)" in
  amd64|x86_64)  ARCH=amd64 ;;
  arm64|aarch64) ARCH=arm64 ;;
  *) echo "지원하지 않는 arch — k9s skip" >&2; exit 0 ;;
esac

URL="https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${ARCH}.tar.gz"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

echo "k9s 다운로드 → ${URL}"
curl -fsSL "${URL}" | tar xz -C "${TMP}" k9s
install "${TMP}/k9s" /usr/local/bin/

echo "k9s $(k9s version -s 2>/dev/null | head -1 || echo installed) 설치 완료"
