-- loaded by the autocmd below, not `ft`: that re-runs every FileType autocmd of the buffer
-- (treesitter, LSP, ftplugin). nixvim autoActivate = false: no activation on every LspAttach
return {
  "jmbuhr/otter.nvim",
  lazy = true,
  init = function()
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "markdown", "quarto", "norg" },
      desc = "Activate otter for embedded code",
      callback = function(args)
        -- freebsd: parsers are built on demand; otter throws without the buffer's one
        if vim.treesitter.get_parser(args.buf, nil, { error = false }) then
          require("otter").activate()
        end
      end,
    })
  end,
  opts = {
    buffers = { write_to_disk = false },
    handle_leading_whitespace = true,
  },
}
