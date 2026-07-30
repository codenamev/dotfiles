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

# chruby for ALL shells, including non-interactive ones, so scripts and
# tool-spawned shells resolve the same ruby as the terminal. Selects the
# newest installed ruby-* in ~/.rubies (chruby fuzzy match: last wins).
# (2026-07-23)
for _chruby_sh in /usr/local/share/chruby/chruby.sh /opt/homebrew/opt/chruby/share/chruby/chruby.sh; do
  if [[ -s $_chruby_sh ]]; then
    source $_chruby_sh
    chruby ruby >/dev/null 2>&1
    break
  fi
done
unset _chruby_sh

# Load McFly if installed
if type mcfly &>/dev/null ; then
  eval "$(mcfly init zsh)"
fi
[[ -f ~/.cargo/env ]] && . "$HOME/.cargo/env"

# claude-memory: local fastembed embeddings (set up 2026-06-08)
export CLAUDE_MEMORY_EMBEDDING_PROVIDER=fastembed
export CLAUDE_MEMORY_EMBEDDING_MODEL=BAAI/bge-base-en-v1.5
