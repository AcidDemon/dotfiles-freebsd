vim.loader.enable(true)

-- before lazy.setup: its `keys` stubs are made with the leader set at that time
vim.g.mapleader = " "
-- differs from nixvim (" "): with localleader == leader, Conjure and vim-sexp shadow leader maps in clojure buffers
vim.g.maplocalleader = ","

require("options.options")
require("options.autocmds")
require("options.filetype")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "env",
    "HOME=/var/empty",
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Disabled rocks/hererocks support to prevent FreeBSD compilation loops
require("lazy").setup("plugins", {
  rocks = {
    enabled = false,
  }
})

-- after the plugins, as in nixvim
require("options.keymaps")
