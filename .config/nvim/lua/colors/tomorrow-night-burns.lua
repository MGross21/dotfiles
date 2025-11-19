-- Tomorrow Night Burns Colorscheme
local colors = {
  black = "#252525",
  red = "#832e31",
  green = "#a63c40",
  yellow = "#d3494e",
  blue = "#fc595f",
  purple = "#df9395",
  cyan = "#ba8586",
  white = "#f5f5f5",
  bright_black = "#5d6f71",
  bright_red = "#832e31",
  bright_green = "#a63c40",
  bright_yellow = "#d2494e",
  bright_blue = "#fc595f",
  bright_purple = "#df9395",
  bright_cyan = "#ba8586",
  bright_white = "#f5f5f5",
  background = "#151515",
  foreground = "#a1b0b8",
  selection_background = "#b0bec5",
  cursor_color = "#ff443e",
}

local function set_highlights()
  vim.cmd("highlight clear")
  vim.cmd("syntax reset")

  vim.o.background = "dark"
  vim.g.colors_name = "tomorrow-night-burns"

  local highlight = function(group, opts)
    vim.api.nvim_set_hl(0, group, {
      fg = opts.fg,
      bg = opts.bg,
      sp = opts.sp,
      italic = opts.gui == "italic",
      bold = opts.gui == "bold",
      underline = opts.gui == "underline",
    })
  end

  -- Editor
  highlight("Normal", { fg = colors.foreground, bg = colors.background })
  highlight("Cursor", { fg = colors.background, bg = colors.cursor_color })
  highlight("Visual", { bg = colors.selection_background })
  highlight("LineNr", { fg = colors.bright_black })
  highlight("CursorLineNr", { fg = colors.yellow })

  -- Syntax
  highlight("Comment", { fg = colors.bright_black, gui = "italic" })
  highlight("Constant", { fg = colors.cyan })
  highlight("String", { fg = colors.green })
  highlight("Function", { fg = colors.blue })
  highlight("Keyword", { fg = colors.red })
  highlight("Type", { fg = colors.yellow })
  highlight("Variable", { fg = colors.foreground })

  -- Diagnostics
  highlight("DiagnosticError", { fg = colors.red })
  highlight("DiagnosticWarn", { fg = colors.yellow })
  highlight("DiagnosticInfo", { fg = colors.blue })
  highlight("DiagnosticHint", { fg = colors.cyan })
end

set_highlights()