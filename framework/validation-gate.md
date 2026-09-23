# Validation Gate — From Lead to Confirmed

Most wasted effort in bug bounty comes from two places: reporting things that are not bugs, and
reporting real bugs badly. This gate fixes the first. A lead does not become a finding, and a
finding does not become a report, until it passes every gate below. No exceptions, no "it's probably
fine."

This is the operational form of the core rule in [CLAUDE.md](../CLAUDE.md): **no false
confirmations.** Claude applies this gate to every lead before it changes a finding's status to
CONFIRMED or drafts a report.

---

## Status ladder

A finding moves in one direction through these states. It never skips a rung.

| Status | Meaning |
|--------|---------|
| `LEAD` | Something looks off. Not yet proven. Default state for anything new. |
| `CONFIRMED` | Passed all five gates below. Reproducible, understood, exploitable, in scope, impactful. |
| `REPORTED` | Submitted to the platform. |
| `TRIAGED` | Platform accepted it as valid. |
| `RESOLVED` / `DUPLICATE` / `N/A` | Final outcomes. |

---

## The five gates

A lead becomes CONFIRMED only when all five are true. If any one fails, it stays a `LEAD`, and the
finding doc records exactly which gate failed and what would close it.

### Gate 1 — Reproducible

The behavior triggers reliably, not once by luck.

- Reproduced at least **twice**, the second time from a clean state — new incognito window, fresh
  login, cleared cookies — to rule out a cached response or a stale session artifact.
- If it depends on timing, ordering, or a race, that condition is written down and repeatable.

Fails if: it worked once and you cannot make it happen again, or you are not sure which of your ten
changes caused it.

**Evidence bundle (capture this as you go, not after).** A finding is only as strong as what you can
show. Collect, in the finding's `logs/` folder:

- The exact triggering request as raw HTTP **and** a runnable `curl` (Burp "Copy as curl").
- The **request + response pair** for both the normal case and the exploit case — the contrast is
  the proof.
- For multi-account bugs, both requests **labeled** attacker/victim, with which account owns what.
- A wall-clock **timestamp** of first reproduction (protects you in first-reporter / dedup disputes).
- A short screen recording for anything stateful (logic, race, multi-step) — steps are hard to
  convey in text alone.

Redact real secrets/tokens to the minimum needed to prove the point; never commit them (describe,
don't paste).

### Gate 2 — Attributable (you know the root cause)

You can name *why* it happens, not just *that* it happens.

- Which check is missing or wrong (no ownership check, no auth, unescaped output, unsigned token, and
  so on).
- Why the server behaves this way, in one sentence, without guessing.

Fails if: the best you can say is "it returns data it shouldn't" without knowing which control is
absent. That is still a lead worth chasing — but it is a lead.

### Gate 3 — Exploitable (you have a working PoC)

There is a concrete proof, not a theory that it "could" be abused.

**Establish the baseline first (control test).** Before you claim a bypass, prove the control
*works* for you: confirm the endpoint correctly denies you when it should, or returns your own data
when it should. Then break it. A "bypass" you never saw enforced is often not a bypass — it may be a
public endpoint, an already-valid session, or data that was never protected. The before/after
contrast is both your proof and your false-positive filter.

**Rule out the class's known false-positive traps.** Generic reproduction is not enough — each class
has specific ways to look real without being real (an IDOR hitting public data, an SSRF that only
resolved DNS, a self-XSS, a "bypass" using your own live cookie). Before confirming, walk the traps
for this class in [../knowledge-base/false-positive-traps.md](../knowledge-base/false-positive-traps.md).

- For access control / IDOR: two accounts, and account A demonstrably reads or changes account B's
  data. A single account seeing its own data is not a finding.
- For injection/XSS: the payload actually executes or the query actually runs — a callback received,
  script fired in a real browser context, error confirming injection. A reflected string is not
  execution.
- For SSRF: an out-of-band callback proves the fetch, and you have tested (safely) whether internal
  targets are reachable.
- The PoC is the **minimum** needed to prove impact. Stop there. Do not chain further, do not pull
  more data than one record proves the point, do not escalate destructively.

Fails if: the proof is "in theory an attacker could..." with no demonstration.

### Gate 4 — In scope and submittable

Confirmed against the current program brief, today — not last week's cached version. Scope is one
half; *how you tested* and *whether the class even qualifies* is the other.

Scope and class:
- Target host/asset is explicitly listed as in scope (wildcard vs. specific host — do not assume).
- The vulnerability class is not on the program's exclusions or the platform's standard non-qualifying
  list. See [compliance-and-exclusions.md](compliance-and-exclusions.md) for the always-excluded
  issues and [platforms/](platforms/) for platform specifics.

How you tested (a finding produced by a prohibited method is not submittable, however real):
- Traffic was marked with the required identifier header.
- No prohibited technique: no automated scanning where banned, no DoS/load testing, no social
  engineering or phishing, no physical attacks.
- You did not touch real users' data or accounts — only your own controlled test accounts.
- You stayed within rate limits and stopped the moment anything degraded.

Fails if: the asset is out of scope or third-party, the class is excluded, or you can only reproduce
it with a method the program forbids. If out of scope or non-qualifying, it is not a submission — full
stop.

### Gate 5 — Impactful

There is real, demonstrable harm to the business or its users — not an inferred or theoretical one.

- Name who is affected (one user, all users, admins) and what an attacker gains (reads PII, takes
  over accounts, moves money, runs code).
- The impact is shown by the PoC, not asserted. "Any user can read any other user's private
  messages" — and the PoC shows message content from account B in account A's session.
- Missing security headers, self-XSS, verbose errors with no exploit, best-practice deviations with
  no demonstrated harm: these usually fail this gate. Log them, do not report them, unless the brief
  says otherwise.
- **Severity self-consistency.** Reconcile the severity you plan to claim with what the PoC actually
  demonstrated, not the worst case you can imagine. If you claim Critical, the PoC must show the
  Critical outcome (code ran, admin taken over, creds pulled) — not a path that "could lead there."
  Rate on the demonstrated outcome and translate via [severity-mapping.md](severity-mapping.md). An
  honest High beats an inflated Critical that triage downgrades and remembers.

Fails if: the only impact you can state is "this is bad practice" or "could potentially lead to," or
your claimed severity outruns what you actually proved.

---

## What a failed gate looks like in the finding doc

When a lead does not pass, the finding doc's status stays `LEAD` and records this, specifically:

```
Status: LEAD
Blocked at: Gate 3 (Exploitable)
What's proven: /api/users/1042/profile returns HTTP 200 with fields for a different account
What's missing: Need a second controlled account (victim) to prove the data returned is actually
                theirs and not a public projection. Register r0-victim@... , populate profile, then
                request its ID from the attacker session.
Next action: Create victim account, re-test, capture both requests.
```

That is the difference between this framework and guesswork. A lead is a to-do with a named blocker,
never a maybe-bug you talk yourself into.

---

## Duplicate check (before you write the report)

Passing the gates means it is real. It does not mean it is *yours* to be paid for. Before drafting:

- Is this the most obvious bug on the most obvious endpoint? Those are found first. Dig for the
  variant others missed (a second endpoint with the same flaw, a harder-to-reach parameter).
- Search the platform's public disclosures / hacktivity for the same class on this target.
- If it is likely a dup, it can still be worth submitting for a fast, well-written report — but set
  your expectation, and prioritize the less obvious findings first.

Being a duplicate does not lower the writing bar. Report it exactly as well; a clean report on a dup
still builds signal.

---

## The honesty rule

If Claude is uncertain, it says which gate is uncertain and what evidence would settle it. It never
dresses a lead up as a finding to be encouraging. An unconfirmed lead reported as confirmed wastes a
submission, risks an N/A on your stats, and burns triager trust. A well-scoped lead with a clear next
action is worth more than a confident guess.
