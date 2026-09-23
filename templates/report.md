# Report Draft — F{###}

> Internal header — do not paste into the submission. Fill the platform form from the sections below;
> which form field each maps to is in `framework/platforms/<platform>.md`. Before submitting, run the
> eight-point self-check in `framework/report-style-guide.md`. The body below is written to pass it:
> plain words, no filler, no emoji, bold only where it carries meaning. For a filled example, see
> `examples/EXAMPLE-report.md`.

Platform: {bugcrowd | hackerone | intigriti | yeswehack}
Program / asset: {name}
Submitted: {date}   Internal ref: F{###}

---

## Title

> One line: `[vuln type] in [endpoint/feature] allows [impact]`.

{e.g. IDOR in GET /api/v1/users/{id}/orders allows any user to read any other user's orders}

## Severity

CVSS 3.1: `{vector}` — {band}
CWE: {CWE-###}

One sentence justifying the band. One sentence why not higher, one why not lower.

## Summary

Two to four sentences. What the bug is, where it lives, what an attacker can do. A triager should
understand it here and need nothing else to know it is real. No preamble, no significance padding.

## Steps to reproduce

Accounts:
- Attacker: {email/handle}
- Victim: {email/handle} (if needed)

1.
2.
3.

Anyone on the triage team should reproduce from these steps alone. No missing IDs, tokens, or
"then do the obvious thing."

## Proof of concept

The request that triggers it:
```http
{METHOD} /path HTTP/1.1
Host: {host}
{auth header}
```

The response that proves impact (trimmed to what matters):
```http
HTTP/1.1 200 OK

{ evidence }
```

Attached: {screenshots / short screen recording}. Keep all PoC media private to the report — never a
public host.

## Impact

State the concrete harm: who is affected, what data or action is exposed, how much of it, and what a
real attacker gains. Let the fact carry the weight — do not editorialize about risk or trust.

## Remediation

The fix in developer terms: the exact check to add and where, applied to every affected route (not
only the one endpoint you demonstrated).

---

## Internal tracking (not submitted)

| | |
|--|--|
| Finding file | `programs/{name}/findings/F{###}-...md` |
| Status | Reported / Triaged / Resolved / Duplicate / N/A |
| Reward | |
| Triage notes | |
| Lesson | |
