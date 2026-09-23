# Recon Playbook

Passive before active. Mark every request with the platform's required identifier header (see
`../../framework/platforms/`). `../../tools/scripts/recon.sh <domain> <program>` runs the core of
this automatically; this file is the manual reference and the "why."

Set PATH once per shell so Go tools resolve:
```bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/go/bin:$HOME/go/bin:$HOME/.local/bin"
```

## 1. Subdomain enumeration (passive)

```bash
subfinder -d TARGET -silent -all | sort -u > subs-subfinder.txt
amass enum -passive -d TARGET -silent | sort -u > subs-amass.txt
curl -s "https://crt.sh/?q=%25.TARGET&output=json" | jq -r '.[].name_value' \
  | sed 's/^\*\.//' | sort -u > subs-crt.txt
cat subs-*.txt | sort -u > subdomains-all.txt
```

## 2. Live host probing

```bash
httpx -l subdomains-all.txt -silent -title -status-code -tech-detect \
  -content-length -follow-redirects -timeout 10 \
  -H "User-Agent: <marked>" -H "<platform-id-header>" -o live-hosts.txt
awk '{print $1}' live-hosts.txt | sort -u > live-urls.txt
```

Flag interesting hosts: `admin api dev staging test internal portal dashboard manage backend vpn
jenkins gitlab jira confluence kibana grafana vault`.

## 3. Historical URLs and JS

```bash
echo TARGET | waybackurls | sort -u > wayback-raw.txt
grep '?' wayback-raw.txt | sort -u > wayback-params.txt      # parameter attack surface
grep -iE '\.js($|\?)' wayback-raw.txt | sort -u > wayback-js.txt
```

Pull endpoints and secrets out of JS files — they reveal API paths the UI never shows and sometimes
hardcoded keys (describe keys in findings, never paste them into the repo).

## 4. Parameter patterns (gf)

```bash
for p in xss ssrf sqli redirect idor lfi rce ssti; do
  cat wayback-params.txt | gf "$p" | sort -u > "gf/$p.txt"
done
```

## 5. Content discovery (active — check the brief allows it)

```bash
ffuf -u https://HOST/FUZZ -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt \
  -H "User-Agent: <marked>" -H "<platform-id-header>" -mc 200,201,301,302,401,403 -ac
```

## 6. Nuclei (conservative)

```bash
nuclei -l live-urls.txt -t ~/nuclei-templates/ \
  -severity critical,high,medium -tags misconfig,exposure,default-login,takeover \
  -rl 30 -c 10 -silent -H "User-Agent: <marked>" -H "<platform-id-header>" -o nuclei-results.txt
```

Keep the rate low (`-rl 30`). Raise it only if the brief explicitly permits, and never past what the
target tolerates.

## Where to look after automation stops

Automation finds the easy 10%. The paid bugs are in the manual 90%:

- Auth flows — reset tokens, OAuth redirect handling, JWT `alg`/signature, session lifecycle.
- Object references — swap IDs between two accounts everywhere an ID appears.
- State machines — skip a step, replay a step, do steps out of order.
- Trust boundaries — anywhere your input becomes a query, template, path, or outbound request.
- Wordlists live at `/usr/share/seclists/`, nuclei templates at `~/nuclei-templates/`, gf patterns
  at `~/.gf/`.
