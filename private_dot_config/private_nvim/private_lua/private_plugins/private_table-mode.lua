-- the plugin's own <Leader><Bar>m (and buffer-local maps while table mode is on)
-- replace these once loaded
local function key(lhs, rhs, desc)
  return { lhs, rhs, mode = "n", silent = true, desc = desc }
end

return {
  "dhruvasagar/vim-table-mode",
  -- read by plugin/table-mode.vim on load. plugin defaults dropped (corner_corner,
  -- header_fillchar, auto_align, syntax).
  init = function()
    vim.g.table_mode_corner = "|"
    vim.g.table_mode_tableize_auto_border = 1
    -- <Bar>, not |: the plugin builds :map commands from these, where | ends the command
    vim.g.table_mode_map_prefix = "<Leader><Bar>"
    vim.g.table_mode_tableize_d_map = "<Leader><Bar>T" -- default <Leader>T ignores the prefix
    vim.g.table_mode_delimiter = "|"
  end,
  keys = {
    key("<leader>|m", "<cmd>TableModeToggle<cr>", "Toggle table mode"),
    key("<leader>|r", "<cmd>TableModeRealign<cr>", "Realign table"),
    key("<leader>|dc", "<cmd>call tablemode#spreadsheet#DeleteColumn()<cr>", "Delete column"),
    key("<leader>|ic", "<cmd>call tablemode#spreadsheet#InsertColumn(1)<cr>", "Insert column after"),
  },
  -- so typing a command before the first key press loads it instead of E492
  cmd = {
    "TableModeToggle",
    "TableModeEnable",
    "TableModeDisable",
    "Tableize",
    "TableSort",
    "TableAddFormula",
    "TableModeRealign",
    "TableEvalFormulaLine",
  },
}
