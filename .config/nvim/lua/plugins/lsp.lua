return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = true },
      codelens = { enabled = true },
      diagnostics = {
        virtual_text = { spacing = 4, source = "if_many", prefix = "●" },
        severity_sort = true,
        float = { border = "rounded", source = "if_many" },
      },
      servers = {
        nil_ls = { enabled = false },
        nixd = {
          settings = {
            nixd = {
              formatting = { command = { "nixfmt" } },
              nixpkgs = { expr = "import <nixpkgs> { }" },
            },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              hint = { enable = true, arrayIndex = "Disable" },
              diagnostics = { globals = { "vim" } },
            },
          },
        },
        bashls = {},
      },
    },
  },
}
