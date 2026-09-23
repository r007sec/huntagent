# After You Submit

The report going in is not the end. How you handle triage decides whether a valid bug gets paid, gets
downgraded, or gets closed. Same principles as the report: plain, factual, fast.

## The clock

Most platforms will close a submission if you go quiet on a triager's question — Bugcrowd's terms say
**7 days**. Check your open submissions regularly. A fast, specific answer keeps momentum and signals
you are a serious researcher.

## Triage states and how to respond

**Needs more info / more evidence.** The triager could not reproduce or wants clarification. Do not
argue — give them exactly what they asked for: a cleaner request, the missing account ID, a short
video, or the one step you left implicit. Reproduce it yourself again first; if *you* can't, say so
and revise.

**Not reproducible.** Usually an environment or step gap. Re-test from a clean state (new account,
fresh session), then reply with the exact, complete sequence and the request/response pair. Name any
precondition you assumed (a populated victim account, a specific role).

**Duplicate.** It happens on obvious bugs. Ask politely whether the original covers the *same
endpoint and impact* — sometimes your variant (a different endpoint, a higher impact) is distinct and
should be split out. If it is a true dup, accept it and move on; disputing genuine dups burns
goodwill.

**Informative / N/A / out of scope.** Check it against `compliance-and-exclusions.md` and the brief
before you respond. If they are right, note the lesson and drop it. If you believe impact was missed,
make the impact case once, concretely — show the concrete harm you can demonstrate, not an assertion
that it "could" be worse.

**Severity disagreement.** Present your CVSS vector with each metric justified in a word, and the
demonstrated impact. Ask for the specific metric they see differently. One well-reasoned round, not a
back-and-forth. If they hold, accept it — an accepted lower severity beats a contested higher one.

**Accepted / triaged.** Good. Stay reachable for questions until it is resolved and paid.

## Escalation and mediation

If a submission stalls or you disagree after a reasonable exchange, use the platform's mediation path
(Bugcrowd and HackerOne both have one) rather than pushing repeatedly in the thread. State facts and
the timeline; stay professional. The security team and the triager are not the same people — assume
good faith.

## Retesting the fix

When asked to verify a fix (or before requesting disclosure), retest the exact PoC. Confirm the fix
actually closes it and doesn't just block your one payload — try the obvious variants. Report the
result plainly: fixed, or still exploitable with this variant.

## How to write triage replies

Same style guide as the report (`report-style-guide.md`):

- Answer the specific question first, in one or two sentences.
- No filler openers ("Thank you for your response! I completely understand..."), no defensiveness.
- Paste the exact request/step, not a paraphrase.
- No emoji, no inflated language, no lecturing about severity.

Good: "Reproduced on a fresh account just now. Full sequence and the request/response pair below —
step 3 was the one I'd left implicit."

Bad: "I truly appreciate your diligent review! I firmly believe this critical issue underscores a
significant risk and should absolutely be reconsidered for a higher severity rating."

## Close the loop internally

Update the finding doc and the program `HANDOFF.md` with the outcome (status, reward, triage notes,
and the lesson). Over time this record is how you learn which programs, classes, and framings pay.
