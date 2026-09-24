return {
  {
    "folke/todo-comments.nvim",
    opts = {
      keywords = {
        TEST = { icon = " ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
      },
      colors = {
        test = { "Identifier", "#ba8586" },
      },
      highlight = { multiline = true },
    },
  },
}
