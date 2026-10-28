#!/bin/bash
# Stdio <-> HTTPS bridge for the Wyss Apps MCP server, in bash + curl so it
# runs on any Mac (no Node, no Python). Claude Desktop, Cowork and Claude
# Code start it as the plugin's local MCP server; each JSON-RPC line on
# stdin is POSTed to the server with the person's token and the reply is
# written to stdout. The server is stateless, so every message is an
# independent exchange.
#
# The token and URL are read on EVERY request, so a new token saved to the
# file works at once, with no restart. Lookup order:
#   token: $WYSS_APPS_TOKEN, then the file $WYSS_APPS_TOKEN_FILE, then ~/.wyss-apps/token
#   url:   $WYSS_APPS_URL, then the file ~/.wyss-apps/url, then https://wigt.med.harvard.edu/mcp
set -u
VERSION="0.3.0"
CLIENT="wyss-apps-plugin-bridge/$VERSION"
DEFAULT_URL="https://wigt.med.harvard.edu/mcp"
TOKEN_HELP="Create a token at https://wigt.med.harvard.edu/tools/claude_access and save it in ~/.wyss-apps/token (no restart needed)."

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

while IFS= read -r line || [ -n "$line" ]; do
  [ -z "${line// /}" ] && continue
  id="$(printf '%s' "$line" | sed -nE 's/.*"id"[[:space:]]*:[[:space:]]*("[^"]*"|[0-9]+).*/\1/p' | head -1)"
  token="$(current_token)"
  url="$(current_url)"
  if [ -z "$token" ]; then
    [ -n "$id" ] && reply_error "$id" -32001 "\"No Wyss Apps token. $TOKEN_HELP\""
    continue
  fi
  tmp="$(mktemp)"
  status="$(curl -s -m 90 -o "$tmp" -w '%{http_code}' -X POST "$url" \
    -H 'content-type: application/json' -H 'accept: application/json, text/event-stream' \
    -H "authorization: Bearer $token" -H "x-wyss-apps-client: $CLIENT" --data-binary "$line" 2>/dev/null)"
  body="$(cat "$tmp")"; rm -f "$tmp"
  case "$status" in
    202|204) ;;
    200)
      if printf '%s' "$body" | grep -q '^data:'; then
        printf '%s\n' "$body" | sed -n 's/^data:[[:space:]]*//p'
      else
        printf '%s\n' "$body"
      fi ;;
    401) [ -n "$id" ] && reply_error "$id" -32003 "\"Wyss Apps refused the token (401: expired, revoked or wrong). $TOKEN_HELP$(token_file_warning)\"" ;;
    403) [ -n "$id" ] && reply_error "$id" -32003 '"Wyss Apps refused this account (403): it does not have the AI Assistant (Claude) tool. Ask Matthew Laubach (matthew.laubach@wyss.harvard.edu)."' ;;
    429) [ -n "$id" ] && reply_error "$id" -32004 '"Wyss Apps rate limit: more than 120 requests a minute on this token. Wait a minute."' ;;
    000|"") [ -n "$id" ] && reply_error "$id" -32002 "\"Cannot reach Wyss Apps at $url. Are you on the Wyss network or VPN?\"" ;;
    *) [ -n "$id" ] && reply_error "$id" -32005 "\"Wyss Apps answered HTTP $status: $(json_escape "${body:0:200}")\"" ;;
  esac
done
