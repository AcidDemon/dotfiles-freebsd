-- snacks keys terminals by cmd/cwd/env/count, so a per-position env gives each key
-- its own shell; a count (2<A-b>) opens another one in the same spot
local function terminal(key, position, desc)
  return {
    key,
    function()
      Snacks.terminal.toggle(nil, { env = { NVX_TERM = position }, win = { position = position } })
    end,
    mode = { "n", "t" },
    silent = true,
    desc = desc,
  }
end

return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  -- don't override the existing lazygit config
  opts = { lazygit = { configure = false } },
  keys = {
    terminal("<A-b>", "bottom", "Terminal toggle horizontal"),
    terminal("<A-v>", "right", "Terminal toggle vertical"),
    terminal("<A-f>", "float", "Terminal toggle float"),
    { "<leader>gg", function() Snacks.lazygit() end, silent = true, desc = "Git lazygit" },
    { "<leader>tz", function() Snacks.zen() end, silent = true, desc = "Toggle zen mode" },
    { "<leader>tZ", function() Snacks.zen.zoom() end, silent = true, desc = "Toggle zoom" },
  },
}
