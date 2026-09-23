# Bug Bounty Workspace

A platform-agnostic hunting framework for Bugcrowd, HackerOne, Intigriti, and YesWeHack. It exists to
do three things well: find bugs systematically, prove they are real before reporting them, and write
reports that read like a human wrote them.

## Layout

```
CLAUDE.md                     How the co-pilot operates (read this first)
identity.md                   Per-platform handles/emails/headers (gitignored)
framework/
  methodology.md              The hunting loop
  validation-gate.md          Five gates: LEAD -> CONFIRMED
  report-style-guide.md       Writing reports that don't read as AI
  severity-mapping.md         CVSS across all four platforms
  platforms/                  Per-platform form fields, headers, scope quirks
knowledge-base/
  vulnerabilities/            Per-class test cases
  payloads/                   Payloads by category
  recon/                      Recon playbook
templates/                    finding, report, handoff, program-setup, recon-checklist
tools/scripts/                recon, activate, new-program, git-push
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
2. Confirm tool PATH (see `knowledge-base/recon/recon-playbook.md`).
3. Point a remote at this repo if you want history synced, then `bash tools/scripts/git-push.sh`.
