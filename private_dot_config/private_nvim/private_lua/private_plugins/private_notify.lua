return {
  "rcarriga/nvim-notify",
  lazy = false,
  config = function()
    local notify = require("notify")
    vim.notify = notify
    notify.setup({
      stages = "slide",
      -- catppuccin is transparent; notify needs a solid colour to animate against
      background_colour = "#1e1e2e",
    })
  end,
}
