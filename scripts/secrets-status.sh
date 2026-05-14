#!/usr/bin/env bash
# Print which secret files are filled vs placeholder.
set -euo pipefail

SECRETS_DIR="${SECRETS_PERSIST_ROOT:-/DATA1/hongcheol}/.secrets"

if [[ ! -d "${SECRETS_DIR}" ]]; then
  echo "secrets dir 없음: ${SECRETS_DIR}"
  echo "→ bootstrap.sh 70-secrets 모듈을 먼저 실행하세요."
  exit 1
fi

printf '%-30s %-15s %s\n' "FILE" "STATUS" "VAR (preview)"
printf '%-30s %-15s %s\n' "----" "------" "-------------"

shopt -s nullglob
for f in "${SECRETS_DIR}"/*.env; do
  name=$(basename "${f}")
  active=$(grep -E '^\s*export\s+[A-Z_]+=' "${f}" 2>/dev/null | head -1 || true)

  if [[ -z "${active}" ]]; then
    printf '%-30s %-15s %s\n' "${name}" "❌ commented" "—"
    continue
  fi

  var=$(echo "${active}" | sed -E 's/^\s*export\s+([A-Z_]+)=.*/\1/')
  val=$(echo "${active}" | sed -E 's/^\s*export\s+[A-Z_]+=([^[:space:]]*).*/\1/' | tr -d "'\"")

  if [[ "${val}" == "REPLACE_ME" || -z "${val}" ]]; then
    printf '%-30s %-15s %s\n' "${name}" "⚠️ placeholder" "${var}"
  else
    printf '%-30s %-15s %s\n' "${name}" "✅ filled" "${var}=${val:0:6}..."
  fi
done
