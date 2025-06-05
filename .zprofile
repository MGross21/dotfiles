# Start DBus session if not already running
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  eval "$(dbus-launch --sh-syntax)"
fi

# Start GNOME Keyring with secrets, ssh, and gpg support
if [ -z "$GNOME_KEYRING_CONTROL" ]; then
  eval "$(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh,gpg)"
  export SSH_AUTH_SOCK
  export GNOME_KEYRING_CONTROL
  export GNOME_KEYRING_PID
fi

# https://wiki.hyprland.org/Useful-Utilities/Systemd-start/

# Compositor Selection Menu
#if uwsm check may-start && uwsm select; then
#	exec uwsm start default
#fi

# Direct Hyprland Launch
if command -v uwsm &>/dev/null && uwsm check may-start; then
    exec uwsm start hyprland.desktop
fi
