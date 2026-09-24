return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        kotlin = { "ktlint" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        nix = { "statix" },
      },
    },
  },
}
