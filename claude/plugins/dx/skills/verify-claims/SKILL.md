---
name: verify-claims
description: >-
  Scientific-rigor self-check for interpreting experiments and stating findings.
  Use BEFORE drawing a conclusion from data, asserting or interpreting statistical
  significance, declaring a result supported / refuted / inconclusive, finalizing a
  recommendation, or wording a claim in docs or to the user. Catches: reading an
  underpowered or ceilinged null as a real negative; over-claiming in EITHER the
  optimistic or the skeptical direction; equivalence / CI-vs-threshold confusion;
  favorable-by-construction metrics; and generalizing beyond what was tested.
  Triggers on moments like "the results show", "this proves/disproves", "no
  significant effect", "X is refuted/supported", "I conclude", "my recommendation is".
  Applies at conclusion time to a claim you are about to make, whatever the medium;
  to audit claims already written into a finished document, use doc-claim-review.
---

# Verify Claims — rigor check at conclusion time

Run this the moment you are about to commit a conclusion, a verdict
(supported/refuted/inconclusive), a statistic, or a recommendation — in docs or to
the user. Re-examine the claim *after* this check; revise the wording or add the caveat.

**Ship the revised claim, not the checking.** The check is yours; its result is the
reader's. If the check confirmed the claim, say the claim and nothing about the check: a
plain assertion already claims to be observed, so "verified", "measured not inferred" and
"I checked it myself" report on you rather than on the thing. If the check changed the
claim, the corrected claim is the whole report; skip the before. If the check left the
claim unsupported, the caveat *is* the outcome and it ships — that is this skill's entire
point and it is not what gets cut.

Where the checking goes instead: when a check taught you something a later session would
want, write it to your memory store as one fact, and link it. A check that changed a claim
is worth a memory; a check that confirmed one is worth nothing to anybody.

Where a project has a deterministic claims gate of its own — a script that mechanically
audits assertions — this is its human-judgment counterpart, for the calls a gate can't
make. Nothing below depends on one existing.

Each item is a yes/no. If you can't answer "yes," fix the claim, don't ship it.

## Step 0 — the timing failure (run this BEFORE you write the sentence, not after)

> The recurring failure mode is **wording first, checking second**: you draft "X is reasoning-
> justified" / "the module doesn't help" / "oracle is worse on fetch", *then* (maybe) verify.
> By then the narrative is anchored. Invoke this check at the moment you reach for the claim —
> before the sentence exists. Three preconditions that are part of the check, not optional extras:
> - **Read the raw thing.** If the claim rests on a count, a field, a score, or a label —
>   open and READ a sample of the underlying content/outputs. (Counting `reasoning_chain:`
>   ≠ reading what it says; a green scorer ≠ a correct scorer; a grep fragment ≠ the full review.)
> - **Compute the asserted stat.** If you're about to write "tracks / cancels / below / not
>   significant / equivalent / most of", compute the CI/Δ/correlation it names first.
> - **Execute every guardrail your pre-registration listed.** If a PREREGISTRATION*.md exists for
>   this experiment, its "validity guardrails" are a BLOCKING checklist — run each one and record
>   the outcome before wording the result, even the ones you're sure will pass. (Real miss: a
>   through-gateway result was written while its own pre-registered "verify top-k == top-1" check
>   sat unrun — it passed, but writing-before-running is the failure regardless of outcome.)
>
> If you have not done all three, you are not ready to word the finding. Do them, *then* the checklist.

## 1. Null results
- [ ] Is "no effect found" actually no effect — or an **underpowered** test (small N, wide CI, few discordant pairs) or a **ceiling/floor** (baseline already at 100%/0%, no headroom)?
- [ ] A test that *couldn't* have shown the effect is **inconclusive, not negative.**

## 2. Statistics before narrative
- [ ] Did I compute the stat I'm about to assert (CI, paired Δ, correlation, ablation) — not just eyeball it?
- [ ] Does the **CI actually exclude the threshold/zero**, or only the point estimate? "Not significant" ≠ "equals zero."
- [ ] For an **equivalence** claim: does the CI fall *entirely within* the band? A near-zero mean with a wide CI is INCONCLUSIVE, not equivalent.

## 3. Over-claiming — both directions
- [ ] Optimistic: am I stating something unproven as fact? Did I pick the flattering cell/metric?
- [ ] **Skeptical: am I over-stating a limitation or calling something "refuted" when it's merely untested/inconclusive?** (Skeptical over-claim is still over-claim.)

## 4. Metric validity
- [ ] Is the metric **favorable by construction** (does it reward exactly what the intervention injects)? If so, scope the claim to it; don't generalize.
- [ ] Did I read a sample of the raw outputs to confirm the scorer/check is measuring what I think?

## 5. Scope
- [ ] Is the claim scoped to what was actually tested (model / task / N / metric / domain)? Did I generalize beyond the rung I ran?
- [ ] Pre-registered thresholds are met or missed — binary, not "partially held."

## 6. The two closing questions (always)
- [ ] **Does this change anything I did or didn't do?**
- [ ] **Does it change my recommendation?** (It doesn't have to — but I should be confident, and say "inconclusive" plainly when it is.)

> Default posture: we are scientists, we follow the evidence, and we do not state the
> unproven as fact or definitive — in either direction.
