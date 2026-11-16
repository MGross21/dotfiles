-- hl.plugin.load() only queues the .so; the plugin is absent on the first pass.
if not hl.plugin.hyprglass then
    return
end

local hg = hl.plugin.hyprglass

hg.config({
    default_theme = "dark",
    default_preset = "window",
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
