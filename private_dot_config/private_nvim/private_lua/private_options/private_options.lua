-- values equal to the nvim 0.12 defaults are left out, as in nixvim

vim.opt.clipboard = "unnamedplus"
-- osc 52 only without wayland (ssh); locally nvim picks wl-copy, whose reads
-- don't hit kitty's read-clipboard-ask prompt. table, not the 'osc52' string:
-- which-key's and snacks' register views skip reading +/* only for name "OSC 52"
if (vim.env.WAYLAND_DISPLAY or "") == "" then
  local osc52 = require("vim.ui.clipboard.osc52")
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = osc52.paste("+"), ["*"] = osc52.paste("*") },
  }
end

-- freebsd: nixvim ships the python3/ruby/node hosts; no plugin here uses a remote
-- plugin host, so they are off instead of failing :checkhealth
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0

-- General
vim.opt.undofile = true
vim.opt.mouse = "nv" -- No mouse in cmdline mode
vim.opt.synmaxcol = 2500
vim.opt.history = 2000
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.autowrite = true
vim.opt.autowriteall = true
vim.opt.modeline = false
vim.opt.swapfile = false
vim.opt.writebackup = false
vim.opt.completeopt = { "menuone", "noselect" }

-- Formatting
vim.opt.iskeyword:append("-") -- Hyphenated words
vim.opt.fillchars = { eob = " " } -- Hide EOB tildes; default fillchars is empty, so set == append
vim.opt.fileencoding = "utf-8"
vim.opt.wrap = false
vim.opt.textwidth = 80
vim.opt.linebreak = true
vim.opt.formatoptions:remove({ "c", "r", "o" }) -- ftplugins re-add these, see autocmds
vim.opt.whichwrap:append("h,l,<,>,[,],~")

-- Searching
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.infercase = true

-- Tabs & Indents
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.smartindent = true
vim.opt.shiftround = true
vim.opt.foldenable = false
vim.opt.foldmethod = "indent"

-- Timing
vim.opt.timeoutlen = 300
vim.opt.ttimeoutlen = 10
vim.opt.updatetime = 200
vim.opt.redrawtime = 1500

-- Editor UI
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.shortmess:append("c") -- Hide completion messages
vim.opt.scrolloff = 2
vim.opt.sidescrolloff = 5
vim.opt.ruler = false
-- Every normal-mode key is echoed bottom right while it runs; arrows show as "~@k"
vim.opt.showcmd = false

vim.opt.helpheight = 12
vim.opt.winwidth = 30
vim.opt.winminwidth = 10

vim.opt.cmdwinheight = 5
vim.opt.equalalways = false
vim.opt.laststatus = 3
vim.opt.signcolumn = "yes"
vim.opt.pumheight = 15

vim.opt.number = true
vim.opt.relativenumber = true
