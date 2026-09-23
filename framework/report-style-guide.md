# Report Style Guide — Write Like a Human

The goal of a report is one thing: a triager reads it once and reproduces the bug without asking a
question. Everything here serves that. A report that reads like it came out of a chatbot gets
skimmed, doubted, and sometimes closed as "AI-generated noise." Triagers now reject on that basis.
So the writing has to disappear and leave only the facts.

This guide is derived from Wikipedia's [Signs of AI
writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing). Every rule below maps to a
tell listed there. When Claude drafts a report, it self-checks against the "Kill list" and the
"Before submit" checklist at the bottom.

---

## The one principle

State what is true, in the fewest words, in the order a reader needs it. If a sentence does not help
someone reproduce the bug, judge its severity, or fix it — cut it.

A good report sentence looks like: "The endpoint returns another user's records because it never
checks ownership." A bad one looks like: "This finding underscores a critical vulnerability that
highlights the importance of robust access control mechanisms."

---

## Kill list — words and phrases that mark AI writing

Do not use these. They are the exact terms the Wikipedia article flags as AI tells. None of them
carry information a triager needs.

**Inflated vocabulary (delete or replace with a plain word):**
delve, underscore, highlight (as a verb meaning "show"), showcase, boasts, robust, crucial, pivotal,
vital, key (as filler: "a key issue"), essential, seamless, comprehensive, intricate, nuanced,
meticulous, leverage (use "use"), utilize (use "use"), facilitate (use "let" / "allow"), foster,
garner, bolster, enhance, testament, tapestry, landscape (as metaphor), realm, vibrant, rich,
profound, notably, importantly, it is worth noting, it is important to note.

**Significance padding (delete the whole clause):**
"serves as a testament to," "plays a crucial/pivotal/vital role," "underscores the importance of,"
"highlights the need for," "reflects a broader," "in today's digital landscape," "in an
ever-evolving threat landscape," "setting the stage for," "paving the way for."

**Vague attribution (name the source or delete):**
"industry best practices," "experts agree," "it is widely known," "studies show" (which study?),
"observers have noted," "security researchers recommend" (which recommendation, from where?).

**Filler transitions (start the sentence with the fact instead):**
"Additionally," "Moreover," "Furthermore," "It is important to note that," "That being said,"
"When it comes to," "In terms of," "Overall."

**Hedge-and-puff closers (delete):**
"By addressing this issue, the organization can strengthen its security posture and protect its
users." Triagers know why fixing a bug is good. Do not lecture them.

---

## Sentence structure — the patterns to avoid

The article names these constructions specifically. They read as machine cadence.

- **The rule of three.** "The bug is simple, dangerous, and easy to exploit." Three-item lists
  appearing everywhere is a tell. Use the number of items the fact requires — often one or two.
- **Negative parallelism.** "This is not just an information leak, but a full account takeover." /
  "It's not X, it's Y." Say what it is: "This leak exposes the session token, which allows account
  takeover."
- **Participle tails.** Sentences ending in "-ing" clauses that restate the point: "...returning the
  data, exposing sensitive records, undermining user trust." Stop at the fact.
- **Copula avoidance.** Do not replace "is" with "serves as," "functions as," "represents,"
  "stands as." The endpoint *is* vulnerable; it does not "serve as a vector that represents."
- **Marketing verbs for plain facts.** "The API offers three endpoints" → "The API has three
  endpoints." "The app features a login" → "The app has a login."

---

## Formatting — the tells to avoid

The article flags formatting habits as strongly as wording. Bug reports need *some* structure
(reproduction steps are a list for a reason), so the rule is: structure that a human would use,
nothing decorative.

- **No emoji.** Not in headings, not as bullets, not as severity markers. Use words: "Critical,"
  not "🔴". (This is why this framework's templates dropped the 🎯/💰/🔴 headers the old ones had.)
- **Bold for genuine emphasis only** — a variable name, a one-word severity, the single line that
  matters. A paragraph with five bold phrases has none.
- **No title case on headings.** "Steps to reproduce," not "Steps To Reproduce."
- **No horizontal rules between every section** in the submitted text. They are a layout crutch.
- **Lists for genuinely enumerable things** (steps, affected endpoints, accounts used). Prose for
  reasoning and impact. Do not turn a two-sentence thought into a five-bullet list.
- **No "Summary of the summary."** Do not open a section by restating the heading ("In this impact
  section, we will discuss the impact...").

---

## Tone

Neutral and factual, the way you would write to an engineer who will fix the bug, because that is
who reads it. Not promotional, not dramatic, not apologetic.

- Do not sell the severity. Show the impact and let it speak. "An attacker reads any user's messages"
  is more alarming than "this catastrophic flaw poses an existential risk to user privacy."
- Do not hedge to sound humble ("this might possibly be a potential issue"). If it is confirmed, say
  it plainly. If it is not confirmed, it is not in the report yet — see
  [validation-gate.md](validation-gate.md).
- Write in the past or present tense of what you did and observed: "I sent," "the server returned."
  First person for your actions is fine and clearer than passive "a request was sent."

---

## Rewrite examples

Each pair: the AI-slop version, then the human version.

**Summary**

> Slop: This report delves into a critical Insecure Direct Object Reference vulnerability that
> underscores a significant lapse in the application's robust access control mechanisms, potentially
> allowing malicious actors to leverage this flaw.

> Human: The `GET /api/v1/users/{id}/orders` endpoint does not check that the caller owns the
> requested `id`. Any logged-in user can read any other user's orders by changing the number.

**Impact**

> Slop: This vulnerability poses a profound risk to the confidentiality of user data and could have
> far-reaching implications, undermining user trust and potentially exposing the organization to
> regulatory scrutiny in today's evolving privacy landscape.

> Human: Every user's order history is readable by any other user. Orders include full name,
> shipping address, and items purchased — PII for the platform's entire customer base. One
> authenticated account is enough; no special role is needed.

**Remediation**

> Slop: It is highly recommended that the organization implement robust, industry-standard access
> control mechanisms to mitigate this critical vulnerability and bolster its overall security posture.

> Human: Check ownership before returning the record: reject the request when the session user's ID
> does not match the resource owner. Apply the check to every `/users/{id}/*` route, not just this one.

---

## Before you submit — self-check

Run this against the drafted report. If any answer is "yes," fix it.

1. Does any sentence use a word from the Kill list?
2. Could a triager reproduce the bug from the steps alone, with no account IDs or tokens missing?
3. Is there a three-item list that should be one or two?
4. Is there a "not just X but Y" sentence?
5. Is there bold text that is not a variable, a severity, or the single key line?
6. Is there an emoji anywhere?
7. Does any paragraph explain why security matters in general, instead of what this bug does?
8. Read it aloud. Does it sound like a person telling a colleague what they found, or like a press
   release? If press release, rewrite.

A report that passes all eight is short, plain, and reproducible. That is the target.
