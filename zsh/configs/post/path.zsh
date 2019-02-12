# ensure dotfiles bin directory is loaded first
PATH="$HOME/.bin:/usr/local/bin:/usr/local/sbin:$PATH"

# load homebrew if available
if type /usr/local/bin/brew &>/dev/null ; then
  # Add homebrew completions
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
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

# load ASDF, falling back to rbenv if not available
if [ -d "$HOME/.asdf" ]; then
  . $HOME/.asdf/asdf.sh
fi

# mkdir .git/safe in the root of repositories you trust
PATH=".git/safe/../../bin:$PATH"

export -U PATH
