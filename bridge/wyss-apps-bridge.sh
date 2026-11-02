#!/bin/bash
# Stdio <-> HTTPS bridge for the Wyss Apps MCP server, in bash + curl so it
# runs on any Mac (no Node, no Python). Claude Desktop, Cowork and Claude
# Code start it as the plugin's local MCP server; each JSON-RPC line on
# stdin is POSTed to the server with the person's token and the reply is
# written to stdout. The server is stateless, so every message is an
# independent exchange.
#
# The token and URL are read on EVERY request, so a new token saved to the
# file works at once, with no restart.
#
# When Wyss Apps cannot answer (off the VPN, no or expired token), the bridge
# still lets Claude connect: `initialize` and `tools/list` are answered from
# the last good replies cached in ~/.wyss-apps/cache (or a one-tool stub on a
# first run), and every tool call returns the reason as a tool error that
# Claude relays in plain words. A connection attempt gives up after 4s
# instead of hanging past Claude's own 30s startup limit. Lookup order:
#   token: $WYSS_APPS_TOKEN, then the file $WYSS_APPS_TOKEN_FILE, then ~/.wyss-apps/token
#   url:   $WYSS_APPS_URL, then the file ~/.wyss-apps/url, then https://wigt.med.harvard.edu/mcp
set -u
# The version reported to Wyss Apps is the plugin's (.claude-plugin/plugin.json next to
# this bridge's folder), so the server can tell the person when the plugin is behind.
PLUGIN_JSON="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)/.claude-plugin/plugin.json"
VERSION="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$PLUGIN_JSON" 2>/dev/null | head -n 1)"
[ -n "$VERSION" ] || VERSION="unknown"
CLIENT="wyss-apps-plugin-bridge/$VERSION"
DEFAULT_URL="https://wigt.med.harvard.edu/mcp"
TOKEN_HELP="Create a token at https://wigt.med.harvard.edu/tools/claude_access and save it in ~/.wyss-apps/token (no restart needed)."
CACHE_DIR="$HOME/.wyss-apps/cache"
OFFLINE_HELP="Wyss Apps is not reachable from this computer right now. Connect to the Wyss VPN (or the Harvard network) and ask again; nothing needs restarting."
STATUS_TOOL="wyss_apps_status"
stub_tools=0   # 1 once tools/list was answered with the stub: the next good reply asks Claude to reload the list
offline_until=0   # after a failed connection, skip the network for 15s except on tool calls (they always retry)

current_token() {
  if [ -n "${WYSS_APPS_TOKEN:-}" ]; then printf '%s' "$WYSS_APPS_TOKEN"; return; fi
  local file="${WYSS_APPS_TOKEN_FILE:-$HOME/.wyss-apps/token}"
  [ -r "$file" ] && tr -d '[:space:]' < "$file"
}
current_url() {
  if [ -n "${WYSS_APPS_URL:-}" ]; then printf '%s' "$WYSS_APPS_URL"; return; fi
  if [ -r "$HOME/.wyss-apps/url" ]; then tr -d '[:space:]' < "$HOME/.wyss-apps/url"; return; fi
  printf '%s' "$DEFAULT_URL"
}
# A token file readable by other accounts on the machine is worth a warning
# in the error text; the token still works.
token_file_warning() {
  local file="${WYSS_APPS_TOKEN_FILE:-$HOME/.wyss-apps/token}"
  [ -f "$file" ] || return 0
  local mode
  mode="$(stat -f '%Lp' "$file" 2>/dev/null || stat -c '%a' "$file" 2>/dev/null)"
  case "$mode" in
    *[1-7][1-7]) printf ' (note: %s is readable by other accounts; run: chmod 600 %s)' "$file" "$file" ;;
  esac
}

reply_error() { # id code message
  printf '{"jsonrpc":"2.0","id":%s,"error":{"code":%s,"message":%s}}\n' "$1" "$2" "$3"
}
json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\n'; }

# Fields of the request line. macOS plutil parses JSON properly (sed would
# take an "id" from inside the tool arguments); elsewhere, the first match.
HAVE_PLUTIL=0
command -v plutil >/dev/null 2>&1 && HAVE_PLUTIL=1
field() { # line keypath
  if [ "$HAVE_PLUTIL" = 1 ]; then
    printf '%s' "$1" | plutil -extract "$2" raw -o - - 2>/dev/null
  else
    printf '%s' "$1" | grep -oE "\"${2##*.}\"[[:space:]]*:[[:space:]]*(\"[^\"]*\"|-?[0-9]+)" | head -1 |
      sed -E 's/^"[^"]*"[[:space:]]*:[[:space:]]*//; s/^"(.*)"$/\1/'
  fi
}
rpc_id() { # the request id as JSON (number or string), empty for a notification
  local v
  v="$(field "$1" id)"
  [ -n "$v" ] || return 0
  case "$v" in *[!0-9-]*) printf '"%s"' "$(json_escape "$v")" ;; *) printf '%s' "$v" ;; esac
}

# The `result` member of a compact success reply ({"jsonrpc":"2.0","id":N,"result":{...}}).
result_of() {
  case "$1" in '{"jsonrpc":"2.0","id":'*'"result":'*) ;; *) return 1 ;; esac
  local r="${1#*\"result\":}"
  printf '%s' "${r%\}}"
}
cache_result() { # name body
  local r
  r="$(result_of "$2")" || return 0
  mkdir -p "$CACHE_DIR" 2>/dev/null && printf '%s' "$r" > "$CACHE_DIR/$1.json.tmp" && mv "$CACHE_DIR/$1.json.tmp" "$CACHE_DIR/$1.json"
}
reply_result() { printf '{"jsonrpc":"2.0","id":%s,"result":%s}\n' "$1" "$2"; }

# Wyss Apps could not answer: keep Claude connected and say why on each tool call.
#   $1 id  $2 method  $3 code  $4 message (plain text)  $5 the request line
answer_offline() {
  local id="$1" method="$2" msg
  msg="\"$(json_escape "$4")\""
  [ -n "$id" ] || return 0
  case "$method" in
    initialize)
      if [ -s "$CACHE_DIR/initialize.json" ]; then
        reply_result "$id" "$(cat "$CACHE_DIR/initialize.json")"
      else
        local pv
        pv="$(field "$5" params.protocolVersion)"
        reply_result "$id" "{\"protocolVersion\":\"${pv:-2025-06-18}\",\"capabilities\":{\"tools\":{\"listChanged\":true}},\"serverInfo\":{\"name\":\"wyss-apps\",\"title\":\"Wyss Apps\",\"version\":\"offline\"},\"instructions\":$msg}"
      fi ;;
    tools/list)
      if [ -s "$CACHE_DIR/tools.json" ]; then
        reply_result "$id" "$(cat "$CACHE_DIR/tools.json")"
      else
        stub_tools=1
        reply_result "$id" "{\"tools\":[{\"name\":\"$STATUS_TOOL\",\"title\":\"Wyss Apps connection\",\"description\":\"Wyss Apps could not be reached when this chat started. Call this whenever the person asks about Wyss projects, grants, people, finance or costing changes: it retries and says what to fix.\",\"inputSchema\":{\"type\":\"object\",\"properties\":{}}}]}"
      fi ;;
    tools/call) reply_result "$id" "{\"content\":[{\"type\":\"text\",\"text\":$msg}],\"isError\":true}" ;;
    *) reply_error "$id" "$3" "$msg" ;;
  esac
}

while IFS= read -r line || [ -n "$line" ]; do
  [ -z "${line// /}" ] && continue
  id="$(rpc_id "$line")"
  method="$(field "$line" method)"
  token="$(current_token)"
  url="$(current_url)"
  if [ -z "$token" ]; then
    answer_offline "$id" "$method" -32001 "No Wyss Apps token on this computer. $TOKEN_HELP" "$line"
    continue
  fi
  if [ "$method" != tools/call ] && [ "$(date +%s)" -lt "$offline_until" ]; then
    answer_offline "$id" "$method" -32002 "$OFFLINE_HELP" "$line"
    continue
  fi
  # The stub tool is whoami under another name: once Wyss Apps answers, it proves the connection.
  case "$line" in *"\"name\":\"$STATUS_TOOL\""*) line="${line/\"name\":\"$STATUS_TOOL\"/\"name\":\"whoami\"}" ;; esac
  tmp="$(mktemp)"
  status="$(curl -s --connect-timeout 4 -m 90 -o "$tmp" -w '%{http_code}' -X POST "$url" \
    -H 'content-type: application/json' -H 'accept: application/json, text/event-stream' \
    -H "authorization: Bearer $token" -H "x-wyss-apps-client: $CLIENT" --data-binary "$line" 2>/dev/null)"
  body="$(cat "$tmp")"; rm -f "$tmp"
  case "$status" in 000|"") ;; *) offline_until=0 ;; esac
  case "$status" in
    202|204) ;;
    200)
      if printf '%s' "$body" | grep -q '^data:'; then
        body="$(printf '%s\n' "$body" | sed -n 's/^data:[[:space:]]*//p')"
      fi
      printf '%s\n' "$body"
      case "$method" in
        initialize) cache_result initialize "$body" ;;
        tools/list) cache_result tools "$body"; stub_tools=0 ;;
      esac
      if [ "$stub_tools" = 1 ]; then
        stub_tools=0
        printf '%s\n' '{"jsonrpc":"2.0","method":"notifications/tools/list_changed"}'
      fi ;;
    401) answer_offline "$id" "$method" -32003 "Wyss Apps refused the token (expired, revoked or wrong). $TOKEN_HELP$(token_file_warning)" "$line" ;;
    403) answer_offline "$id" "$method" -32003 "Wyss Apps refused this account: it does not have the AI Assistant (Claude) tool. Ask Matthew Laubach (matthew.laubach@wyss.harvard.edu)." "$line" ;;
    429) [ -n "$id" ] && reply_error "$id" -32004 '"Wyss Apps rate limit: more than 120 requests a minute on this token. Wait a minute."' ;;
    000|"") offline_until=$(( $(date +%s) + 15 )); answer_offline "$id" "$method" -32002 "$OFFLINE_HELP" "$line" ;;
    *) answer_offline "$id" "$method" -32005 "Wyss Apps answered HTTP $status: ${body:0:200}" "$line" ;;
  esac
done
