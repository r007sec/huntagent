# Business Logic Flaws

> Severity: Medium–Critical (depends on what the logic guards)
> Scanner-blind: fully — no tool finds these; they are pure manual reasoning. High dedup resistance.
> Translate severity via `framework/severity-mapping.md`.

Logic bugs come from the app doing exactly what it was coded to do, where the code assumed something
the attacker won't respect. There is no payload — the exploit is a sequence of legitimate requests in
an order or with values the developer didn't expect.

## Where to look

Anywhere state changes across steps or where a value is trusted from the client:
- Checkout / payment / pricing / discounts / refunds
- Quotas, limits, credits, points, invites, trial periods
- Multi-step flows (registration, KYC, onboarding, wizards)
- Approval / role / ownership transitions
- Anything with a "status" field (order, subscription, ticket)

## Test cases

- **Parameter tampering on trusted values**: change `price`, `amount`, `quantity` (to negative,
  zero, decimals), `currency`, `role`, `is_admin`, `user_id`, `status` in the request body.
- **Skip a step**: jump straight to the final endpoint of a multi-step flow without completing the
  prerequisites (payment confirmation, verification, approval).
- **Replay / reuse**: reuse a one-time coupon, gift card, invite, or signed token more than once.
- **Order of operations**: apply a discount after tax, cancel then use, refund then keep.
- **Negative / boundary values**: quantity `-1` to credit yourself; huge values to overflow limits.
- **Currency / rounding**: pay in a weaker currency, exploit rounding on tiny amounts.
- **Ownership assumptions**: perform an action on a resource mid-workflow that you no longer own.
- **Concurrency** (see `RACE-CONDITIONS.md`): do the "once only" action many times at once.

## Confirm it's real

Prove the **end state is genuinely impossible** under the intended rules: the balance is wrong, the
item shipped without payment, the limit was exceeded, the trial extended. See the race-condition and
IDOR entries in `../false-positive-traps.md`.

## Report tips

- Spell out the intended flow, then the exact deviation — triagers may not know the business rule.
- Quantify: "bought a $149 item for $0.01," "extended a 14-day trial indefinitely."
- A short screen recording is worth more here than anywhere else.

## Resources

- [OWASP WSTG — Business Logic Testing](https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/10-Business_Logic_Testing/)
