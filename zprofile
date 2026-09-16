if [ -d "/opt/homebrew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -d "~/.linuxbrew" ]; then
  eval "$(~/.linuxbrew/bin/brew shellenv)"
elif [ -d "/home/linuxbrew" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Local config
[[ -f ~/.zprofile.local ]] && source ~/.zprofile.local

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# /etc/zprofile runs `eval $(/usr/libexec/path_helper -s)` for every login
# shell, and path_helper moves every non-system PATH entry to the END. zshenv
# has already picked a ruby by then, so its chruby bin dir gets demoted below
# /usr/bin while GEM_HOME/RUBY_ROOT keep pointing at the chosen ruby. A
# non-interactive login shell never runs .zshrc, so nothing repairs it and you
# get /usr/bin/ruby 2.6.10 with a 4.x GEM_HOME. Re-assert the same selection
# zshenv made, now that path_helper is done reordering.
#
# Deliberately NOT inside the /opt/homebrew branch above: that gate is false on
# x86_64, which is how the original chruby setup in zsh/configs/post/path.zsh
# ended up dead on this machine. (2026-08-27)
for _chruby_sh in /usr/local/share/chruby/chruby.sh /opt/homebrew/opt/chruby/share/chruby/chruby.sh; do
  if [[ -s $_chruby_sh ]]; then
    source $_chruby_sh
    chruby ruby >/dev/null 2>&1
    break
  fi
done
unset _chruby_sh

# path_helper demotes zshenv's mise shims the same way, so re-assert them too,
# after chruby so the mise-managed ruby wins. (2026-09-11)
for _mise_bin in $HOME/.local/bin/mise /opt/homebrew/bin/mise /usr/local/bin/mise; do
  if [[ -x $_mise_bin ]]; then
    eval "$($_mise_bin activate zsh --shims)"
    break
  fi
done
unset _mise_bin

# Homebrew wraps some Ruby formulae (tmuxinator, for one) in a shim that runs
# the real binary with GEM_HOME pointed at the formula's own libexec. tmux
# started via tmuxinator inherits that into the server, so every pane it opens
# has GEM_HOME=/opt/homebrew/Cellar/<formula>/<version>/libexec — and a
# `gem install` from one of those panes lands in a directory the next `brew
# upgrade` deletes. Nothing owns that GEM_HOME but the formula, so drop it and
# let RubyGems fall back to the ruby selected above. (2026-09-16)
if [[ -n ${GEM_HOME-} && $GEM_HOME == */Cellar/* ]]; then
  unset GEM_HOME
fi
