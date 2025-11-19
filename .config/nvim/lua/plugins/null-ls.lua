return {
  "jose-elias-alvarez/null-ls.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    local null_ls = require("null-ls")
    null_ls.setup({
      sources = {
        null_ls.builtins.formatting.prettier, -- JavaScript/TypeScript
        null_ls.builtins.formatting.black, -- Python
        null_ls.builtins.formatting.stylua, -- Lua
      },
    })
  end,
}