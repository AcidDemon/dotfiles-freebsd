-- Read by nvchad-ui's nvconfig; everything not set here keeps NvChad's defaults
return {
  base46 = {
    theme = "catppuccin",
    theme_toggle = { "catppuccin", "catppuccin-latte" },
  },
  ui = {
    statusline = {
      modules = {
        -- NvChad's block with line:col and percentage. The line number is padded to the
        -- buffer's line count and the column to 3, so moving never shifts the statusline.
        cursor = function()
          local buf = require("nvchad.stl.utils").stbufnr()
          local digits = #tostring(vim.api.nvim_buf_line_count(buf))
          return "%#St_pos_sep#\u{e0b6}%#St_pos_icon#\u{e612} %#St_pos_text# %"
            .. digits
            .. "l:%-3v %3p%% "
        end,
      },
    },
    -- show the tabline from the first buffer, not only once a second one opens
    tabufline = {
      lazyload = false,
      modules = {
        -- NvChad's tabs, with the close button on the current tab that it used to have
        tabs = function()
          local btn = require("nvchad.tabufline.utils").btn
          local tabs, cur = vim.fn.tabpagenr("$"), vim.fn.tabpagenr()
          if tabs < 2 then
            return ""
          end
          if vim.g.TbTabsToggled == 1 then
            return btn(" \u{f0141} ", "TabTitle", "ToggleTabs")
          end

          local result = btn(" \u{f0415} ", "TabNewBtn", "NewTab") .. btn(" TABS ", "TabTitle", "ToggleTabs")
          for nr = 1, tabs do
            if nr == cur then
              result = result
                .. btn(" " .. nr .. " ", "TabCloseBtn", "GotoTab", nr)
                .. btn("\u{f0159} ", "TabCloseBtn", "TabClose")
            else
              result = result .. btn(" " .. nr .. " ", "TabOff", "GotoTab", nr)
            end
          end
          return result
        end,
      },
    },
  },
}
