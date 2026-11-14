-- Cleared on re-source, so the autocmds below never stack
local group = vim.api.nvim_create_augroup("user_autocmds", { clear = true })
local function autocmd(event, opts)
  opts.group = group
  vim.api.nvim_create_autocmd(event, opts)
end

autocmd("FileType", {
  pattern = { "qf", "help", "man" },
  desc = "q closes the window, buffer unlisted",
  callback = function(args)
    vim.keymap.set("n", "q", ":close<CR>", { buffer = args.buf, silent = true })
    vim.bo[args.buf].buflisted = false
  end,
})

autocmd("FileType", {
  pattern = { "gitcommit", "markdown" },
  desc = "Wrap/spell for markdown & gitcommit",
  callback = function()
    vim.opt_local.textwidth = 72
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- nixvim: nvim-tree's autoClose option; nvim-tree.lua has no such setting. nixvim compares
-- with tabpagenr(), but nvim-tree names its buffer after the tab handle (view.lua), and
-- quits inside the BufEnter of a window close, which raises E1312; so scheduled here
autocmd("BufEnter", {
  nested = true,
  desc = "Quit when nvim-tree is the last window",
  callback = function()
    vim.schedule(function()
      if vim.fn.winnr("$") == 1 and vim.fn.bufname() == "NvimTree_" .. vim.api.nvim_get_current_tabpage() then
        vim.cmd("quit")
      end
    end)
  end,
})

autocmd("CursorHold", {
  desc = "Diagnostic tooltip",
  callback = function()
    vim.diagnostic.open_float({ focusable = false })
  end,
})

-- Runs after ftplugins (loaded before init.lua), which re-add c/r/o
autocmd("FileType", {
  desc = "No comment continuation",
  callback = function()
    vim.opt_local.formatoptions:remove({ "c", "r", "o" })
  end,
})

-- tabdo, not nvim_win_call: that would skip the row update of non-current tabs
autocmd("VimResized", {
  desc = "Equalize splits in all tabs",
  callback = function()
    local tab = vim.api.nvim_get_current_tabpage()
    vim.cmd("tabdo wincmd =")
    vim.api.nvim_set_current_tabpage(tab)
  end,
})

autocmd("TextYankPost", {
  desc = "Highlight yanked text",
  callback = function()
    vim.hl.on_yank({ higroup = "Visual", timeout = 200 })
  end,
})

autocmd("BufWritePre", {
  desc = "Trim trailing whitespace",
  callback = function()
    if not vim.bo.modifiable then
      return
    end
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd([[%s/\s\+$//e]])
    vim.api.nvim_win_set_cursor(0, cursor_pos)
  end,
})
