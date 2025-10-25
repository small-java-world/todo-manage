#!/usr/bin/env bash
set -euo pipefail
: "${API_URL:=http://localhost:8000}"
: "${AUTH_TOKEN:=}"

if ! command -v curl >/dev/null 2>&1; then
  echo "[ERR] curl not found" >&2; exit 127
fi

blue(){ printf "\033[34m%s\033[0m\n" "$*"; }
red(){ printf "\033[31m%s\033[0m\n" "$*"; }
green(){ printf "\033[32m%s\033[0m\n" "$*"; }

api::header_auth(){ [ -n "$AUTH_TOKEN" ] && printf 'Authorization: Bearer %s' "$AUTH_TOKEN" || true; }
api::curl(){
  local method="$1"; shift
  local path="$1"; shift
  local data="${1:-}"
  local out; out="$(mktemp)"; trap 'rm -f "$out"' RETURN
  local code
  code="$(curl -sS -o "$out" -w "%{http_code}" --connect-timeout 3 --max-time 15 --retry 2 --retry-connrefused -H 'Content-Type: application/json' ${AUTH_TOKEN:+ -H "$(api::header_auth)"} -X "$method" "${API_URL%/}${path}" ${data:+ --data "$data"})"
  if [[ "$code" =~ ^2 ]]; then cat "$out"; else red "HTTP $code $(cat \"$out\")"; return 1; fi
}
api::get(){ api::curl GET "$1"; }
api::post(){ api::curl POST "$1" "${2:-}"; }
api::put(){ api::curl PUT "$1" "${2:-}"; }
api::delete(){ api::curl DELETE "$1"; }
api::health(){ api::get "/"; }

# Tasks
api::tasks_list(){ local type="${1:-task}"; local status="${2:-in_progress}"; local limit="${3:-5}"; local fields="${4:-hid,title,status,updated_at}"; api::get "/tasks?type=${type}&status=${status}&limit=${limit}&fields=${fields}"; }
api::requirement_create(){ local title="$1"; local description="${2:-}"; local payload; payload=$(jq -c --null-input --arg t "$title" --arg d "$description" '{title:$t, description:$d}'); api::post "/tasks/requirements/" "$payload"; }
api::task_create(){ local title="$1"; local parent_id="$2"; local type="${3:-task}"; local description="${4:-}"; local payload; payload=$(jq -c --null-input --arg t "$title" --arg type "$type" --argjson p "$parent_id" --arg d "$description" '{title:$t, type:$type, parent_id:$p, description:$d}'); api::post "/tasks/" "$payload"; }
api::task_get(){ local id="$1"; api::get "/tasks/${id}"; }
api::task_update(){ local id="$1"; shift; local payload='{}'; while [ $# -gt 0 ]; do local kv="$1"; shift; local key="${kv%%=*}"; local val="${kv#*=}"; payload=$(jq -c --arg k "$key" --arg v "$val" '. + {($k): $v}' <<< "$payload"); done; api::put "/tasks/${id}" "$payload"; }
api::task_delete(){ local id="$1"; api::delete "/tasks/${id}"; }
api::tree(){ api::get "/tasks/tree/"; }

# Reviews
api::reviews_list(){ api::get "/reviews/"; }
api::review_create(){ local task_hid="$1"; local comment="$2"; local verdict="${3:-pending}"; local payload; payload=$(jq -c --null-input --arg hid "$task_hid" --arg c "$comment" --arg v "$verdict" '{task_hid:$hid, comment:$c, verdict:$v}'); api::post "/reviews/" "$payload"; }

# Artifacts
api::artifacts_list(){ api::get "/artifacts/"; }
api::artifact_create(){ local task_hid="$1"; local uri="$2"; local type="${3:-link}"; local payload; payload=$(jq -c --null-input --arg hid "$task_hid" --arg u "$uri" --arg t "$type" '{task_hid:$hid, uri:$u, type:$t}'); api::post "/artifacts/" "$payload"; }

# Backup
api::backup_list(){ api::get "/backup/"; }
api::backup_create(){ api::post "/backup/" "{}"; }

api::docs(){ curl -fsSI "${API_URL%/}/docs" | head -n1; }
api::info(){ blue "API_URL=$API_URL"; [ -n "$AUTH_TOKEN" ] && blue "AUTH_TOKEN=*** (set)" || blue "AUTH_TOKEN=(unset)"; }

# Storage (git path handshake)
api::storage_git_config(){ api::get "/storage/git/config"; }
api::storage_git_resolve_uri(){
  local uri="$1"
  local payload; payload=$(jq -c --null-input --arg u "$uri" '{uri:$u}')
  api::post "/storage/git/resolve-uri" "$payload"
}
api::storage_git_from_abs(){
  local abs="$1"
  local payload; payload=$(jq -c --null-input --arg p "$abs" '{abs_path:$p}')
  api::post "/storage/git/from-abs" "$payload"
}

# Client-side mapping: map git://<rel> to a local path.
# Uses CLIENT_GIT_ROOT if set; otherwise falls back to server git_root.
api::git_uri_to_abs(){
  local uri="$1"; local rel
  rel="${uri#git://}"
  if [[ "$uri" != git://* ]]; then echo "$uri"; return; fi
  local base="${CLIENT_GIT_ROOT:-}"
  if [[ -z "$base" ]]; then
    base="$(api::storage_git_config | jq -r .git_root 2>/dev/null || true)"
  fi
  if [[ -z "$base" ]]; then echo ""; return 1; fi
  case "$base" in
    /*) printf '%s/%s\n' "${base%/}" "$rel" ;;
    *) printf '%s/%s\n' "$(pwd)/${base%/}" "$rel" ;;
  esac
}


# Storage (fs path handshake)
api::storage_fs_config(){ api::get "/storage/fs/config"; }
api::storage_fs_resolve_uri(){
  local uri="$1"
  local payload; payload=$(jq -c --null-input --arg u "$uri" '{uri:$u}')
  api::post "/storage/fs/resolve-uri" "$payload"
}
api::storage_fs_from_abs(){
  local abs="$1"
  local payload; payload=$(jq -c --null-input --arg p "$abs" '{abs_path:$p}')
  api::post "/storage/fs/from-abs" "$payload"
}

# Map fs://<rel> to absolute path (client side)
# Prefers CLIENT_FS_ROOT, fallback to server /storage/fs/config
api::fs_uri_to_abs(){
  local uri="$1"; local rel
  rel="${uri#fs://}"
  if [[ "$uri" != fs://* ]]; then echo "$uri"; return; fi
  local base="${CLIENT_FS_ROOT:-}"
  if [[ -z "$base" ]]; then
    base="$(api::storage_fs_config | jq -r .fs_root 2>/dev/null || true)"
  fi
  if [[ -z "$base" ]]; then echo ""; return 1; fi
  case "$base" in
    /*) printf '%s/%s
' "${base%/}" "$rel" ;;
    *) printf '%s/%s
' "$(pwd)/${base%/}" "$rel" ;;
  esac
}
