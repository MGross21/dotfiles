-- https://wiki.hypr.land/Configuring/Basics/Monitors/

hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@144.03",
    position = "0x0",
    scale = 1.0,
})

hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@60.0",
    position = "1920x0",
    scale = 1.0,
    mirror = "eDP-1",
})
