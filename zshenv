# use vim as the visual editor
export VISUAL=vim
export EDITOR=$VISUAL
export SHELL=zsh

# ensure dotfiles bin directory is loaded first
export PATH="$HOME/.bin:/usr/local/sbin:$PATH"

# load rbenv if available
if type rbenv &>/dev/null ; then
  eval "$(rbenv init - --no-rehash)"
elif type $HOME/.rvm/scripts/rvm &>/dev/null ; then
  export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
  [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
fi

# load homebrew if available
if type /usr/local/bin/brew &>/dev/null ; then
  export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
  # load php-version if available
  if [ -f $(brew --prefix php-version)/php-version.sh ]; then
    source $(brew --prefix php-version)/php-version.sh && php-version 5
  fi
fi


# mkdir .git/safe in the root of repositories you trust
export PATH=".git/safe/../../bin:$PATH"

# Local config
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
