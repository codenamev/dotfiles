# Persistent, cross-platform ssh-agent.
#
# Bind the agent to a fixed socket so every shell, tmux pane, and SSH session
# shares one agent instead of spawning orphans that nothing points at.
# `ssh-add -l` exits 2 when no agent is reachable at $SSH_AUTH_SOCK (the socket
# is dead or missing); exit 0 (has keys) or 1 (reachable, empty) means an agent
# is already answering, so leave it running.
export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"

ssh-add -l &>/dev/null
if [ $? -eq 2 ]; then
  rm -f "$SSH_AUTH_SOCK"
  ssh-agent -a "$SSH_AUTH_SOCK" >/dev/null 2>&1
fi

# macOS: preload keys and their passphrases from the login Keychain, no prompt.
# Linux: `AddKeysToAgent yes` in ~/.ssh/config adds keys lazily on first use,
# so there is nothing to do at shell startup.
if [[ "$OSTYPE" == darwin* ]]; then
  ssh-add --apple-load-keychain &>/dev/null
fi
