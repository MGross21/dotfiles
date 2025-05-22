# Start GNOME Keyring with secrets, ssh, and gpg support
if [ -z "$GNOME_KEYRING_CONTROL" ]; then
  eval $(gnome-keyring-daemon --start --components=secrets,ssh,gpg)
  export SSH_AUTH_SOCK
  export GPG_AGENT_INFO
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