-- Requires tmuxPlugins.vim-tmux-navigator on the tmux side.
return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate Left" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate Down" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate Up" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate Right" },
    },
  },
}
