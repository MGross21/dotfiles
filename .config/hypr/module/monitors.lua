-- https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Hotplug layout (extend/present) is owned by shikane; see modules/nixos/desktop/displays.nix.

hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@144.03",
    position = "0x0",
    scale = 1.0,
})

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1.0,
})
