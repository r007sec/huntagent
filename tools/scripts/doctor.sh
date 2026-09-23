#!/usr/bin/env bash
# doctor.sh — check the toolchain is installed and paths resolve, before you rely on them.
# Usage: bash tools/scripts/doctor.sh
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/go/bin:$HOME/go/bin:$HOME/.local/bin"

ok=0; miss=0
check() { # check <name> [alt-binary]
  if command -v "$1" >/dev/null 2>&1 || { [ -n "${2:-}" ] && command -v "$2" >/dev/null 2>&1; }; then
    printf "  ok    %s\n" "$1"; ok=$((ok+1))
  else
    printf "  MISS  %s\n" "$1"; miss=$((miss+1))
  fi
}
path() { if [ -e "$2" ]; then printf "  ok    %s (%s)\n" "$1" "$2"; else printf "  MISS  %s (%s)\n" "$1" "$2"; fi; }

echo "Recon tools:"
for t in subfinder amass httpx waybackurls gf ffuf nuclei dirsearch jq; do
  [ "$t" = httpx ] && check httpx httpxx || check "$t"
done
echo "Exploitation / OOB:"
for t in jwt_tool subzy interactsh-client sqlmap; do check "$t"; done
echo "Resources:"
path "SecLists"          "/usr/share/seclists"
path "Nuclei templates"  "$HOME/nuclei-templates"
path "gf patterns"       "$HOME/.gf"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
path "Recon keys"        "$ROOT/.keys.env"

echo
echo "Present: $ok   Missing: $miss"
[ "$miss" -gt 0 ] && echo "Install the MISS items or adjust PATH (see knowledge-base/tools/toolchain.md)."
exit 0
