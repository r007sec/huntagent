# False-Positive Traps — Rule These Out Before You Confirm

Every class has ways to look real without being real. Generic reproduction passes them; a triager
does not. Walk the traps for your class (Gate 3 in `../framework/validation-gate.md`) before changing
a lead to CONFIRMED. The fix for almost all of these is the same: **establish the baseline first** —
prove the control works, then break it, and keep both request/response pairs.

## IDOR / broken access control

- The "victim" object is actually **public** or shared by design — check whether an anonymous or
  unrelated user can already see it. If yes, it's not an access-control bug.
- The ID is a **UUID/GUID you got from your own account** — you're reading your own object, not
  someone else's. Use a genuinely separate victim account and confirm the data is theirs.
- **200 OK with an empty or redacted body** — the endpoint accepted the ID but returned nothing
  sensitive. Read the body, not the status code.
- The object is returned but **filtered to non-sensitive fields** (a public projection). Confirm the
  fields actually matter.
- You're still authenticated as the owner in another tab / the token still maps to the owner. Test
  cross-account with the attacker's token only.

## SSRF

- You got a **DNS lookup but no HTTP hit** — a resolver or preview crawler resolved your hostname; the
  target never fetched it. Confirm a full HTTP request arrived at your listener (Burp Collaborator /
  interactsh shows the HTTP interaction, not just DNS).
- The request came from a **third party** (a link-unfurler, a CDN, a headless preview bot), not the
  target's server. Check the source IP / user-agent of the callback.
- The app fetched your URL **client-side** (in the browser), which is not SSRF.
- You reached an external URL but **cannot reach anything internal** — that may be a benign URL
  fetch, not exploitable SSRF. Confirm (safely) that an internal/metadata target responds differently.

## XSS

- **Self-XSS**: the payload only fires in your own input in your own session, with no way to deliver
  it to another user. Not a finding on its own.
- It rendered in the **DOM inspector** but never executed — you saw the string in the elements panel,
  not an actual `alert()` / callback firing in a real browser.
- Reflected in a response with `Content-Type: application/json` or `text/plain` — browsers won't
  execute it there. Confirm it lands in an HTML context that renders.
- The value is **sanitized on output** even though it's stored raw — check what the victim's browser
  actually receives, not what the database holds.
- It only works in a browser/config no real user has (disabled protections, a dead browser).

## SQL injection

- A single quote returns a 500 — that's an **error, not proven injection**. Confirm with a
  boolean-based true/false pair or a controlled time delay that tracks your input.
- The "delay" was **network jitter**, not your `SLEEP()`. Repeat; vary the sleep value and confirm the
  response time tracks it.
- A WAF returned a generic error that looks like a DB error but isn't.

## Auth bypass / account takeover

- You tested with your **own still-valid session/cookie** — of course it worked. Use a fresh,
  unauthenticated context.
- The reset/OTP token you "reused" was still within its valid window for your own account — confirm
  it works **across accounts** or after it should have expired.
- "alg:none" or a tampered JWT was accepted by your **client** but **rejected server-side** — confirm
  the server acts on it (returns protected data), not just that the app didn't crash.

## CSRF

- The action is behind a token you **also control/can read** same-origin — that's not cross-site.
- The endpoint requires a custom header the browser won't send cross-site (effectively CSRF-protected).
- The "action" has no security impact (logout, anonymous form) — non-qualifying by default.

## Open redirect

- It redirects to your URL but the app is a **known redirector by design** and in scope exclusions.
- It's only a redirect with **no chained impact** (no token/credential leak, no OAuth abuse) — usually
  low or non-qualifying alone.

## Race conditions

- You saw two "successes" but the **end state is correct** (idempotent) — no actual double-effect.
  Confirm the resource (balance, coupon count, invite) is genuinely in an impossible state afterward.
- The parallelism was your client's retmit, not a server-side race — confirm the duplicated effect
  persists.

## The universal check

For any class: **did the server do the thing, and is the actor genuinely an unprivileged attacker?**
If you can't answer both from a request/response pair, it stays a LEAD.
