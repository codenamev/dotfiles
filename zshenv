# use zsh as default shell
export SHELL=zsh

# ensure dotfiles bin directory is loaded first
export PATH="$HOME/.bin:$PATH"

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
fi

# add yarn if available
if type yarn &>/dev/null ; then
  export PATH="$PATH:`yarn global bin`"
fi

# add go if available
if type go &>/dev/null ; then
  export PATH="$PATH:$HOME/go/bin"
fi

local _old_path="$PATH"

# Local config
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local

if [[ $PATH != $_old_path ]]; then
  # `colors` isn't initialized yet, so define a few manually
  typeset -AHg fg fg_bold
  if [ -t 2 ]; then
    fg[red]=$'\e[31m'
    fg_bold[white]=$'\e[1;37m'
    reset_color=$'\e[m'
  else
    fg[red]=""
    fg_bold[white]=""
    reset_color=""
  fi

  cat <<MSG >&2
${fg[red]}Warning:${reset_color} your \`~/.zshenv.local' configuration seems to edit PATH entries.
Please move that configuration to \`.zshrc.local' like so:
  ${fg_bold[white]}cat ~/.zshenv.local >> ~/.zshrc.local && rm ~/.zshenv.local${reset_color}
(called from ${(%):-%N:%i})
MSG
fi

unset _old_path
