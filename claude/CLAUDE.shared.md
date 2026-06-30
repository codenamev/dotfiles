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
