#!/usr/bin/env bash
# recon.sh — recon pipeline for a program (platform-agnostic).
# Usage: bash tools/scripts/recon.sh <domain> <program>
# Reads the program's .session.env for the identifier header/UA; falls back to generic marking.
# Output: programs/<program>/recon/
set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/go/bin:$HOME/go/bin:$HOME/.local/bin"

DOMAIN="${1:-}"; PROGRAM="${2:-}"
[ -z "$DOMAIN" ] || [ -z "$PROGRAM" ] && { echo "Usage: bash tools/scripts/recon.sh <domain> <program>"; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[ ! -d "$ROOT/programs/$PROGRAM" ] && { echo "[!] programs/$PROGRAM not found. Run new-program.sh first."; exit 1; }
OUT="$ROOT/programs/$PROGRAM/recon"; mkdir -p "$OUT/gf"

# Identity from session file, with safe defaults
SESSION="$ROOT/programs/$PROGRAM/.session.env"
[ -f "$SESSION" ] && { set -a; source "$SESSION"; set +a; }
UA="${HUNTER_UA:-Mozilla/5.0 (compatible; BugBounty-Research; ${HUNTER_HANDLE:-researcher})}"
ID_HEADER="${HUNTER_HEADER_NAME:-X-Bug-Bounty}: ${HUNTER_HEADER_VALUE:-${HUNTER_HANDLE:-researcher}}"
NUCLEI_RATE=30
log(){ echo "[$(date '+%H:%M:%S')] $*"; }

echo "recon: $DOMAIN  ->  programs/$PROGRAM/recon/   header: $ID_HEADER"

# 1. Subdomains (passive)
log "subdomains"
subfinder -d "$DOMAIN" -silent -all 2>/dev/null | sort -u > "$OUT/subs-subfinder.txt" || true
amass enum -passive -d "$DOMAIN" -silent 2>/dev/null | sort -u > "$OUT/subs-amass.txt" || true
curl -s --max-time 30 "https://crt.sh/?q=%25.$DOMAIN&output=json" 2>/dev/null \
  | python3 -c "import sys,json
try:
 d=json.load(sys.stdin);n=set()
 for e in d:
  for x in e.get('name_value','').split(chr(10)):
   x=x.strip().lstrip('*.')
   if x.endswith('$DOMAIN'):n.add(x)
 print(chr(10).join(sorted(n)))
except:pass" > "$OUT/subs-crt.txt" || true
cat "$OUT"/subs-*.txt 2>/dev/null | sort -u | grep -v '^$' > "$OUT/subdomains-all.txt"
log "  $(wc -l < "$OUT/subdomains-all.txt") unique subdomains"

# 1b. Scope filter — only probe in-scope hosts (don't send marked traffic out of scope)
SCOPE="$ROOT/programs/$PROGRAM/scope.txt"
PROBE="$OUT/subdomains-all.txt"
if [ -f "$SCOPE" ] && grep -qvE '^\s*#|^\s*$' "$SCOPE"; then
  python3 - "$SCOPE" "$OUT/subdomains-all.txt" > "$OUT/subdomains-inscope.txt" <<'PY'
import sys
pats=[l.split('#')[0].strip() for l in open(sys.argv[1])]; pats=[p for p in pats if p]
def ok(h):
    for p in pats:
        if p.startswith('*.'):
            b=p[2:]
            if h==b or h.endswith('.'+b): return True
        elif h==p: return True
    return False
for h in open(sys.argv[2]):
    h=h.strip()
    if h and ok(h): print(h)
PY
  PROBE="$OUT/subdomains-inscope.txt"
  log "  scope filter: $(wc -l < "$PROBE") of $(wc -l < "$OUT/subdomains-all.txt") in scope (probing only these)"
else
  log "  no scope.txt — probing all enumerated hosts; fill scope.txt to restrict"
fi

# 2. Live hosts (httpx; binary may be 'httpx' or 'httpxx')
log "live hosts"
HTTPX=$(command -v httpxx || command -v httpx || echo httpx)
"$HTTPX" -l "$PROBE" -silent -title -status-code -tech-detect \
  -content-length -follow-redirects -timeout 10 \
  -H "User-Agent: $UA" -H "$ID_HEADER" -o "$OUT/live-hosts.txt" 2>/dev/null || true
awk '{print $1}' "$OUT/live-hosts.txt" 2>/dev/null | sort -u > "$OUT/live-urls.txt"
log "  $(wc -l < "$OUT/live-hosts.txt" 2>/dev/null || echo 0) live"

# 3. Interesting hosts
grep -iE "admin|api|dev|staging|test|internal|portal|dashboard|manage|backend|staff|vpn|jenkins|gitlab|jira|confluence|kibana|grafana|vault" \
  "$OUT/live-hosts.txt" > "$OUT/interesting-hosts.txt" 2>/dev/null || true
log "  $(wc -l < "$OUT/interesting-hosts.txt" 2>/dev/null || echo 0) interesting"

# 4. Wayback URLs + JS
log "wayback"
echo "$DOMAIN" | waybackurls 2>/dev/null | sort -u > "$OUT/wayback-raw.txt" || true
grep '?' "$OUT/wayback-raw.txt" 2>/dev/null | sort -u > "$OUT/wayback-params.txt" || true
grep -iE '\.js($|\?)' "$OUT/wayback-raw.txt" 2>/dev/null | sort -u > "$OUT/wayback-js.txt" || true

# 5. gf patterns
for p in xss ssrf sqli redirect idor lfi rce ssti; do
  [ -f "$HOME/.gf/$p.json" ] && cat "$OUT/wayback-params.txt" 2>/dev/null | gf "$p" 2>/dev/null | sort -u > "$OUT/gf/$p.txt" || true
done

# 6. Nuclei (conservative)
log "nuclei (rl $NUCLEI_RATE)"
nuclei -l "$OUT/live-urls.txt" -t "$HOME/nuclei-templates/" \
  -severity critical,high,medium -tags misconfig,exposure,default-login,takeover \
  -rl "$NUCLEI_RATE" -c 10 -silent -H "User-Agent: $UA" -H "$ID_HEADER" \
  -o "$OUT/nuclei-results.txt" 2>/dev/null || true

# 7. Summary
{
  echo "# Recon Summary — $PROGRAM"
  echo; echo "Domain: $DOMAIN   ·   $(date '+%Y-%m-%d %H:%M')"
  echo
  echo "| Data | Count |"; echo "|--|--|"
  echo "| Subdomains | $(wc -l < "$OUT/subdomains-all.txt" 2>/dev/null||echo 0) |"
  echo "| Live hosts | $(wc -l < "$OUT/live-hosts.txt" 2>/dev/null||echo 0) |"
  echo "| Interesting | $(wc -l < "$OUT/interesting-hosts.txt" 2>/dev/null||echo 0) |"
  echo "| Wayback params | $(wc -l < "$OUT/wayback-params.txt" 2>/dev/null||echo 0) |"
  echo "| JS files | $(wc -l < "$OUT/wayback-js.txt" 2>/dev/null||echo 0) |"
  echo "| Nuclei hits | $(wc -l < "$OUT/nuclei-results.txt" 2>/dev/null||echo 0) |"
  echo; echo "## Interesting hosts"; echo '```'; cat "$OUT/interesting-hosts.txt" 2>/dev/null||echo none; echo '```'
  echo; echo "## Nuclei"; echo '```'; cat "$OUT/nuclei-results.txt" 2>/dev/null||echo none; echo '```'
  echo; echo "## Next"
  echo "- Review interesting hosts and JS files (endpoints, secrets)"
  echo "- gf/idor.txt: swap IDs between two accounts   ·   gf/ssrf.txt: point at a callback"
  echo "- Map auth flow; record tech stack in README"
} > "$OUT/summary.md"

log "done -> programs/$PROGRAM/recon/summary.md"
