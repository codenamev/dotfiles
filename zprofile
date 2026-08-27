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
