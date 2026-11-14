local prettier = { "prettierd", "prettier", stop_after_first = true }

return {
  "stevearc/conform.nvim",
  config = function()
    require("conform").setup({
      -- conform resolves lsp_format as call > formatters_by_ft row > default_format_opts,
      -- so a row can still opt out
      default_format_opts = { lsp_format = "fallback" },
      formatters_by_ft = {
        lua = { "stylua" },
        go = { "goimports", "gofumpt" },
        nix = { "alejandra" },
        python = { "black" },
        rust = { "rustfmt" },
        sh = { "shfmt" },
        -- never format on save (the old ignore list)
        sql = { lsp_format = "never" },
        -- latex.enableFormatting is on for desktop; plaintex has no formatter, texlab formats it
        tex = { "latexindent", lsp_format = "fallback" },
        plaintex = { lsp_format = "fallback" },
        htmlangular = prettier,
        css = prettier,
        graphql = prettier,
        html = prettier,
        javascript = prettier,
        json = prettier,
        javascriptreact = prettier,
        less = prettier,
        markdown = prettier,
        scss = prettier,
        typescript = prettier,
        typescriptreact = prettier,
        vue = prettier,
        yaml = prettier,
      },
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        if vim.api.nvim_buf_get_name(bufnr):match("/node_modules/") then
          return
        end
        return { timeout_ms = 500 }
      end,
    })

    vim.api.nvim_create_user_command("FormatToggle", function(args)
      if args.bang then
        vim.b.disable_autoformat = not vim.b.disable_autoformat
        print("Document autoformat " .. (vim.b.disable_autoformat and "disabled" or "enabled"))
      else
        vim.g.disable_autoformat = not vim.g.disable_autoformat
        print("Global autoformat " .. (vim.g.disable_autoformat and "disabled" or "enabled"))
      end
    end, {
      desc = "Toggle autoformat-on-save (use ! for buffer-local)",
      bang = true,
    })
  end
}
