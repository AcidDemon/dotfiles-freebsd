-- Follows the desktop theme in ~/.local/state/theming/current, also while Neovim runs
local M = {}

local themes = require("nvx.themes")
local file = (vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")) .. "/theming/current"
local fallback = "catppuccin-mocha"

function M.current()
  local f = io.open(file)
  if not f then
    return fallback
  end
  local id = vim.trim(f:read("*a"))
  f:close()
  return themes[id] and id or fallback
end

function M.apply(id)
  local t = themes[id] or themes[fallback]
  vim.g.nvx_theme = id
  vim.g.nvx_base46 = t.base46
  vim.o.background = t.background
  vim.cmd.colorscheme(t.colorscheme)
end

function M.setup()
  M.apply(M.current())
  -- freebsd: nixvim watches the directory with fs_event; kqueue gives directory events no
  -- filename and misses in-place rewrites, so stat the file. it may not exist yet: the
  -- poll also sees theme-switch create it
  -- ponytail: 1 s stat poll, a switch shows up within a second; fs_event on the file
  -- (re-armed after each rename) if that is ever too slow
  M.watch = vim.uv.new_fs_poll()
  M.watch:start(file, 1000, vim.schedule_wrap(function()
    local id = M.current()
    if id ~= vim.g.nvx_theme then
      M.apply(id)
    end
  end))
end

return M
