#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/api.sh"
api::info
blue "[1/3] Health"; api::health | (command -v jq >/dev/null && jq . || cat); green OK
blue "[2/3] List minimal"; api::tasks_list task in_progress 5 | (command -v jq >/dev/null && jq . || cat); green OK
blue "[3/3] Docs HEAD"; api::docs; green OK
