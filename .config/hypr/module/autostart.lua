-- https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.exec_once("waybar")
hl.exec_once("dunst")
hl.exec_once("systemctl --user enable --now hyprpaper.service")
hl.exec_once("systemctl --user start hyprpolkitagent")
hl.exec_once("clipse -listen")
hl.exec_once("wl-paste --watch cliphist store --no-fork")
hl.exec_once("dbus-update-activation-environment --systemd --all")
hl.exec_once('[ -n "$QT_QPA_PLATFORMTHEME" ] && systemctl --user import-environment QT_QPA_PLATFORMTHEME')
