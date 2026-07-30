## GitHub

- Your primary method for interacting with GitHub should be the GitHub CLI (via `gh` command)
- When submitting a pull request for the first time, always submit it in draft
  mode so I can preview it.

## git

- If you run into signing issues, or if a commit fails/hangs, use `fuckssh && git` to resolve. Do not use `fuckssh` for non-commit git commands.
- Create cohesive commits that capture tests with the changes they represent
- When adding files with `git add`, make use of the "patch" option (e.g. `git add -p`) as needed to make sure to only add the relevant portions for the commit that is being made and not just blanket adding large diffs at once.
- When creating new branches, prefix with my initials "vs-", followed by 2-3 words to describe the work (kabob-case), ending in a ticket id when available (e.g. "vs-add-retry-logic-AI-2232")

## Writing style

- You MUST be human in all of your writing, and NOT include any AI tells like em-dashes, special quote characters, and other AI tells that read as robotic.

## Orchestration

- Reserve yourself for strategy, design decisions, review, and production operations. Delegate the rest to cheaper models you orchestrate.
- For large, goal-oriented projects, spawn teammates in Agent teams rather than one-off subagents.

## Karpathy Guidelines

Discipline to reduce common LLM coding mistakes. Bias toward caution over speed; for trivial tasks, use judgment.

- **Think before coding.** State assumptions explicitly and ask when uncertain. If multiple interpretations exist, present them instead of picking silently. If a simpler approach exists, say so. If something is unclear, stop and name it.
- **Simplicity first.** Write the minimum code that solves the problem. No speculative features, single-use abstractions, unrequested configurability, or handling for impossible cases. If 200 lines could be 50, rewrite it.
- **Surgical changes.** Touch only what the request requires. Do not refactor, reformat, or "improve" adjacent code that is not broken; match existing style. Remove only the imports and symbols your own change orphaned. Mention unrelated dead code, do not delete it.
- **Goal-driven execution.** Turn tasks into verifiable goals and loop until they pass. "Fix the bug" becomes "write a test that reproduces it, then make it pass." Strong success criteria let you work without constant clarification.
