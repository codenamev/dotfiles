---
name: doc-claim-review
description: >-
  Review a local markdown design spec, proposal, scope doc, RFC, or
  planning artifact for unsourced claims, unattributed decisions, and
  structural bloat before publishing to Notion or sharing with humans.
  Use when the user invokes /doc-claim-review, says "check claims",
  "claim check", "review this design spec/proposal/RFC", or is about to
  publish or share such a doc ("before I publish", "before notion sync",
  "is this ready to share"). Read-only: output is flags only — line-tied
  questions and soften suggestions, no auto-rewrites. Skip for structural
  reshaping (use architecture-ledger), style/voice (use humanize-prose),
  code review, PR body review, and Slack messages or quick notes.
allowed-tools: Read, Grep, Bash(wc *)
---

# Doc Claim Review

## Why this exists

Standalone synthesis docs accumulate three failure modes that bleed reviewer trust and inflate cleanup time:

1. **Existence ≠ behavior.** "X is used in production" presented when the source is a single-file grep, not point-of-use or runtime data.
2. **Unattributed decisions.** "X is rejected" or "the convention is Y" presented as canon without a human source (spec, Slack permalink, doc URL, sync date).
3. **Section bloat.** Same point in prose, bullets, and a "what must be guaranteed" list. Cleanup tax compounds with doc size.

This skill flags them while the draft is still local markdown, before the Notion sync makes them harder to scan.

## Input

A local markdown file path. Accept any path the user provides. If your workflow keeps drafts in a standard location, default to it; otherwise ask.

If no path is provided, ask for one. Do not search.

If the file isn't markdown or doesn't exist, fail fast and ask for a corrected path.

## Output

A single markdown report to stdout. Header with structural numbers, then three numbered passes. Each flag line-tied:

```
# Doc claim review — <filename>

Word count: 3,412 · Sections: 14 · First problem statement: L18 ("...")

## Pass 1 — Grounding

L42: "Production call sites today: main_chat_agent, escalation_detection, ..."
  Source? (point-of-use scan / runtime data / single-file read / memory)
  Suggest: soften to "call sites observed in code as of <date>" if not runtime-verified.

L87: "Every LLM call site constructs ChatOpenAI directly"
  Universal quantifier — verified across all call sites, or inferred from a few?

## Pass 2 — Decision attribution

L134: "Auto-deriving from file paths is rejected."
  Human source? (Slack permalink with date / doc URL / spec link / sync date+attendees)
  Suggest: reframe as "this spec proposes against auto-deriving..." if no prior decision exists.

## Pass 3 — Structure

L210-L245 and L260-L290: Contract 2 prose, bullet list, and "What implementations must guarantee" cover overlapping ground. Collapse?

Section "Contract 3: Attribution model" — 612 words, zero inline sources.
```

Use exact line numbers. Quote offending text verbatim. One question per flag. Optional one-line suggestion.

No rewrites. No diffs. The user (or driver mode) decides per flag.

## Pass 1 — Grounding

Flag claims that assert state without showing how they were verified.

Surface forms to catch:
- Existence/usage: "X exists", "X is used", "X doesn't exist", "X is not used", "X handles Y"
- Universal quantifiers: "every", "all", "no", "zero", "none", "always", "never"
- Snapshot framing: "today", "currently", "production X", "the current state", "as of today"
- PR references in active tense: "PR #N establishes/introduces/adds Y" — flag when the PR is OPEN or unverified-as-merged
- Quantitative claims without inline source: "31.5%", "9,200 RPM", "175 errors in 30 days"

For each: ask whether the source is point-of-use scan, runtime data (Datadog/Braintrust/logs), single-file read, or memory recall. Recommend softening when point-of-use can't be cleanly established — "present in code, runtime usage unverified" or "observed in <file> as of <date>".

Skip claims that already cite a source inline: a URL, a Jira ID, a Slack permalink with date, a sync date with attendees, a metric name with a dashboard link, a quoted human source.

## Pass 2 — Decision attribution

Flag declarative decisions presented as canon without a human source.

Surface forms to catch:
- "X is rejected", "X is not pursued", "X is out of scope", "X is deferred", "X is not in scope"
- "we decided", "the team chose", "we agreed", "the convention is", "the standard is"
- Bare declarative musts/shoulds: "X must Y" / "Y should Z" / "Y is required" without inline citation

For each: ask for the human source — Slack permalink with date, doc URL, spec link, sync date with attendees. If none exists, recommend reframing as the doc's own proposal ("this spec proposes", "we recommend") rather than canon.

Skip decisions with inline sources. Examples of well-attributed forms that should NOT be flagged:
- "Out of scope per the 2026-05-13 sync"
- "Daniel's pairing-session correction (verified)"
- "Sam Mueller (OpenAI admin) 2026-05-12: '...'"
- "Rejected in [RFC #42](url)"

## Pass 3 — Structure

Mechanical signals only. No subjective style judgments.

Report at the top of the output:
- Total word count
- Section count (count `^#` lines)
- First problem statement check: does a sentence stating the problem being solved appear in the first 200 words? Quote where it lands, or note its absence.

Flag patterns:
- Sections that restate each other: prose paragraph plus bullet list plus a "What must be guaranteed" or equivalent list covering the same point. Quote line ranges of the duplicates.
- Sections over 400 words with zero inline-sourced claims.
- Headings deeper than `###` for non-reference content (signal of over-fragmentation).

No fixed pass/fail thresholds. Report the numbers and the patterns; the human decides.

## What NOT to do

- **No auto-rewrites.** Flag only. The user adjusts.
- **No style enforcement.** Em-dashes, smart quotes, voice — not this skill's job.
- **No Notion fetch or push.** Local markdown in, flags out.
- **No claim-by-claim research.** Fast pattern-matching only. Investigation is a separate driver-mode step.
- **No tone judgments.** Don't flag "sounds too formal" or "this paragraph is hard to follow."

## Boundaries

- One file per invocation. Multi-doc reviews are separate invocations.
- Skill stops after producing the report. The user (or a follow-up driver-mode step) handles fixes.
- Skill does not modify the input file.
