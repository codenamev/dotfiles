#!/usr/bin/env bash

# Basic starship status for tmux
# Version 1: Core functionality

set -euo pipefail

# Cache directory
CACHE_DIR="$HOME/.tmux/cache"
mkdir -p "$CACHE_DIR"

# Get current working directory from tmux
PWD=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null || pwd)
cd "$PWD" || exit 1

# Colors (tmux format)
BLUE="#[fg=colour117]"
GREEN="#[fg=colour2]"
ORANGE="#[fg=colour166]"
RESET="#[fg=colour250]"

# Initialize output
output=""

# Git status using starship logic
if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

    # Check git status
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        git_status="✗"
    else
        git_status="✓"
    fi

    output+="${GREEN} ${branch}${git_status}${RESET}"
fi

# Language detection
# Node.js
if [[ -f package.json ]] || [[ -f .nvmrc ]] || [[ -f .node-version ]]; then
    if command -v node >/dev/null 2>&1; then
        node_version=$(node --version | sed 's/v//')
        output+="${BLUE} ⬢${node_version}${RESET}"
    fi
fi

# Python
if [[ -f requirements.txt ]] || [[ -f setup.py ]] || [[ -f pyproject.toml ]] || [[ -f Pipfile ]]; then
    if command -v python >/dev/null 2>&1; then
        python_version=$(python --version 2>&1 | cut -d' ' -f2)
        output+="${BLUE} 🐍${python_version}${RESET}"
    fi
fi

# Ruby
if [[ -f Gemfile ]] || [[ -f .ruby-version ]]; then
    if command -v ruby >/dev/null 2>&1; then
        ruby_version=$(ruby --version | cut -d' ' -f2)
        output+="${BLUE} 💎${ruby_version}${RESET}"
    fi
fi

# Directory (shortened)
dir=$(basename "$PWD")
output=" ${ORANGE}~/${dir}${RESET}${output}"

echo "$output"
