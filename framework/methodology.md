# Hunting Methodology

The same loop every time. Consistency beats inspiration — inspiration is what happens when a
disciplined process surfaces something odd and you notice.

```
READ BRIEF -> RECON -> MAP SURFACE -> PRIORITIZE -> TEST -> VALIDATE -> REPORT
     ^                                                          |
     +--------------------- iterate ----------------------------+
```

Each session declares which phase it is in (see [../CLAUDE.md](../CLAUDE.md)). You do not drift into
exploitation while still doing recon.

---

## Phase 1 — Read the brief (before touching anything)

The brief decides whether your work counts. Read it fully and record, in the program's
`README.md`:

- Exact in-scope assets (wildcards vs. specific hosts — do not assume).
- Out-of-scope assets and excluded vulnerability classes.
- Required traffic-identifier header for the platform (see [platforms/](platforms/)).
- Testing constraints: automated scanning allowed? rate limits? test accounts self-registered?
- Reward table and any Focus Areas (higher-paying targets).
- Cross-check the class exclusions and conduct rules in
  [compliance-and-exclusions.md](compliance-and-exclusions.md) so you don't spend time on something
  non-qualifying.

If an asset is not clearly in scope, it is out of scope until proven otherwise.

## Phase 2 — Recon

Map what exists. Passive first, then active, marking traffic as required. Use
[../knowledge-base/recon/recon-playbook.md](../knowledge-base/recon/recon-playbook.md) and
`../tools/scripts/recon.sh`. Outputs land in `programs/<name>/recon/`.

Diff-thinking on the output: surface the handful of hosts/endpoints worth investigating, not the full
dump. An `admin.` subdomain, an exposed `.git`, an old API version, a JS file full of endpoints —
those are leads. Two hundred parked subdomains are not.

Keep the output between sessions and diff it. Re-running recon and comparing `subdomains-all.txt` and
the JS/wayback endpoint lists against the last run surfaces *new* surface — a subdomain, a `/v3/` route,
a parameter that wasn't there before. New surface is the best hunting ground; see the fresh-surface read
in [prior-art-check.md](prior-art-check.md).

## Phase 3 — Map the attack surface

Turn recon into a testable model. For each live, in-scope app, note:

- Auth model: login, registration, reset, 2FA, OAuth/SAML, session mechanism (cookie vs. JWT).
- Object model: what resources exist and how they are addressed (numeric IDs, UUIDs, slugs) — the
  IDOR map.
- State-changing actions: anything that moves money, changes permissions, sends mail, uploads files.
- Trust boundaries: where user input crosses into a query, a template, a file path, an outbound
  request (the injection/SSRF map).
- Integrations: webhooks, third-party callbacks, import/export, PDF/image generation.

## Phase 4 — Prioritize

Spend time where impact and payout are highest and where auto-scanners are weakest.

First, aim at fresh surface. A just-shipped feature, a new API version, a newly in-scope asset — read
[prior-art-check.md](prior-art-check.md) for how to spot these. New code has had the fewest testers and
no prior reports, so it has the best bug-to-time ratio. Test it before the well-trodden endpoints.

Then, by class, rough order:

1. Broken access control / IDOR on sensitive data or actions — common, high-paying, scanner-blind.
2. Authentication and account takeover — reset flows, OAuth/JWT handling, session fixation.
3. Server-side injection — SQLi, SSRF, SSTI, XXE — where user input reaches a backend action.
4. Business-logic flaws — pricing, quotas, workflow bypass — unique, hard to dedupe.
5. XSS with real impact (stored, or reflected reaching a session/action).

Skip, unless the brief says otherwise: self-XSS, missing headers with no exploit, low-value info
disclosure, best-practice deviations with no demonstrated harm.

Before you commit hours to a lead, run the quick [prior-art-check.md](prior-art-check.md) — the
program's disclosures, changelog, and known CVEs for the stack. Ten minutes here saves a day chasing a
bug someone already reported.

## Phase 5 — Test

Work one hypothesis at a time so you can attribute cause (Gate 2). Change one variable, observe,
record. Keep every interesting request.

**Build a test matrix.** For each priority target from Phase 4, list the classes worth trying against
it (an upload feature → file-upload, XXE, stored XSS; an ID-addressed API → IDOR, access control; a
"fetch URL" field → SSRF). Then work the matrix cell by cell. This is how you get coverage instead of
poking at whatever catches your eye.

**Establish the baseline before claiming a break.** Prove the control works first — the endpoint
denies you when it should, returns only your own data, enforces the limit — then break it and keep
both request/response pairs. Most false positives die here (see
[../knowledge-base/false-positive-traps.md](../knowledge-base/false-positive-traps.md)).

Per-class test cases live in [../knowledge-base/vulnerabilities/](../knowledge-base/vulnerabilities/):
IDOR, SSRF, AUTH-BYPASS, OAUTH-JWT, XSS, CSRF, FILE-UPLOAD, XXE-SSTI, BUSINESS-LOGIC,
RACE-CONDITIONS, SUBDOMAIN-TAKEOVER, GRAPHQL, MOBILE. Payloads by category are in
[../knowledge-base/payloads/quick-reference.md](../knowledge-base/payloads/quick-reference.md).

Stay within the rules: read-only PoCs, no DoS, no destructive payloads, no touching real users' data,
marked traffic, conservative rates. If a target degrades, stop. Full list:
[compliance-and-exclusions.md](compliance-and-exclusions.md).

## Phase 6 — Validate

Run the lead through [validation-gate.md](validation-gate.md). It becomes a finding only when all
five gates pass. Document leads that do not pass with the specific blocker and next action — those
are your fastest wins next session.

Once it passes, ask whether it's worth more than its class suggests: can you chain or widen it into a
higher impact? See [impact-escalation.md](impact-escalation.md) and demonstrate the escalation before
you rate the severity.

## Phase 7 — Report

Write it with [report-style-guide.md](report-style-guide.md) and the
[../templates/report.md](../templates/report.md) template, mapped to the platform's form
([platforms/](platforms/)). Then submit through the platform only.

---

## Documentation discipline

- Open a `finding.md` the moment something looks promising — do not trust memory.
- One file per finding: `F###-<class>-<slug>.md`.
- Update the program `HANDOFF.md` at the end of every session. It is what makes the next session
  start in thirty seconds instead of thirty minutes.
