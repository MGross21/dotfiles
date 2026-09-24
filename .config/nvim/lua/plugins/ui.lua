local theme = require("config.theme")

return {
  {
    "folke/tokyonight.nvim",
    lazy = theme.name ~= "tokyonight-storm",
    priority = 1000,
    opts = { style = "storm", transparent = false, terminal_colors = true },
  },

  { "catppuccin/nvim", enabled = false },

  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = table.concat({
            "                      ",
            "  ███╗   ███╗ ██████╗ ",
            "  ████╗ ████║██╔════╝ ",
            "  ██╔████╔██║██║  ███╗",
            "  ██║╚██╔╝██║██║   ██║",
            "  ██║ ╚═╝ ██║╚██████╔╝",
            "  ╚═╝     ╚═╝ ╚═════╝ ",
            "                      ",
          }, "\n"),
        },
      },
      indent = { enabled = true, animate = { enabled = false } },
      scroll = { enabled = false },
      notifier = { enabled = true, timeout = 3000 },
      words = { enabled = true },
    },
  },

  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = vim.tbl_extend("force", opts.options or {}, {
        globalstatus = true,
        section_separators = "",
        component_separators = "│",
      })
      return opts
    end,
  },

  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        separator_style = "thin",
        show_buffer_close_icons = false,
        diagnostics = "nvim_lsp",
      },
    },
  },
}
