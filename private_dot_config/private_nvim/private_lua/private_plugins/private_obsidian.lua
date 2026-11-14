local vault = vim.fn.expand("~/Documents/Obsidian")

local function key(lhs, sub, desc)
  return { lhs, "<cmd>Obsidian " .. sub .. "<cr>", silent = true, desc = desc }
end

return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  -- lazy: the :Obsidian stub (all <leader>o maps go through it) or opening a vault note.
  -- setup() mkdirs the vault folders, so it must not run at startup.
  cmd = "Obsidian",
  event = "BufReadPre " .. vault .. "/*.md",
  keys = {
    key("<leader>on", "new", "New note"),
    -- freebsd: no Obsidian app package, kept for parity
    key("<leader>oo", "open", "Open in Obsidian app"),
    key("<leader>oq", "quick_switch", "Quick switch notes"),
    key("<leader>os", "search", "Search notes"),
    key("<leader>ot", "tags", "Search tags"),
    key("<leader>ob", "backlinks", "Show backlinks"),
    key("<leader>od", "today", "Today's daily note"),
    key("<leader>oy", "yesterday", "Yesterday's daily note"),
    key("<leader>of", "follow_link", "Follow link"),
    key("<leader>oc", "toggle_checkbox", "Toggle checkbox"),
  },
  opts = {
    workspaces = {
      {
        name = "personal",
        path = vault,
      },
    },

    notes_subdir = "notes",
    daily_notes = {
      folder = "daily",
      date_format = "%Y-%m-%d",
    },

    -- completion comes from obsidian's built-in LSP via blink's lsp source
    completion = {
      min_chars = 2,
    },

    note_id_func = function(title)
      local suffix = ""
      if title ~= nil then
        suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
      else
        for _ = 1, 4 do
          suffix = suffix .. string.char(math.random(65, 90))
        end
      end
      return tostring(os.time()) .. "-" .. suffix
    end,

    frontmatter = {
      func = function(note)
        local out = { id = note.id, aliases = note.aliases, tags = note.tags }
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end
        return out
      end,
    },

    templates = {
      folder = "templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
    },

    -- render-markdown does the rendering
    ui = {
      enable = false,
    },

    checkbox = {
      order = { " ", "x", ">", "~" },
    },

    attachments = {
      folder = "attachments",
    },

    legacy_commands = false,
  },
}
