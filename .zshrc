# =================
# Zsh Configuration
# =================

# Setting zsh for user: chsh -s $(which zsh) $USER

# --- Keybindings ---
bindkey -e                # Emacs-style keybindings (default)

# --- History Settings ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt HIST_IGNORE_ALL_DUPS      # Remove older duplicate commands
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before saving
setopt INC_APPEND_HISTORY        # Add to history immediately
setopt SHARE_HISTORY             # Share history between sessions

# --- Shell Behavior ---
setopt AUTO_CD                   # Just type directory name to cd
setopt AUTO_PUSHD                # Use directory stack for cd
setopt PUSHD_IGNORE_DUPS         # Don't duplicate entries in stack
setopt EXTENDED_GLOB             # Advanced globbing support
setopt GLOB_DOTS                 # Include dotfiles in globs
setopt NO_NOMATCH                # If glob doesn't match, don't error out
setopt PROMPT_SUBST              # Allow variable expansion in prompt
setopt INTERACTIVE_COMMENTS      # Allow comments in interactive shell
setopt NO_CLOBBER                 # Prevent `>` from overwriting files
setopt IGNORE_EOF                # Prevent accidental exit on Ctrl-D
setopt CORRECT                   # Auto-correct mistyped commands
unsetopt CORRECT_ALL             # Only correct the command name, not args
CORRECT_IGNORE=('_*' '.*')

# --- Completion System ---
autoload -Uz compinit
compinit -d ~/.cache/zsh/zcompdump

# Smarter completion menu
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list \
    'm:{a-zA-Z}={A-Za-z}' \
    'r:|?=**' \
    'l:|=* r:|=*'
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# --- Sourcing ---
for dot in ~/.{exports,aliases};do
  [ -r "$dot" ] && [ -f "$dot" ] && source "$dot";
done

# --- Prompt ---
autoload -Uz colors && colors
PROMPT='%F{cyan}%n@%m%f:%F{#9C6ADE}%~%f %# ' # Purple

# --- Plugins/Frameworks ---
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=cyan'

for plugin in zsh-{autosuggestions,history-substring-search}; do
  plugin_path="/usr/share/zsh/plugins/$plugin/$plugin.zsh"
  [[ -r "$plugin_path" ]] && source "$plugin_path"
done

highlight_path="/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[[ -r "$highlight_path" ]] && source "$highlight_path"


source <(fzf --zsh)
eval "$(zoxide init zsh --cmd cd)"

# Auto-start tmux if not already inside one
#if command -v tmux >/dev/null 2>&1; then
#  if [[ -z "$TMUX" ]] && [[ "$TERM_PROGRAM" != "vscode" ]]; then
#    exec tmux new-session -A -s main
#    fastfetch --logo none && echo ""
#  fi
#fi
