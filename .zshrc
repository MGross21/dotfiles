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
export SUDO_PROMPT="${(L)USER} password: "

# --- Prompt ---
autoload -Uz colors && colors
#PROMPT='%F{cyan}%n@%m%f:%F{yellow}%~%f %# ' # Orange (Default)
PROMPT='%F{cyan}%n@%m%f:%F{#9C6ADE}%~%f %# ' # Purple

# --- Vivid Terminal Colors ---
#export LS_COLORS="$(vivid generate purple)"
export LS_COLORS="$(vivid generate tokyonight-storm)"

# --- Aliases ---
alias c="clear"
alias ..="cd .."
alias ...="cd ../.."
alias c-='cd - >/dev/null'

alias ls='ls --color=auto'
alias la='ls -lAFhSr --color=auto' # list all, show filetype, format sizing, reverse sort
alias ll='ls -lah'

alias vim=$EDITOR
alias vi=$EDITOR

alias gs='git status'
alias gc="git commit"
alias gl="git log --oneline --graph --all"

alias zshrc='${EDITOR} ~/.zshrc'
alias reload='source ~/.zshrc'

alias update="sudo pacman -Syu --noconfirm && yay -Sua --noconfirm && spicetify update && echo 'Done.'"
alias install="sudo pacman -S"
alias uninstall="sudo pacman -Rns"
alias search="pacman -Si"
alias packages="pacman -Qet" # All Explicitly installed pacakges, non-dependencies

cleanup() {
  local orphans
  orphans=$(pacman -Qdtq)

  if [[ -n "$orphans" ]]; then
    echo "Removing orphan packages:"
    echo "$orphans"
    sudo pacman -Rns $orphans
  else
    echo "No orphan packages to remove."
  fi
}


alias forcekill="killall -9"

alias neo="neofetch"

alias hyprreload="hyprctl reload"
alias hyprlog="journalctl -xe | grep Hyprland"
alias hyprconfig="${EDITOR} $HOME/.config/hypr/hyprland.conf"

alias barreload='pkill waybar; (waybar & disown)'

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
alias speedtest="speedtest-cli --simple --secure | column -t"

alias soundtest="speaker-test -c 8 -t wav"

copyfile() {
  [[ -f "$1" ]] && wl-copy < "$1" || echo "Usage: copyfile <file>"
}

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

dotsync(){
  cd ~/dotfiles || return
  git status
  git pull --rebase origin main
  cp -r ~/.config ~/dotfiles/ 2>/dev/null
  cp ~/.*rc ~/dotfiles/
  cp ~/.zprofile ~/dotfiles/
  gc -am "Sync dotfiles ($(date +"%m/%d/%y %H:%M:%S %Z"))"
  git push
  cd -
}

twitch() {
  streamlink --player mpv \
             --player-args="--no-osc --no-input-cursor --no-input-default-bindings" \
             "twitch.tv/$1" best & disown
}


export PATH=$PATH:/home/mgross/.spicetify

# Requires https://github.com/caarlos0/timer
# yay -S timer-bin

pomodoro() {
  local work_minutes=25
  local break_minutes=5
  local count=1
  local no_break=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -w|--work)     shift; work_minutes="$1" ;;
      -b|--break)    shift; break_minutes="$1" ;;
      -c|--count)    shift; count="$1" ;;
      -n|--no-break) no_break=true ;;
      *) echo "Usage: pomodoro [-w minutes] [-b minutes] [-c count] [--no-break]"; return 1 ;;
    esac
    shift
  done

  on_interrupt() {
    trap - SIGINT
    exit 130
  }

  for ((i = 1; i <= count; i++)); do
    echo "Pomodoro $i of $count"
    c

    echo "Work: ${work_minutes} minutes"
    trap on_interrupt SIGINT
    timer "${work_minutes}m"
    local timer_exit=$?
    trap - SIGINT

    (( timer_exit != 0 )) && return 130

    notify-send "Pomodoro" "Work session over. Take a break!"

    if ! $no_break; then
      echo "Break: ${break_minutes} minutes"
      timer "${break_minutes}m"
      notify-send "Pomodoro" "Break is over. Get back to work!"
    else
      echo "Skipping break as requested."
    fi
  done
}

