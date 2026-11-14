-- every which-key group and icon nixvim merges into plugins.which-key.settings.spec,
-- one block per nixvim file; icons are for keys which-key's built-in rules miss
return {
  "folke/which-key.nvim",
  opts = {
    spec = {
      -- keymaps
      { "<leader>t", group = "Toggle" },
      -- comment
      { "<leader>c", icon = { icon = "󰆂", color = "grey" } },
      -- dap
      { "<leader>G", group = "Debug" },
      -- lsp
      { "<leader>l", group = "LSP", icon = { icon = "󰅩", color = "blue" } },
      { "<leader>k", icon = { icon = "󱁯", color = "azure" } },
      { "<leader>r", icon = { icon = "󰑕", color = "orange" } },
      -- markdown-preview
      { "<leader>m", group = "Markdown", icon = { icon = "󰍔", color = "blue" } },
      { "<leader>mp", icon = { icon = "󰈈", color = "green" } },
      { "<leader>ms", icon = { icon = "󰙦", color = "red" } },
      -- neorg
      { "<leader>n", group = "Neorg", icon = { icon = "󰠮", color = "cyan" } },
      { "<leader>nj", icon = { icon = "󰃶", color = "yellow" } },
      { "<leader>nn", icon = { icon = "󰋜", color = "cyan" } },
      { "<leader>nr", icon = { icon = "󰌑", color = "grey" } },
      { "<leader>nt", icon = { icon = "󱄵", color = "yellow" } },
      { "<leader>nw", icon = { icon = "󰓡", color = "cyan" } },
      { "<leader>ny", icon = { icon = "󱄴", color = "yellow" } },
      -- obsidian
      { "<leader>o", group = "Obsidian", icon = { icon = "󰇈", color = "purple" } },
      { "<leader>ob", icon = { icon = "󰌹", color = "purple" } },
      { "<leader>od", icon = { icon = "󰃶", color = "yellow" } },
      { "<leader>of", icon = { icon = "󱅷", color = "purple" } },
      { "<leader>on", icon = { icon = "󰝒", color = "green" } },
      { "<leader>oo", icon = { icon = "󰶭", color = "purple" } },
      { "<leader>oy", icon = { icon = "󱄴", color = "yellow" } },
      -- table-mode
      { "<leader>|", group = "Table Mode" },
      { "<leader>|dc", icon = { icon = "󰓮", color = "red" } },
      { "<leader>|ic", icon = { icon = "󰓬", color = "green" } },
      -- telescope
      { "<leader>'", icon = { icon = "󰋚", color = "azure" } },
      { "<leader>j", icon = { icon = "󱞳", color = "azure" } },
      { "<leader>p", icon = { icon = "󰚝", color = "yellow" } },
      { "<leader>s", icon = { icon = "󰉹", color = "purple" } },
      { "<leader>S", icon = { icon = "󰒪", color = "purple" } },
      -- typst
      { "<leader>T", group = "Typst", icon = { icon = "󰬛", color = "cyan" } },
      { "<leader>Tf", icon = { icon = "󰆤", color = "cyan" } },
      { "<leader>TF", icon = { icon = "󰽅", color = "grey" } },
      { "<leader>Tp", icon = { icon = "󰈈", color = "green" } },
      { "<leader>Ts", icon = { icon = "󰙦", color = "red" } },
      { "<leader>TS", icon = { icon = "󰓦", color = "cyan" } },
      { "<leader>Tu", icon = { icon = "󰑐", color = "blue" } },
      -- vimtex
      { "<leader>L", group = "LaTeX", icon = { icon = "", color = "green" } },
      { "<leader>Le", icon = { icon = "󰩋", color = "red" } },
      { "<leader>Li", icon = { icon = "󰋽", color = "azure" } },
      { "<leader>Ll", icon = { icon = "󰈚", color = "grey" } },
      { "<leader>Ls", icon = { icon = "󰐊", color = "green" } },
      { "<leader>Lv", icon = { icon = "󰈦", color = "red" } },
    },
  },
}
