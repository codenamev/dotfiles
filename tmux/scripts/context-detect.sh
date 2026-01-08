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
