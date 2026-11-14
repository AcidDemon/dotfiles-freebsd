-- eager: vimtex advises against lazy loading (inverse search), and its g: vars must be set first
return {
  "lervag/vimtex",
  lazy = false,
  init = function()
    vim.g.vimtex_compiler_method = 'latexmk'
    vim.g.vimtex_compiler_latexmk = {
      options = {
        '-pdf',
        '-shell-escape',
        '-verbose',
        '-file-line-error',
        '-synctex=1',
        '-interaction=nonstopmode',
      },
    }

    vim.g.vimtex_view_method = 'zathura'

    -- indentation left to treesitter
    vim.g.vimtex_indent_enabled = 0

    -- syntax highlighting via treesitter
    vim.g.vimtex_syntax_enabled = 0

    -- Quickfix settings
    vim.g.vimtex_quickfix_mode = 0
  end,
  -- the <leader>L group and icons live in whichkey.lua
  keys = {
    { "<leader>Lc", "<cmd>VimtexCompile<cr>", desc = "Toggle continuous compilation" },
    { "<leader>Ls", "<cmd>VimtexCompileSS<cr>", desc = "Compile single-shot" },
    { "<leader>Lv", "<cmd>VimtexView<cr>", desc = "View PDF" },
    { "<leader>Le", "<cmd>VimtexErrors<cr>", desc = "Show errors" },
    { "<leader>Lt", "<cmd>VimtexTocToggle<cr>", desc = "Toggle table of contents" },
    { "<leader>Ll", "<cmd>VimtexLog<cr>", desc = "Show compiler log" },
    { "<leader>LC", "<cmd>VimtexClean<cr>", desc = "Clean auxiliary files" },
    { "<leader>Li", "<cmd>VimtexInfo<cr>", desc = "Show VimTeX info" },
  },
}
