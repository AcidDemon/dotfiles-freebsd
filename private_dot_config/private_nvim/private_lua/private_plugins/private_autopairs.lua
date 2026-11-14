-- blink.cmp's auto_brackets adds the parens after accepted functions.
-- dropped: top-level map_char (read only by the nvim-compe integration) and
-- fast_wrap.offset/check_comma (fastwrap.lua never reads them).
return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  opts = {
    check_ts = true, -- treesitter integration
    disable_filetype = { "TelescopePrompt", "spectre_panel" },
    disable_in_macro = false,
    disable_in_visualblock = false,
    enable_afterquote = true,
    enable_check_bracket_line = false,
    enable_moveright = true,
    ignored_next_char = [=[[%w%%%'%[%"%.]]=],
    map_bs = true,
    map_c_w = false,
    fast_wrap = {
      map = "<M-e>",
      chars = { "{", "[", "(", '"', "'" },
      pattern = [=[[%'%"%)%>%]%)%}%,]]=],
      end_key = "$",
      keys = "qwertyuiopzxcvbnmasdfghjkl",
      highlight = "PmenuSel",
      highlight_grey = "LineNr",
    },
    ts_config = {
      lua = { "string", "source" },
      javascript = { "string", "template_string" },
      java = false,
    },
  },
}
