-- ponytail: eager load (plugin/mkdp.vim sources in ~0.07ms); a lazy load from the keymaps
-- missed its buffer-local :MarkdownPreview* commands, defined only on BufEnter/FileType
return {
  "iamcco/markdown-preview.nvim",
  lazy = false,
  -- freebsd: mkdp#util#install fetches a Linux/macOS binary only; mkdp runs
  -- `node app/index.js` instead, which needs the app's npm deps
  build = "cd app && npm install",
  init = function()
    vim.g.mkdp_auto_start = 0
    vim.g.mkdp_auto_close = 0
    vim.g.mkdp_refresh_slow = 0
    vim.g.mkdp_command_for_global = 0
    vim.g.mkdp_open_to_the_world = 0
    vim.g.mkdp_open_ip = '127.0.0.1'
    vim.g.mkdp_port = '8765'
    vim.g.mkdp_browser = ""
    vim.g.mkdp_echo_preview_url = 1
    vim.g.mkdp_page_title = '${name}'
    vim.g.mkdp_theme = 'dark'
    -- empty preview_options lists dropped (the app defaults each to {})
    vim.g.mkdp_preview_options = {
      disable_sync_scroll = 0,
      sync_scroll_type = 'middle',
      hide_yaml_meta = 1,
      content_editable = false,
      disable_filename = 0,
    }
    vim.g.mkdp_markdown_css = ""
    vim.g.mkdp_highlight_css = ""
    vim.g.mkdp_filetypes = { "markdown" }
  end,
  -- the <leader>m group (shared with render-markdown's <leader>mr) lives in whichkey.lua
  keys = {
    { "<leader>mp", "<cmd>MarkdownPreview<cr>", desc = "Start preview" },
    { "<leader>ms", "<cmd>MarkdownPreviewStop<cr>", desc = "Stop preview" },
    { "<leader>mt", "<cmd>MarkdownPreviewToggle<cr>", desc = "Toggle preview" },
  },
}
