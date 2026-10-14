-- hl.plugin.load() only queues the .so; the plugin is absent on the first pass.
if not hl.plugin.hyprglass then
    return
end

local hg = hl.plugin.hyprglass

hg.config({
    default_theme = "dark",
    default_preset = "window",
    layers = { enabled = true },
})

hg.preset("window", {
    blur_strength = 3.0,
    blur_iterations = 3,
    glass_opacity = 1.0,
    refraction_strength = 0.22,
    chromatic_aberration = 0.08,
    lens_distortion = 0.0,
    fresnel_strength = 0.6,
    specular_strength = 0.6,
    edge_thickness = 0.10,
    dark = {
        -- Unset falls through to the plugin default 0x8899aa22, not to no tint.
        tint_color = THEME.glass_tint or 0x1a0e12a0,
        brightness = 0.90,
        contrast = 1.10,
        adaptive_dim = 0.35,
        adaptive_boost = 0.0,
        saturation = 1.05,
        vibrancy = 0.5,
    },
})

hg.preset("bar", {
    blur_strength = 2.4,
    blur_iterations = 3,
    glass_opacity = 0.9,
    refraction_strength = 0.35,
    chromatic_aberration = 0.2,
    fresnel_strength = 0.5,
    specular_strength = 0.6,
    lens_distortion = 0.15,
    edge_thickness = 0.05,
    dark = {
        tint_color = THEME.glass_tint or 0x12080ca0,
        brightness = 0.62,
        contrast = 1.05,
        adaptive_dim = 0.0,
        adaptive_boost = 0.0,
    },
})

hg.preset("launcher-light", {
    blur_strength = 3.0,
    blur_iterations = 3,
    glass_opacity = 1.0,
    refraction_strength = 0.22,
    chromatic_aberration = 0.08,
    lens_distortion = 0.0,
    fresnel_strength = 0.4,
    specular_strength = 0.4,
    edge_thickness = 0.10,
    dark = {
        tint_color = THEME.glass_tint_light or 0xf7e8b250,
        brightness = 1.05,
        contrast = 0.95,
        adaptive_dim = 0.0,
        adaptive_boost = 0.0,
        saturation = 1.0,
        vibrancy = 0.3,
    },
})

-- Namespaces match WlrLayershell.namespace; mask_threshold must stay below Theme.surfaceAlpha.
hg.layer("quickshell-bar", { preset = "bar", mask_threshold = 0.05 })
hg.layer("quickshell-launcher", { preset = "window", mask_threshold = 0.05 })
hg.layer("quickshell-launcher-light", { preset = "launcher-light", mask_threshold = 0.05 })
