# Claude Code customizations

Portable, non-proprietary Claude Code config. Machine-specific, secret, and
work-specific pieces are deliberately excluded and stay local in `~/.claude`.

## What's here

| Path | Purpose | Wired up by |
|------|---------|-------------|
| `CLAUDE.shared.md` | Portable global instructions (GitHub, git, writing style) | `@`-include from `~/.claude/CLAUDE.md` |
| `rules/performance.md` | Model-selection guidance | symlink |
| `output-styles/navigator.md` | Navigator strong-style pairing output style | symlink |
| `file-suggestion.sh` | Fast `@file` autocomplete helper | symlink + `fileSuggestion` in settings |
| `statusline/starship.toml` | Catppuccin statusline theme | symlink to `~/.claude/starship.toml` |
| `statusline/starship-claude` | Statusline renderer (model, cost, context bar) | symlink to `~/.local/bin/`, `statusLine` in settings |
| `hooks/rtk-rewrite.sh` | RTK command-rewrite hook (optional) | symlink; self-guards if RTK absent |
| `RTK.md` | RTK tool reference (optional) | `@`-include from local CLAUDE.md if used |
| `settings.shared.json` | Portable settings baseline (reference, not symlinked) | copy keys manually |

## Install

```bash
./claude/install.sh
```

Symlinks the portable files into `~/.claude` and `~/.local/bin` (existing
non-symlink files are backed up to `*.bak`). Idempotent.

Then, two manual steps the installer cannot safely automate:

1. **`~/.claude/CLAUDE.md`** — keep it local; make its first line:
   ```
   @~/dotfiles/claude/CLAUDE.shared.md
   ```
   followed by any local or plugin-managed blocks. The shared file holds the
   portable instructions; the local file holds machine and work-specific glue.

2. **`~/.claude/settings.json`** — copy the keys you want from
   `settings.shared.json`. The live file stays local because setup commands and
   plugin installers write to it directly.

## Intentionally excluded (stays local / never committed)

- **Secrets:** `.credentials.json`, `auth-cache.json`, `*-auth-*`
- **State / transient:** `projects/`, `plugins/`, `*.sqlite3*`, `history.jsonl`,
  `file-history/`, caches, `sessions/`, `telemetry/`, `shell-snapshots/`
- **Work-specific:** private plugin marketplaces and their configs, work-specific
  `env` vars, and any work-specific blocks in `CLAUDE.md`
- **Personal analytics**

Run a content and commit-author audit before pushing this repo anywhere public.
