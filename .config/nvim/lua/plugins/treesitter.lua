return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      highlight = { enable = true },
      indent = { enable = true },
    })
  opts = {
    ensure_installed = { "c", "cpp", "lua", "python", "javascript", "html", "css" , "kotlin" },
  }
  end
}