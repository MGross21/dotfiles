# Start DBus session if not already running
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  eval "$(dbus-launch --sh-syntax)"
fi


# Start gnome-keyring-daemon if not already running
if ! busctl --user | grep -q org.freedesktop.secrets; then
  eval "$(gnome-keyring-daemon --start --components=pkcs11,secrets,ssg,gpg)"
fi

# https://wiki.hyprland.org/Useful-Utilities/Systemd-start/

# Explicitly point to keyring
export SSH_AUTH_SOCK="/run/user/$UID/keyring/ssh"

# Source uswm-generated env vars, if they exist
[ -f ${XDG_RUNTIME_DIR}/wayland-session.env ] && source "${XDG_RUNTIME_DIR}/wayland-session.env"


# Compositor Selection Menu
#if uwsm check may-start && uwsm select; then
#	exec uwsm start default
#fi

# Direct Hyprland Launch
if [ "$(tty)" = "/dev/tty1" ] && command -v uwsm &>/dev/null && uwsm check may-start; then
  exec uwsm start hyprland.desktop
fi
