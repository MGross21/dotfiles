return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
  },
  config = function()
    require("mason-lspconfig").setup({
      ensure_installed = {
        "lua_ls", -- Lua
        "pyright", -- Python
        "tsserver", -- TypeScript/JavaScript
        "gopls", -- Go
        "rust_analyzer", -- Rust
        "clangd", -- C/C++
      },
    })
    local lspconfig = require("lspconfig")
    lspconfig.lua_ls.setup({})
    lspconfig.pyright.setup({})
    lspconfig.tsserver.setup({})
    lspconfig.gopls.setup({})
    lspconfig.rust_analyzer.setup({})
    lspconfig.clangd.setup({})
  end,
}