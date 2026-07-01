---
name: name-variable
description: Use when the user needs help naming a variable, function, class, constant, or any code identifier. Use when user says "name this", "what should I call", "good name for", "better name", or invokes /name-variable.
---

# Name Variable

A word nerd for your codebase. Finds the precise, evocative name that makes code read like well-written prose.

## Process

1. **Understand the concept** — ask what the thing *is*, not just what it *does*. A name should capture the essential nature.

2. **Mine the semantic field.** For whatever concept the user describes, explore:
   - **Synonyms & near-synonyms**: What are all the words for this idea? (`remove` vs `delete` vs `purge` vs `evict` vs `expunge` — each implies different permanence and force)
   - **Metaphors in use**: What metaphor does the codebase already use? (Is it a pipeline? A queue? A ledger? Stay in-world.)
   - **Specificity ladder**: Move up and down the abstraction ladder. Too vague? Go concrete. Too narrow? Go general. (`items` -> `line_items` -> `unbilled_line_items`)
   - **Temporal/state distinctions**: Does the name need to convey *when* or *what phase*? (`raw_input` vs `sanitized_input` vs `validated_input` — three stages, three names)

3. **Present options as a ranked menu** with the *word nerd rationale* for each:

   | Pick | Name | Rationale |
   |------|------|-----------|
   | 1 | `stale_sessions` | "Stale" implies expired-but-not-yet-cleaned-up — exactly the limbo state you described |
   | 2 | `expired_sessions` | More literal, but loses the nuance that they're still lingering |
   | 3 | `zombie_sessions` | Vivid — use if the team already uses "zombie" metaphors elsewhere |

4. **Call out traps** — only when the user is about to fall into one:
   - **Vague catch-alls**: `data`, `info`, `result`, `temp`, `stuff` — these are the "nice" of variable names, they mean nothing
   - **Verb confusion**: `process`, `handle`, `manage`, `do` — what *specifically* does it do? (`validate`, `transform`, `route`, `dispatch`)
   - **False friends**: words that *sound* right but mislead (`execute` for something that just enqueues, `sync` for something that's one-directional)

## Word Nerd Arsenal

### Verbs (pick the one that says what you mean)

**Getting things:**
`fetch` (go get from elsewhere) · `retrieve` (find and return from storage) · `resolve` (figure out which one) · `extract` (pull out of a larger thing) · `derive` (compute from other values) · `lookup` (quick index hit) · `poll` (ask repeatedly) · `hydrate` (fill in from external source)

**Changing things:**
`transform` (reshape) · `normalize` (make consistent) · `sanitize` (make safe) · `enrich` (add more data) · `reconcile` (make two things agree) · `coerce` (force into shape) · `marshal` (prepare for transport) · `redact` (remove sensitive parts)

**Checking things:**
`validate` (is it correct?) · `verify` (prove it's true) · `assert` (crash if wrong) · `inspect` (look at details) · `audit` (check for compliance) · `probe` (test if responsive)

**Removing things:**
`remove` (general) · `delete` (permanent) · `purge` (bulk cleanup) · `evict` (kick out of cache/memory) · `revoke` (take back permission) · `expire` (time-based removal) · `tombstone` (mark dead, don't actually delete)

**Lifecycle:**
`initialize` / `bootstrap` (setup) · `spawn` / `launch` (create and start) · `suspend` / `pause` (stop temporarily) · `resume` (continue) · `drain` (finish in-flight, stop accepting new) · `teardown` / `dispose` (cleanup) · `finalize` (last step before done)

### Adjectives & States

**Readiness:** `pending` · `staged` · `queued` · `deferred` · `provisional` · `tentative`
**Validity:** `stale` · `dirty` · `pristine` · `canonical` · `authoritative` · `ephemeral`
**Completeness:** `partial` · `sparse` · `exhaustive` · `truncated` · `saturated`

### Collection Qualifiers

Instead of just `users`, what *kind* of collection?
`pool` (reusable set) · `batch` (grouped for processing) · `roster` (named members) · `registry` (lookup table) · `manifest` (shipping list) · `ledger` (record of transactions) · `backlog` (waiting to be worked) · `cohort` (grouped by shared trait)
