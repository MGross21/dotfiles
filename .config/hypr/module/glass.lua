-- HyprGlass: compositor-side liquid glass. Loaded by /etc/hypr/plugins.lua,
-- which Nix generates (see modules/desktops/hyprland.nix) because only Nix
-- knows the plugin's store path.
--
-- The guard is required: hl.plugin.load() only queues the .so, so on the first
-- config pass hl.plugin.hyprglass does not exist yet.
if not hl.plugin.hyprglass then
    return
end

local hg = hl.plugin.hyprglass

hg.config({
    default_theme = "dark",
    default_preset = "window",
    -- Off by default; a namespace whitelist.
    layers = { enabled = true },
})

-- Wallpaper sets the ceiling: the active one is 0.167 mean luminance, stddev
-- 0.137, so there is little behind a window to blur or refract. Retune if the
-- theme's wallpaper changes.
--
-- The rule this preset holds: the glass must come out darker than the wallpaper
-- it sits on. Brighter reads as fog, not a pane.
hg.preset("window", {
    blur_strength = 3.0,
    blur_iterations = 3,
    glass_opacity = 1.0,
    -- refractionPx = strength * 50, decaying exp(-depth / (edge_thickness *
    -- min(w,h))) inward. On a full-height window that bezel is the whole effect.
    refraction_strength = 0.22,
    -- Both distort glyphs, so near zero: lens_distortion bows straight lines,
    -- chromatic_aberration fringes edges.
    chromatic_aberration = 0.08,
    lens_distortion = 0.0,
    -- Edge-only, so they cost no legibility -- and the pane's middle has nothing
    -- to refract anyway.
    fresnel_strength = 0.6,
    specular_strength = 0.6,
    edge_thickness = 0.10,
    dark = {
        -- Unset does NOT mean "no tint": it falls through to the global default
        -- 0x8899aa22, a light blue-grey mixed over every pixel, which comes out
        -- brighter than this wallpaper.
        tint_color = 0x1a0e12a0,
        brightness = 0.90,
        contrast = 1.10,
        -- Both are gated on smoothstep(0.25, 0.55, backdrop luminance), ~0 on
        -- this wallpaper: adaptive_dim is near inert, adaptive_boost runs at
        -- full strength.
        adaptive_dim = 0.35,
        adaptive_boost = 0.0,
        saturation = 1.05,
        vibrancy = 0.5,
    },
})

-- Backdrop under the bar (top 32px of the wallpaper) spans 0.073-0.142
-- luminance, stddev 0.020. Blurring a flat field returns a flat field; knobs
-- cannot fix that.
--
-- That peak is under the 0.25 smoothstep floor, so adaptive_dim is a no-op
-- here; brightness carries it.
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
        tint_color = 0x12080ca0,
        brightness = 0.62,
        contrast = 1.05,
        adaptive_dim = 0.0,
        adaptive_boost = 0.0,
    },
})

-- Namespace must match WlrLayershell.namespace in the bar's shell.qml.
-- mask_threshold sits under the island glass alpha (Theme.surfaceAlpha, 0.10)
-- or the effect is skipped exactly where it is wanted -- same trap as
-- blur:popups_ignorealpha in lookandfeel.lua.
hg.layer("quickshell-bar", { preset = "bar", mask_threshold = 0.05 })

-- Edge effects barely reach the islands: hyprglass builds the glass SDF from
-- the layer surface box, and every edge term decays as
-- exp(cornerSdf / (edge_thickness * min(w,h))). On a 1920x32 bar that is 1.6px,
-- so an island 16px inside sees ~5e-5 of it. Per-island layer surfaces would
-- fix the geometry but each needs its own exclusive zone. Done shell-side
-- instead -- see components/Glass.qml.
