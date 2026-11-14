-- NvChad's statusline, tabufline and cheatsheet. base46 only colours these three; catppuccin.nvim
-- keeps every other highlight, so base46's load_all_highlights is never run.
local M = {}

local function load_highlights()
  local opts = require("nvconfig").base46
  -- nvx.theme sets the statusline theme that belongs to the desktop theme
  local light = vim.o.background == "light"
  opts.theme = vim.g.nvx_base46 or "catppuccin"
  vim.g.toggle_theme_icon = light and " \u{f204}  " or " \u{f205}  "

  -- the integration modules compute their colours when first required
  for _, mod in ipairs({
    "base46.integrations.statusline",
    "base46.integrations.statusline.default",
    "base46.integrations.tbline",
    "base46.integrations.nvcheatsheet",
  }) do
    package.loaded[mod] = nil
  end

  -- tabufline dofile()s its highlights from the cache, as in NvChad
  local base46 = require("base46")
  vim.fn.mkdir(vim.g.base46_cache, "p")
  for _, name in ipairs({ "statusline", "tbline", "nvcheatsheet" }) do
    base46.str_to_cache(name, base46.tb_2str(base46.get_integration(name)))
    dofile(vim.g.base46_cache .. name)
  end
end

-- flips between Catppuccin Mocha and Latte until the desktop theme changes again
function M.toggle_theme()
  require("nvx.theme").apply(vim.o.background == "light" and "catppuccin-mocha" or "catppuccin-latte")
end

function M.setup()
  -- base46 reads this once, when first required
  vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46/"
  load_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", { callback = load_highlights })

  vim.o.statusline = "%!v:lua.require('nvchad.stl.default')()"
  require("nvchad.stl.utils").autocmds()

  require("nvchad.tabufline.lazyload")
  -- modules defines the tabline click handlers when first required; its theme
  -- button would hand every highlight over to base46, so swap the colorscheme instead
  require("nvchad.tabufline.modules")
  vim.cmd([[
    function! TbToggle_theme(a,b,c,d)
      lua require("nvx.bars").toggle_theme()
    endfunction
    function! TbTabClose(a,b,c,d)
      tabclose
    endfunction
  ]])
end

return M
