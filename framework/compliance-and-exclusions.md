# Compliance and Exclusions — What Not to Submit, What Not to Do

The purpose of this file: stop wasted submissions before they happen. A finding can be technically
real and still be un-submittable — because the class doesn't qualify, or because of how it was found.
Gate 4 in [validation-gate.md](validation-gate.md) checks against this list.

The baseline below is Bugcrowd's [Standard Disclosure
Terms](https://www.bugcrowd.com/resources/hacker-resources/standard-disclosure-terms/). HackerOne,
Intigriti, and YesWeHack publish closely similar policies. **The program brief always supersedes
this** — if a brief explicitly wants one of these, submit it; if a brief excludes something not
listed here, respect that.

---

## Non-qualifying by default — do not submit without demonstrated impact

These are low-impact by default. Log them if you like, but they are not submissions unless the brief
asks for them **or** you chain them into real impact.

- Missing security headers (CSP, HSTS, X-Frame-Options, etc.) with no working exploit
- Missing cookie flags (HttpOnly, Secure) with no demonstrated theft
- Username / account enumeration via login or forgot-password
- Missing rate limiting / account-lockout, with no proven consequence
- Weak or bypassable CAPTCHA on its own
- Clickjacking with no sensitive action behind it
- CSRF on anonymous forms, or logout CSRF
- Autocomplete / "save password" enabled
- Descriptive error messages / stack traces with no exploit
- HTTP 404 or other non-200 responses treated as a "bug"
- Banner / version disclosure on public services
- Known public files or directories (robots.txt, and similar)
- OPTIONS / TRACE HTTP methods enabled
- SSL/TLS issues: BEAST, BREACH, renegotiation, missing forward secrecy, weak cipher suites
- Lack of a security "speedbump" (interstitial confirmation)
- Functional bugs, UI/UX issues, spelling mistakes

Rule of thumb: if the only impact is "best practice says otherwise," it fails Gate 5 anyway. If you
can chain one of these into a real outcome (clickjacking → a state-changing action; missing lockout →
a demonstrated 2FA brute force), then it is the *chain* you report, with the impact shown.

## Out of bounds — never in scope, regardless of impact

These are excluded by the terms and some are illegal. Do not test them, do not submit them.

- Anything not listed in the program's Targets / in-scope section
- Network-level Denial of Service (DoS / DDoS), load testing, or anything affecting availability
- Social engineering: phishing, vishing, pretexting against staff or users
- Physical attacks: office access, tailgating, device theft
- Accessing, modifying, or deleting **real** users' data or accounts (use your own test accounts)
- Attacks against Bugcrowd/platform infrastructure itself

## Testing conduct — required, or the finding isn't submittable

- Mark all traffic with the program's required identifier header.
- Suspend automated tools immediately if you see performance degradation on the target.
- Create your own test accounts; never use a third party's account.
- One account per researcher; you are responsible for everything done under it.

## Reward eligibility — what actually pays

- You must be the **first** to report a previously unknown issue (duplicates don't pay).
- The issue must trigger a **code or configuration change** — impact the vendor will actually fix.
- Respond to triage questions within **7 days**, or the submission may be closed.
- Monetary rewards require you to meet the platform's age/legal eligibility terms.

## Confidentiality — non-negotiable

- All submissions are confidential to the program owner unless the brief states otherwise.
- The existence and details of private / invite-only programs must not be shared with anyone.
- Keep all communication inside the platform's official channels.
- Never upload PoC files (screenshots, video, data) to public sites — keep them in the report.

---

## The one-line test before you submit

"Is this asset in scope, is this class not on the exclusion list, did I find it with an allowed
method, and did I prove impact that would make them change code?" Four yeses, or it doesn't go.
