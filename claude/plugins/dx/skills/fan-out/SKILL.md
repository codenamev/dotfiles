---
name: fan-out
description: >-
  Parallel-subagent fan-out orchestration harness. Use when a research,
  review, or analysis task can be decomposed into independent slices that
  benefit from being executed concurrently and then synthesized. Invoke as
  /fan-out with a question or task as args. Classic triggers: "research X
  from multiple angles", "compare these N things in parallel", "fan out and
  synthesize", "parallel research", "gather and merge". Use only when the work
  genuinely splits into independent slices worth running concurrently, not for
  ordinary single-track tasks.
disable-model-invocation: true
allowed-tools: Read, Agent
---

# Fan-Out Orchestration Harness

## Purpose

Some tasks have a natural shape: break a question into independent slices,
execute each concurrently, collect structured notes, and synthesize them
into a single coherent output. This skill codifies that pattern as a
repeatable harness.

> **Reach for the built-in `Workflow` tool instead** when you want the fan-out
> to be deterministic (loops, conditionals, staged pipelines, resumable runs).
> This skill is the model-driven version of the same pattern: lighter weight,
> good for ad-hoc decomposition where you don't need the orchestration harness.

The canonical shape is:

```
Orchestrator
  ├── Subagent A (independent slice)
  ├── Subagent B (independent slice)
  ├── Subagent C (independent slice)
  └── ... N slices
Synthesizer (receives all notes, produces final output)
```

Each subagent is launched with the Agent tool. All subagent calls for a
given fan-out batch are sent **in a single message** so they run
concurrently. The synthesizer runs only after all notes are collected.

---

## When to use

- A question has N loosely-coupled sub-questions (N >= 2)
- Each sub-question can be answered independently without knowing the others
- The cost of latency dominates the cost of token usage (parallel >> serial)
- The final answer benefits from multiple angles being merged into one view

When NOT to use:
- Sub-tasks depend on each other's output (use a serial chain instead)
- N = 1 (just do the task directly)
- The question is already well-scoped and doesn't benefit from decomposition

---

## Protocol

### Step 1 — Decompose

Break the user's goal into 2–6 independent slices. Each slice should be:
- Self-contained: an agent with no prior context can answer it from scratch
- Scoped: specific enough to produce actionable notes, not a mini-essay
- Parallel-safe: order of execution does not affect correctness

Write the decomposition explicitly before launching agents. Format:

```
Slice A: <one-sentence scope>
Slice B: <one-sentence scope>
Slice C: <one-sentence scope>
```

### Step 2 — Brief each subagent

Each subagent prompt must be self-contained. Include:
1. What to research or produce
2. What prior context the agent needs (paste it, don't say "see above")
3. The output format: a structured note block (see template below)
4. A word-count cap (default: 300 words per note)

Template for subagent output:

```
## Note: <Slice Title>
**Source/scope**: <what was examined>
**Key findings**:
- <finding 1>
- <finding 2>
**Caveats / open questions**:
- <caveat>
**Confidence**: high | medium | low
```

### Step 3 — Launch concurrently

Send a single message with all Agent tool calls. Do NOT send them
sequentially unless there is an explicit dependency between slices.

```
[Agent A call]   # simultaneous — single message
[Agent B call]   # simultaneous — single message
[Agent C call]   # simultaneous — single message
```

Wait for all agents to return before proceeding.

### Step 4 — Collect structured notes

Paste all returned notes into a working scratch block. Scan for:
- Contradictions between slices (flag explicitly)
- Gaps (a slice that returned low-confidence or empty)
- Convergence (multiple slices pointing to the same signal)

### Step 5 — Synthesize

Write the synthesis. Default structure:

1. **TL;DR** (2–3 sentences)
2. **Findings by slice** (brief subsection per slice, no duplication)
3. **Convergence signals** (what multiple slices agreed on)
4. **Contradictions / gaps** (what needs follow-up)
5. **Recommended next step** (one concrete action)

The synthesis should read as a single coherent document, not a
concatenation of notes. Eliminate redundancy; integrate rather than list.

---

## Worked example

A "compare three caching libraries" fan-out runs like this:

- **Decompose** — Slice A: Redis tradeoffs; Slice B: Memcached tradeoffs;
  Slice C: in-process LRU tradeoffs.
- **Launch** — three Agent calls in one message, each briefed with the same
  evaluation criteria (latency, ops burden, failure modes) and a 300-word cap.
- **Collect** — three notes in the template format above; flag where they
  disagree (e.g. one rates ops burden "low" that another rates "high").
- **Synthesize** — one integrated recommendation: a tradeoff table, the
  convergence points, the single contradiction, and one concrete next step.

The synthesizer integrates the notes; it does not concatenate them.

---

## Anti-patterns to avoid

- **Phantom parallelism**: sending agent calls in separate messages defeats
  concurrency. All independent calls go in one message.
- **Under-scoped prompts**: an agent with a vague brief returns vague notes.
  Each subagent prompt should be specific enough to stand alone.
- **Over-splitting**: more than 6 slices usually signals the decomposition
  is too fine-grained. Group related slices.
- **Synthesis as concatenation**: just gluing notes together is not
  synthesis. The synthesizer must integrate, resolve contradictions, and
  produce a unified view.
- **Skipping the collect step**: jumping straight from parallel launch to
  synthesis without explicitly reviewing notes misses contradictions.

---

## Scaling the pattern

For larger fan-outs (>6 slices), use a two-tier structure:

```
Meta-orchestrator
  ├── Cluster A orchestrator (owns slices A1–A3)
  ├── Cluster B orchestrator (owns slices B1–B3)
  └── Cluster C orchestrator (owns slices C1–C3)
Final synthesizer (merges cluster summaries)
```

Each cluster orchestrator runs its own fan-out internally and returns a
single cluster summary. The meta-orchestrator synthesizes cluster summaries
only.

---

## Notes on token budget

Each subagent call has its own context window. Prefer:
- Haiku 4.5 for worker agents doing narrow reads or searches
- Sonnet 4.6 for worker agents doing reasoning or code review
- Opus 4.6 for the synthesizer on high-stakes outputs

Set explicit output word caps in each subagent prompt to control note size.
