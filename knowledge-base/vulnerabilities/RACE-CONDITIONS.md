# Race Conditions

> Severity: Medium–Critical (limit bypass to financial impact)
> Scanner-blind: fully. Undertested, so lower dedup risk on the right target.
> Translate severity via `framework/severity-mapping.md`.

A race condition exists when an app checks a condition and then acts on it in two steps, and you slip
extra requests into the gap. The classic outcome: do a "once only" action several times before the
first one finishes updating state.

## Where to look

Anywhere a limit or uniqueness is enforced:
- Redeem coupon / gift card / promo (redeem N times)
- Withdraw / transfer funds (spend the same balance twice)
- Apply votes, likes, follows, ratings past the cap
- Accept invite / claim a one-time reward
- 2FA/OTP submission (defeat rate limiting via parallelism)
- Account or username registration (uniqueness bypass)

## Test cases

- **Single-packet / parallel send**: fire 20–50 identical requests as simultaneously as possible.
  Burp Repeater "Send group in parallel" (single-packet attack) or Turbo Intruder.
- Target the exact endpoint that mutates state (the redeem/withdraw call), not the page around it.
- Vary concurrency (10, 50, 100) — the sweet spot is server-dependent.
- Combine with a limit that "should" allow one: one coupon, one withdrawal, one vote.

## Turbo Intruder starting point

```python
def queueRequests(target, wordlists):
    engine = RequestEngine(endpoint=target.endpoint, concurrentConnections=30, engine=Engine.BURP2)
    for i in range(30):
        engine.queue(target.req, gate='race1')
    engine.openGate('race1')

def handleResponse(req, interesting):
    table.add(req)
```

## Confirm it's real

The intended limit must be **provably exceeded and persisted**: coupon applied twice on the final
invoice, balance went negative, two accounts got the same unique handle. An idempotent double-success
that ends in a correct state is not a finding — see `../false-positive-traps.md`.

## Report tips

- Show the before/after state (balance, count) and the burst of parallel responses that caused it.
- State the concrete gain: "$500 balance withdrawn as $1,500 across three parallel requests."

## Resources

- [PortSwigger — Race conditions](https://portswigger.net/web-security/race-conditions)
