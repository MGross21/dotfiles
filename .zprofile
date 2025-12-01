COLOR_THEME="ff0000"

CLR_RESET=$'\e[0m'
WHITE=$'\e[37m'

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
  toilet -f pagga -F border -F metal "Welcome $USER"
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
  uwsm start hyprland.desktop | colorize "$WHITE"
fi
