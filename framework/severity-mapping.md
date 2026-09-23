# Severity Mapping — One Bug, Four Platforms

Each platform grades severity its own way. The underlying judgment is the same; only the label
changes. Rate the bug once on impact, then translate. Always defer to the program brief's own reward
table when it gives one.

## The master table

| Band | CVSS 3.1 | Bugcrowd (VRT/P) | HackerOne | Intigriti | YesWeHack | Typical examples |
|------|----------|------------------|-----------|-----------|-----------|------------------|
| Critical | 9.0–10.0 | P1 | Critical (9.0–10.0) | Critical | Critical | RCE, SQLi with data access, auth bypass to admin, SSRF to cloud metadata + creds |
| High | 7.0–8.9 | P2 | High (7.0–8.9) | High | High | IDOR on sensitive data/actions, stored XSS with session theft, account takeover, XXE, SSTI |
| Medium | 4.0–6.9 | P3 | Medium (4.0–6.9) | Medium | Medium | Reflected XSS, CSRF on meaningful action, most open redirects when chained, some IDOR |
| Low | 0.1–3.9 | P4 | Low (0.1–3.9) | Low | Low | Self-XSS with a vector, low-impact info disclosure, missing hardening with a real (small) impact |
| Info | 0.0 | P5 | None/Informational | Accepted-Informational | Low/None | Best-practice notes, missing headers with no exploit, verbose errors |

Notes:
- **CVSS is the common currency.** Compute it once at
  <https://www.first.org/cvss/calculator/3.1> and quote the vector in the report. Every platform
  accepts a justified CVSS vector even when it uses its own scale.
- **Bugcrowd** rates by its Vulnerability Rating Taxonomy (VRT), which maps to P1–P5. Pick the most
  specific VRT category; it often sets the priority directly, sometimes overriding raw CVSS. VRT:
  <https://bugcrowd.com/vulnerability-rating-taxonomy>.
- **HackerOne** uses CVSS bands directly and shows the calculator in the submission form.
- **Intigriti** uses its own CVSS-based calculator during submission and its Contextual
  Vulnerability Standard.
- **YesWeHack** uses CVSS 3.1; some programs add their own grid. Its report form asks for the vector.

## Rating discipline

Rate on **demonstrated** impact, the outcome of [validation-gate.md](validation-gate.md) Gate 5 —
not the worst case you can imagine.

- Justify each CVSS metric in one word in the report (Attack Vector: Network; Privileges Required:
  Low; and so on). A vector without justification invites a downgrade.
- If you rate High, be ready to say why not Critical and why not Medium. One sentence each. This
  survives triage pushback.
- Do not inflate. An inflated severity that gets corrected down costs you credibility on the next
  report. A correct severity that the triager *raises* is the best outcome — let the facts earn it.

## CWE — attach the right one

Platforms increasingly want a CWE. Common ones:

| Class | CWE |
|-------|-----|
| IDOR / broken object-level auth | CWE-639 |
| SSRF | CWE-918 |
| Reflected/Stored XSS | CWE-79 |
| SQL injection | CWE-89 |
| Auth bypass / broken auth | CWE-287 |
| CSRF | CWE-352 |
| XXE | CWE-611 |
| SSTI | CWE-1336 (or CWE-94) |
| Open redirect | CWE-601 |
| Sensitive data exposure | CWE-200 |
| Improper access control (general) | CWE-284 |
