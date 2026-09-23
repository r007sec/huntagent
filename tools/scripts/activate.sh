#!/usr/bin/env bash
# activate.sh — load a program's identity + tokens into the shell.
# Usage: source tools/scripts/activate.sh <program-name>
# Defines hcurl / ucurl / jcurl / idor_check, all carrying the platform's identifier header.

PROGRAM="$1"
WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROGRAM_DIR="$WORKSPACE_ROOT/programs/$PROGRAM"
SESSION_FILE="$PROGRAM_DIR/.session.env"

if [ -z "$PROGRAM" ]; then
  echo "Usage: source activate.sh <program-name>"
  echo "Programs:"; ls "$WORKSPACE_ROOT/programs/" 2>/dev/null | grep -v '^\.' | sed 's/^/  - /'
  return 1 2>/dev/null || exit 1
fi
if [ ! -f "$SESSION_FILE" ]; then
  echo "[!] No .session.env for '$PROGRAM'."
  echo "    cp tools/scripts/.session.env.template programs/$PROGRAM/.session.env  # then fill it in"
  return 1 2>/dev/null || exit 1
fi

set -a; source "$SESSION_FILE"; set +a

export ACTIVE_PROGRAM="$PROGRAM"
export ACTIVE_PROGRAM_DIR="$PROGRAM_DIR"
: "${HUNTER_UA:=Mozilla/5.0 (compatible; BugBounty-Research; $HUNTER_HANDLE)}"
: "${HUNTER_HEADER_NAME:=X-Bug-Bounty}"
: "${HUNTER_HEADER_VALUE:=$HUNTER_HANDLE}"
ID_HEADER="${HUNTER_HEADER_NAME}: ${HUNTER_HEADER_VALUE}"

# Authenticated request (attacker), marked
hcurl() {
  curl -s -i \
    -H "User-Agent: $HUNTER_UA" \
    -H "$ID_HEADER" \
    ${SESSION_COOKIE:+-H "Cookie: $SESSION_COOKIE"} \
    ${AUTH_BEARER:+-H "Authorization: Bearer $AUTH_BEARER"} \
    ${CSRF_TOKEN:+-H "X-CSRF-Token: $CSRF_TOKEN"} \
    "$@"
}
# Unauthenticated request, still marked
ucurl() { curl -s -i -H "User-Agent: $HUNTER_UA" -H "$ID_HEADER" "$@"; }
# Authenticated, pretty JSON
jcurl() { hcurl -H "Accept: application/json" "$@" | sed -n '/^{/,$p' | python3 -m json.tool 2>/dev/null || hcurl "$@"; }
# IDOR helper: pass a URL containing $ATTACKER_USER_ID; it re-requests with the victim's ID swapped in
idor_check() {
  local url="$1"
  [ -z "$VICTIM_USER_ID" ] && { echo "[!] VICTIM_USER_ID not set"; return 1; }
  local victim_url="${url//$ATTACKER_USER_ID/$VICTIM_USER_ID}"
  echo "=== ATTACKER: $url ==="; hcurl "$url"
  echo; echo "=== VICTIM (id swapped): $victim_url ==="; hcurl "$victim_url"
}
export -f hcurl ucurl jcurl idor_check

echo "Active program: $PROGRAM  [${PLATFORM:-platform?}]"
echo "  Target:  ${TARGET_BASE_URL:-NOT SET}"
echo "  Header:  $ID_HEADER"
echo "  Bearer:  $([ -n "$AUTH_BEARER" ] && echo SET || echo '- ')   Cookie: $([ -n "$SESSION_COOKIE" ] && echo SET || echo '- ')   VictimID: ${VICTIM_USER_ID:-'-'}"
echo "  Commands: hcurl ucurl jcurl idor_check"
