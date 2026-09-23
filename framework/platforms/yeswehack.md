# Platform — YesWeHack

## Identity and traffic marking

- YesWeHack provides disposable researcher emails (`@yeswehack.ninja` style) — use one for test
  accounts.
- Programs commonly require a header identifying your hunter tag so their team can whitelist and
  attribute research traffic. Common:
  ```
  X-YesWeHack: <username>
  ```
  or a program-defined header/marker. The program page's scope and rules state what is required —
  follow it exactly.

## Submission form fields (map your report to these)

1. **Title** — `[Vuln type] on [asset] allows [impact]`.
2. **Scope / asset** — select the in-scope asset.
3. **Bug type** — YesWeHack's category taxonomy (aligns with CWE/OWASP).
4. **Severity (CVSS)** — CVSS 3.1 vector; some programs add their own grid. See
   [../severity-mapping.md](../severity-mapping.md).
5. **Description / scenario** — the report body: summary, reproduction, PoC, impact, remediation.
   Apply the style guide.
6. **Attachments** — screenshots / video, kept private to the report.

## Rating

CVSS 3.1. Provide the vector and justify each metric. Where the program publishes its own severity
grid or reward matrix, rate against that as well.

## Rules that catch people out

- Scope discipline is strict; test only listed assets. Out-of-scope testing can mean a ban.
- Many YesWeHack programs are European and privacy-sensitive — do not exfiltrate real user PII;
  prove access with the minimum (one record, your own controlled victim account).
- Nondisclosure by default; private program details are confidential.
- Report language: keep it clear and plain; reviewers span many first languages, so the style guide's
  simplicity helps directly.
