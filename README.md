# huntagent

An AI-assisted, platform-agnostic bug bounty framework for Bugcrowd, HackerOne, Intigriti, and
YesWeHack. It turns an AI coding agent (built for Claude Code, but the method is model-agnostic) into a
structured hunting partner that does three things well: find bugs systematically, prove they are real
before reporting them, and write reports that read like a person wrote them.

huntagent is not a scanner and not a pile of scripts. It is a way of working. The scripts handle the
mechanical parts (recon, request marking, scaffolding), and a set of plain-English playbooks give the
agent a method to follow so its output is disciplined instead of a stream of low-confidence guesses.

## Why it exists

Three problems waste more hunter time than anything else. huntagent is built around fixing each one.

1. **False confirmations.** Calling something a bug on a hunch burns your own hours and the triager's
   trust. Here, nothing is a "finding" until it clears five explicit gates: reproducible, root cause
   understood, working proof of concept, in scope, and real demonstrated impact.
2. **Wasted effort on invalid or duplicate reports.** A bug can be real and still get rejected because
   it is out of scope, non-qualifying under the program's terms, or already reported. huntagent checks
   scope, exclusions, and prior art before you invest time, not after.
3. **Reports that read as machine-generated.** Triagers reject walls of AI slop. The report style guide
   is grounded in the Wikipedia "Signs of AI writing" article and enforces plain, short, reproducible
   writing, with a self-check before anything is submitted.

## How it works

The whole framework is driven by `CLAUDE.md`, the file the agent reads first. It defines the agent's
role (an active hunting partner, not a note-taker), the phase discipline it follows, the operational
rules it never breaks (mark all traffic, read-only proofs, stay in scope), and how it recovers its
place if the conversation is summarized mid-task.

You work one program at a time. Each program lives in its own folder under `programs/`, scaffolded from
templates, holding its scope, its findings, its recon output, and a handoff file that lets any later
session resume instantly.

## The hunting loop

```
READ BRIEF  ->  RECON  ->  MAP  ->  PRIORITIZE  ->  TEST  ->  VALIDATE  ->  REPORT  ->  FOLLOW-UP
```

Each phase has a playbook in `framework/methodology.md`. The two hard rules that gate the end of the
loop:

- Nothing is called a finding until it passes all five gates in `framework/validation-gate.md`.
- No report goes out until it passes the eight-point self-check in `framework/report-style-guide.md`.

## Repository layout

```
CLAUDE.md                       How the agent operates. Read this first.
ENVIRONMENT.md                  Your operational notes: VPN, Burp, tools, quirks (gitignored; see .template).
identity.md                     Your per-platform handles, emails, and required headers (gitignored).
.keys.env                       Recon provider API keys, account-wide (gitignored; see .template).

framework/
  methodology.md                The hunting loop, phase by phase.
  validation-gate.md            The five gates a lead passes to become a finding.
  impact-escalation.md          Chain or widen a bug into higher severity before you report it.
  prior-art-check.md            Avoid duplicates, and aim at fresh surface (new features, changelogs).
  report-style-guide.md         How to write reports that do not read as AI.
  compliance-and-exclusions.md  What not to submit and what not to do (based on disclosure terms).
  post-submission.md            Handling triage after you submit: dupes, needs-info, retests.
  severity-mapping.md           CVSS mapped across all four platforms' rating scales.
  platforms/                    Per-platform submission fields, required headers, and scope quirks.

knowledge-base/
  vulnerabilities/              Per-class test cases across 13 vulnerability classes.
  false-positive-traps.md       Per-class ways a lead can look real but is not.
  payloads/                     Payloads grouped by category.
  recon/                        Manual recon playbook.
  tools/                        Toolchain reference and Burp setup.

templates/                      finding, report, handoff, program-setup, recon-checklist.
examples/                       A worked finding and its report on a fictional target (safe to publish).
tools/scripts/                  recon, activate, new-program, git-push, doctor.
programs/                       One folder per program, created on demand.
```

## Getting started

### Prerequisites

A standard bug bounty toolchain on your PATH: subfinder, amass, httpx, nuclei, ffuf, dirsearch, gf,
waybackurls, plus jq and Python 3. Burp Suite for interception. Run `bash tools/scripts/doctor.sh` at
any point to see what is installed and what is missing.

### First-time setup (once per machine)

1. Copy `identity.md` from your notes or fill it in: your handle, test-account email pattern, and the
   traffic-identifier header each platform requires. This file is gitignored.
2. `cp ENVIRONMENT.md.template ENVIRONMENT.md`, then record anything operational you would otherwise
   have to rediscover: how to reach the VPN, how to launch Burp, tool paths, and any quirk that cost
   you time once. The agent reads this on start and after a context compaction.
3. `cp tools/scripts/.keys.env.template .keys.env`, then add your recon provider keys (Shodan, Censys,
   GitHub, SecurityTrails, and so on). These are account-wide and gitignored. `recon.sh` and
   `activate.sh` load them automatically.
4. Run `bash tools/scripts/doctor.sh` and install anything it reports missing.

### Start a program

```bash
bash tools/scripts/new-program.sh <platform> <name> <domain>
# example:
bash tools/scripts/new-program.sh hackerone acme acme.com
```

This creates `programs/acme/` with a README, a handoff file, a scope allowlist, and the folders for
recon and findings. Next:

1. Fill `programs/acme/README.md` from the program brief: scope, rules, required header, reward table.
2. Copy the scope hosts from the brief into `programs/acme/scope.txt` (the scaffolder seeds it with the
   root domain and its wildcard).
3. Put your session tokens into `programs/acme/.session.env` (gitignored).

### Daily use

```bash
source tools/scripts/activate.sh acme      # loads identity, tokens, and keys; defines helper commands
bash   tools/scripts/recon.sh acme.com acme # runs the recon pipeline into programs/acme/recon/
```

`activate` defines request helpers that carry your identifier header automatically: `hcurl`
(authenticated), `ucurl` (unauthenticated), `jcurl` (authenticated, pretty JSON), `idor_check` (swaps a
victim ID in), and `inscope <url>` (checks a host against `scope.txt` before you touch it).

Or, if you are driving the agent, just say: **"start program: acme on hackerone."**

## What makes a finding

A lead only becomes a reportable finding when all five gates in `framework/validation-gate.md` pass:

1. **Reproducible** on a clean state, with a labeled evidence bundle.
2. **Root cause understood**, not just an odd response.
3. **Exploitable**, with a working proof of concept and the class's false-positive traps ruled out.
4. **In scope and submittable**, tested within the program's rules.
5. **Impactful**, with the harm demonstrated rather than asserted.

Before you settle severity, `framework/impact-escalation.md` shows how to chain or widen a bug so you
report its true worst case (for example, a read-only IDOR that leaks a reset token is account takeover,
not data exposure).

## Reports that do not read as AI

`framework/report-style-guide.md` is the centerpiece of the reporting phase. It lists the words and
patterns that mark writing as machine-generated, bans emoji and decorative formatting, and ends with an
eight-point check you run against every draft. See `examples/EXAMPLE-report.md` for a full report,
drafted from the lab-notebook `examples/EXAMPLE-finding.md`, that passes the check.

## Safety and secrets

Four files hold private data, and all four are gitignored and blocked by `git-push.sh`:

- `identity.md`: who you are on each platform.
- `ENVIRONMENT.md`: how you reach things (VPN, Burp, tools).
- `.keys.env`: your recon provider API keys.
- `programs/*/.session.env`: per-program target auth tokens.

The scripts enforce read-only proofs, marked traffic, and scope checks so a testing session cannot
quietly step outside the rules.

## Publishing and reuse

This framework is built to be shared and is safe to make public. The `examples/` use a fictional target
on purpose: real program findings are confidential under platform disclosure terms (see
`framework/compliance-and-exclusions.md`), so never commit a real program's report, host, or data to a
public repository. Sanitize to an invented target if you want to keep an example of your own.

To reuse on a new machine: clone the repository, copy the four templates listed above into their real
gitignored counterparts, fill them in, and run `bash tools/scripts/doctor.sh`.

## License

MIT. See `LICENSE`.
