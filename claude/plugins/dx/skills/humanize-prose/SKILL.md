---
name: humanize-prose
description: >-
  Strip AI tells from an existing draft so technical prose reads as
  human-written. Covers em-dashes and smart quotes, filler intensifiers,
  corporate-register verbs, AI vocabulary, hedging qualifiers, nominalization,
  stacked noun phrases, copula avoidance, participial tack-ons, antithesis and
  corrective negation, negative anaphora, tailing negations, the rule of three,
  setup/payoff, rhetorical crutches, throat-clearing openers, aphorism formulas,
  landing sentences, paragraph pinning, parataxis, sentence-length variation,
  diff-anchored framing, spoken voice, and performed enthusiasm. Also cuts
  volume, which is the real failure: over-length passages, bullet walls,
  significance-claiming, hedged emphasis, and performative contrition. Ships a
  metric script for the mechanically detectable tells, including sentence-length
  and bullet-density distributions, and a false-positive guard so real human
  prose does not get over-edited. Edits prose only; it does not restructure
  content (use architecture-ledger) or fact-check claims (use doc-claim-review).
when_to_use: >-
  Use on an existing draft that was AI-written or AI-assisted and is about to
  reach a person: a design doc, PR body, Notion page, ticket, review, or chat
  post. Invoke as /humanize-prose, or as the prose pass inside a doc-shaping
  workflow (architecture-ledger delegates to it). Do not use to write prose from
  scratch, to reorder or cut sections, or to check whether a claim is true.
allowed-tools: >-
  Read, Edit, Write,
  Bash(ruby ${CLAUDE_SKILL_DIR}/scripts/ai_tells_metric.rb *),
  Bash(ruby ${CLAUDE_SKILL_DIR}/scripts/test_ai_tells_metric.rb)
---

# Humanize Prose

## Why this exists

AI-assisted writing fatigues human readers with synthesis patterns: em-dashes everywhere, everything in threes, abstract nouns doing the work of verbs, rhetorical shapes that promise a payoff and deliver a restatement. This is the one genre-agnostic pass that removes those tells from an existing draft, with a measurable check so "reads human" is verified rather than asserted. It is the prose layer shared across the doc-craft family. A genre shaper (like `architecture-ledger`) handles structure, `doc-claim-review` handles grounding, this handles voice and cadence.

Most of what follows describes prose a language model produces by default. Expect the rules to feel wrong to follow. That is why they are written down instead of left to taste.

## When to use

- A draft (doc, PR body, Notion page, Slack post) was AI-drafted or AI-assisted and needs to read human before it goes to people.
- Invoked as the prose pass within a larger doc workflow (e.g. step in `architecture-ledger`).

When NOT to use:
- The content structure is wrong (sections in the wrong order, missing a problem statement): that is a genre shaper's job.
- A claim might be unsourced or a decision unattributed: that is `doc-claim-review`.
- Writing from scratch: this edits existing prose, it does not generate it.
- **Conversational surfaces**: a chat post, a console reply, a mailbox report, a turn in a live exchange. The reference numbers below were measured on documents, and the rhetorical-shape rules assume a reader who will re-read. On those surfaces the `Keeper voice` output style governs instead, and its contrasting pairs ("momentum, not mania") are character rather than tells. One authority per surface; do not run both and split the difference.

## The pass

Five groups, in this order. Mechanical strips first because they are fast and unambiguous. Rhetorical shape second because it needs judgment and because the shapes are easier to see once the noise is gone. Cadence third because you can only hear rhythm after the words settle. Volume fourth, once you can see which sentences are carrying weight. Register last, as the read-aloud check on everything above.

### 1. Mechanical strips

- **No em-dashes (`—`), en-dashes (`–`), or smart quotes (`" " ' '`).** Replace an em-dash with a comma, a period, parens, or "and" depending on rhythm. Do not blindly comma-replace; read each one. Watch for the ASCII stand-ins people reach for once the real character is banned: a spaced double hyphen (` -- `) and a spaced single hyphen (` - `) do the same job and read the same way.

- **No AI vocabulary.** A specific set of adjectives and abstract nouns spiked in post-2023 text and now function as a signature: `crucial`, `pivotal`, `seamless`, `robust`, `nuanced`, `holistic`, `intricate`, `vibrant`, `testament`, `interplay`, `tapestry`, `landscape` and `realm` used abstractly. The fix is a plainer word or no word.
  - Before: "This is a crucial step toward a more seamless developer experience."
  - After: "This removes two manual steps from the setup."

- **No copula avoidance.** An elaborate construction standing in for plain "is": `serves as`, `stands as`, `acts as`, `represents a`, `marks a`, `boasts`, `offers a`. Say "is" or "has".
  - Before: "The script serves as a measuring tape and boasts a sentence-length histogram."
  - After: "The script is a measuring tape. It reports a sentence-length histogram."

- **No filler intensifiers.** `genuinely`, `really`, `truly`, `actually`, `incredibly`, `remarkably`, `fundamentally`. They ask for emphasis the sentence has not earned.
  - Before: "This is genuinely the last gate on everything we publish."
  - After: "This is the last gate on everything we publish."

- **No corporate-register verbs.** `leverage`, `underscore`, `reflect`, `utilize`, `facilitate`, `unlock`, `foster`. Each has a plainer verb hiding behind it.
  - Before: "The incident underscores the need to leverage our existing retry logic."
  - After: "The incident shows we should have used the retry logic we already have."

- **No hedging qualifiers.** `arguably`, `somewhat`, `relatively`, `largely`, `generally`, `tends to`, `seems to`. If the claim needs a caveat, state the caveat. If it does not, drop the hedge and own the sentence.
  - Before: "This arguably tends to somewhat improve throughput."
  - After: "This improves throughput by about 15% on the staging box. We have not measured production."

- **No nominalization.** A verb turned into a noun drags an empty verb along with it, and it hides who acted. This absorbs the older "abstract-noun `the X`" rule: `the cost`, `the value`, `the question` are the same problem.
  - Before: "The implementation of the migration resulted in a reduction in latency."
  - After: "We migrated it and latency dropped."
  - Before: "There is a question of ownership."
  - After: "Nobody owns it."

- **No stacked noun phrases.** Three or more nouns modifying each other force the reader to parse before they can read. Break the pile with a preposition or a verb.
  - Before: "the customer onboarding flow latency budget regression"
  - After: "onboarding got slower than the budget allows"

- **No participial tack-ons.** A present participle bolted onto the end of a clause to add depth the sentence does not have: `, underscoring...`, `, highlighting...`, `, reflecting...`, `, ensuring...`, `, demonstrating...`. Cut the clause. If it carries a real claim, make it its own sentence.
  - Before: "The cache never refreshed, underscoring the need for a version bump."
  - After: "The cache never refreshed. A version bump would have caught it."

### 2. Rhetorical shape

- **No antithesis.** The move is defining a thing by what it is not. For the first two variants the fix is to cut the negative half and state the positive claim alone.
  - Corrective negation. Before: "This isn't a style preference. It's a correctness problem." After: "This is a correctness problem."
  - Not-X-but-Y. Before: "The failure was not the retry logic but the timeout." After: "The timeout caused the failure."
  - Contrasting pair, which needs a judgment call. Cut it when the contrast is there for cadence. Before: "We need discipline, not enthusiasm." After: "We need discipline." Keep it when the negative half names the thing a reader would otherwise assume: "S2-1 Pro is text-to-speech, not speech-to-text" stops doing its job the moment you cut the second half. See the guard below.

- **No negative parallelism or negative anaphora.** Consecutive sentences or clauses opening on the same negation. It reads as chanting.
  - Before: "No tests. No docs. No owner. Just a merged PR."
  - After: "The PR merged with no tests, no docs, and nobody named as owner."
  - (One negation, one sentence. The list belongs inside it.)

- **No tailing negations.** The clipped cousin of the above: a negation stapled to the end of a sentence as a closer instead of written out as a clause. "..., no guessing." "..., no wasted motion."
  - Before: "The options come from the selected item, no guessing."
  - After: "The options come from the selected item, so the user never has to guess."

- **No rule of three.** "X, Y, and Z" everywhere is the loudest tell in the set, because a real observation rarely has exactly three parts. Cut to the two that matter, or expand to four, or make it one sentence with a subordinate clause.
  - Before: "The script is fast, cheap, and easy to run."
  - After: "The script is fast and cheap to run."

- **No setup/payoff constructions.** Building a small suspense so the next sentence can resolve it. Delete the setup and keep the payoff.
  - Before: "There was one problem with all of this. The cache never refreshed."
  - After: "The cache never refreshed."

- **No rhetorical crutches.** Three shapes, one fix, which is to state the claim without the ceremony.
  - A question asked so you can answer it. Before: "So what does that mean for the release? It means we slip a week." After: "We slip a week."
  - An authority trope claiming to cut through to a deeper truth: "The real question is", "At its core", "In reality", "What really matters is", "The heart of the matter". Before: "At its core, what really matters is organizational readiness." After: "This depends on whether the team is ready to change how it works."
  - Signposting that announces the writing instead of doing it: "Let's dive in", "Let's break this down", "Here's what you need to know". Before: "Let's dive into how the cache works." After: "The cache is a copy made at install time."

- **No aphorism formulas.** An ordinary claim reshaped into something quotable: "X is the Y of Z", "the language of", "the currency of", "the architecture of", "X becomes a trap". The formula sounds precise while saying less than the plain version.
  - Before: "Speed is the currency of trust."
  - After: "People stop trusting a tool once it feels slow."

- **No throat-clearing openers.** "It's worth noting", "It bears mentioning", "It's important to", "To be clear", "That said". Just say the thing.
  - Before: "It's worth noting that the cache does not refresh automatically."
  - After: "The cache does not refresh automatically."

- **No landing sentences or summary beats.** A closing line that restates the paragraph in a more quotable shape. "These are real. They are the reason we..." reads as tidying up after yourself. Let the prose end where the point ends.
  - Before: "...so the metric now reports variance. That, in the end, is the whole point of measuring."
  - After: "...so the metric now reports variance."

- **No paragraph pinning.** Opening and closing a paragraph on the same idea or the same word to bookend it. The reader gets the point on the first pass; the return trip is decoration.
  - Before: paragraph opens "Ownership is the missing piece." and closes "Ownership, then, is what we need to fix."
  - After: drop the closing sentence. The paragraph already argued it.

- **Replace mechanical transitions.** "Furthermore", "Additionally", "On the other hand", "That said". Use a human pivot ("Here's the catch", "The other side of that is") or nothing. Often the paragraph break is the transition.

- **Vary mechanical headings.** "What X means", "Why this matters" toward headings in the author's own voice.

### 3. Cadence

- **Vary sentence length unpredictably.** This is the constraint a model reliably fails, and the one the script now measures. Uniform length is the tell even when every individual sentence is good. Aim for a coefficient of variation around 0.6 or above, and check the longest uniform run: seven or more consecutive sentences of near-identical length needs breaking up, however clean each one reads. Four or five is normal for our own prose.
  - Before: "The cache holds the old copy. The source has the new rules. Nothing reconciles them. The gap stays invisible." (four sentences, 6 to 7 words each)
  - After: "The cache holds the old copy while the source has the new rules, and nothing reconciles them. The gap stays invisible."

- **No parataxis.** Short declaratives strung together with no subordination. It is the failure mode you fall into when correcting for long sentences, and it reads as clipped and portentous.
  - Before: "We shipped it. It broke. We rolled back. Nobody noticed."
  - After: "We shipped it, it broke, and we rolled back before anyone noticed."
  - (The script's short-sentence-run counter catches this: four or more consecutive sentences of five words or fewer. Two or three is ordinary.)

- **No parallel sentence structures within a paragraph.** Two or more sentences sharing a grammatical shape, or bullets that all open "**Bold noun phrase.**" Mix verb openings, conditional clauses, and full prose sentences. This absorbs the older "vary bullet structure" rule.
  - Before: "The script counts dashes. The script counts hedges. The script counts sentence length."
  - After: "The script counts dashes and hedges. Sentence length needed a distribution rather than a count, so that part reports standard deviation."

### 4. Volume

The failure this whole pass exists to prevent is volume, not grammar. A humanized draft is normally **shorter** than what came in. If a pass made something longer, it was applied cosmetically.

- **Say it in two or three sentences when that covers it.** Length is a cheap proxy for diligence, which is exactly why it gets produced. Ask what the reader has to do differently after reading, then cut everything that does not serve that.
  - Before: "I looked at the cache behaviour and there are a few things going on. The install copies the source rather than linking it, which means edits to the source do not reach the cache. That has implications for how changes go live, and it is worth understanding before you make the next edit."
  - After: "The install copies the source instead of linking it, so source edits never reach the cache."

- **No bullet walls.** A list of one-line bullets is often a paragraph that gave up. Bullets earn their place for genuinely parallel items a reader will scan or return to; they do not earn it for three related thoughts that wanted a sentence each.
  - Before: five bullets reading "Fixed the fence regex", "Fixed the abbreviations", "Fixed the list markers", "Added tests", "Updated the table"
  - After: "The fence, abbreviation and list-marker bugs are fixed, with a test each. The reference table moved with them."

- **No significance-claiming.** "The part that matters", "the key insight", "worth knowing", "more importantly". Telling the reader what to care about instead of letting them decide.
  - Before: "The part that matters here is that the cache never refreshes."
  - After: "The cache never refreshes."

- **No hedged emphasis.** "To be explicit", "stated plainly", "I want to be clear", "simply put". Announcing directness instead of being direct.
  - Before: "To be explicit, and stated plainly, the count was 104."
  - After: "The count was 104."

- **No performative contrition.** "My mistake", "I had it badly", "that was sloppy of me". Self-criticism offered as a trust signal. Report the error, fix it, move on.
  - Before: "I got this wrong, and I had it badly. The regex never matched indented fences."
  - After: "The regex never matched indented fences."

### 5. Register and voice

- **Write for the spoken voice.** Read each sentence aloud. If you would not say it to a colleague at a desk, rewrite it until you would. This is the check that catches what the rules above miss.
  - Before: "Prior to deployment, validation of the configuration should be performed."
  - After: "Check the config before you deploy."

- **No performed enthusiasm.** Exclamation, superlatives, and appreciation the reader did not ask for: "Great question", "This is exciting", "a powerful new capability". Enthusiasm belongs to the reader once the work has earned it.
  - Before: "This is a really exciting improvement to how we measure prose!"
  - After: "The script now measures sentence-length variation."

- **No diff-anchored framing.** Prose written as if narrating a change rather than describing the thing. It reads fine on the day of the PR and becomes unreadable a month later, when nobody remembers what it was compared against. Changelogs, release notes, and migration guides are version-scoped by nature and exempt; everything else should stand on its own.
  - Before: "This replaces the previous approach of iterating through every item, which was O(n²)."
  - After: "This looks the item up in a hash map, so it stays O(1) as the list grows."

## What not to flag

A competent human writer hits several of the patterns above without any model involved. Over-editing real prose is the failure mode of this pass, and it is the one nobody catches downstream, because the result looks processed rather than wrong. None of the following is evidence on its own:

- Polish. Many writers are professionals, or were edited. Clean grammar is not a tell.
- Mixed casual and formal register in one document. That is usually a person in a technical field.
- Dryness. AI prose has specific tells. Flat writing without them is just flat writing.
- Formal vocabulary in general. The signature is a specific word set, not every long word. Leave "ostensibly" alone.
- One "however". One em-dash from a writer who has always used them. One short emphatic sentence. Isolated instances are noise.
- Curly quotes on their own. macOS, Word, and most editors curl them by default.
- A phrase being discussed rather than used. Do not rewrite a banned construction that appears inside a quotation, a title, or an example.
- Bullets in a document whose genre is a list. A rule set, a checklist, a reference table, an API surface: bullets are the right form and the volume numbers will read badly by design. This file scores 86% bullet lines against 11 to 23% for the prose documents it was calibrated on. Do not convert a rule list into paragraphs to satisfy a metric.
- A negation that names the thing a reader would otherwise assume. "The hard half is injection, not transcription" reads as a contrasting pair to the detector, and the negative half is the whole point of the sentence. Every one of the nine `, not Y` hits on one of our shipped docs was this, not the rhetorical tell. Cadence contrast goes; disambiguation stays.

Look for clusters. A single rule-of-three means nothing; rule-of-three plus copula avoidance plus `seamless` plus a generic closing paragraph is a confession.

Some things are positive evidence that a person wrote it, and are worth protecting even when a rule above technically applies:

- Specific, hard-to-fabricate detail. A real number, an odd aside, a name.
- Unresolved tension. "I think this is right and it still bothers me."
- Sentence length that already varies. That is the thing this pass is trying to produce.
- Genuine self-interruption or parenthetical second thoughts.

When a rule and one of these collide, the human signal wins.

## Measure

Run the metric script before declaring the draft done:

```bash
ruby "${CLAUDE_SKILL_DIR}/scripts/ai_tells_metric.rb" <path>
```

Stdlib only, no gems, Ruby 2.7 or newer. `${CLAUDE_SKILL_DIR}` resolves to this skill's directory wherever it is installed, so the path works the same as a personal skill, a project skill, or a plugin.

The script has its own test suite. Run it after touching a detector, since several of them were wrong in ways the report still rendered plausibly:

```bash
ruby "${CLAUDE_SKILL_DIR}/scripts/test_ai_tells_metric.rb"
```

The script measures on prose, in two tiers. Code and blockquotes come out for every counter, because an em-dash inside a code sample is not a prose tell and a quoted paragraph is somebody else's voice. Headings and table cells stay in for the character-level counts and come out for the word, sentence, and vocabulary counts: they are the author's own prose, so an em-dash in a heading has to count, but a heading is a fragment rather than a sentence and would wreck the cadence numbers. Hard-wrapped lines are rejoined before sentences are counted; without that step every wrapped line reads as its own sentence and the length numbers are meaningless.

Reference numbers, measured on four documents we already shipped, sized 800 to 3,600 prose words. Paths so the table stays re-derivable rather than trusted:

- `~/src/zar/.accomplishments/2026-07-27.md`
- `~/src/zar/.accomplishments/2026-07-29.md`
- `~/src/zar/.workflow/answers/2026-07-29-marketplace-issue-DRAFT.md`
- `~/src/zar/.workflow/answers/BRIEF-humanize-prose-upgrade.md`

| signal | our shipped docs | read it as |
| --- | --- | --- |
| em / en-dashes, smart quotes | 0 to 18 | 0 is the target; the two high readings are legate-written files that never went through this pass |
| dash substitutes (` -- `, ` - `) | 0 | anything above 0 is the em-dash rule being routed around |
| filler intensifiers | 0 to 3 per doc | each one is a candidate cut |
| corporate-register verbs | 0 to 3 | check the matches; `reflect` has honest uses |
| AI vocabulary | 0 to 1 | 3 or more, clustered, is the strongest single signal in the set |
| hedging qualifiers | 0 | a cluster means the draft is dodging |
| copula avoidance | 0 | anything above 0 is a plain "is" waiting to happen |
| nominalization | 0.9 to 2.5 per 100 words | above 3 reads bureaucratic |
| participial tack-ons | 0 | each hit is a clause to cut |
| rule of three | 1 to 5 per 1,000 prose words | above 6 is a tell |
| antithesis / corrective negation | 2 to 5 per 1,000 prose words | above 6 is house style leaking through |
| tailing negations | 0 to 2 | each one wants writing out as a clause |
| longest negative-opener run | 0 to 1 | 3 or more is chanting |
| rhetorical crutches, aphorism formulas | 0 | these read as 0 on our prose, so any hit is worth looking at |
| significance-claiming, hedged emphasis, performative contrition | 0 | the standing-order voice patterns; any hit is a cut |
| bullet lines | 11 to 23% of a prose document | above 40% is a bullet wall, unless the genre is a list |
| sentences per paragraph | mean 3.0 to 4.5 | a mean above 6 means the paragraphs are doing too much |
| sentence-length CV | 0.60 to 0.70 | below 0.5 is mechanical |
| longest uniform run | 4 to 5 sentences | 7 or more needs breaking up |
| longest short-sentence run | 2 to 3 sentences | 4 or more is parataxis |
| first-person markers | varies by genre | verify none are position claims |
| collaborative markers (we / our / us) | higher for team docs, lower for a solo spec | judgment |

These are calibrated against our own voice, not a universal law, and they scale with length and genre. The script reports; you judge.

Several detectors over-fire on purpose and print their matches so you can dismiss them in a glance. Read the matches; do not act on the counts alone.

The stacked-noun detector is much the loosest. Most of its hits on our own docs are false positives, because separating a noun pile from a verb phrase needs part-of-speech tagging the script does not have, so any run containing a verb it cannot see ("Liam wants his dev-loop skills") comes through. It reliably catches real piles, which is why it stays, but treat every hit as a question rather than a finding.

Five constraints are not mechanically detectable at all and stay human-judged: paragraph pinning, setup/payoff, summary beats, performed enthusiasm, and spoken voice.

This file scores badly against its own rules, because every example above quotes the phrase it bans. Do not chase its numbers to zero.

## Boundaries

- Edits prose only. No content restructure, no fact-checking, no publish. If a sentence can only be fixed by cutting a claim, flag it and leave it; that call belongs to the author, and `doc-claim-review` has already signed off on the claims by the time this pass runs.
- One draft per invocation.
- The script measures; it does not edit. The edits are yours after reading for cadence.

## Sources

The constraint list is Val's. Several of the rules and the shape of the "what not to flag" guard come from [blader/humanizer](https://github.com/blader/humanizer) (MIT), which in turn draws on [Wikipedia:Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing) maintained by WikiProject AI Cleanup. That skill is a rewriter: it compresses content, merges paragraphs, and treats the information as what must survive rather than the prose. This one is an editor and stops at the sentence, which is why the rules were ported here instead of the skill being chained after this one.
