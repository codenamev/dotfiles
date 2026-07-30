#!/usr/bin/env bash
# Symlink the portable Claude Code customizations into ~/.claude and ~/.local/bin.
# Idempotent: re-running is safe. Existing non-symlink files are backed up to *.bak.
#
# Intentionally NOT handled here (kept local / machine-specific):
#   - ~/.claude/settings.json   (see settings.shared.json for the portable baseline;
#                                kept local because setup commands and plugin
#                                installers write to it directly)
#   - ~/.claude/CLAUDE.md       (keep local; add `@~/dotfiles/claude/CLAUDE.shared.md`
#                                as its first line, then your local/plugin blocks)
set -o errexit -o nounset -o pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Target config dir; override for alternate setups, e.g. CLAUDE_DIR=~/.claude-zar ./install.sh
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
BIN_DIR="$HOME/.local/bin"

link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "  ok    $dest"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.bak"
    echo "  back  $dest -> $dest.bak"
  fi
  ln -s "$src" "$dest"
  echo "  link  $dest"
}

echo "Linking portable Claude customizations from $SRC_DIR"
link "$SRC_DIR/rules/performance.md"          "$CLAUDE_DIR/rules/performance.md"
link "$SRC_DIR/output-styles/navigator.md"    "$CLAUDE_DIR/output-styles/navigator.md"
link "$SRC_DIR/output-styles/keeper-voice.md" "$CLAUDE_DIR/output-styles/keeper-voice.md"
link "$SRC_DIR/file-suggestion.sh"            "$CLAUDE_DIR/file-suggestion.sh"
link "$SRC_DIR/statusline/starship.toml"      "$CLAUDE_DIR/starship.toml"
link "$SRC_DIR/statusline/starship-claude"    "$BIN_DIR/starship-claude"

# Optional: RTK command-rewrite hook. The hook self-guards if rtk/jq are absent,
# so the symlink is harmless even without RTK installed (see RTK.md).
link "$SRC_DIR/hooks/rtk-rewrite.sh"          "$CLAUDE_DIR/hooks/rtk-rewrite.sh"

echo
echo "Done. Remaining manual steps:"
echo "  - $CLAUDE_DIR/CLAUDE.md: ensure first line is  @$SRC_DIR/CLAUDE.shared.md"
echo "  - $CLAUDE_DIR/settings.json: copy desired keys from settings.shared.json"
