return {
  {
    "stevearc/conform.nvim",
    opts = {
      format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
      formatters_by_ft = {
        lua = { "stylua" },
        nix = { "nixfmt" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
        python = { "ruff_fix", "ruff_format" },
        rust = { "rustfmt" },
        toml = { "taplo" },
        kotlin = { "ktlint" },
      },
      formatters = {
        shfmt = { prepend_args = { "-i", "2", "-ci" } },
      },
    },
  },
}
