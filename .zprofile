# Theme + colorizer
COLOR_THEME="ff0000"

hex_fg() {
    local hex=${1#\#}
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    printf '\e[38;2;%d;%d;%dm' "$r" "$g" "$b"
}

CLR_RESET=$'\e[0m'
THEME_FG=$(hex_fg "$COLOR_THEME")

colorize() {
    local color=$1
    shift || true
    echo -ne "$color"
    if [ $# -gt 0 ]; then
        echo "$*"
    else
        cat
    fi
    echo -ne "$CLR_RESET"
}

# Welcome message
if [[ "$(tty)" == /dev/tty* ]] && command -v toilet &>/dev/null; then
  clear
  echo
  if [[ "$COLORTERM" == "truecolor" ]]; then
    toilet -f pagga -F border -F metal "Welcome $USER" | colorize "$THEME_FG"
  else
    # Fallback for TTYs without truecolor support
    echo "Welcome $USER" | toilet -f pagga -F border | colorize "\e[31m" # Red as fallback
  fi
  echo
fi

# Keyboard lighting (uses COLOR_THEME)
if command -v msi-perkeyrgb &>/dev/null && grep -qi "GS65" /sys/class/dmi/id/product_name 2>/dev/null; then
    msi-perkeyrgb --model GS65 --steady "$COLOR_THEME"
fi

# DBus
[ -z "$DBUS_SESSION_BUS_ADDRESS" ] && eval "$(dbus-launch --sh-syntax)"

# Keyring
! busctl --user | grep -q org.freedesktop.secrets && \
    eval "$(gnome-keyring-daemon --start --components=pkcs11,secrets,ssg,gpg)"

export SSH_AUTH_SOCK="/run/user/$UID/keyring/ssh"

# uwsm env vars
[ -f "${XDG_RUNTIME_DIR}/wayland-session.env" ] && source "${XDG_RUNTIME_DIR}/wayland-session.env"

# Hyprland via uwsm
if [[ "$(tty)" == "/dev/tty1" ]] && command -v uwsm &>/dev/null && uwsm check may-start; then
  uwsm start hyprland.desktop 2>&1 | colorize "$THEME_FG"
fi
