-- mapleader is set in init.lua, before lazy.setup creates the `keys` stubs
local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

-- Handle typos
vim.cmd([[
    cnoreabbrev W w
    cnoreabbrev Q q
    cnoreabbrev qw wq
    cnoreabbrev Wq wq
    cnoreabbrev WQ wq
    cnoreabbrev Qa qa
    cnoreabbrev # q
    cnoreabbrev w# wq
    cnoreabbrev W# wq
    cnoreabbrev #w wq
    cnoreabbrev #W wq
    cnoreabbrev #a wq
    cnoreabbrev Bd bd
    cnoreabbrev bD bd
]])

map("", "<Space>", "<Nop>")

-- Stay in indent mode
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Maintain cursor position and keep it centered during search & joining
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
map("n", "J", "mzJ`z")

-- Navigation
map("n", "ga", "<cmd>e#<CR>", "Go to last accessed file")
map("n", "gn", "<cmd>bnext<cr>", "Go to next buffer")
map("n", "gp", "<cmd>bprevious<cr>", "Go to previous buffer")

-- Editor
map("n", "<CR>", "<cmd>let @/ = ''<CR><CR>", "Toggle visual effects")
map("n", "<leader>ts", "<cmd>setlocal spell!<cr>", "Toggle spell checking")
map("n", "<leader>tn", "<cmd>setlocal nonumber!<CR><cmd>setlocal rnu!<CR>", "Toggle line numbers")
map("n", "<leader>tw", "<cmd>execute('setlocal wrap! breakindent! colorcolumn='. (&colorcolumn == '' ? &textwidth : ''))<CR>", "Toggle wrapping")
