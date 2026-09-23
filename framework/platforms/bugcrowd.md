# Platform — Bugcrowd

## Identity and traffic marking

- Test-account emails follow `handle@bugcrowdninja.com` (and `handle_2@...` for a victim account).
- **Every request must carry these headers** (Bugcrowd requirement — identifies traffic as
  authorized research so you are not flagged or IP-banned):
  ```
  User-Agent: Mozilla/5.0 (compatible; BugBounty-Research; <handle>@bugcrowdninja.com)
  X-Bug-Bounty: <handle>
  ```
  If a brief specifies a different marker, the brief wins.

## Submission form fields (map your report to these)

1. **Submission title** — `[Vuln type] in [endpoint/feature] allows [impact]`.
2. **Target** — pick from the dropdown; must match the brief's asset string exactly.
3. **Bug URL / location** — the exact affected URL.
4. **VRT category** — choose the most specific match. This drives the priority.
5. **Description** — markdown. This is where the report body goes (summary, steps, PoC, impact, fix).
6. **Attachments** — up to 20 files. Never upload PoC media to public sites (YouTube, Imgur).

## Rating

Bugcrowd rates by the **VRT** → P1–P5. Choose the VRT entry first; it usually sets the priority.
Provide a CVSS vector too, but the VRT category is what the triager works from. See
[../severity-mapping.md](../severity-mapping.md).

## Rules that catch people out

- Nondisclosure by default — findings and even a private program's *existence* stay confidential.
- Submit only through Bugcrowd (Crowdcontrol). No direct company contact.
- Read the brief's "Focus Areas" — those pay more.
- Standard Disclosure Terms apply on top of each brief. Program brief always supersedes.
