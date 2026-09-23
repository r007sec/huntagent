# Cross-Site Scripting (XSS)

> Severity: Low–High (self-XSS is near-zero; stored XSS stealing sessions is High)
> Scanner-blind: partly — reflected is scanner-heavy and dup-heavy; stored/context-specific is manual.
> Translate severity via `framework/severity-mapping.md`.

Impact is everything with XSS. A reflected `alert()` on a page nobody visits is worth little; stored
XSS that runs in an admin's session is an account takeover. Chase impact, not the popup.

## Types and where they live

- **Stored** — input saved and rendered to other users: profile fields, comments, messages,
  filenames, support tickets, admin dashboards (XSS that fires for staff is gold).
- **Reflected** — input echoed in the immediate response: search, error messages, URL params.
- **DOM** — client-side sink: `innerHTML`, `document.write`, `eval`, `location`, framework bindings.
- **Blind** — fires elsewhere later (admin panel, logs); confirm with an out-of-band callback.

## Test cases

- Find reflection first with a harmless marker (`bugbounty1337`), then see the **context**: HTML body,
  attribute, `<script>`, URL, JS string. The context decides the payload.
- Break out of the context: `"><svg onload=alert(1)>`, `'-alert(1)-'`, `</script><svg...>`,
  `javascript:` in `href`.
- Attribute context: `" autofocus onfocus=alert(1) x="`.
- DOM: trace the source (`location.hash`, `postMessage`) to the sink in the JS.
- Filter bypass: case, encoding, no-parentheses (`onerror=alert\`1\``), alternative tags/events,
  double encoding, mutation XSS.
- Blind XSS: inject a callback payload (e.g. an XSS Hunter–style beacon) into fields staff will view.

## Confirm it's real

Actual **execution in a real browser**, in an origin that matters, delivered to a **different user**
(for stored). A string in the DOM inspector, a payload in a JSON/`text/plain` response, or self-XSS
only is not a finding — see `../false-positive-traps.md`.

## Report tips

- Show the payload firing and name who it fires for (any user / admins).
- For stored XSS, demonstrate the real impact: session/cookie theft, an action taken as the victim,
  or admin-panel execution — not just `alert(1)`.
- Keep the PoC benign (`alert(document.domain)` or a callback); do not exfiltrate real user data.

## Resources

- [PortSwigger — XSS](https://portswigger.net/web-security/cross-site-scripting) · [contexts & cheat sheet](https://portswigger.net/web-security/cross-site-scripting/cheat-sheet)
