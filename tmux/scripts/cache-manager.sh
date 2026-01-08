#!/usr/bin/env bash

# Cache manager for tmux starship status
# Provides intelligent caching for expensive operations

set -euo pipefail

CACHE_DIR="$HOME/.tmux/cache"
mkdir -p "$CACHE_DIR"

# Cache key generation
cache_key() {
    local type="$1"
    local context="$2"
    echo "${CACHE_DIR}/${type}_$(echo -n "$context" | md5sum | cut -d' ' -f1)"
}

# Check if cache is valid
cache_valid() {
    local cache_file="$1"
    local max_age="${2:-5}"  # Default 5 seconds

    if [[ -f "$cache_file" ]]; then
        local file_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0)))
        [[ $file_age -lt $max_age ]]
    else
        return 1
    fi
}

# Get cached value or compute new one
get_or_compute() {
    local type="$1"
    local context="$2"
    local compute_cmd="$3"
    local max_age="${4:-5}"

    local cache_file
    cache_file=$(cache_key "$type" "$context")

    if cache_valid "$cache_file" "$max_age"; then
        cat "$cache_file"
    else
        # Compute new value
        local result
        result=$(eval "$compute_cmd" 2>/dev/null || echo "")
        echo "$result" > "$cache_file"
        echo "$result"
    fi
}

# Git status with caching (cache for 5 seconds or until .git changes)
get_git_status() {
    local pwd="$1"
    local git_dir="$pwd/.git"

    if [[ -d "$git_dir" ]]; then
        local git_mtime
        git_mtime=$(find "$git_dir" -type f -name "HEAD" -o -name "index" | xargs stat -c %Y 2>/dev/null | sort -n | tail -1 || echo 0)
        local cache_file
        cache_file=$(cache_key "git" "$pwd")

        if [[ -f "$cache_file" ]]; then
            local cache_mtime
            cache_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
            if [[ $cache_mtime -gt $git_mtime ]]; then
                cat "$cache_file"
                return
            fi
        fi

        # Compute git status
        cd "$pwd" || return
        local branch
        branch=$(git branch --show-current 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "")

        local git_state
        if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            git_state="✗"
        else
            git_state="✓"
        fi

        local result="${branch}${git_state}"
        echo "$result" > "$cache_file"
        echo "$result"
    fi
}

# Language version with caching (cache for 60 seconds)
get_language_version() {
    local language="$1"
    local pwd="$2"

    get_or_compute "lang_${language}" "$pwd" "command -v $language >/dev/null && $language --version | head -1" 60
}

# Export functions for use by other scripts
export -f cache_key cache_valid get_or_compute get_git_status get_language_version
