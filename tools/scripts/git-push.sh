#!/usr/bin/env bash
# git-push.sh — safe commit + push. Blocks if any secret file is staged.
# Usage: bash tools/scripts/git-push.sh "acme: F001 IDOR confirmed High"
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

SECRET_RE='\.session\.env|session\.env\.local|^identity\.md|\.crt$|\.key$|\.pem$'

blocked() {
  local staged; staged=$(git diff --cached --name-only | grep -E "$SECRET_RE" || true)
  [ -n "$staged" ] && { echo "[!] BLOCKED — secret file staged:"; echo "$staged" | sed 's/^/    /'; \
    echo "    git reset HEAD <file>  then retry"; return 0; }
  return 1
}

blocked && exit 1
git add -A
if blocked; then git reset HEAD >/dev/null; echo "[!] Unstaged everything — fix .gitignore."; exit 1; fi

MSG="${1:-Session update $(date '+%Y-%m-%d %H:%M')}"
echo "=== committing ==="; git diff --cached --name-only | sed 's/^/  /'
git commit -q -m "$MSG"
if git remote | grep -q .; then git push -q && echo "[+] pushed: $MSG"; else echo "[i] committed (no remote set): $MSG"; fi
