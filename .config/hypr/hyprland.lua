-- https://wiki.hypr.land/Configuring/Start/
local ok, theme = pcall(dofile, "/etc/hypr/colors.lua")
THEME = ok and type(theme) == "table" and theme or {}
-- Nix-generated; hl.plugin.load() for hyprglass. Must run before module.glass.
pcall(dofile, "/etc/hypr/plugins.lua")

require("module.monitors")
require("module.workspaces")
require("module.vars")
require("module.env")
require("module.autostart")
require("module.rules")
require("module.binds")
require("module.inputs")
require("module.lookandfeel")
require("module.glass")
