---
name: session-task-tracker
description: Give each Claude Code session a task list that maintains itself across sessions and syncs to a shared Notion dashboard, with the agent recording its own work as it goes. Sets up the two-layer system (beans, a local graph-based tracker, plus Notion) and the automatic sync. Use this skill when a user wants to track tasks across Claude Code sessions, set up project tracking with Notion sync, configure beans, connect their Notion dashboard to local work, or asks about "beans", "task tracking", "notion workflow", "track my work", "session tracking", or "project dashboard". Also use when the user already has it set up and wants to sync items to Notion, check what's ready to work on, or do a session start/end handoff.
allowed-tools: [Read, Write, Edit, "Bash(beans)", "Bash(beans *)", "Bash(uv tool install magic-beans)", "Bash(mkdir *)", "Bash(cp *)", "Bash(chmod *)", "Bash(python3 *)"]
---

# Beans + Notion: Two-Layer Workflow Tracking

## The Idea

Most task tracking in Claude Code sessions is ephemeral -- it vanishes when the conversation ends. This skill sets up a system where:

- **Beans** handles the fast, local, in-session layer. It's a graph-based issue tracker where tasks are nodes and dependencies are edges. The CLI is designed for both humans and AI agents (`--json` on most commands: `list`, `ready`, `show`, `search`, `graph`, `stats` and `schema` all honour it, while `types` and `config` print plain text regardless). Verified against 0.7.0. It lives in a `.beans/` directory as a SQLite file -- no servers, no background processes, no network. Note that `beans init` now defaults to a registry store under `~/.local/share/beans/<project>` keyed on the git remote; `--dir` is what puts it in a local `.beans/`.

- **Notion** handles the persistent, shareable layer. Projects and tasks live in the user's Notion dashboard where they survive across sessions and can be shared with teammates for visibility and feedback.

The two layers connect through a **Bean ID** field in Notion that maps to the local beans ID. This link is what makes sync possible without either system "owning" the other.

**Why two layers instead of one?** Notion is great for persistence and sharing but has too much friction for the rapid create/claim/close/depend cycle during active development. Beans is great for that rapid cycle but disappears when you close the terminal. Together they cover both needs.

## What this automates (the value over the raw CLI)

Running beans by hand gives you a local tracker and nothing more. The value of this skill is the layer on top, which the CLI does not provide:

- **The agent operates the graph for you.** A behavioral contract written into the workspace `CLAUDE.md` (step 10) tells the agent to create or claim a bean when it starts a unit of work, close it with a commit or PR reference when it finishes, and model blockers as it finds them. You do not type beans commands; the agent tracks its own work as it goes.
- **State syncs to Notion on its own.** A deterministic script, `beans-notion-sync.py`, pushes the status, priority, and title of every already-linked bean to Notion on the Stop hook. It is diff-gated, so it is a no-op when nothing changed, and it never blocks a session.
- **You stay in the loop only for judgment.** The script moves mechanical state. Deciding which new beans deserve a Notion task, and publishing doc artifacts, stays with the agent, which is nudged at natural stopping points.

The division: beans is the substrate, the agent is the operator, the script is the courier, and you make the calls that need taste.

## Setup

Walk through these steps with the user. Each step has a checkpoint -- confirm it worked before moving on.

### 1. Install beans and configure permissions

The package is `magic-beans` on PyPI. The CLI command is `beans`.

```bash
# Best option: uv handles Python version automatically
uv tool install magic-beans
beans --help  # checkpoint: should show the CLI help
```

If `uv` isn't available, `pip install magic-beans` works but requires Python 3.12+.

If beans is already installed, skip the install. Check with `beans --help`.

**Permissions**: This skill's `allowed-tools` frontmatter pre-approves `beans` and `uv tool install magic-beans` while the skill is active. For ongoing use outside the skill, recommend the user add these to their `~/.claude/settings.json` permissions allow list:

```json
"Bash(beans)", "Bash(beans *)"
```

**Checkpoint:** `beans --help` runs without a permission prompt.

### 2. Initialize in the workspace

```bash
beans init --dir  # creates .beans/ in the current directory
```

Then add custom types to match the user's workflow. The defaults are task, bug, and epic. Common additions:

```bash
beans types add spike --description "Time-boxed investigation"
beans types add research --description "Research or gap analysis"
beans types add review --description "Code or design review"
```

Ask the user if they want other types. The type becomes part of the bean ID prefix (e.g., `spike-a3f2dd1c`), so keep them short.

**Checkpoint:** `beans types` should list all configured types.

### 3. Connect Notion

Search for the user's personal dashboard or workspace in Notion. If they already have a Projects and Tasks Tracker database structure, look for those first.

If no dashboard exists, ask whether to create a standalone database pair or skip Notion integration entirely (beans works fine standalone).

**Checkpoint:** You can fetch the dashboard and see its database structure.

### 4. Align Notion schemas

Fetch the Tasks Tracker data source schema and add any missing properties. The target schema:

| Property | Type | Purpose |
|---|---|---|
| Task name | Title | The task title |
| Status | Status | Not started / In progress / Done |
| Priority | Select | High (red) / Medium (yellow) / Low (green) |
| Effort level | Select | Small / Medium / Large |
| Task type | Multi-select | Match the bean types from step 2 (capitalized) |
| Bean ID | Rich text | The beans ID for sync linkage (e.g., `task-a3f2dd1c`) |
| Source Repo | Select | Populate with the user's repos |
| Due date | Date | Optional deadline |
| Projects | Relation | Link to the Projects database |

Use `notion-update-data-source` with DDL statements to add columns. Ask the user which repos belong in the Source Repo dropdown.

The Projects database usually doesn't need changes -- the default schema (name, status, priority, due date, tasks relation) covers most needs.

**Checkpoint:** Fetch the data source again and confirm the new columns appear.

### 5. Document Hub (optional)

If the user also wants to publish research/design docs to Notion instead of committing them to repo `docs/` folders, set up a Document Hub database with:

| Property | Type | Values |
|---|---|---|
| Doc name | Title | Free text, prefixed with `[AI]` for machine-generated docs |
| Category | Multi-select | Proposal, Research, Strategy doc, Planning, Design Spec, Gap Analysis, Experiment, Spike |
| Source Repo | Select | Same repos as Tasks Tracker |
| Status | Select | Draft / Review / Final / Archived |

Convention: robot emoji icon on AI-generated pages for visual distinction.

### 6. Save reference memory

This is what makes the setup durable across sessions. Save a memory file with:

- Dashboard page ID
- Tasks Tracker data source ID (`collection://...`)
- Projects data source ID (`collection://...`)
- Document Hub data source ID (if set up)
- The type, status, and priority mappings (see reference below)
- The beans CLI quick reference

Without this memory, future sessions won't know where to sync.

### 7. Test the round-trip

Create a bean, sync it to Notion, confirm it appears:

```bash
beans create "Test: verify beans-to-Notion sync" --type task
```

Then create the matching Notion task with the Bean ID set. Verify it shows in the dashboard. Clean up both sides when confirmed.

### 8. Configure hooks and permissions

Add hooks and beans permissions to the **project-level local settings** (`.claude/settings.local.json` in the workspace directory, not global user settings). This keeps the config scoped to this workspace and gitignored.

First, copy the sync check script from this skill's bundled scripts into the workspace hooks directory:

```bash
mkdir -p .claude/hooks
cp <skill-path>/scripts/beans-sync-check.sh .claude/hooks/beans-sync-check.sh
cp <skill-path>/scripts/beans-notion-sync.py .claude/hooks/beans-notion-sync.py
chmod +x .claude/hooks/beans-sync-check.sh
```

The `<skill-path>` is the directory containing this skill.md file. Use the absolute path when copying. Both scripts must land in the same directory: the Stop hook script calls the sync script from its own directory.

Then use the `/update-config` skill or edit `.claude/settings.local.json` directly. Merge with any existing content:

```json
{
  "permissions": {
    "allow": [
      "Bash(beans)",
      "Bash(beans *)",
      "Bash(uv tool install magic-beans)"
    ]
  },
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "beans ready 2>/dev/null || true",
            "statusMessage": "Checking beans..."
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "<absolute-path-to-workspace>/.claude/hooks/beans-sync-check.sh",
            "statusMessage": "Checking beans sync..."
          }
        ]
      }
    ]
  }
}
```

Replace `<absolute-path-to-workspace>` with the actual workspace path. The Stop hook command must be an absolute path.

This does three things:
- **Permissions**: All `beans` commands run without prompting in this workspace
- **SessionStart hook**: On every fresh session, `beans ready` output is injected into the agent's context automatically, so the agent sees what's unblocked before the user says anything
- **Stop hook**: After every response, the hook runs the deterministic beans->Notion state push (diff-gated, silent when nothing changed), then injects a compact status line. The agent is nudged to promote unlinked beans and publish doc artifacts at a natural stopping point, not on every turn. The script guards against loops via `stop_hook_active`.

**Checkpoint:** Start a new session (or ask the user to restart). The agent should see the `beans ready` output in its context without being asked.

### 9. Configure the deterministic Notion sync

The mechanical push (`beans-notion-sync.py`) needs two things; until both are set it stays silent, so sync is simply off rather than broken.

1. **A Notion integration token.** Create an internal integration at notion.so/my-integrations, share the Tasks Tracker database with it, and export the token as `NOTION_TOKEN`. The sync script and Stop hook read it from the process environment, so it has to be exported there. **Put it in your shell profile (`~/.zshrc`, `~/.bashrc`, or equivalent), not in a file inside the repo** — that keeps the credential out of the working tree entirely, so there is nothing to accidentally commit. The hook does not source a `.env` file on its own, so a workspace `.env` is both riskier and won't work unless your tooling exports it; if you use one anyway, add the exact line `.env` to the workspace `.gitignore` first (verify it is ignored with `git check-ignore .env`) so the credential is never committed.
2. **The database UUID.** This is the raw-API id of the Tasks Tracker database, a UUID, distinct from the `collection://...` id the Notion MCP uses. Take it from the database URL (the 32-char hex before `?v=`). Write the sync config to `.beans/notion-sync.config.json`:

   ```json
   {
     "database_id": "<32-char-uuid>",
     "properties": { "bean_id": "Bean ID", "title": "Task name", "status": "Status", "priority": "Priority" },
     "status_map": { "open": "Not started", "in_progress": "In progress", "closed": "Done" },
     "priority_map": { "0": "High", "1": "High", "2": "Medium", "3": "Low", "4": "Low" }
   }
   ```

   The maps and property names default to these values; include them only to override. Property names must match the Notion schema from step 4.

**Checkpoint:** with the token set and a linked bean whose status differs from Notion, `python3 .claude/hooks/beans-notion-sync.py --verbose` reports a task updated; with nothing changed, it is silent.

### 10. Write the autonomous-operation contract (CLAUDE.md)

This is what makes the agent operate beans on its own rather than waiting for commands. Add a block to your **personal** instruction file, not a shared one. In a solo workspace the workspace `CLAUDE.md` is fine; in a shared repo or monorepo, put it in a personal/untracked file instead (`CLAUDE.local.md`, or `~/.claude/CLAUDE.md`) so you are not imposing autonomous bean operation on every other contributor's agent without their consent. Keep it short and imperative:

```markdown
## Beans task tracking (operate autonomously)

Keep the local beans graph current as you work, without being asked:
- When you begin a distinct unit of work, `beans create` it (or `beans claim` an
  existing bean) and let it sit in_progress.
- When you finish, `beans close <id> --reason "<commit or PR>"`.
- Model a blocker with `beans dep add <blocker> <blocked>` the moment you find it.
- Break a large effort into child beans under an epic.

Linked beans sync to Notion automatically. At a natural stopping point, promote
the unlinked beans worth sharing (create the Notion task, set its Bean ID) and
publish any doc artifacts to the Document Hub.
```

**Checkpoint:** in a fresh session, give the agent a small task and watch it create and later close a bean on its own.

## Mapping Reference

These mappings translate between beans and Notion. They're used during every sync operation.

### Status
| Beans | Notion |
|---|---|
| open | Not started |
| in_progress | In progress |
| closed | Done |

### Priority
| Beans (0-4 scale) | Notion |
|---|---|
| 0-1 | High |
| 2 | Medium |
| 3-4 | Low |

### Types
| Beans | Notion |
|---|---|
| task | Task |
| bug | Bug |
| epic | Epic (or create as a Notion Project for large initiatives) |
| spike | Spike |
| research | Research |
| review | Review |

### Linking
- **Notion -> Beans**: The "Bean ID" text field stores the beans ID
- **Beans -> Notion**: The `ref_id` model field can store the Notion page ID (note: not yet exposed via CLI `update`, so the Notion-side link is the primary one)

## Session Workflow

After setup, this runs mostly on its own. The pattern below is what the agent does autonomously (per the step 10 contract), not a list of commands you type.

### Session start

`beans ready` is injected automatically by the SessionStart hook, so the agent opens each session already knowing what is unblocked, and claims what it is about to work on rather than waiting to be told.

### During the session (agent-operated)

As the agent works, it keeps the graph current without being asked:

```bash
beans create "Title" --type task                # new work surfaces
beans create "Subtask" --parent epic-<id>       # break a unit of work down
beans dep add <blocker-id> <blocked-id>         # model a blocker as it appears
beans close <id> --reason "Done in <commit/PR>"  # close on completion
```

You can still drive beans by hand any time; the point is that you no longer have to. Meanwhile the status, priority, and title of any bean already linked to Notion is pushed there automatically on the Stop hook, diff-gated so it costs nothing when nothing changed.

### Session end (the judgment layer)

The mechanical state sync has already happened. What is left is the judgment the script deliberately does not make, and the agent handles it at the stopping point:

1. **Promote** the new beans worth tracking across sessions or sharing with people (not every sub-task), creating the Notion task and setting its Bean ID so the script keeps it current from then on.
2. **Publish** any research or design artifacts to the Document Hub.
3. **Update** project-level status in Notion if a milestone shifted.

Beans holds the full granular breakdown locally; Notion holds what matters between sessions and to other people.

## Beans CLI Quick Reference

```bash
# Query
beans list                                # all beans
beans ready                               # unblocked, ready to work on
beans show <id>                           # one summary line (text output omits deps)
beans --json show <id>                    # full record, incl. blocks / blocked_by
beans search "query"                      # search title and body
beans stats                               # counts by status, type, assignee
beans graph                               # dependency tree

# Create and update
beans create "Title" --type task          # new bean
beans create "Title" --parent <epic-id>   # child of an epic
beans update <id> --title "New title"     # modify fields
beans close <id> --reason "why"           # close with reason

# Assignment
beans claim <id> --actor <name>           # claim (sets in_progress)
beans release <id> --actor <name>         # unclaim (sets open)

# Dependencies
beans dep add <blocker> <blocked>         # blocker must close first
beans dep remove <from> <to>              # remove dependency

# Types
beans types                               # list configured types
beans types add <name> --description "..."# add custom type

# Machine-readable
beans --json list                         # JSON output (most commands, not types/config)
beans --json --fields id,title,status list # specific fields
beans schema                              # JSON schemas for all models
```
