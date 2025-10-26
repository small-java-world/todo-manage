#!/usr/bin/env bash
set -euo pipefail

API_URL=${API_URL:-http://localhost:8000}

curl_json(){
  local method=$1; shift
  local path=$1; shift
  local data=${1:-}
  if [ -n "$data" ]; then
    curl -sS -H 'Content-Type: application/json' -X "$method" "$API_URL$path" --data "$data"
  else
    curl -sS -H 'Content-Type: application/json' -X "$method" "$API_URL$path"
  fi
}

info(){ printf '\033[34m%s\033[0m\n' "$*"; }
ok(){ printf '\033[32m%s\033[0m\n' "$*"; }
fail(){ printf '\033[31m%s\033[0m\n' "$*"; exit 1; }

info "API_URL=$API_URL"

# 1) requirement
req=$(curl_json POST "/tasks/requirements/" '{"title":"ログイン要件 (smoke)","description":""}')
reqId=$(jq -r .id <<<"$req")
[ "$reqId" != "null" ] || fail "requirement create failed: $req"
ok "requirement id=$reqId"

# 2) task
task=$(curl_json POST "/tasks/" "$(jq -c --null-input --argjson p "$reqId" '{title:"ログインAPI (smoke)", type:"task", parent_id:$p, description:""}')")
hid=$(jq -r .hierarchical_id <<<"$task")
[ "$hid" != "null" ] || fail "task create failed: $task"
ok "task HID=$hid"

# 3) save OpenSpec
yaml=$(cat <<YAML
version: "0.1"
id: "$hid"
title: "ログインAPI"
acceptance_criteria:
  - id: "AC-001"
    text: "正しい資格情報で200を返す"
scenarios:
  - id: "SCN-001"
    name: "成功シナリオ"
    steps:
      - request: { method: POST, path: "/login" }
        expect:  { status: 200 }
YAML
)
save=$(curl_json POST "/storage/openspec/$hid" "$(jq -c --null-input --arg c "$yaml" '{content:$c}')")
ok "OpenSpec saved uri=$(jq -r .openspec_uri <<<"$save") sha256=$(jq -r .cas_sha256 <<<"$save")"

# 4) validate
val=$(curl_json POST "/storage/openspec/$hid/validate")
[ "$(jq -r .valid <<<"$val")" = "true" ] || fail "validate failed: $val"
ok "OpenSpec validated"

# 5) generate tests
gen=$(curl_json POST "/storage/openspec/$hid/generate-tests")
ok "Generated: $(jq -r .message <<<"$gen")"

# 6) artifacts
arts=$(curl_json GET "/artifacts/tasks/$hid/artifacts")
hasSpec=$(jq '[.[]|select(.role=="spec")]|length>0' <<<"$arts")
hasTest=$(jq '[.[]|select(.role=="test")]|length>0' <<<"$arts")
[ "$hasSpec" = "true" ] || fail "no spec artifact"
[ "$hasTest" = "true" ] || fail "no test artifact"
ok "Artifacts linked (spec & test)"

ok "SUCCESS: OpenSpec smoke passed for HID=$hid"

