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

# --- Environment Setup ---
export EDITOR="nvim"  
export PATH="$HOME/bin:/usr/local/bin:$PATH"

# --- Prompt ---
autoload -Uz colors && colors
PROMPT='%F{cyan}%n@%m%f:%F{yellow}%~%f %# '

# --- Aliases ---
alias c="clear"
alias ..="cd .."
alias ...="cd ../.."

alias ls='ls --color=auto'
alias la='ls -lAFhSr --color=auto' # list all, show filetype, format sizing, reverse sort
alias ll='ls -lah'

alias gs='git status'
alias gc="git commit"
alias gl="git log --oneline --graph --all"

alias zshrc='${EDITOR} ~/.zshrc'
alias reload='source ~/.zshrc'

alias update="sudo pacman -Syu && yay -Sua && echo 'Done.'"
alias install="sudo pacman -S"
alias uninstall="sudo pacman -Rns"
alias search="pacman -Si"
alias packages="pacman -Qet" # All Explicitly installed pacakges, non-dependencies
#alias cleanup='orphans=$(pacman -Qdtq); [[ -n "$orphans" ]] && sudo pacman -Rns $orphans || echo "No orphans to remove."'


alias hyprreload="hyprctl reload"
alias hyprlog="journalctl -xe | grep Hyprland"

alias barreload='pkill waybar && (waybar & disown)'

alias wlr="env | grep -i wl" # Wayland Variables
alias monitors="hyprctl monitors"
alias logout="hyprctl dispatch exit"
alias reboot="systemctl reboot"
alias shutdown="systemctl poweroff"
alias services="systemctl list-unit-files --state=enabled"

alias devices="lsusb && lspci | less"
alias disks="lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,LABEL"
alias usage="df -hT | grep '^/dev/'"
alias ports='ss -tulwn'

#alias volup="pactl set-sink-volume @DEFAULT_SINK@ +5%"
#alias voldown="pactl set-sink-volume @DEFAULT_SINK@ -5%"
#alias mute="pactl set-sink-mute @DEFAULT_SINK@ toggle"
#alias micmute="pactl set-source-mute @DEFAULT_SOURCE@ toggle"
#alias audiolist="pactl list sinks short"

# --- Plugins/Frameworks (optional section) ---
# If using a plugin manager like zinit, add plugin loads here

# Example (if using zinit):
# source ~/.zinit/bin/zinit.zsh
# zinit light zsh-users/zsh-autosuggestions
# zinit light zsh-users/zsh-syntax-highlighting

# ==========
# End Config
# ==========

_d2g() {
  cp -r ~/.config ~/dotfiles/
  cp ~/.*shrc ~/dotfiles/
}
alias dot2git=_d2g

_ds() {
  cd ~/dotfiles || return
  git status
  git pull
  dot2git
  gc -am "Sync dotfiles ($(date +"%m/%d/%y %H:%M:%S %Z"))"
  git push
  cd -
}
alias dotsync=_ds

alias twitch='function _twitch() { firefox --new-window "https://www.twitch.tv/$1"; }; _twitch'
