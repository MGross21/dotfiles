# Zsh Configuration
bindkey -e

# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS INC_APPEND_HISTORY SHARE_HISTORY
setopt HIST_IGNORE_SPACE HIST_VERIFY

# Filter out massive scripts and long commands from history
zshaddhistory() {
    local line=${1%%$'\n'}
    [[ ${#line} -le 200 && $line != *$'\n'* ]]
}

# Shell Behavior
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
setopt EXTENDED_GLOB GLOB_DOTS NO_NOMATCH PROMPT_SUBST
setopt INTERACTIVE_COMMENTS NO_CLOBBER IGNORE_EOF CORRECT
setopt NO_BEEP MULTIOS NOTIFY
unsetopt CORRECT_ALL

CORRECT_IGNORE=('_*' '.*')

# Completion
[[ ! -d ~/.cache/zsh ]] && mkdir -p ~/.cache/zsh

autoload -Uz compinit
compinit -C -d ~/.cache/zsh/zcompdump

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list \
    'm:{a-zA-Z}={A-Za-z}' \
    'r:|?=**' \
    'l:|=* r:|=*'
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' group-name ''
zstyle ':completion:*:*:kill:*' list-colors '=(#b) #([0-9]#)*( *[a-z])*=34=31=33'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.cache/zsh

# Source Config Files
for dot in ~/.{exports,aliases}; do
    [[ -r "$dot" && -f "$dot" ]] && source "$dot"
done

# Prompt
autoload -Uz colors && colors
PROMPT='%F{blue}%1~%f %# '

# Plugins
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

plugins=(
    "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
    "/usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh"
    "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
)

for plugin in "${plugins[@]}"; do
    [[ -r "$plugin" ]] && source "$plugin"
done

# Keybindings for History Search
if [[ -n "${functions[history-substring-search-up]}" ]]; then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey '^P' history-substring-search-up
    bindkey '^N' history-substring-search-down
fi

# Tool Integrations
command -v fzf &>/dev/null && source <(fzf --zsh)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh --cmd cd)"
command -v uv &>/dev/null && eval "$(uv generate-shell-completion zsh)"
command -v uvx &>/dev/null && eval "$(uvx --generate-shell-completion zsh)"

# Performance
[[ $TERM == "dumb" ]] && unsetopt zle && PS1='$ '

# Async Support
[[ -f /usr/share/zsh/functions/Misc/async ]] && source /usr/share/zsh/functions/Misc/async

# Virtual Environment
[[ -f ./.venv/bin/activate ]] && source ./.venv/bin/activate