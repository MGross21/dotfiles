-- Appends to LazyVim's ensure_installed; opts_extend, not a replace.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "cpp",
        "css",
        "dockerfile",
        "git_config",
        "gitcommit",
        "gitignore",
        "hyprlang",
        "ini",
        "kotlin",
        "make",
        "nix",
        "qmljs",
        "rust",
        "scss",
        "ssh_config",
        "zig",
      },
    },
  },
}
