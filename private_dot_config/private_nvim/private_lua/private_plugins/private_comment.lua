-- the old setup() only restated Comment.nvim's defaults; its ts_context_commentstring
-- pre_hook was a no-op (plugin never installed)
return {
  "numToStr/Comment.nvim",
  config = function()
          local wk = require "which-key"
          wk.add {
            { "<leader>c", "<Plug>(comment_toggle_linewise_current)", desc = "(Un)comment selection" },
            { "<leader>c", "<Plug>(comment_toggle_linewise_visual)", desc = "(Un)comment selection", mode = "v" },
          }

          require("Comment").setup()
  end
}
