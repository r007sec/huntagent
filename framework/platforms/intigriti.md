# Platform — Intigriti

## Identity and traffic marking

- Intigriti issues researcher email aliases (`@intigriti.me` style) — use one for test accounts.
- Many programs require an identifying header so their WAF/SOC can tell research from attack. Common:
  ```
  X-Intigriti-Username: <username>
  ```
  or a program-specified header. Check the program's "Details / Out of scope" and any custom testing
  requirements. Follow what the program states.

## Submission form fields (map your report to these)

1. **Title** — `[Vuln type] in [endpoint] allows [impact]`.
2. **Domain / endpoint** — the in-scope asset the bug is on.
3. **Type of vulnerability** — Intigriti's category list (maps to OWASP/CWE).
4. **Severity** — Intigriti's CVSS-based calculator / Contextual Vulnerability Standard. Provide the
   vector. See [../severity-mapping.md](../severity-mapping.md).
5. **Description** — the report body. Intigriti reviewers value a tight summary, exact steps, and a
   clear PoC. Apply the style guide.
6. **Proof of concept** — steps + attachments. Keep PoC private.

## Rating

CVSS-based, using Intigriti's calculator and its Contextual Vulnerability Standard (impact can raise
or lower the raw score based on business context). Justify metrics; note real business impact.

## Rules that catch people out

- Scope is per-program and often narrow — read "In scope" and "Out of scope" carefully.
- Some programs are tuples of exact domains, not wildcards; do not assume subdomains are in scope.
- Nondisclosure by default; private programs are confidential.
- Intigriti weights report quality heavily in reviewer experience — a clean, reproducible report is
  rated and paid faster.
