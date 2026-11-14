-- catppuccin at startup; nvx.theme then switches to the desktop theme's colorscheme.
-- the others are lazy: lazy.nvim loads one (and runs its opts) on `:colorscheme <name>`.
-- transparent like catppuccin, so the terminal's background shows through
return {
  {
    "catppuccin/nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        background = {
          light = "latte",
          dark = "mocha",
        },
        transparent_background = true,
        term_colors = false,
        integrations = {
          alpha = true,
          blink_cmp = true,
          gitsigns = true,
          nvimtree = true,
          treesitter_context = true,
          which_key = true,
          telescope = { enabled = true },
          illuminate = {
            enabled = true,
            lsp = false,
          },
          indent_blankline = { enabled = true },
          dap = true,
          dap_ui = true,
        },
      })
      require("nvx.theme").setup()
    end,
  },
  { "Mofiqul/dracula.nvim", lazy = true, opts = { transparent_bg = true } },
  {
    "sainnhe/everforest",
    lazy = true,
    init = function()
      vim.g.everforest_background = "medium"
      vim.g.everforest_transparent_background = 1
    end,
  },
  { "projekt0n/github-nvim-theme", lazy = true, main = "github-theme", opts = { options = { transparent = true } } },
  { "ellisonleao/gruvbox.nvim", lazy = true, opts = { transparent_mode = true } },
  { "rebelot/kanagawa.nvim", lazy = true, opts = { theme = "wave", transparent = true } },
  {
    "shaunsingh/nord.nvim",
    lazy = true,
    init = function()
      vim.g.nord_disable_background = true
    end,
  },
  { "navarasu/onedark.nvim", lazy = true, opts = { style = "dark", transparent = true } },
  { "rose-pine/neovim", name = "rose-pine", lazy = true, opts = { variant = "main", styles = { transparency = true } } },
  { "craftzdog/solarized-osaka.nvim", lazy = true, opts = { transparent = true } },
  { "folke/tokyonight.nvim", lazy = true, opts = { style = "night", transparent = true } },
}
