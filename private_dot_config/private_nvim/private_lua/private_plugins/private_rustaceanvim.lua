return {
  "mrcjkb/rustaceanvim",
  version = "^9",
  lazy = false, -- the plugin lazy-loads itself on rust buffers
  init = function()
    -- rust-analyzer from PATH (pkg rust-analyzer); debugging falls back to lldb-dap
    vim.g.rustaceanvim = { server = { cmd = { "rust-analyzer" } } }
    -- clear rust-analyzer's comment token so it doesn't paint over comment highlighting;
    -- re-applied on every :colorscheme, which resets it (theme switches)
    local function clear()
      vim.api.nvim_set_hl(0, "@lsp.type.comment.rust", {})
    end
    clear()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("RustaceanHl", { clear = true }),
      callback = clear,
    })
  end,
}
