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
# Account-wide recon/provider API keys (gitignored), if present — exported into the shell.
[ -f "$WORKSPACE_ROOT/.keys.env" ] && { set -a; source "$WORKSPACE_ROOT/.keys.env"; set +a; }

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
# Scope check: is a host/URL in scope for this program? Reads programs/<name>/scope.txt.
# Usage: inscope https://api.example.com/x   ->  prints IN SCOPE / OUT OF SCOPE (exit 0/1)
inscope() {
  local raw="${1:?usage: inscope <host-or-url>}" scope="$ACTIVE_PROGRAM_DIR/scope.txt"
  [ -f "$scope" ] || { echo "[!] no scope.txt for $ACTIVE_PROGRAM — fill it from the brief"; return 2; }
  local host="${raw#*://}"; host="${host%%/*}"; host="${host%%:*}"; host="${host%%\?*}"
  local pat
  while IFS= read -r pat; do
    pat="${pat%%#*}"; pat="$(echo "$pat" | tr -d '[:space:]')"; [ -z "$pat" ] && continue
    if [[ "$pat" == \*.* ]]; then
      local base="${pat#\*.}"
      [[ "$host" == "$base" || "$host" == *".$base" ]] && { echo "IN SCOPE  ($host ~ $pat)"; return 0; }
    else
      [[ "$host" == "$pat" ]] && { echo "IN SCOPE  ($host = $pat)"; return 0; }
    fi
  done < "$scope"
  echo "OUT OF SCOPE  ($host not in scope.txt) — do not test"; return 1
}

# IDOR helper: pass a URL containing $ATTACKER_USER_ID; it re-requests with the victim's ID swapped in
idor_check() {
  local url="$1"
  [ -z "$VICTIM_USER_ID" ] && { echo "[!] VICTIM_USER_ID not set"; return 1; }
  local victim_url="${url//$ATTACKER_USER_ID/$VICTIM_USER_ID}"
  echo "=== ATTACKER: $url ==="; hcurl "$url"
  echo; echo "=== VICTIM (id swapped): $victim_url ==="; hcurl "$victim_url"
}
export -f hcurl ucurl jcurl idor_check inscope

echo "Active program: $PROGRAM  [${PLATFORM:-platform?}]"
echo "  Target:  ${TARGET_BASE_URL:-NOT SET}"
echo "  Header:  $ID_HEADER"
echo "  Bearer:  $([ -n "$AUTH_BEARER" ] && echo SET || echo '- ')   Cookie: $([ -n "$SESSION_COOKIE" ] && echo SET || echo '- ')   VictimID: ${VICTIM_USER_ID:-'-'}"
echo "  Scope:   $([ -f "$PROGRAM_DIR/scope.txt" ] && echo "$(grep -vcE '^\s*#|^\s*$' "$PROGRAM_DIR/scope.txt") entries in scope.txt" || echo 'scope.txt MISSING — fill from brief')"
echo "  Keys:    $([ -f "$WORKSPACE_ROOT/.keys.env" ] && echo "$(grep -cE '^[A-Z].*="[^"]+"' "$WORKSPACE_ROOT/.keys.env" 2>/dev/null || echo 0) recon keys loaded" || echo 'no .keys.env (recon runs with free sources only)')"
echo "  Commands: hcurl ucurl jcurl idor_check inscope"
