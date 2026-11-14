return {
  {
    "Olical/conjure",
    ft = "clojure", -- = conjure#filetypes
    init = function()
      -- Conjure maps <localleader> keys in every filetype it supports; keep it to Clojure
      vim.g["conjure#filetypes"] = { "clojure" }
      -- a string gets the <localleader> prefix (<localleader>gk); Conjure's default {"K"} does not
      vim.g["conjure#mapping#doc_word"] = "gk"
      vim.g["conjure#highlight#enabled"] = true
      -- buffer-local: localleader == leader, so global groups would relabel <leader>e/l/t/c
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "clojure",
        callback = function(ev)
          local ok, wk = pcall(require, "which-key")
          if ok then
            wk.add({
              buffer = ev.buf,
              { "<localleader>e", group = "Conjure: eval" },
              { "<localleader>l", group = "Conjure: log" },
              { "<localleader>t", group = "Conjure: test" },
              { "<localleader>c", group = "Conjure: connect" },
            })
          end
        end,
      })
    end,
  },
  {
    "guns/vim-sexp",
    ft = { "clojure", "scheme", "lisp", "timl", "fennel", "janet" }, -- its g:sexp_filetypes default
    init = function()
      vim.g.sexp_enable_insert_mode_mappings = 0
    end
  },
  -- regular-people loads after vim-sexp (a dependency), so its FileType maps run last
  {
    "tpope/vim-sexp-mappings-for-regular-people",
    dependencies = { "guns/vim-sexp", "tpope/vim-repeat" },
    ft = { "clojure", "scheme", "lisp", "timl", "fennel", "janet" },
  }
}
