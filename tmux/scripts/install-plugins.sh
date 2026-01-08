#!/usr/bin/env bash

# Install and configure tmux plugins

set -euo pipefail

echo "Installing tmux plugins..."

# Install TPM if not present
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
    echo "Installing TPM (Tmux Plugin Manager)..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Check if tmux is running
if tmux info &> /dev/null; then
    echo "Tmux is running. Installing plugins..."
    ~/.tmux/plugins/tpm/scripts/install_plugins.sh
else
    echo "Tmux is not running. Please start tmux and press prefix + I to install plugins."
fi

echo "Plugins configured successfully!"
echo ""
echo "To install/update plugins:"
echo "  1. Start tmux"
echo "  2. Press prefix + I (Ctrl-a + Shift-I)"
echo ""
echo "Configured plugins:"
echo "  - tmux-sensible: Basic tmux settings everyone can agree on"
echo "  - tmux-resurrect: Restore tmux environment after system restart"
echo "  - tmux-continuum: Automatic tmux environment save/restore"
echo "  - tmux-yank: Copy to system clipboard"
echo "  - tmux-fzf: Fuzzy finder for tmux"
echo "  - tmux-copycat: Enhanced search and copy"
