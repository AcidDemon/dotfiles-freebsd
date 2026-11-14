-- nixvim ships every grammar (allGrammars). freebsd: no prebuilt grammars, so a missing
-- parser is compiled on first use (tree-sitter-cli + cc). full set once, from a shell:
--   nvim --headless -c 'lua require("nvim-treesitter").install("all"):wait(3600000)' -c qa
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    -- global, as nixvim: filetypes whose indent script sets indentexpr keep theirs
    vim.o.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

    local tried = {}
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("TreesitterSetup", { clear = true }),
      callback = function(args)
        if pcall(vim.treesitter.start, args.buf) then
          return
        end
        -- freebsd: on-demand install, once per language and session
        local lang = vim.treesitter.language.get_lang(args.match)
        if not lang or tried[lang] or not require("nvim-treesitter.parsers")[lang] then
          return
        end
        tried[lang] = true
        require("nvim-treesitter").install(lang):await(vim.schedule_wrap(function()
          if vim.api.nvim_buf_is_valid(args.buf) then
            pcall(vim.treesitter.start, args.buf)
          end
        end))
      end,
    })
  end,
}
