-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- ignore_alpha must stay below Theme.surfaceAlpha.
hl.layer_rule({
    name         = "lr-quickshell",
    match        = { namespace = "quickshell-bar" },
    blur         = true,
    ignore_alpha = 0.05,
    no_anim      = true,
})

hl.layer_rule({
    name         = "lr-launcher",
    match        = { namespace = "^quickshell-launcher(-light)?$" },
    blur         = true,
    ignore_alpha = 0.05,
    animation    = "popin 92%",
})

hl.layer_rule({
    name  = "lr-notifications",
    match = { namespace = "notifications" },
    blur  = true,
})

hl.window_rule({
    name         = "wr-idle-fullscreen",
    match        = { class = ".*" },
    idle_inhibit = "fullscreen",
})

hl.window_rule({
    name   = "windowrule-1",
    match  = { class = "^(terminal|g\\.terminal|com\\.mitchellh\\.ghostty)$" },
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
