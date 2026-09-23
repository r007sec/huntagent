# Prior-art check and program intelligence

A program's public signals — disclosed reports, changelog, release notes, new features, scope changes
— answer two questions at once. Read defensively: *has this already been found?* (avoid duplicates).
Read offensively: *where is the fresh, under-tested surface?* (aim your time). Same sources, both jobs.
Do this early (Prioritize) and again before you submit (Gate 4).

Duplicates are the most common way hours get wasted and the most common reject after triage. A dup is
not a failure of skill — someone got there first. The goal is to find that out in ten minutes, not
after a day of work. But the higher-value habit is the offensive one below: hunt where others haven't
looked yet.

## Aim at the fresh surface — hunt what just shipped

This is the offensive read, and it's where the undiscovered bugs are. New code has had the fewest
testers, scanners aren't tuned to it, and nobody has reported against it yet — the best ratio of bugs
found to time spent. When a program ships something, test it first.

Where new surface shows up:

- **Product announcements / changelog / release notes / "What's new".** A new feature, a new API
  version, a rewritten flow — go straight at it while it's fresh.
- **Blog posts, status page, and social.** Companies announce launches, integrations, and acquisitions.
  A new integration or a just-acquired product folded into scope is raw surface.
- **Scope expansions in the brief.** A newly added asset or domain is a land grab — few people have
  looked at it yet. Watch the program's scope-change history.
- **New endpoints and subdomains you can see yourself.** Diff recon over time: re-run and compare
  `recon/subdomains-all.txt` and the JS/wayback endpoint lists against the last run. A new subdomain, a
  new `/v3/` route, or a new parameter appearing in JS is a signal nobody handed you.
- **Beta / feature-flag / staging surfaces** that the brief allows — often the new feature before it's
  hardened.

Then use disclosed reports as a map of the program's weak spots:

- **Recurring classes.** If the program has paid several IDORs or several SSRFs, the codebase and team
  have a pattern — look for the *next* instance of that class on a different endpoint, not the exact one
  already fixed.
- **What's already taken.** The specific endpoints in disclosed reports are spent; the technique behind
  them usually isn't. Reapply the idea to surface the report didn't cover.
- **Response and payout behavior.** Disclosures tell you how the program rates, how fast it triages, and
  what it tends to reward — useful for deciding where to invest.

Feed the winners of this read into Phase 4 prioritization: new feature first, then the recurring weak
class on surface no one has reported.

## Before investing time in a lead

- **Program's own disclosure list.** On HackerOne, read the program's disclosed reports and
  hacktivity. On Bugcrowd, check the program's public activity if any. A bug matching a disclosed one
  is a likely dup.
- **Changelog and release notes.** A recent "fixed a security issue in X" or a version bump around the
  feature you're testing often means the bug you see is a regression, already-known, or out of date.
- **The program brief's known-issues / out-of-scope.** Many briefs list already-reported classes or
  accepted risks. Re-read it — the answer is sometimes written down.
- **Public CVEs and advisories** for the exact product/version if it's off-the-shelf (the fingerprint
  from recon tells you the stack). A known CVE on a third-party component may be N/A or a dup depending
  on the brief.

## Before submitting

- **Search your own program folder.** Grep `findings/` and `HANDOFF.md` dead-ends — you or a past
  session may have already logged this endpoint as tried.
- **Re-read the brief's exclusions** one more time (`compliance-and-exclusions.md`) — a bug can be real
  and still non-qualifying.
- **Timing.** If the target just shipped a fix or the endpoint changed under you mid-test, confirm your
  repro still holds on the current state before you send it.

## What to do when it looks like a dup

- **Likely dup, but you have more impact.** If a disclosed report stops at a lower severity and you can
  demonstrate the escalation (`impact-escalation.md`), the report can still be worth filing — lead with
  the impact the prior report did not show, and reference that yours goes further.
- **Same bug, nothing extra.** Skip it. Log it in `HANDOFF.md` dead-ends with a link to the prior art
  so no future session re-chases it.
- **Uncertain.** Programs generally reward the first valid report and mark later ones duplicate — being
  early matters more than being certain. If the bug is real, in scope, and you cannot confirm it's
  known, submit; a duplicate verdict costs you nothing but time, an unreported real bug costs the bounty.

One line for the pre-submit check: *I searched the program's disclosures, changelog, and my own notes;
this is either not previously reported or I add impact the prior report did not show.*
