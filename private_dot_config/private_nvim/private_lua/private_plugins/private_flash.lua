local function key(mode, lhs, fn, desc)
  return { lhs, function() require("flash")[fn]() end, mode = mode, silent = true, desc = desc }
end

return {
  "folke/flash.nvim",
  -- eager like nixvim: flash's f/F/t/T char mode works before the first s
  lazy = false,
  opts = {},
  keys = {
    key({ "n", "x", "o" }, "s", "jump", "Flash"),
    key({ "n", "x", "o" }, "S", "treesitter", "Flash treesitter"),
    key("o", "r", "remote", "Remote flash"),
    key({ "o", "x" }, "R", "treesitter_search", "Treesitter search"),
    key("c", "<c-s>", "toggle", "Toggle flash search"),
  },
}
