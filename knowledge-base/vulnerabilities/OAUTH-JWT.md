# OAuth and JWT Flaws

> Severity: Medium–Critical (many lead to account takeover)
> Scanner-blind: mostly. Common on SSO / "Login with…" flows.
> Translate severity via `framework/severity-mapping.md`.

## OAuth — where to look and what to test

The flow: your app redirects to the provider, the provider redirects back with a `code`, your app
exchanges it for a session. Attacks target the redirect and state handling.

- **redirect_uri validation**: change `redirect_uri` to your domain, a subdomain, a path suffix, an
  open-redirect on an allowed host, or use `//attacker`, `@attacker`, trailing-dot, path traversal.
  If the `code`/token lands on your URL, that's account takeover.
- **Missing `state`**: no `state` parameter (or it's not validated) → CSRF on the OAuth flow (force a
  victim to link your account, or log in as you).
- **Pre-account-takeover**: register the victim's email at the app with a password *before* they
  first use social login; if the app links by email without verification, you keep access.
- **Leaking `code`/token** via Referer to third-party scripts on the redirect page.
- **Scope / provider confusion**: swap the provider, replay a `code` from one client to another.

## JWT — where to look and what to test

- **`alg: none`**: change the header to `{"alg":"none"}`, strip the signature — does the server accept
  it? Confirm it returns protected data, not just a non-crash.
- **alg confusion (RS256 → HS256)**: re-sign the token with the public key as the HMAC secret.
- **Weak HMAC secret**: crack `HS256` with `hashcat`/`jwt_tool` against a wordlist.
- **`kid` injection**: path traversal or SQLi in the `kid` header to control the verifying key.
- **`jku` / `x5u`**: point to an attacker-hosted JWKS if the server fetches keys by URL.
- **No signature verification** at all: tamper a claim (`sub`, `role`, `is_admin`) and see if it's
  honored.
- **Expiry / revocation**: does an old or logged-out token still work? Is `exp` enforced?

## Tools

```
jwt_tool <token> -M at        # run all attacks
jwt_tool <token> -C -d wordlist.txt   # crack HMAC secret
```

## Confirm it's real

For JWT: the tampered token must make the **server** return protected data or act as another user —
client-side acceptance is not enough (`../false-positive-traps.md`). For OAuth: the `code`/token must
actually reach an attacker-controlled destination, or you must complete a takeover.

## Resources

- [PortSwigger — OAuth](https://portswigger.net/web-security/oauth) · [JWT attacks](https://portswigger.net/web-security/jwt)
