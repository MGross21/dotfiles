# =================
# Zsh Configuration
# =================

# Setting zsh for user: chsh -s $(which zsh) $USER

# --- Keybindings ---
bindkey -e                # Emacs-style keybindings (default)

# --- History Settings ---
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000

setopt HIST_IGNORE_ALL_DUPS      # Remove older duplicate commands
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before saving
setopt INC_APPEND_HISTORY        # Add to history immediately
setopt SHARE_HISTORY             # Share history between sessions

# --- Shell Behavior ---
setopt AUTO_CD                   # Just type directory name to cd
setopt AUTO_PUSHD                # Use directory stack for cd
setopt PUSHD_IGNORE_DUPS         # Don't duplicate entries in stack
setopt EXTENDED_GLOB             # Advanced globbing support
setopt PROMPT_SUBST              # Allow variable expansion in prompt
setopt INTERACTIVE_COMMENTS      # Allow comments in interactive shell
setopt NO_CLOBBER                # Prevent `>` from overwriting files
setopt IGNORE_EOF                # Prevent accidental exit on Ctrl-D
setopt CORRECT                   # Auto-correct mistyped commands

# --- Completion System ---
autoload -Uz compinit && compinit

# Optional: Smarter completion menu
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# --- Sourcing ---
for dot in ~/.{exports,aliases,path};do
  [ -r "$dot" ] && [ -f "$dot" ] && source "$dot";
done

# --- Prompt ---
autoload -Uz colors && colors
#PROMPT='%F{cyan}%n@%m%f:%F{yellow}%~%f %# ' # Orange (Default)
PROMPT='%F{cyan}%n@%m%f:%F{#9C6ADE}%~%f %# ' # Purple

# --- Vivid Terminal Colors ---
#export LS_COLORS="$(vivid generate purple)"
export LS_COLORS="$(vivid generate tokyonight-storm)"

# --- Plugins/Frameworks ---
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=cyan'

for plugin in zsh-{autosuggestions,history-substring-search}; do
  plugin_path="/usr/share/zsh/plugins/$plugin/$plugin.zsh"
  [[ -r "$plugin_path" ]] && source "$plugin_path"
done

# Needs to be last
highlight_path="/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[[ -r "$highlight_path" ]] && source "$highlight_path"