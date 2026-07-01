---
name: humanize-prose
description: >-
  Strip AI tells from an existing draft so technical prose reads as
  human-written: em-dashes, smart quotes, triadic overuse, abstract-noun
  phrasing, mechanical transitions, and closing-summary tics, with a metric
  script for the mechanical tells (dashes, quotes, triadic lists, pronoun use;
  the others are human-judged). Invoke as /humanize-prose, or use it as the prose pass inside
  a doc-shaping workflow (architecture-ledger delegates to it). Edits prose only;
  it does not restructure content (use a genre shaper like architecture-ledger)
  or fact-check claims (use doc-claim-review).
allowed-tools: Read, Edit, Write, Bash(python3 *ai_tells_metric.py*)
---

# Humanize Prose

## Why this exists

AI-assisted writing fatigues human readers with synthesis patterns: em-dashes everywhere, everything in threes, abstract-noun phrasing, mechanical transitions, tidy closing summaries. This is the one genre-agnostic pass that removes those tells from an existing draft, with a measurable check so "reads human" is verified, not asserted. It is the prose layer shared across the doc-craft family: a genre shaper (like `architecture-ledger`) handles structure, `doc-claim-review` handles grounding, this handles voice and cadence.

## When to use

- A draft (doc, PR body, Notion page, Slack post) was AI-drafted or AI-assisted and needs to read human before it goes to people.
- Invoked as the prose pass within a larger doc workflow (e.g. step in `architecture-ledger`).

When NOT to use:
- The content structure is wrong (sections in the wrong order, missing a problem statement): that is a genre shaper's job, not this.
- A claim might be unsourced or a decision unattributed: that is `doc-claim-review`.
- Writing from scratch: this edits existing prose, it does not generate it.

## The pass

Run it in this order. Mechanical first because it is fast and unambiguous, structural second because it needs judgment, cadence last because you can only hear it once the noise is gone.

### Mechanical strips

- **No em-dashes (`—`), en-dashes (`–`), or smart quotes (`" " ' '`).** Replace em-dashes with a comma, period, parens, or "and" depending on rhythm. Do not blindly comma-replace; read each one.
- **Limit triadic structures.** "X, Y, and Z" everywhere is a tell. Mix in pairs and singletons.
- **Cut "worth noting / worth flagging / it bears mentioning."** Just say the thing.

### Structural strips

- **Vary bullet structure.** Don't open every bullet with "**Bold noun phrase.**" Mix verbs, conditional clauses, and full prose sentences.
- **Reduce "the X" abstract-noun phrasing** ("the cost", "the value", "the question") where a concrete subject works.
- **Replace mechanical transitions** ("Furthermore", "Additionally", "On the other hand", "That said") with human pivots ("Here's the catch", "The other side of that is") or nothing; often the paragraph break is the transition.
- **Avoid closing-summary tics.** "These are real. They are the reason..." reads as AI tidying up. Let the prose end where the point ends.
- **Vary mechanical headings** ("What X means", "Why this matters") toward author-voice headings.

### Cadence

Read the draft in your head after the strips. Replacements that scanned fine mechanically often read wrong; some commas should have been periods, some sentences should have been split or merged.

## Measure

Run the metric script before declaring the draft done:

```bash
python3 "$CLAUDE_SKILL_DIR/scripts/ai_tells_metric.py" <path>
```

(If `$CLAUDE_SKILL_DIR` is not set, use the path to this skill's `scripts/` directory.)

Healthy ranges for a tight technical doc (roughly 1,000 to 1,500 words):

- em / en-dashes, smart quotes: **0**
- triadic patterns: **0 to 2** (a few are fine, a lot is a tell)
- first-person markers: a handful as writer-voice; verify none are position claims
- collaborative markers (we / our / us): higher for a team/retrospective doc, lower for a solo spec

The ranges scale with length and genre; the script reports counts, you judge.

## Boundaries

- Edits prose only. No content restructure, no fact-checking, no publish.
- One draft per invocation.
- The script measures; it does not edit. The edits are yours after reading for cadence.
