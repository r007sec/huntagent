# Prior-art check

Duplicates are the most common way hours get wasted and the most common reject after triage. Run this
before you sink real time into a lead (early, during Prioritize) and again before you submit (as part
of Gate 4). It answers one question: has this already been found, fixed, or publicly documented?

A duplicate is not a failure of skill — it means someone got there first. The goal is to find that out
in ten minutes, not after a day of work or after a triager tells you.

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
