#!/usr/bin/env bash
# new-program.sh — scaffold a program folder from the templates.
# Usage: bash tools/scripts/new-program.sh <platform> <name> [domain]
#   e.g. bash tools/scripts/new-program.sh hackerone acme acme.com
set -euo pipefail

PLATFORM="${1:-}"; NAME="${2:-}"; DOMAIN="${3:-}"
if [ -z "$PLATFORM" ] || [ -z "$NAME" ]; then
  echo "Usage: bash tools/scripts/new-program.sh <platform> <name> [domain]"
  echo "  platform: bugcrowd | hackerone | intigriti | yeswehack"
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIR="$ROOT/programs/$NAME"
if [ -d "$DIR" ]; then echo "[!] programs/$NAME already exists"; exit 1; fi

mkdir -p "$DIR"/{recon,findings,report-drafts,logs}

sed "s/{name}/$NAME/g; s/{platform}/$PLATFORM/g" "$ROOT/templates/program-setup.md" > "$DIR/README.md"
sed "s/{program}/$NAME/g"                          "$ROOT/templates/HANDOFF.md"       > "$DIR/HANDOFF.md"
sed "s/{program}/$NAME/g"                          "$ROOT/templates/recon-checklist.md" > "$DIR/recon/checklist.md"
cp "$ROOT/tools/scripts/.session.env.template" "$DIR/.session.env"
sed -i "s/^PLATFORM=.*/PLATFORM=\"$PLATFORM\"/" "$DIR/.session.env"
[ -n "$DOMAIN" ] && sed -i "s#^TARGET_BASE_URL=.*#TARGET_BASE_URL=\"https://$DOMAIN\"#" "$DIR/.session.env"

# Scope allowlist — the source of truth for what you may test. Fill from the brief.
{
  echo "# In-scope hosts for $NAME — copy EXACTLY from the program brief."
  echo "# One per line. '*.example.com' matches any subdomain; 'api.example.com' is exact."
  echo "# The 'inscope <url>' helper (after activate) and your judgement both read this."
  [ -n "$DOMAIN" ] && { echo "$DOMAIN"; echo "*.$DOMAIN"; }
} > "$DIR/scope.txt"

echo "Created programs/$NAME  [$PLATFORM]"
echo "Next:"
echo "  1. Fill programs/$NAME/README.md from the brief (scope, rules, required header)"
echo "  2. Fill programs/$NAME/.session.env (identity + tokens)"
echo "  3. source tools/scripts/activate.sh $NAME"
[ -n "$DOMAIN" ] && echo "  4. bash tools/scripts/recon.sh $DOMAIN $NAME"
