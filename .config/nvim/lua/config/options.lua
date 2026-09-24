vim.opt.termguicolors = true

vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.cursorline = true
vim.opt.colorcolumn = "100"
vim.opt.wrap = false
vim.opt.linebreak = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.smartindent = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.inccommand = "split"

vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.swapfile = false
vim.opt.updatetime = 200
vim.opt.timeoutlen = 300

vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.splitkeep = "screen"

vim.opt.confirm = true
vim.opt.pumheight = 12
vim.opt.pumblend = 0
vim.opt.winblend = 0
vim.opt.signcolumn = "yes"
vim.opt.laststatus = 3

vim.opt.list = true
vim.opt.listchars = { tab = "→ ", trail = "·", nbsp = "␣", extends = "›", precedes = "‹" }
vim.opt.fillchars = { eob = " ", fold = " ", foldsep = " " }

vim.opt.clipboard = "unnamedplus"

vim.g.lazyvim_picker = "snacks"
vim.g.lazyvim_python_lsp = "pyright"
vim.g.lazyvim_python_ruff = "ruff"
