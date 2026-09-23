# Toolchain and Burp Setup

Command reference and one-time setup. The one rule that spans all of it: every request to a target
carries the program's identifier header (see `../../framework/platforms/` and `identity.md`).

## PATH (once per shell, or add to shell rc)

```bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/go/bin:$HOME/go/bin:$HOME/.local/bin"
```

| Resource | Location |
|----------|----------|
| SecLists | `/usr/share/seclists/` |
| Nuclei templates | `~/nuclei-templates/` |
| gf patterns | `~/.gf/` |
| Go binaries | `~/go/bin/` |

Run `bash tools/scripts/doctor.sh` to confirm the toolchain is installed and paths resolve.

## Recon API keys

Provider keys (Shodan, Censys, VirusTotal, GitHub, SecurityTrails, Chaos, …) are account-wide, not
per-program. Keep them in one gitignored file at the repo root:

```bash
cp tools/scripts/.keys.env.template .keys.env   # then fill in the keys you have
```

`recon.sh` and `activate.sh` source `.keys.env` automatically, so the tools that read environment
variables pick them up. `activate` shows how many keys loaded; `doctor.sh` checks the file exists.
`.keys.env` is gitignored and blocked by `git-push.sh` — it never leaves your machine.

Two tools also keep their own config, which you fill separately if you use them directly:

| Tool | Its own key file |
|------|------------------|
| subfinder | `~/.config/subfinder/provider-config.yaml` |
| amass | `~/.config/amass/config.ini` |

Record those paths in `ENVIRONMENT.md` so a rebuild is quick. Without any keys, recon still runs on the
free passive sources — you just get fewer subdomains.

## Burp — mark all traffic (set once per program)

The identifier header differs per platform/program. Set it as a Match & Replace rule so every proxied
request carries it automatically.

Settings → Proxy → Match and replace → Add:

```
Type:    Request header
Match:    (leave blank)
Replace:  X-Bug-Bounty: <your-handle>        # use the program's required header name/value
```

Add a second rule for a marked User-Agent if the program wants one. To scope Burp so you never stray
out of bounds, set Target → Scope to the in-scope hosts (advanced scope control, matching your
program `scope.txt`), and set Proxy to intercept in-scope only.

For a per-program header, update the one Match & Replace rule when you switch programs, or keep
per-program Burp project files.

## Core commands

```bash
# Subdomains (passive)
subfinder -d TARGET -silent -all | sort -u > subs.txt
amass enum -passive -d TARGET -silent | sort -u >> subs.txt

# Live hosts
httpx -l subs.txt -silent -title -status-code -tech-detect -H "<id-header>" -o live.txt

# Historical URLs / params / JS
echo TARGET | waybackurls | sort -u > wb.txt
gf ssrf < wb.txt        # gf xss|sqli|idor|redirect|lfi|rce|ssti

# Content discovery
ffuf -u https://HOST/FUZZ -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt \
     -H "<id-header>" -mc all -fc 404 -ac

# Templated scan (conservative)
nuclei -l live.txt -severity critical,high,medium -rl 30 -H "<id-header>" -o nuclei.txt

# Out-of-band (SSRF/XXE/blind) — use interactsh or Burp Collaborator
interactsh-client
```

Wrapped, marked curl helpers (`hcurl`, `ucurl`, `jcurl`, `idor_check`) load with
`source tools/scripts/activate.sh <program>`.

## Manual toolkit

- **Burp Suite** — the core. Repeater, Intruder, Match & Replace, Collaborator, Turbo Intruder
  (races), Autorize/AuthMatrix (access control).
- **jwt_tool** — JWT attacks (`OAUTH-JWT.md`).
- **subzy / nuclei takeovers** — subdomain takeover (`SUBDOMAIN-TAKEOVER.md`).
- **ffuf / dirsearch** — content and parameter discovery.
