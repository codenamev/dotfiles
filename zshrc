# Starship configuration
export STARSHIP_CONFIG="$HOME/.starship.toml"

# load zmv for our mmv function
autoload -U zmv

# extra files in ~/.zsh/configs/pre , ~/.zsh/configs , and ~/.zsh/configs/post
# these are loaded first, second, and third, respectively.
_load_settings() {
  _dir="$1"
  if [ -d "$_dir" ]; then
    if [ -d "$_dir/pre" ]; then
      for config in "$_dir"/pre/**/*~*.zwc(N-.); do
        . $config
      done
    fi

    for config in "$_dir"/**/*(N-.); do
      case "$config" in
        "$_dir"/(pre|post)/*|*.zwc)
          :
          ;;
        *)
          . $config
          ;;
      esac
    done

    if [ -d "$_dir/post" ]; then
      for config in "$_dir"/post/**/*~*.zwc(N-.); do
        . $config
      done
    fi
  fi
}
_load_settings "$HOME/.zsh/configs"

# User-installed scripts
export PATH="$HOME/src/bin:$PATH"
[[ -f ~/.cargo/env ]] && source "$HOME/.cargo/env"

# Local config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Auoto-loaded scripts post-session start
[ -f ~/.startup ] && source ~/.startup

# Initialize starship prompt
eval "$(starship init zsh)"

# aliases
[[ -f ~/.aliases ]] && source ~/.aliases

. "$HOME/.local/bin/env"


# claude: expand --fs to --fork-session (works with -c/-r)
claude() {
  local args=()
  for arg in "$@"; do
    [[ "$arg" == "--fs" ]] && args+=("--fork-session") || args+=("$arg")
  done
  command claude "${args[@]}"
}
