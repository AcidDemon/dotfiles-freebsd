-- dropped (illuminate defaults): the empty allow/deny lists, under_cursor
return {
  "RRethy/vim-illuminate",
  config = function()
          require("illuminate").configure({
              providers = {
                  "lsp",
                  "treesitter",
                  "regex",
              },
              delay = 200,
              -- replaces the BufWinEnter IlluminatePauseBuf autocmd (>= 5000 lines)
              max_file_lines = 4999,
              filetypes_denylist = {
                  "DiffviewFiles",
                  "DressingInput",
                  "DressingSelect",
                  "Jaq",
                  "NeogitCommitMessage",
                  "NeogitStatus",
                  "NvimTree",
                  "Outline",
                  "TelescopePrompt",
                  "Trouble",
                  "alpha",
                  "dirvish",
                  "fugitive",
                  "harpoon",
                  "lazy",
                  "lir",
                  "minifiles",
                  "neogitstatus",
                  "netrw",
                  "packer",
                  "qf",
                  "spectre_panel",
                  "toggleterm",
              },
          })
  end
}
