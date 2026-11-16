local M = {}

M.terminal = "ghostty +new-window"
M.fileManager = "thunar"
M.menu = "omarchy-shell shell toggle dotfiles.launcher"
M.clipboard = [[omarchy-shell shell summon dotfiles.launcher '{"text":"#"}']]
M.caffeine = "omarchy-shell caffeine toggle"
M.barToggle = "omarchy-toggle-bar"
M.mainMod = "SUPER"
M.browser = "firefox"

return M
