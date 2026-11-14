-- freebsd: Mason only for npm/go/cargo-built servers and the PSES zip; its prebuilt
-- GitHub binaries have no FreeBSD target, so the rest comes from pkg (see lsp.lua)
return {
  "williamboman/mason-lspconfig.nvim",
  dependencies = { "williamboman/mason.nvim" },
  config = function()
    local ensure_installed = {
      "ansiblels",
      "astro",
      "bashls",
      "cssls",
      "dockerls",
      "emmet_ls",
      "eslint",
      "graphql",
      "html",
      "jsonls",
      "perlnavigator",
      "powershell_es",
      "prismals",
      "sqlls",
      "tailwindcss",
      "ts_ls",
      "vimls",
      "yamlls",
    }
    -- freebsd: Mason builds this from source; without go the install fails with an ERROR on every start
    if vim.fn.executable("go") == 1 then table.insert(ensure_installed, "dagger") end
    -- freebsd: no nil_ls. Its build.rs runs `nix eval` to list the builtins, and there is no nix here;
    -- nixd has no FreeBSD build either, so .nix files get no language server
    -- (lsp.lua keeps nil_ls configured: it starts only if a nil binary appears on PATH)

    require("mason-lspconfig").setup({
      -- lsp.lua enables exactly its own servers, as nixvim does; the default would also
      -- start every installed Mason server
      automatic_enable = false,
      ensure_installed = ensure_installed,
    })
  end
}
