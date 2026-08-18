-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- ignore_alpha must stay below the bar's glass alpha or the blur is skipped
-- in exactly the regions meant to show it.
hl.layer_rule({
    name         = "lr-quickshell",
    match        = { namespace = "quickshell-bar" },
    blur         = true,
    ignore_alpha = 0.05,
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
