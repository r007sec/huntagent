# Platform — HackerOne

## Identity and traffic marking

- HackerOne gives each researcher an `@wearehackerone.com` email alias — use it (or a program-
  specified alias) for test accounts so traffic is attributable to you.
- Many programs ask you to include an identifying header. Common convention:
  ```
  User-Agent: <username> (HackerOne)
  ```
  Some programs specify their own header (for example a per-program token). Follow the policy page.

## Submission form fields (map your report to these)

1. **Title** — `[Vuln type] on [asset] leads to [impact]`.
2. **Asset** — select the in-scope asset from the structured scope list.
3. **Weakness (CWE)** — pick the matching CWE. See [../severity-mapping.md](../severity-mapping.md).
4. **Severity** — HackerOne's built-in CVSS 3.1 calculator. Fill the vector; it produces the band.
5. **Description** — markdown. Report body goes here: summary, steps to reproduce, PoC, impact,
   remediation. HackerOne renders markdown, so structure it well but keep to the style guide.
6. **Attachments** — screenshots / video. Keep PoC private to the report.

## Rating

CVSS 3.1 bands directly (Critical/High/Medium/Low/None). The program may adjust based on its own
business impact. Justify each metric.

## Rules that catch people out

- Structured scope: test only assets marked "In scope / Eligible for bounty." "Out of scope" assets
  are reportable only if the policy says so, and usually unpaid.
- Respect the policy's testing constraints (no automated scanning where prohibited, rate limits).
- Disclosure is coordinated — a report is public only if both sides agree to disclose. Do not post
  details anywhere until then.
- Signal and reputation matter: N/A and spam reports lower your stats. The validation gate protects
  this.
- Duplicate detection is strict; check Hacktivity for the same class on the target first.
