# Bug Bounty Workspace

A platform-agnostic hunting framework for Bugcrowd, HackerOne, Intigriti, and YesWeHack. It exists to
do three things well: find bugs systematically, prove they are real before reporting them, and write
reports that read like a human wrote them.

## Layout

```
CLAUDE.md                     How the co-pilot operates (read this first)
ENVIRONMENT.md                How to reach VPN / Burp / Burp MCP / tools (gitignored; see .template)
identity.md                   Per-platform handles/emails/headers (gitignored)
framework/
  methodology.md              The hunting loop
  validation-gate.md          Five gates: LEAD -> CONFIRMED (evidence, baseline, traps)
  report-style-guide.md       Writing reports that don't read as AI
  compliance-and-exclusions.md  What not to submit, what not to do
  post-submission.md          Handling triage after you submit
  severity-mapping.md         CVSS across all four platforms
  platforms/                  Per-platform form fields, headers, scope quirks
knowledge-base/
  vulnerabilities/            Per-class test cases (13 classes)
  false-positive-traps.md     Per-class ways a lead looks real but isn't
  payloads/                   Payloads by category
  recon/                      Recon playbook
  tools/                      Toolchain + Burp setup
templates/                    finding, report, handoff, program-setup, recon-checklist
tools/scripts/                recon, activate, new-program, git-push, doctor
programs/                     One folder per program (created on demand)
```

## Start a program

```bash
bash tools/scripts/new-program.sh <platform> <name> <domain>
# e.g. bash tools/scripts/new-program.sh hackerone acme acme.com
```

Then fill `programs/<name>/README.md` from the brief, drop your session tokens into
`programs/<name>/.session.env`, and:

```bash
source tools/scripts/activate.sh <name>     # loads identity + tokens, defines hcurl/ucurl/idor_check
bash   tools/scripts/recon.sh <domain> <name>
```

Or just tell Claude: **"start program: acme on hackerone."**

## The loop

```
READ BRIEF -> RECON -> MAP -> PRIORITIZE -> TEST -> VALIDATE -> REPORT
```

Nothing is called a finding until it passes all five gates in `framework/validation-gate.md`. No
report goes out until it passes the eight-point check in `framework/report-style-guide.md`.

## First-time setup

1. Fill in `identity.md` with your handle, test-account email pattern, and required header for each
   platform you hunt on.
2. `cp ENVIRONMENT.md.template ENVIRONMENT.md` and fill in how you reach the VPN, Burp / Burp MCP, and
   tools. This is what the co-pilot reads on start and after a context compaction so it never has to
   rediscover access.
3. Confirm tool PATH and run `bash tools/scripts/doctor.sh`.
4. Point a remote at this repo if you want history synced, then `bash tools/scripts/git-push.sh`.
