return {
  "nvim-tree/nvim-tree.lua",
  config = function()
          local wk = require "which-key"
          wk.add {
            { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle explorer" },
          }

          local function my_on_attach(bufnr)
              local api = require("nvim-tree.api")

              local function opts(desc)
                  return {
                      desc = "nvim-tree: " .. desc,
                      buffer = bufnr,
                      noremap = true,
                      silent = true,
                      nowait = true,
                  }
              end

              api.config.mappings.default_on_attach(bufnr)

              vim.keymap.set("n", "l", api.node.open.edit, opts("Open"))
              vim.keymap.set(
                  "n",
                  "h",
                  api.node.navigate.parent_close,
                  opts("Close Directory")
              )
              vim.keymap.set(
                  "n",
                  "v",
                  api.node.open.vertical,
                  opts("Open: Vertical Split")
              )
              vim.keymap.del("n", "<C-k>", { buffer = bufnr })
              vim.keymap.set(
                  "n",
                  "<S-k>",
                  api.node.open.preview,
                  opts("Open Preview")
              )
          end

          -- values equal to the nvim-tree defaults dropped, as in nixvim
          require("nvim-tree").setup({
              on_attach = my_on_attach,
              sync_root_with_cwd = true,
              renderer = {
                  root_folder_label = ":t",
                  special_files = {
                      "Cargo.toml",
                      "Makefile",
                      "README.md",
                      "Readme.md",
                      "readme.md",
                  },
              },
              -- freebsd: nixvim's exclude skips /nix/store, which this host does not have
              update_focused_file = {
                  enable = true,
                  update_root = { enable = true },
              },
              diagnostics = {
                  enable = true,
                  debounce_delay = 50,
              },
              view = {
                  width = 32,
                  side = "left",
              },
          })
  end
}
