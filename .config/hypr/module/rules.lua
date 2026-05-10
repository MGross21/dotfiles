-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/

hl.layer_rule({
    name         = "lr-waybar",
    match        = { namespace = "waybar" },
    blur         = true,
    ignore_alpha = 0.6,
    no_anim      = true,
})

hl.layer_rule({
    name  = "lr-wofi",
    match = { namespace = "wofi" },
    blur  = true,
})

hl.layer_rule({
    name  = "lr-notifications",
    match = { namespace = "notifications" },
    blur  = true,
})

hl.window_rule({
    name   = "windowrule-1",
    match  = { class = "^(terminal|g.terminal)$" },
    float  = true,
    size   = "800 600",
    center = true,
})

hl.window_rule({
    name  = "windowrule-2",
    match = { class = "^(python.*)$" },
    float = true,
})

hl.window_rule({
    name  = "windowrule-4",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})
