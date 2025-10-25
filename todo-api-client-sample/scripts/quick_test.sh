#!/usr/bin/env bash
set -euo pipefail
API_URL="${API_URL:-http://localhost:8000}"

blue() { printf "\033[34m%s\033[0m\n" "$*"; }
green() { printf "\033[32m%s\033[0m\n" "$*"; }
red() { printf "\033[31m%s\033[0m\n" "$*"; }

blue "[1/3] Health check: $API_URL/"
if curl -fsS "$API_URL/" | sed -e 's/.*/  &/'; then
  green "OK"
else
  red "FAILED"; exit 1
fi

blue "[2/3] List tasks (minimal fields)"
URL="$API_URL/tasks?type=task&status=in_progress&limit=5&fields=hid,title,status,updated_at"
echo "GET $URL"
if curl -fsS "$URL" | sed -e 's/.*/  &/'; then
  green "OK"
else
  red "FAILED"; exit 1
fi

blue "[3/3] OpenAPI docs"
echo "GET $API_URL/docs (expect HTML)"
if curl -fsS -I "$API_URL/docs" | head -n 1; then
  green "OK"
else
  red "FAILED"; exit 1
fi
