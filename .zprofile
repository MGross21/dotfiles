# https://wiki.hyprland.org/Useful-Utilities/Systemd-start/

# Compositor Selection Menu
#if uwsm check may-start && uwsm select; then
#	exec uwsm start default
#fi

# Direct Hyprland Launch
if uwsm check may-start; then
    exec uwsm start hyprland.desktop
fi
