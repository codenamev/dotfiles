#!/usr/bin/env bash

# Responsive starship status for tmux
# Adapts content based on terminal width

set -euo pipefail

# Source cache manager
source ~/.tmux/scripts/cache-manager.sh

# Get terminal width
WIDTH=$(tmux display-message -p '#{window_width}' 2>/dev/null || echo 80)

# Get current working directory from tmux
PWD=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null || pwd)
cd "$PWD" || exit 1

# Colors
BLUE="#[fg=colour117]"
GREEN="#[fg=colour2]"
ORANGE="#[fg=colour166]"
RESET="#[fg=colour250]"

# Get context information
context_info=$(~/.tmux/scripts/context-detect.sh)

# Initialize components
git_info=""
lang_info=""
dir_info=""

# Git status with caching
git_status_cached=$(get_git_status "$PWD")
if [[ -n "$git_status_cached" ]]; then
    git_info="${GREEN} ${git_status_cached}${RESET}"
fi

# Language detection with responsive formatting
detect_languages() {
    local format="$1"  # "full", "short", or "minimal"
    local output=""

    # Node.js
    if [[ -f package.json ]] || [[ -f .nvmrc ]] || [[ -f .node-version ]]; then
        if command -v node >/dev/null 2>&1; then
            if [[ "$format" == "full" ]]; then
                node_version=$(node --version | sed 's/v//')
                output+="${BLUE} ⬢v${node_version}${RESET}"
            elif [[ "$format" == "short" ]]; then
                node_version=$(node --version | sed 's/v//' | cut -d'.' -f1,2)
                output+="${BLUE} ⬢${node_version}${RESET}"
            fi
        fi
    fi

    # Python
    if [[ -f requirements.txt ]] || [[ -f setup.py ]] || [[ -f pyproject.toml ]] || [[ -f Pipfile ]]; then
        if command -v python >/dev/null 2>&1; then
            if [[ "$format" == "full" ]]; then
                python_version=$(python --version 2>&1 | cut -d' ' -f2)
                output+="${BLUE} 🐍${python_version}${RESET}"
            elif [[ "$format" == "short" ]]; then
                python_version=$(python --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
                output+="${BLUE} 🐍${python_version}${RESET}"
            fi
        fi
    fi

    # Ruby
    if [[ -f Gemfile ]] || [[ -f .ruby-version ]]; then
        if command -v ruby >/dev/null 2>&1; then
            if [[ "$format" == "full" ]]; then
                ruby_version=$(ruby --version | cut -d' ' -f2)
                output+="${BLUE} 💎${ruby_version}${RESET}"
            elif [[ "$format" == "short" ]]; then
                ruby_version=$(ruby --version | cut -d' ' -f2 | cut -d'.' -f1,2)
                output+="${BLUE} 💎${ruby_version}${RESET}"
            fi
        fi
    fi

    echo "$output"
}

# Directory info with responsive truncation
get_directory() {
    local format="$1"
    if [[ "$format" == "full" ]]; then
        echo "${ORANGE}~/${PWD#$HOME/}${RESET}"
    elif [[ "$format" == "short" ]]; then
        echo "${ORANGE}~/$(basename "$PWD")${RESET}"
    else
        echo ""
    fi
}

# Build status based on width
if [[ $WIDTH -gt 120 ]]; then
    # Wide: Full info
    dir_info=$(get_directory "full")
    lang_info=$(detect_languages "full")
    echo "${context_info}${dir_info}${git_info}${lang_info}"
elif [[ $WIDTH -gt 80 ]]; then
    # Medium: Abbreviated
    dir_info=$(get_directory "short")
    lang_info=$(detect_languages "short")
    echo "${context_info}${dir_info}${git_info}${lang_info}"
else
    # Narrow: Essential only
    echo "${context_info}${git_info}"
fi
