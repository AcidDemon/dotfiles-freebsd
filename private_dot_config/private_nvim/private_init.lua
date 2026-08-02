require("options.options")
require("options.autocmds")
require("options.filetype")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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

-- after lazy: plugins must be on the runtime path first
require("options.keymaps")
