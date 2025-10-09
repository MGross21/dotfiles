# Zsh Configuration
bindkey -e

# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY

# Filter out massive scripts and long commands from history
zshaddhistory() {
    local line=${1%%$'\n'}
    # Exclude commands longer than 200 chars or containing newlines
    [[ ${#line} -le 200 && $line != *$'\n'* ]]
}

# Shell behavior
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt EXTENDED_GLOB
setopt GLOB_DOTS
setopt NO_NOMATCH
setopt PROMPT_SUBST
setopt INTERACTIVE_COMMENTS
setopt NO_CLOBBER
setopt IGNORE_EOF
setopt CORRECT
setopt NO_BEEP
setopt MULTIOS
setopt NOTIFY
unsetopt CORRECT_ALL

CORRECT_IGNORE=('_*' '.*')

# Completion
[[ ! -d ~/.cache/zsh ]] && mkdir -p ~/.cache/zsh

autoload -Uz compinit
if [[ ~/.zcompdump(#qNmh+24) ]]; then
    compinit -d ~/.cache/zsh/zcompdump
else
    compinit -C -d ~/.cache/zsh/zcompdump
fi

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

# Source config files
for dot in ~/.{exports,aliases}; do
    [[ -r "$dot" ]] && [[ -f "$dot" ]] && source "$dot"
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

# Keybindings for history search
if [[ -n "${functions[history-substring-search-up]}" ]]; then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey '^P' history-substring-search-up
    bindkey '^N' history-substring-search-down
fi

# Tool integrations
command -v fzf &>/dev/null && source <(fzf --zsh)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh --cmd cd)"
command -v uv &>/dev/null && eval "$(uv generate-shell-completion zsh)"
command -v uvx &>/dev/null && eval "$(uvx --generate-shell-completion zsh)"

# Performance
[[ $TERM == "dumb" ]] && unsetopt zle && PS1='$ '

if [[ -f /usr/share/zsh/functions/Misc/async ]]; then
    source /usr/share/zsh/functions/Misc/async
fi