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
  # load chruby if available
  if [[ -s /opt/homebrew/opt/chruby/share/chruby/chruby.sh ]] ; then source /opt/homebrew/opt/chruby/share/chruby/chruby.sh ; fi
  if [[ -s /opt/homebrew/opt/chruby/share/chruby/auto.sh ]] ; then source /opt/homebrew/opt/chruby/share/chruby/auto.sh ; fi
fi

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
elif which brew >/dev/null; then
  . "$(brew --prefix asdf)/libexec/asdf.sh"
fi

# load nvm
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# mkdir .git/safe in the root of repositories you trust
PATH=".git/safe/../../bin:$PATH"

export -U PATH
