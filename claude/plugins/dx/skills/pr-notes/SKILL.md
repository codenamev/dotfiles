---
name: pr-notes
description: >-
  Deep-dive on one PR and keep a persistent local scratchpad: a summative
  "what's proposed and why", where your high-level eyes matter, and optional
  draft reply comments you revisit across windows. Notes live in
  ~/.claude/pr-reviews/, one file per PR. Use when the user invokes
  /pr-notes <url>, says "dig into this PR", "take notes on this PR", "draft a
  reply to", "open my notes on", or picks a PR from the review-queue output to
  review in depth. Local only by design: it never posts to GitHub.
allowed-tools: [Read, Write, Edit, Grep, Glob, "Bash(gh pr view *)", "Bash(gh pr diff *)", "Bash(gh api *)", "Bash(jq *)", "Bash(python3 *)", "Bash(ls *)", "Bash(mkdir *)"]
disable-model-invocation: true
---

# PR Notes

Deep-dive companion to `review-queue`. The queue tells you *what* to review and
ranks it; this shapes *how* you review one PR and remembers it. You hand it a PR
URL (straight off a queue card), it builds or reopens a persistent scratchpad so
you can dig in, capture your read, and draft replies across spare windows without
re-deriving context each time.

**Local only, by design.** This skill has no GitHub-write tools in its
`allowed-tools`. Drafts sit in the scratchpad; nothing is ever posted. Posting is
deliberately out of scope for now.

## Operating rules

These mirror `review-queue` so the two stay consistent.

- **Evidence only, no assumptions.** Every line traces to the diff, PR body, a
  commit, a linked ticket, recalled memory, or a thread. Missing source, say so
  ("no linked ticket"); never infer intent.
- **Review angle stays high.** Surface abstractions, framework fit, logical
  placement, and clear typos or signs of logical confusion/misplacement. Never
  raise formatting, naming style, or anything a linter owns. That is bike-shedding
  and out of scope.
- **Respect private channels.** Never quote or reference safe-space channels; pull
  discussion as context, not quotes.
- **No AI tells.** No em-dashes, no smart quotes, no robotic phrasing. PR and
  ticket references as plain URLs.

## Scratchpad

One markdown file per PR in `~/.claude/pr-reviews/` (your work product, kept out of
the skill dir so skill updates never clobber it). Filename is derived from the URL:

```
https://github.com/your-org/your-repo/pull/42  ->  your-org-your-repo-42.md
```

```bash
mkdir -p ~/.claude/pr-reviews
echo "<url>" | sed 's|https://github.com/||; s|/pull/|-|; s|/|-|g' | tr '[:upper:]' '[:lower:]'
# -> your-org-your-repo-42.md
```

## Flow

1. **Resolve the file.** Derive the filename. If it already exists, **read it and
   show it first**, then say when it was last touched and its `status`. The existing
   file is the canonical state of your review ("you have notes from 2026-06-09,
   status: in-progress"). Update in place; never overwrite silently.
2. **Gather (only what's missing).** For a new note or to fill gaps:
   `gh pr view <url>` for title/body/commits, `gh pr diff <url>` for the change
   shape, the linked ticket from the body or branch name, recalled memory for prior
   related decisions, related threads as context. If the PR came from a `review-queue`
   card, carry its score/tier/why-here straight in rather than recomputing.
3. **Write the summative note**, not a file-by-file readout. The point is to
   re-orient you in seconds after a context switch.
4. **Draft replies only when asked** (or when you spot something at your altitude
   worth staging). Each draft is keyed to a `path:line` or marked general. They stay
   staged in the file. Nothing posts.
5. **Set `status`** so you can resurface unfinished work:
   `grep -l "status: in-progress" ~/.claude/pr-reviews/*.md`.

## File format

```markdown
# <owner>/<repo> #<num>: <title>
<url>
reviewed-on: <date>
status: in-progress | reviewed | deferred
queue: score <n> · tier <T1|T2|T3> (owner: <team>)   # if it came from review-queue, else omit

## what's being proposed and why
<2-4 lines, abstract, from diff + body + commits + linked ticket. The shape of the
 change and its intent. Written once, revisitable.>

## touched
<subsystems/packs grouped, not a raw file list>

## intent (linked)
<Jira/Notion intent in one line, or "no linked ticket">

## your review angle
<where your high-level eyes matter on THIS PR: an abstraction that looks off, a
 framework used against its grain, logic in the wrong layer, a typo/naming that
 signals real confusion. If it is clean at that altitude, say "looks sound at the
 abstraction level" and move on. Not lint, not style.>

## draft replies
<!-- staged locally; nothing posts. Remove this section if you have no drafts. -->

### <path/to/file.ext>:<line>   (or: general)
<draft comment, in your concise voice: lead with the shape/concern, brief why,
 no per-line walkthrough, no quantities>
---
```

## Notes

- Companion to `review-queue`, not a replacement; the queue ranks and distills,
  this is the per-PR deep-dive and memory.
- The scratchpad persists across sessions on purpose. It is the only thing this
  skill writes, and it writes nowhere else.
- Posting drafts to GitHub is intentionally unsupported in this version. If that
  changes, it belongs in a separate, explicitly-approved step with its own write
  tools, never folded into this skill.
