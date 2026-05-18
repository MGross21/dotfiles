-- https://wiki.hypr.land/Configuring/Start/
pcall(dofile, "/etc/hypr/colors.lua")

require("module.monitors")
require("module.workspaces")
require("module.vars")
require("module.env")
require("module.autostart")
require("module.rules")
require("module.binds")
require("module.inputs")
require("module.lookandfeel")
