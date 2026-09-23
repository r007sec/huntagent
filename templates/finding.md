# F{###} — {vuln class} — {short slug}

Program: {program}
Platform: {bugcrowd | hackerone | intigriti | yeswehack}
Date: {YYYY-MM-DD}
Status: LEAD
Severity (proposed): {Critical | High | Medium | Low | Info}  ·  CVSS: {vector}
CWE: {CWE-###}

> This is the working file — a lab notebook, not the submission. Write freely here. The polished
> submission goes in a report drafted from `report.md`. Status changes to CONFIRMED only after all
> five gates in `framework/validation-gate.md` pass. For a filled example, see
> `examples/EXAMPLE-finding.md`.

## Summary

One paragraph: what the bug is, where, and what an attacker does with it. Plain language.

## Location

| | |
|--|--|
| Affected URL | `https://target/path` |
| Method | GET / POST / PUT / DELETE |
| Parameter | `name` |
| Auth required | Yes / No |
| Role required | None / User / Admin |

## Root cause

Which control is missing or wrong, and why the server behaves this way. One or two sentences. If you
cannot name it yet, say so — that means Gate 2 is not met and this is still a LEAD.

## Reproduction

Accounts used:
- Attacker: `{email}`
- Victim: `{email}` (if the class needs two accounts)

Steps:
1.
2.
3.

## Proof of concept

Attacker request:
```http
{METHOD} /path HTTP/1.1
Host: target
Authorization: Bearer {ATTACKER_TOKEN}
```

Response (the part that proves impact):
```http
HTTP/1.1 200 OK

{ ...evidence... }
```

Evidence files: `../logs/F{###}-*.png`

## Impact

Who is affected and what the attacker gains — shown by the PoC above, not asserted. Name the data or
action and the scope (one user / all users / admins).

## Validation gate

| Gate | Pass? | Note |
|------|-------|------|
| 1 Reproducible | | reproduced ×__ |
| 2 Root cause known | | |
| 3 Working PoC | | |
| 4 In scope | | checked brief on {date} |
| 5 Real impact | | |

Blocked at: {gate, or "none — CONFIRMED"}
What's missing: {specific evidence needed}
Next action: {exact first step next session}

## Remediation

The fix, in the developer's terms. What check to add, where.

## Notes

Anything that does not fit above — failed attempts (so you don't repeat them), related endpoints,
duplicate-likelihood check.
