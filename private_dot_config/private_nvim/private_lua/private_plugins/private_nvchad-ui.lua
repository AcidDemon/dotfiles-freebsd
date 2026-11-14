-- NvChad's statusline, tabufline and cheatsheet (lua/nvx/bars.lua, lua/chadrc.lua)
local tabufline = function() return require("nvchad.tabufline") end

-- position in the tabufline, which keeps buffers in vim.t.bufs per tab
local keys = {
  { "<leader>x", function() tabufline().close_buffer() end, silent = true, desc = "Close buffer" },
  { "<leader>?", function() require("nvchad.cheatsheet.grid")() end, silent = true, desc = "Cheatsheet open" },
}
for n = 1, 9 do
  table.insert(keys, {
    "<leader>" .. n,
    function()
      local buf = (vim.t.bufs or {})[n]
      if buf then tabufline().goto_buf(buf) end
    end,
    silent = true,
    desc = "Go to buffer " .. n,
  })
end

return {
  "nvchad/ui",
  lazy = false,
  -- volt: nixpkgs' nvchad-ui dependency
  dependencies = { "nvchad/base46", "nvzone/volt" },
  config = function() require("nvx.bars").setup() end,
  keys = keys,
}
