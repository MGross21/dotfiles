local augroup = function(name)
  return vim.api.nvim_create_augroup("dotfiles_" .. name, { clear = true })
end

vim.filetype.add({
  filename = {
    ["hyprland.conf"] = "hyprlang",
    ["hyprpaper.conf"] = "hyprlang",
    ["hyprlock.conf"] = "hyprlang",
    ["hypridle.conf"] = "hyprlang",
  },
  pattern = {
    [".*/hypr/.*%.conf"] = "hyprlang",
    [".*/ghostty/config"] = "ini",
  },
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("nix_width"),
  pattern = "nix",
  callback = function()
    vim.opt_local.colorcolumn = "100"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("no_colorcolumn"),
  pattern = { "markdown", "text", "gitcommit", "help", "snacks_dashboard" },
  callback = function()
    vim.opt_local.colorcolumn = ""
    vim.opt_local.list = false
  end,
})
