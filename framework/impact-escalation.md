# Impact escalation

A bug's payout tracks its demonstrated impact, not its class. The same IDOR pays P4 as "read another
user's display name" and P1 as "full account takeover of any user." This file is how you push a lead
up the severity scale before you report it — by chaining it, widening it, or proving the worse thing it
actually enables.

Do this at Gate 5 (`validation-gate.md`), after the bug is confirmed but before you write the report.
The rule from the report style: demonstrate the escalation, do not speculate about it. "Could allow" is
worth nothing; a second request that proves it is worth the higher band.

## The three moves

**Chain** — one bug feeds another. The first is a stepping stone; the impact is the second bug's.
**Widen** — prove the bug is not one record but all of them, not one user but any user.
**Escalate the primitive** — turn read into write, write into execute, self into any-user.

Always ask: what is the worst thing this actually lets me do, and can I show it with a controlled test
on my own accounts?

## Common chains that lift severity

| Starting bug | Escalates to | How you prove it |
|--------------|-------------|------------------|
| Self-XSS | Stored/reflected XSS on a victim | Find a sink another user renders (support ticket, shared doc, profile viewed by staff); land the payload there |
| IDOR (read) | Account takeover | The object you can read is a reset token, session id, email, or API key — use it to act as the victim |
| IDOR (write) | Privilege escalation | The field you can set includes role, tier, `is_admin`, org membership — set it, show elevated access |
| Open redirect | OAuth/token theft | The redirect sits in an OAuth `redirect_uri` or SSO return — leak the code/token to your host |
| Open redirect | SSRF | The redirect is followed server-side (webhook, link preview, PDF renderer) — point it inward |
| SSRF (DNS/HTTP) | Cloud metadata → creds → RCE | Reach 169.254.169.254 / metadata, pull a role credential, show what it grants (never use it destructively) |
| Info leak (verbose error, .git, source map) | Auth bypass / RCE | The leak reveals a secret, an internal endpoint, or a credential — use it to reach something gated |
| CSRF | State change with impact | The forged action is email/password change or fund transfer, not a cosmetic setting |
| Blind SQLi / SSTI | Data exfil / RCE | Move from boolean/time oracle to reading one non-public row, or a controlled command with output |
| Subdomain takeover | Session/cookie theft, phishing on-brand | Host proof content; if the parent sets cookies on `*.domain`, show cookie capture |
| Low-priv API access | Full tenant compromise | The endpoint leaks or mutates other tenants' data — show cross-tenant with two orgs you own |
| Rate-limit bypass | ATO via brute force / OTP | Bypass leads to guessing a login, OTP, or coupon at scale — show the successful guess |

## Widening a single instance

A one-off often reads as low until you show its reach:

- **One → all.** IDOR on `?id=1002` that returns your own record is nothing. The same call returning
  `?id=1003` (an account you also control, to stay clean) proves the boundary is missing for everyone.
- **One field → the sensitive field.** Reading a victim's display name is P4; the same response
  carrying their email, phone, or token is P2–P1. Look at the whole response, not the field you asked
  for.
- **One role → across roles.** An action allowed for your role that also works with the role parameter
  changed, or with the endpoint called directly, shows broken function-level authorization.
- **One tenant → cross-tenant.** In multi-tenant apps, the jump from "my org" to "another org I also
  registered" is the difference between a bug and a critical.

## Proving escalated impact cleanly

The escalation must stay inside the rules in `compliance-and-exclusions.md`:

- Use accounts and tenants you control for both ends. Never pivot into a real user's data to prove
  reach — a second controlled account proves it just as well.
- For SSRF-to-metadata or leaked-credential chains, prove *access* (the credential returns, the
  metadata responds) and stop. Do not use the credential to touch real infrastructure; describe what it
  would grant.
- Minimum evidence. One extra request that demonstrates the worse impact, captured as a labeled
  request/response pair per the evidence-bundle spec in `validation-gate.md`.
- If you cannot demonstrate the escalation, report the impact you *can* prove and note the plausible
  escalation as a follow-up — do not rate the finding as if you proved it.

## Reporting a chain

Write it as one finding built from steps, not several thin reports:

- Title names the end impact: "Chained open redirect and OAuth misconfiguration allows account
  takeover," not "Open redirect in /go."
- Steps to reproduce walk the whole chain in order, each step's output feeding the next.
- Severity is rated on the final impact; the stepping-stone bugs are the path, and you say so.
- If a stepping stone is independently reportable and the program pays per-bug, note it, but lead with
  the chain — it is the story that earns the higher band.

See a chain written up end to end in `examples/EXAMPLE-report.md`.
