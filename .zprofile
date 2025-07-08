# Start DBus session if not already running
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  eval "$(dbus-launch --sh-syntax)"
fi

# https://wiki.hyprland.org/Useful-Utilities/Systemd-start/

# Compositor Selection Menu
#if uwsm check may-start && uwsm select; then
#	exec uwsm start default
#fi

# Direct Hyprland Launch
if [ "$(tty)" = "/dev/tty1" ] && command -v uwsm &>/dev/null && uwsm check may-start; then
  exec uwsm start hyprland.desktop
fi
