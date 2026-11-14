-- not lazy: blink registers its LSP capabilities on setup, so servers started before
-- the first InsertEnter would miss them. snippets use the built-in vim.snippet preset,
-- which also reads friendly-snippets from the runtimepath.
return {
  "saghen/blink.cmp",
  version = "1.*",
  lazy = false,
  dependencies = {
    "rafamadriz/friendly-snippets",
    "Kaiser-Yang/blink-cmp-git",
    "mikavilpas/blink-ripgrep.nvim",
  },
  opts = {
    keymap = {
      preset = "none",
      ["<C-k>"] = { "select_prev", "fallback" },
      ["<C-j>"] = { "select_next", "fallback" },
      ["<Up>"] = { "select_prev", "fallback" },
      ["<Down>"] = { "select_next", "fallback" },
      ["<C-b>"] = { "scroll_documentation_up", "fallback" },
      ["<C-f>"] = { "scroll_documentation_down", "fallback" },
      ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
      ["<C-e>"] = { "hide", "fallback" },
      ["<Tab>"] = { "select_and_accept", "fallback" },
    },

    -- a mapped Tab can't fire wildchar, so the inherited fallback typed a literal ^I
    cmdline = {
      keymap = {
        preset = "inherit",
        ["<Tab>"] = { "show_and_insert_or_accept_single", "select_next" },
        ["<S-Tab>"] = { "select_prev" },
      },
    },

    completion = { documentation = { auto_show = true } },
    signature = { enabled = true },

    -- fuzzy: the default Rust matcher, as nixvim; for the version tag blink downloads its
    -- x86_64-unknown-freebsd prebuilt (curl, sha256sum) into lazy/blink.cmp/target/release

    sources = {
      default = { "lsp", "snippets", "buffer", "path", "git", "ripgrep" },
      providers = {
        git = {
          module = "blink-cmp-git",
          name = "Git",
        },
        ripgrep = {
          module = "blink-ripgrep",
          name = "Ripgrep",
          async = true,
          score_offset = -10,
        },
      },
    },
  },
}
