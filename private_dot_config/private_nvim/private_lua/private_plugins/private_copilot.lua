return {
  "zbirenbaum/copilot.lua",
  -- lazy: the server starts on the first insert
  event = "InsertEnter",
  cmd = "Copilot",
  config = function()
          require("copilot").setup({
            -- freebsd: the bundled server ships no freebsd watcher.node and exits at start;
            -- pkg github-copilot-language-server builds its native modules for freebsd
            server = {
              type = "nodejs",
              custom_server_filepath = "/usr/local/lib/node_modules/@github/copilot-language-server/dist/language-server.js",
            },
            suggestion = {
              enabled = true,
              auto_trigger = false,
              hide_during_completion = true,
              debounce = 75,
              trigger_on_accept = true,
              keymap = {
                accept = "<M-l>",
                accept_word = false,
                accept_line = false,
                next = "<M-]>",
                prev = "<M-[>",
                dismiss = "<C-]>",
              },
            },
            filetypes = {
              conf = true,
              go = true,
              nix = true,
              javascript = true,
              lua = true,
              sh = true,
              sql = true,
              toml = true,
              typescript = true,
              yaml = true,
              ["*"] = false,
            },
          })
  end
}
