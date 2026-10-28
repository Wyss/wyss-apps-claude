#!/bin/bash
# Stdio <-> HTTPS bridge for the Wyss Apps MCP server, in bash + curl so it
# runs on any Mac (no Node, no Python). Claude Desktop / Cowork start it as a
# local MCP server; each JSON-RPC line on stdin is POSTed to the server with
# the person's token and the reply written to stdout. The server is
# stateless, so every message is an independent exchange.
#
# Token, first found wins:
#   $WYSS_APPS_TOKEN
#   $WYSS_APPS_TOKEN_FILE (a file holding the token)
#   ~/.wyss-apps/token
# URL: $WYSS_APPS_URL, default https://wigt.med.harvard.edu/mcp
set -u
URL="${WYSS_APPS_URL:-https://wigt.med.harvard.edu/mcp}"
CLIENT="wyss-apps-plugin-bridge/0.1.0"
TOKEN="${WYSS_APPS_TOKEN:-}"
if [ -z "$TOKEN" ]; then
  FILE="${WYSS_APPS_TOKEN_FILE:-$HOME/.wyss-apps/token}"
  [ -r "$FILE" ] && TOKEN="$(tr -d '[:space:]' < "$FILE")"
fi

reply_error() { # id code message
  printf '{"jsonrpc":"2.0","id":%s,"error":{"code":%s,"message":%s}}\n' "$1" "$2" "$3"
}
json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\n'; }

while IFS= read -r line || [ -n "$line" ]; do
  [ -z "${line// /}" ] && continue
  # The request id, if any (notifications have none and get no reply).
  id="$(printf '%s' "$line" | sed -nE 's/.*"id"[[:space:]]*:[[:space:]]*("[^"]*"|[0-9]+).*/\1/p' | head -1)"
  if [ -z "$TOKEN" ]; then
    [ -n "$id" ] && reply_error "$id" -32001 '"No Wyss Apps token. Create one at https://wigt.med.harvard.edu/tools/claude_access and save it in ~/.wyss-apps/token"'
    continue
  fi
  tmp="$(mktemp)"
  status="$(curl -s -m 90 -o "$tmp" -w '%{http_code}' -X POST "$URL" \
    -H 'content-type: application/json' -H 'accept: application/json, text/event-stream' \
    -H "authorization: Bearer $TOKEN" -H "x-wyss-apps-client: $CLIENT" --data-binary "$line" 2>/dev/null)"
  body="$(cat "$tmp")"; rm -f "$tmp"
  case "$status" in
    202|204) ;;
    200)
      if printf '%s' "$body" | grep -q '^data:'; then
        printf '%s\n' "$body" | sed -n 's/^data:[[:space:]]*//p'
      else
        printf '%s\n' "$body"
      fi ;;
    401|403) [ -n "$id" ] && reply_error "$id" -32003 "\"Wyss Apps refused the token ($status). Make a new token at https://wigt.med.harvard.edu/tools/claude_access and save it in ~/.wyss-apps/token\"" ;;
    429) [ -n "$id" ] && reply_error "$id" -32004 '"Wyss Apps rate limit: more than 120 requests a minute. Wait a minute."' ;;
    000|"") [ -n "$id" ] && reply_error "$id" -32002 "\"Cannot reach Wyss Apps at $URL. Are you on the Wyss network or VPN?\"" ;;
    *) [ -n "$id" ] && reply_error "$id" -32005 "\"Wyss Apps answered HTTP $status: $(json_escape "${body:0:200}")\"" ;;
  esac
done
