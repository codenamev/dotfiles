# ensure dotfiles bin directory is loaded first
PATH="$HOME/.bin:/usr/local/bin:/usr/local/sbin:$PATH"

# Add .local/bin if present
[[ -d "$HOME/.local/bin" ]] && export PATH=$HOME/.local/bin:$PATH

# load homebrew if available
if type /opt/homebrew/bin/brew &>/dev/null ; then
  # Add homebrew completions
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
  # Front-load brew'ed bins
  export PATH=$(brew --prefix)/bin:$(brew --prefix)/sbin:$PATH
fi

# chruby's .ruby-version auto-switching, for interactive shells. zshenv loads
# chruby.sh itself but never auto.sh, and the only tracked load of auto.sh used
# to sit inside the /opt/homebrew branch above -- dead on x86_64, live on arm64.
# So it belongs here: top level (arch-neutral) and interactive-only, since
# auto.sh hooks preexec_functions. Sourcing it twice is safe: it guards its own
# hook registration and unsets RUBY_AUTO_VERSION on load, so a fresh load with
# no .ruby-version in scope leaves the ruby zprofile selected alone.
# (2026-08-27)
for _chruby_auto in /usr/local/share/chruby/auto.sh /opt/homebrew/opt/chruby/share/chruby/auto.sh; do
  if [[ -s $_chruby_auto ]]; then
    source $_chruby_auto
    break
  fi
done
unset _chruby_auto

# load rbenv if available
if type rbenv &>/dev/null ; then
  eval "$(rbenv init - --no-rehash)"
elif type $HOME/.rvm/scripts/rvm &>/dev/null ; then
  export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
  [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
fi

# add yarn if available
if type yarn &>/dev/null ; then
  export PATH="$PATH:`yarn global bin`"
fi

# add go if available
if type go &>/dev/null ; then
  export PATH="$PATH:$HOME/go/bin"
  export GOPATH=$(go env GOPATH)
fi

# Try loading ASDF from the regular home dir location
if [ -f "$HOME/.asdf/asdf.sh" ]; then
  . "$HOME/.asdf/asdf.sh"
elif which brew >/dev/null && [ -f "$(brew --prefix asdf)/libexec/asdf.sh" ]; then
  . "$(brew --prefix asdf)/libexec/asdf.sh"
fi

# load nvm
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# mkdir .git/safe in the root of repositories you trust
PATH=".git/safe/../../bin:$PATH"

export -U PATH
