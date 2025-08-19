# Welcome Message
if [[ "$(tty)" == "/dev/tty*" ]] && command -v toilet &>/dev/null && command -v lolcat &>/dev/null; then
    echo
    toilet -f pagga -F border -F metal "Welcome $USER" | lolcat -a -d 5 -s 100 -S 100 -F 1
    echo
fi

# Setup Keyboard Lighting (requires yay -S msi-perkeyrgb)
command -v msi-perkeyrgb &>/dev/null && msi-perkeyrgb --model GS65 --steady 9c6ade

# Start DBus session if not already running
[ -z "$DBUS_SESSION_BUS_ADDRESS" ] && eval "$(dbus-launch --sh-syntax)"

# Start gnome-keyring-daemon if not already running
! busctl --user | grep -q org.freedesktop.secrets && eval "$(gnome-keyring-daemon --start --components=pkcs11,secrets,ssg,gpg)"

# Explicitly point to keyring
export SSH_AUTH_SOCK="/run/user/$UID/keyring/ssh"

# Source uswm-generated env vars, if they exist
[ -f "${XDG_RUNTIME_DIR}/wayland-session.env" ] && source "${XDG_RUNTIME_DIR}/wayland-session.env"

# Direct Hyprland Launch
if [[ "$(tty)" == "/dev/tty1" ]] && command -v uwsm &>/dev/null && uwsm check may-start; then
  exec uwsm start hyprland.desktop
fi
