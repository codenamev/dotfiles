# Tmux + Starship Integration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Integrate starship prompt information into tmux status bar while adding modern terminal features and responsive design.

**Architecture:** Hybrid approach keeping tmux session/window management on left/center, adding starship-powered git/language info on right. Custom shell script calls starship modules and formats output for tmux consumption with intelligent caching and responsive design.

**Tech Stack:** tmux, starship, bash scripting, tmux plugins (tpm, continuum, yank, fzf), true color terminal support

---

## Phase 1: Foundation Setup

### Task 1: Directory Structure & Dependencies

**Files:**
- Create: `~/.tmux/scripts/`
- Create: `~/.tmux/themes/`
- Modify: `tmux.conf`

**Step 1: Create tmux directory structure**

```bash
mkdir -p ~/.tmux/scripts
mkdir -p ~/.tmux/themes
```

**Step 2: Backup current tmux config**

```bash
cp ~/.tmux.conf ~/.tmux.conf.backup
```

**Step 3: Verify tmux and starship are available**

Run: `tmux -V && starship --version`
Expected: Version numbers for both tools

**Step 4: Install Tmux Plugin Manager if not present**

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

**Step 5: Commit directory structure**

```bash
git add -A
git commit -m "feat: create tmux scripts and themes directories"
```

### Task 2: Modern Terminal Features

**Files:**
- Modify: `tmux.conf:6-8`
- Modify: `tmux.conf:125-137` (plugin section)

**Step 1: Add true color support**

Add after line 8 in `tmux.conf`:
```bash
# True color support
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"
set -ag terminal-overrides ",*256col*:RGB"
```

**Step 2: Enable mouse support**

Add after true color section:
```bash
# Mouse support
set -g mouse on
```

**Step 3: Update clipboard integration**

Add after mouse support:
```bash
# Enhanced clipboard
set -g set-clipboard on
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'pbcopy'
bind-key -T copy-mode-vi r send-keys -X rectangle-toggle
```

**Step 4: Add enhanced plugins**

Replace plugin section (lines 125-137) with:
```bash
# Plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'sainnhe/tmux-fzf'
set -g @plugin 'tmux-plugins/tmux-copycat'

# Plugin settings
set -g @continuum-restore 'on'
set -g @resurrect-strategy-vim 'session'
set -g @resurrect-strategy-nvim 'session'

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'
```

**Step 5: Test tmux config reload**

Run: `tmux source-file ~/.tmux.conf`
Expected: No errors

**Step 6: Commit modern features**

```bash
git add tmux.conf
git commit -m "feat: add true color, mouse support, and enhanced plugins"
```

## Phase 2: Core Starship Integration

### Task 3: Color Theme Configuration

**Files:**
- Create: `~/.tmux/themes/starship-colors.conf`

**Step 1: Create color theme file**

```bash
# Starship-coordinated color theme
# Based on existing orange/gray scheme + starship palette

# Base colors
set -g @orange '#ff9500'
set -g @dark_gray '#1e1e2e'
set -g @light_gray '#6c6f85'
set -g @bright_blue '#89b4fa'
set -g @bright_green '#a6e3a1'
set -g @bright_red '#f38ba8'
set -g @bright_yellow '#f9e2af'

# Status bar colors
set -g status-style bg=colour235,fg=colour250
set -g status-left-style fg=colour229,bg=colour166
set -g status-right-style fg=colour250,bg=colour235

# Window status colors
set -g window-status-style fg=colour250,bg=colour235
set -g window-status-current-style fg=colour117,bg=colour31
```

**Step 2: Source color theme in tmux.conf**

Add after line 123 in `tmux.conf`:
```bash
# Load color theme
source-file ~/.tmux/themes/starship-colors.conf
```

**Step 3: Test color reload**

Run: `tmux source-file ~/.tmux.conf`
Expected: Colors applied without errors

**Step 4: Commit color theme**

```bash
git add ~/.tmux/themes/starship-colors.conf tmux.conf
git commit -m "feat: add starship-coordinated color theme"
```

### Task 4: Basic Starship Status Script

**Files:**
- Create: `~/.tmux/scripts/starship-status.sh`

**Step 1: Create basic status script**

```bash
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
```

**Step 2: Make script executable**

Run: `chmod +x ~/.tmux/scripts/starship-status.sh`

**Step 3: Test script manually**

Run: `~/.tmux/scripts/starship-status.sh`
Expected: Formatted output with current directory and git/language info

**Step 4: Update tmux status-right**

Modify `tmux.conf` around lines 85-87:
```bash
# Enhanced status right with starship integration
set -g status-right '#(~/.tmux/scripts/starship-status.sh)'
set -g status-right-length 150
set -g status-interval 5
```

**Step 5: Test in tmux session**

Run: `tmux source-file ~/.tmux.conf`
Expected: Status bar shows directory and detected language/git info

**Step 6: Commit basic integration**

```bash
git add ~/.tmux/scripts/starship-status.sh tmux.conf
git commit -m "feat: add basic starship status integration"
```

## Phase 3: Responsive Design

### Task 5: Window Width Detection

**Files:**
- Create: `~/.tmux/scripts/responsive-status.sh`
- Modify: `tmux.conf` (status-right line)

**Step 1: Create responsive status script**

```bash
#!/usr/bin/env bash

# Responsive starship status for tmux
# Adapts content based on terminal width

set -euo pipefail

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

# Initialize components
git_info=""
lang_info=""
dir_info=""

# Git status
if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
        git_status="✗"
    else
        git_status="✓"
    fi

    git_info="${GREEN} ${branch}${git_status}${RESET}"
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
    echo "${dir_info}${git_info}${lang_info}"
elif [[ $WIDTH -gt 80 ]]; then
    # Medium: Abbreviated
    dir_info=$(get_directory "short")
    lang_info=$(detect_languages "short")
    echo "${dir_info}${git_info}${lang_info}"
else
    # Narrow: Essential only
    echo "${git_info}"
fi
```

**Step 2: Make script executable**

Run: `chmod +x ~/.tmux/scripts/responsive-status.sh`

**Step 3: Test responsive behavior**

Run: `~/.tmux/scripts/responsive-status.sh`
Expected: Output varies based on terminal width

**Step 4: Update tmux to use responsive script**

Modify `tmux.conf` status-right:
```bash
set -g status-right '#(~/.tmux/scripts/responsive-status.sh)'
```

**Step 5: Test window resizing**

Run: `tmux source-file ~/.tmux.conf`
Then resize terminal window
Expected: Status content adapts to window size

**Step 6: Commit responsive design**

```bash
git add ~/.tmux/scripts/responsive-status.sh tmux.conf
git commit -m "feat: add responsive status bar design"
```

## Phase 4: Enhanced Features

### Task 6: Context Awareness

**Files:**
- Create: `~/.tmux/scripts/context-detect.sh`
- Modify: `~/.tmux/scripts/responsive-status.sh`

**Step 1: Create context detection script**

```bash
#!/usr/bin/env bash

# Context detection for tmux starship integration
# Detects SSH, Docker, Kubernetes, virtual environments

set -euo pipefail

# Colors
CYAN="#[fg=colour14]"
MAGENTA="#[fg=colour13]"
YELLOW="#[fg=colour11]"
RESET="#[fg=colour250]"

context_info=""

# SSH detection
if [[ -n "${SSH_CONNECTION:-}" ]] || [[ -n "${SSH_CLIENT:-}" ]] || [[ -n "${SSH_TTY:-}" ]]; then
    hostname=$(hostname -s)
    user=$(whoami)
    context_info+="${CYAN}${user}@${hostname}${RESET} "
fi

# Docker detection
if [[ -f /.dockerenv ]] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    container_name=$(hostname)
    context_info+="${CYAN}🐳${container_name}${RESET} "
fi

# Kubernetes context detection
if command -v kubectl >/dev/null 2>&1; then
    k8s_context=$(kubectl config current-context 2>/dev/null || echo "")
    if [[ -n "$k8s_context" ]]; then
        k8s_namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null || echo "default")
        context_info+="${MAGENTA}☸️${k8s_context}/${k8s_namespace}${RESET} "
    fi
fi

# Python virtual environment
if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    venv_name=$(basename "$VIRTUAL_ENV")
    context_info+="${YELLOW}(${venv_name})${RESET} "
fi

# Conda environment
if [[ -n "${CONDA_DEFAULT_ENV:-}" ]] && [[ "$CONDA_DEFAULT_ENV" != "base" ]]; then
    context_info+="${YELLOW}(${CONDA_DEFAULT_ENV})${RESET} "
fi

echo "$context_info"
```

**Step 2: Make context script executable**

Run: `chmod +x ~/.tmux/scripts/context-detect.sh`

**Step 3: Update responsive status to include context**

Add to beginning of `~/.tmux/scripts/responsive-status.sh` after the color definitions:
```bash
# Get context information
context_info=$(~/.tmux/scripts/context-detect.sh)
```

And update the output sections to include context:
```bash
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
```

**Step 4: Test context detection**

Run: `~/.tmux/scripts/context-detect.sh`
Expected: Shows relevant context (SSH, virtual env, etc.)

**Step 5: Test integrated status**

Run: `tmux source-file ~/.tmux.conf`
Expected: Status shows context information

**Step 6: Commit context awareness**

```bash
git add ~/.tmux/scripts/context-detect.sh ~/.tmux/scripts/responsive-status.sh
git commit -m "feat: add context awareness (SSH, Docker, K8s, virtual envs)"
```

### Task 7: Performance Optimization & Caching

**Files:**
- Create: `~/.tmux/scripts/cache-manager.sh`
- Modify: `~/.tmux/scripts/responsive-status.sh`

**Step 1: Create cache manager**

```bash
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

        local status
        if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            status="✗"
        else
            status="✓"
        fi

        local result="${branch}${status}"
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
```

**Step 2: Make cache manager executable**

Run: `chmod +x ~/.tmux/scripts/cache-manager.sh`

**Step 3: Update responsive status to use caching**

Add to top of `~/.tmux/scripts/responsive-status.sh`:
```bash
# Source cache manager
source ~/.tmux/scripts/cache-manager.sh
```

Replace git detection section with:
```bash
# Git status with caching
git_status_cached=$(get_git_status "$PWD")
if [[ -n "$git_status_cached" ]]; then
    git_info="${GREEN} ${git_status_cached}${RESET}"
fi
```

**Step 4: Add toggle keybindings**

Add to `tmux.conf`:
```bash
# Toggle status bar details
bind-key t run-shell 'tmux set-option -g status-right-length $(( $(tmux show-option -gv status-right-length) == 150 ? 50 : 150 ))'
bind-key T run-shell 'tmux set-option -g status-right ""'
```

**Step 5: Test caching performance**

Run: `time ~/.tmux/scripts/responsive-status.sh`
Run again immediately
Expected: Second run should be faster due to caching

**Step 6: Test toggle keybindings**

In tmux: `prefix + t` and `prefix + T`
Expected: Status toggles between detailed/minimal/off

**Step 7: Commit performance optimizations**

```bash
git add ~/.tmux/scripts/cache-manager.sh ~/.tmux/scripts/responsive-status.sh tmux.conf
git commit -m "feat: add intelligent caching and toggle controls"
```

### Task 8: Final Integration & Testing

**Files:**
- Create: `~/.tmux/scripts/install-plugins.sh`
- Modify: `tmux.conf` (add keybindings)

**Step 1: Create plugin installation script**

```bash
#!/usr/bin/env bash

# Install and configure tmux plugins

set -euo pipefail

echo "Installing tmux plugins..."

# Install TPM if not present
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Install plugins
tmux run-shell ~/.tmux/plugins/tpm/scripts/install_plugins.sh

echo "Plugins installed successfully!"
echo "Press prefix + I in tmux to reload plugins"
```

**Step 2: Make installation script executable**

Run: `chmod +x ~/.tmux/scripts/install-plugins.sh`

**Step 3: Add enhanced keybindings to tmux.conf**

Add after line 106:
```bash
# Enhanced keybindings for starship integration
bind-key f run-shell -t popup "tmux-fzf-session"
bind-key F run-shell -t popup "tmux-fzf-window"
bind-key u run-shell "tmux capture-pane -p | grep -oE '(https?://[^ ]+)' | fzf-tmux -d 20% --multi --bind alt-a:select-all,alt-d:deselect-all | xargs open"

# Status bar toggles
bind-key t run-shell 'current=$(tmux show-option -gv status-right-length); tmux set-option -g status-right-length $(( current == 150 ? 50 : 150 ))'
bind-key T run-shell 'tmux set-option -g status-right $([ "$(tmux show-option -gv status-right)" = "" ] && echo "#(~/.tmux/scripts/responsive-status.sh)" || echo "")'

# Quick status refresh
bind-key r run-shell 'tmux source-file ~/.tmux.conf && find ~/.tmux/cache -name "*.cache" -delete'
```

**Step 4: Install plugins**

Run: `~/.tmux/scripts/install-plugins.sh`
Expected: All plugins installed successfully

**Step 5: Test full integration in new tmux session**

```bash
tmux new-session -d -s test
tmux attach -t test
```

Expected:
- Status bar shows responsive starship info
- Mouse support works
- True colors display correctly
- Keybindings function properly

**Step 6: Test in different contexts**

- Change directories (git repos, Node projects, Python projects)
- Resize terminal window
- Test toggle keybindings
- Test in SSH session if available

Expected: Status adapts to all contexts correctly

**Step 7: Performance test**

Run: `tmux info | grep "status updates"`
Expected: Status updates efficiently without lag

**Step 8: Final commit**

```bash
git add ~/.tmux/scripts/install-plugins.sh tmux.conf
git commit -m "feat: complete tmux starship integration with enhanced features"
```

**Step 9: Create summary documentation**

Create: `~/.tmux/README.md`
```markdown
# Tmux + Starship Integration

## Features
- Responsive status bar with git/language info
- Context awareness (SSH, Docker, K8s, virtual envs)
- Intelligent caching for performance
- True color and mouse support
- Enhanced plugins (fzf, yank, resurrect, continuum)

## Keybindings
- `prefix + f`: Fuzzy find sessions
- `prefix + F`: Fuzzy find windows
- `prefix + u`: Find and open URLs
- `prefix + t`: Toggle status detail level
- `prefix + T`: Toggle status on/off
- `prefix + r`: Refresh config and clear cache

## Status Bar Behavior
- Wide (>120 cols): Full directory path, full version numbers
- Medium (80-120 cols): Short directory, abbreviated versions
- Narrow (<80 cols): Git status only

## Scripts
- `~/.tmux/scripts/responsive-status.sh`: Main status generator
- `~/.tmux/scripts/context-detect.sh`: Context awareness
- `~/.tmux/scripts/cache-manager.sh`: Performance caching
```

**Step 10: Final commit**

```bash
git add ~/.tmux/README.md
git commit -m "docs: add tmux starship integration documentation"
```

---

## Plan complete and saved to `docs/plans/2026-01-07-tmux-starship-integration.md`. Two execution options:

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?**