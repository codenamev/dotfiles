---
name: architecture-ledger
description: >-
  Shape an architectural tradeoff document (gap analysis, decision
  retrospective, cost-of-a-choice writeup) into tight high-level prose
  that reads as human-written even when AI helped draft it. Use when
  the user invokes /architecture-ledger, or says "reshape this doc",
  "tighten this", "apply prime directive", "make it a tradeoff ledger",
  or is drafting
  a doc that itemizes the cost of an architectural choice and the
  value the choice was aimed at. Constructive shaping — applies
  transformations and rewrites, unlike doc-claim-review which only
  flags, and calls humanize-prose for the prose pass. Pair with
  doc-claim-review for grounding QA before publish. Skip for code
  review, PR body work, or Slack messages.
allowed-tools: Read, Edit, Write, Skill(dx:humanize-prose *)
disable-model-invocation: true
---

# Architecture Ledger

## Why this exists

Some docs are tradeoff ledgers: an architectural decision is being re-examined now that the picture has moved. The genre has to do three things at once and most drafts only do one or two:

1. **Itemize honestly** what the decision buys and what it costs.
2. **Honor the original call** as sound for what was known at the time (Retrospective Prime Directive).
3. **Read as human prose** that doesn't fatigue the reader with AI synthesis patterns, even when AI helped draft it.

Doc-claim-review handles fact-grounding and structural QA. This skill handles the constructive shaping that makes a tradeoff doc readable, trustworthy, and usable by the people who originally made the call.

## When to use

- The doc is a tradeoff retrospective, gap analysis, or "what we're giving up by X" framing
- The topic is a past architectural decision being re-examined as the picture evolves
- The doc will be authored under a teammate's name and needs to read like they wrote it
- The output is meant to invite a conversation, not prescribe an answer

## Structure: the tradeoff ledger

A tradeoff ledger typically has these sections in order. Adjust as the material warrants; the principle is value-first, cost-second, evolution-third, questions-last.

1. **TL;DR** that honors the original decision and frames the doc as honest accounting. Include the disclaimer "It does not prescribe an answer" if true.
2. **What [the choice] was meant to buy.** Itemize the architectural payoffs of the existing decision. Lead the reader to nod with the original rationale before you introduce the cost.
3. **What [the alternative] provides that we forgo.** A table is usually the right shape: *Capability × What the framework / alternative gives × What we have today*.
4. **What else opens up.** Elevator pitches (one or two sentences each) for capabilities not directly tied to current planned work but that come bundled with the alternative. This separates "features we need" from "features we'd pick up naturally."
5. **Where the cost actually lands.** Itemize where the cost has shifted to in the absence of the alternative. Cite concrete failures or downstream costs where available.
6. **Where the lines are already blurring.** Evolving signal: new proposals, upstream movement, edge cases the original frame doesn't cover. This is the "why now" section.
7. **Questions worth answering together.** Collaborative prompts framed less as "should we adopt X" and more as "where is the architectural pressure coming from now". Three to five questions, each anchored in concrete evidence.
8. **Sources.** Footnote-style reference list for every doc cited in the body.

## Voice: neutral collaborator with Prime Directive

**The Retrospective Prime Directive** (Norm Kerth): "Regardless of what we discover, we understand and truly believe that everyone did the best job they could, given what they knew at the time, their skills and abilities, the resources available, and the situation at hand."

How this shows up in prose:

- Credit the original call as sound for what was known: *"The X choice was sound for what we knew at the time, and the rationale still stands up."*
- Frame evolution as the picture changing, not the original call being wrong: *"The infrastructure picture turned out sharper than we'd estimated at the time."*
- Honor the original concerns; don't strawman them: *"The vendor-coupling concern has resolved itself, in practice, into an infrastructure question rather than a portability one."*
- **No framing-by-negation** that puts a position in someone's mouth they didn't take. "Not an accident" implies someone said it was. Drop it.
- **No claims about specific people's positions on past decisions** unless directly attested.

**First-person voice as writer-voice is fine** (observation, intent, invitation):
- *"What I keep noticing is..."* (observation about the picture moving)
- *"I want to be honest about..."* (writer's intent)
- *"Questions I'd want us to chew on together"* (collaborative invitation)

**First-person voice as position-claim is not** (unless the author has explicitly confirmed):
- *"I argued for X"* (claims a faction in the original debate)
- *"I helped push back on Y"* (same)
- Any phrase that fabricates an internal-political stance

When in doubt, default to "we / our" collaborative voice that places the author on the team without claiming a faction. *"Our charter is..."*, *"We landed there..."*, *"What we have today..."*.

## AI-tell reduction

A tradeoff ledger has to read human even though AI helped draft it. The mechanical and cadence pass that does this is genre-agnostic, so it lives in its own skill rather than being duplicated here: run **/humanize-prose** on the draft. It owns the canonical strip list (em-dashes, smart quotes, triadic overuse, abstract-noun phrasing, mechanical transitions, closing-summary tics) and the metric script with healthy ranges.

Two ledger-specific notes layered on top of that general pass:

- The collaborative-marker count matters more here than for most prose. A team retrospective should read "we / our", not "I". Aim high on collaborative voice and verify none of the first-person markers are position claims (see Voice above).
- Vary section headings toward author-voice ("Where the cost actually lands") rather than mechanical patterns ("What X means").

## Citation discipline: inline vs. footnote

Two layers, and both belong in the doc:

- **Inline links** when a document is explicitly named in prose. *"[the author]'s [HITL proposal](url)..."* / *"the [durable-conversations spec](url)..."* / *"the [platform recommendation](url)..."*. Readers should never have to hunt the Sources section for a doc that's named in the body.
- **Footnote-style Sources section** at the bottom for the full reference list. Include docs cited in spirit (a quote, a paraphrase, an incident the body alludes to) but not explicitly name-dropped in prose.

When in doubt: inline-link the named reference; keep the Sources section as the canonical overview of every doc that informed the page.

## Workflow

1. **Sketch the sections.** Don't write prose yet. Decide what goes in each, what the table columns are, and which questions you want the group to chew on.
2. **Draft section by section.** Lead with value (what the decision was meant to buy), then cost, then opportunities, then evolution, then questions. Write past tense / present tense consistently within each section.
3. **Apply Prime Directive on the first pass.** Honor the original call as sound for what was known. Strip any framing-by-negation. Audit for position claims you're putting in the author's mouth.
4. **Run /humanize-prose** on the draft for the AI-tell pass and the metric check, then re-read for cadence, minding the collaborative-voice and position-claim notes above.
5. **Add inline citations** wherever a document is named in prose. Verify the Sources section is the canonical reference list.
6. **Pair with doc-claim-review** before publish. That skill flags grounding and citation gaps; this skill shapes voice and structure. They are complementary, not redundant.
7. **Optional one-pager constraint.** Aim for under 1,500 words for an architecture ledger. The discipline is what makes it useful at an offsite or in a thread.

## What NOT to do

- **Don't claim positions** for the author about past decisions unless they have explicitly confirmed.
- **Don't strawman** the original rationale, even subtly ("not an accident" is a strawman).
- **Don't prescribe an answer** in the doc body — the genre is honest accounting that invites a conversation.
- **Don't bloat** the doc to demonstrate thoroughness; tightness is part of trustworthiness.
- **Don't replace** every em-dash with a comma blindly. Read for cadence after the mechanical pass; some replacements should be periods, parens, or restructured sentences.
- **Don't auto-publish.** Notion / external sync is out of scope for this skill. The user decides when to push.

## Boundaries

- One doc per invocation.
- Constructive shaping (rewrites, edits, restructure). For flag-only QA, use `doc-claim-review`.
- This skill writes and edits local markdown. It does not push to Notion or sync to external systems.
- Skill stops when the doc reads as a human-written architectural ledger and passes the metric script. Publish is a separate step the user owns.
