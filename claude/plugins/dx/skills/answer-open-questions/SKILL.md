---
name: answer-open-questions
description: >-
  Sweep every open question, decision and unresolved commitment across the session's
  sources of record, then work them one at a time until the list is empty or everything
  left is genuinely blocked. Use when the user says "iteratively walk me through all
  questions or decisions you need answered", "what are you waiting on me for", "what's
  blocked on me", "clear the queue", "what do you need from me", or invokes
  /answer-open-questions. Also use unprompted at a natural pause when several decisions
  have accumulated. Not for a single known question, which you should just ask.
---

# Answer open questions

The user is the bottleneck by design. This skill exists because that bottleneck silts up:
decisions accumulate across the board, subsession mailboxes and the conversation itself,
and nobody is holding the whole list. Its job is to find them all, put them in an order,
and get them answered without wasting the user's attention.

**Two failures this skill exists to prevent, both observed:**

- A decision the user made was never recorded, and had to be reconstructed from the
  transcript an hour later.
- A decision the user made was acted on after its premise had already evaporated.

## 1. Sweep, before asking anything

Open questions hide in more places than the conversation. Check all of these:

- **The board.** Rows with `status=blocked` or `owner=<user>`, and rows whose note contains
  a question that never got an answer.
- **Subsession mailboxes.** Any window that asked something and is holding. A window sitting
  quiet is often a window waiting.
- **This conversation.** Questions you asked that got no answer, and questions you *should*
  have asked but talked past.
- **Commitments to other people.** Something the user told a colleague they would do, that
  has not happened. These rot silently and cost the most.
- **Decisions already made that new facts have invalidated.** This is the one everyone
  misses. Re-check the premise of every decision made earlier in the session before treating
  it as settled.

## 2. Filter: most of what you find is not for them

Cut, in this order:

- **Anything you can settle yourself.** Read the code, run the check, look it up. A question
  you could have answered by reading a file is a tax on their attention.
- **Anything routed elsewhere.** If the user put a topic in another window, it is not yours
  to re-ask. Say so and leave it.
- **Anything with a conventional default.** Pick it, state it, move on.

What survives is: irreversible, outward-facing, a genuine fork with different work behind
each arm, or a matter of the user's own preference.

## 3. Present the runway, then ask in small groups

Lead with a compact index, a table with one line each and what it blocks. They need to see
the size of the list before committing to it.

Then ask in groups of **at most four**, and only where the answers do not depend on each
other. A question whose options change depending on the previous answer waits for the next
group. Strict one-per-turn is the wrong trade: it turns eight decisions into eight round
trips, and the user is the scarce resource, not the turn count.

Each question:

- States the decision and what turns on it.
- Offers real, distinct options with the consequence of each. Not "yes/no/other".
- Puts your recommendation first and says it is your recommendation.
- Names what you already know, so they are not re-deriving it.
- Is answerable in one word by someone who has the context.

Order by what unblocks the most, but lead with anything cheap and finished, because clearing one
immediately buys attention for the rest. Put your own mistakes early; they are quick and
the user should not discover them at the end.

### Use AskUserQuestion, and use its previews

The tool renders up to four questions side by side and returns all the answers at once,
which is what makes a group cheaper than a sequence. Two things carry most of the weight:

- **`preview` on each option.** A monospace sketch of the actual diff, file tree, coverage
  table or command does more work than the label and description together. Show the change,
  do not describe it. Previews are single-select only.
- **Recommendation first, marked.** Put it in position one with `(Recommended)` in the label,
  and let the description say what it costs rather than why it is nice.

An option with no consequence written into it is not an option, it is a prompt for the user
to do your thinking.

## 4. Record every answer immediately

**Before asking the next group, write the answers down** in the board row, the ticket, or the
durable record. Not at the end of the sweep.

An answer that lives only in the transcript is lost at the next compaction. This is not
bookkeeping: a ruling that has to be reconstructed later gets reconstructed wrong.

Record what they chose, what they were told when they chose it, and what you recommended if
it differed. A future reader needs to know whether a decision was informed.

## 5. Do not treat an answer as wider than it is

- An answer to "should we do X" is not consent to the outward-facing step that follows.
  Rebase approved is not push approved. Push approved is not merge approved.
- If executing their answer requires an action they did not name, stop and ask for that too.
- If new information arrives between the question and the act, **the answer is void**. Go
  back. Do not execute a decision whose premise has changed, even five minutes later.

Voiding is not a formality. Say plainly that the answer is void, name the fact that killed
it, and do not act on it. A decision made on a dead premise is worse than an open question,
because it looks settled.

## 6. Close out

When the list is empty, say so plainly and state what remains blocked and on whom. If new
questions surfaced while working through the old ones, and they will, add them and keep going,
or say clearly that you are stopping with N outstanding.

## What good looks like

A user who can answer nine decisions in nine words, having been told exactly what each one
costs, and who finds every one of them correctly recorded tomorrow.
