-- https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("dunst")
    hl.exec_cmd("systemctl --user enable --now hyprpaper.service")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("clipse -listen")
    hl.exec_cmd("wl-paste --watch cliphist store --no-fork")
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd('[ -n "$QT_QPA_PLATFORMTHEME" ] && systemctl --user import-environment QT_QPA_PLATFORMTHEME')
end)
