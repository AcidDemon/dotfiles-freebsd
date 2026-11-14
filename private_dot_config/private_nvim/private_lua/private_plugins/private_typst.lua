-- global keys (they load the plugin outside typst buffers too); the <leader>T group
-- and icons live in whichkey.lua
return {
  "chomosuke/typst-preview.nvim",
  ft = "typst",
  opts = {
    -- tinymist from PATH; unset, the plugin downloads Linux/macOS/Windows builds
    -- freebsd: websocat from pkg too (nixvim keeps the store path nixpkgs patches in)
    dependencies_bin = {
      tinymist = "tinymist",
      websocat = "websocat",
    },
  },
  config = function(_, opts)
    -- freebsd: its platform detection errors on FreeBSD even with dependencies_bin set;
    -- preset asset names (fetch.lua's documented escape hatch) skip it
    local fetch = require("typst-preview.fetch")
    fetch.tinymist_bin_name, fetch.websocat_bin_name = "tinymist", "websocat"
    require("typst-preview").setup(opts)
  end,
  keys = {
    { "<leader>Tp", "<cmd>TypstPreview<cr>", desc = "Start live preview" },
    { "<leader>Ts", "<cmd>TypstPreviewStop<cr>", desc = "Stop preview" },
    { "<leader>Tt", "<cmd>TypstPreviewToggle<cr>", desc = "Toggle preview" },
    { "<leader>Tu", "<cmd>TypstPreviewUpdate<cr>", desc = "Update preview" },
    { "<leader>Tf", "<cmd>TypstPreviewFollowCursor<cr>", desc = "Follow cursor" },
    { "<leader>TF", "<cmd>TypstPreviewNoFollowCursor<cr>", desc = "Stop following cursor" },
    { "<leader>Tc", "<cmd>TypstPreviewFollowCursorToggle<cr>", desc = "Toggle follow cursor" },
    { "<leader>TS", "<cmd>TypstPreviewSyncCursor<cr>", desc = "Sync cursor position" },
  },
}
