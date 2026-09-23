# CSRF — Cross-Site Request Forgery

> Severity: Low–High (depends entirely on the action it forces)
> Scanner-blind: partly. Often non-qualifying unless the action matters — check exclusions first.
> Translate severity via `framework/severity-mapping.md`.

CSRF makes a victim's browser send a state-changing request they didn't intend, using their live
session. It only matters when the forced action has security impact. CSRF on anonymous forms and
logout CSRF are non-qualifying by default (`framework/compliance-and-exclusions.md`).

## Where to look

State-changing requests that rely only on the session cookie:
- Change email / password / 2FA settings (email change → account takeover)
- Add a payment method, transfer funds, change payout details
- Change account role / invite a user / grant access
- Link a social/OAuth account (see `OAUTH-JWT.md`)

## Test cases

- **Is there a token?** Remove the CSRF token / `X-CSRF` header — does the request still succeed?
- **Is the token validated?** Use an empty token, another user's token, a token of the wrong length,
  or swap `POST`→`GET`.
- **SameSite**: is the session cookie `SameSite=None`/absent? `Lax` still allows top-level GET
  navigations — a state-changing GET is exploitable.
- **Content-type**: does the endpoint accept `application/x-www-form-urlencoded` (form-submittable
  cross-site) vs. requiring `application/json` with a custom header (not CSRF-able)?
- **Method override**: `_method=PUT`, or `POST` with an override header.

## PoC skeleton

```html
<form action="https://target.com/account/email" method="POST">
  <input name="email" value="attacker@evil.com">
</form>
<script>document.forms[0].submit()</script>
```

## Confirm it's real

The request must succeed **cross-site with no attacker-readable token**, using only the victim's
cookie, and change something that matters. If a custom header or unreadable token is required, the
browser won't send it cross-site — not exploitable (`../false-positive-traps.md`).

## Report tips

- Lead with the impact of the forced action (email change → takeover), not "CSRF exists."
- Provide the self-submitting HTML PoC and show the account state change.

## Resources

- [PortSwigger — CSRF](https://portswigger.net/web-security/csrf)
