local map = vim.keymap.set

map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>Q", "<cmd>qa<cr>", { desc = "Quit All" })

map("n", "J", "mzJ`z", { desc = "Join Line" })
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

map("x", "<leader>p", [["_dP]], { desc = "Paste (keep register)" })
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete (no yank)" })

map("v", "<", "<gv")
map("v", ">", ">gv")
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move Selection Down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move Selection Up" })

map("n", "<leader>ur", "<cmd>nohlsearch<cr>", { desc = "Clear Search Highlight" })
