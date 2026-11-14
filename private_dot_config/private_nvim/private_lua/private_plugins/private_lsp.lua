return {
  "neovim/nvim-lspconfig",
  config = function()
    -- global, not LspAttach-scoped; which-key groups/icons live in whichkey.lua
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
    end
    map("<leader>a", "<cmd>lua vim.lsp.buf.code_action()<cr>", "Apply code action")
    map("<leader>q", "<cmd>lua vim.diagnostic.setloclist()<cr>", "Quickfix code action")
    map("<leader>k", "<cmd>lua vim.lsp.buf.hover()<cr>", "Show documentation for symbol under cursor")
    map("<leader>r", "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename symbol")
    map("<leader>ll", "<cmd>lua vim.lsp.codelens.run()<cr>", "CodeLens Action")
    map("gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", "Go to declaration")

    vim.diagnostic.config({
      -- [d/]d are Neovim defaults (vim.diagnostic.jump); show the float after each jump
      jump = {
        on_jump = function(_, bufnr)
          vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
        end,
      },
      -- NvChad's sign icons (nvchad-ui lua/nvchad/lsp/init.lua) instead of E/W/I/H
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = "\u{f0159}",
          [vim.diagnostic.severity.WARN] = "\u{f071}",
          [vim.diagnostic.severity.INFO] = "\u{f02fc}",
          [vim.diagnostic.severity.HINT] = "\u{f0335}",
        },
      },
    })

    -- texlab, tinymist and clojure_lsp live in vimtex/, typst/ and clojure/ in nixvim
    -- freebsd: binaries come from pkg or Mason (npm/go/cargo builds), see mason-lspconfig.lua
    local servers = {
      ansiblels = {
        -- lint only where ansible-lint exists, else it warns on every open
        settings = { ansible = { validation = { lint = { enabled = vim.fn.executable("ansible-lint") == 1 } } } },
      },
      -- project typescript first, else a TS that still ships tsserverlibrary.js (TS 7 dropped it)
      -- freebsd: nixvim falls back to nixpkgs typescript_5; here TS 6 bundled with Mason's ts_ls
      astro = {
        before_init = function(_, config)
          local tsdk = require("lspconfig.util").get_typescript_server_path(config.root_dir)
          config.init_options.typescript.tsdk = tsdk ~= "" and tsdk
            or vim.fn.stdpath("data") .. "/mason/packages/typescript-language-server/node_modules/typescript/lib"
        end,
      },
      bashls = {},
      clangd = {},
      clojure_lsp = {},
      cssls = {},
      dagger = {},
      dockerls = {},
      emmet_ls = {},
      eslint = {},
      -- freebsd: lspconfig's gopls root_dir runs `go env` and throws on every go buffer
      -- without the go command (pkg go; go126 alone has no `go`)
      gopls = vim.fn.executable("go") == 1 and {} or nil,
      graphql = {},
      html = {},
      jsonls = {},
      lua_ls = {},
      markdown_oxide = {
        capabilities = { workspace = { didChangeWatchedFiles = { dynamicRegistration = true } } },
      },
      -- freebsd: nixd has no FreeBSD build; nil (Mason, cargo) instead
      nil_ls = {},
      perlnavigator = {},
      -- freebsd: PowerShellEditorServices from Mason instead of nixpkgs; only with pwsh, since
      -- its cmd is a function, which skips the executable check and errors on every .ps1
      powershell_es = vim.fn.executable("pwsh") == 1 and {
        bundle_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services",
      } or nil,
      prismals = {},
      sqlls = {},
      tailwindcss = {},
      terraformls = {
        cmd = { "tofu-ls", "serve", "-log-file=/dev/null" }, -- no log level; stderr tracing floods lsp.log
        -- tofu-ls reads this from init_options only; as settings.terraform-ls it was ignored
        init_options = { ignoreSingleFileWarning = true },
      },
      texlab = {
        settings = {
          texlab = {
            build = {
              executable = "latexmk",
              args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
              onSave = true,
            },
            forwardSearch = {
              executable = "zathura",
              args = { "--synctex-forward", "%l:1:%f", "%p" },
            },
            chktex = { onOpenAndSave = true, onEdit = false },
          },
        },
      },
      tinymist = {
        settings = {
          formatterMode = "typstyle",
          exportPdf = "onSave",
        },
      },
      ts_ls = {},
      vimls = {},
      yamlls = { filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values", "yaml.ansible" } },
    }

    for name, cfg in pairs(servers) do
      vim.lsp.config(name, cfg)
      vim.lsp.enable(name)
    end
  end,
}
