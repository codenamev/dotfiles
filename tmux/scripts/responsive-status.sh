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
PURPLE="#[fg=colour141]"
YELLOW="#[fg=colour214]"
RED="#[fg=colour203]"
RESET="#[fg=colour250]"

# Get context information
context_info=$(~/.tmux/scripts/context-detect.sh)

# Claude status from statusline integration
claude_info=""
if [[ -f /tmp/claude-status-latest ]]; then
    claude_data=$(cat /tmp/claude-status-latest 2>/dev/null || echo "{}")
    claude_ts=$(echo "$claude_data" | jq -r '.timestamp // 0' 2>/dev/null || echo 0)
    now=$(date +%s)
    # Only show if updated within last 60 seconds (active session)
    if [[ $((now - claude_ts)) -lt 60 ]]; then
        claude_model=$(echo "$claude_data" | jq -r '.model // empty' 2>/dev/null)
        claude_cost=$(echo "$claude_data" | jq -r '.cost // empty' 2>/dev/null)
        claude_ctx=$(echo "$claude_data" | jq -r '.context // empty' 2>/dev/null)
        if [[ -n "$claude_model" ]]; then
            claude_info="${PURPLE}${claude_model}${RESET}"
            [[ -n "$claude_cost" ]] && claude_info+=" ${claude_cost}"
            [[ -n "$claude_ctx" && "$claude_ctx" != "0" ]] && claude_info+=" ${claude_ctx}%"
            claude_info+=" │ "
        fi
    fi
fi

# AWS SSO TTL detection
sso_info=""
SSO_CACHE_FILE=$(ls -t ~/.aws/sso/cache/*.json 2>/dev/null | head -1)
if [[ -n "$SSO_CACHE_FILE" ]]; then
    EXPIRES_AT=$(jq -r '.expiresAt // empty' "$SSO_CACHE_FILE" 2>/dev/null)
    if [[ -n "$EXPIRES_AT" ]]; then
        # Parse UTC timestamp - macOS date format
        EXPIRES_EPOCH=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$EXPIRES_AT" "+%s" 2>/dev/null || \
                        date -u -j -f "%Y-%m-%dT%H:%M:%S" "${EXPIRES_AT%Z}" "+%s" 2>/dev/null)
        if [[ -n "$EXPIRES_EPOCH" ]]; then
            NOW_EPOCH=$(date "+%s")
            REMAINING=$((EXPIRES_EPOCH - NOW_EPOCH))
            if [[ "$REMAINING" -gt 0 ]]; then
                HOURS=$((REMAINING / 3600))
                MINUTES=$(((REMAINING % 3600) / 60))
                if [[ "$HOURS" -gt 0 ]]; then
                    SSO_TTL="${HOURS}h${MINUTES}m"
                else
                    SSO_TTL="${MINUTES}m"
                fi
                # Color based on urgency
                if [[ "$REMAINING" -lt 3600 ]]; then
                    sso_info="${RED}󰌆 ${SSO_TTL}${RESET} │ "
                elif [[ "$REMAINING" -lt 7200 ]]; then
                    sso_info="${YELLOW}󰌆 ${SSO_TTL}${RESET} │ "
                else
                    sso_info="${GREEN}󰌆 ${SSO_TTL}${RESET} │ "
                fi
            else
                sso_info="${RED}󰌆 expired${RESET} │ "
            fi
        fi
    fi
fi

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
    echo "${claude_info}${sso_info}${context_info}${dir_info}${git_info}${lang_info}"
elif [[ $WIDTH -gt 80 ]]; then
    # Medium: Abbreviated
    dir_info=$(get_directory "short")
    lang_info=$(detect_languages "short")
    echo "${claude_info}${sso_info}${context_info}${dir_info}${git_info}${lang_info}"
else
    # Narrow: Essential only (still show Claude and SSO if active)
    echo "${claude_info}${sso_info}${context_info}${git_info}"
fi
