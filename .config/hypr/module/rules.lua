-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/

hl.layer_rule({
    name    = "lr-bar",
    match   = { namespace = "omarchy-bar" },
    no_anim = true,
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
