local notes = vim.fn.expand("~/Documents/Neorg")

local function key(lhs, rhs, desc)
  return { lhs, rhs, silent = true, desc = desc }
end

-- the telescope pickers need neorg loaded (its telescope module registers them); lazy loads it on the key
local function picker(name)
  return function() require("telescope").extensions.neorg[name]() end
end

-- ft_to_lang() and nvim-treesitter.configs were removed from nvim-treesitter.
-- freebsd: nixvim patches search_headings.lua at build time; lazy owns the checkout, so
-- hand it the two replacements for the length of the call instead
-- ponytail: covers <leader>nh only; :Telescope neorg search_headings still hits the old api
local function search_headings()
  local loaded = package.loaded
  local parsers, configs = loaded["nvim-treesitter.parsers"], loaded["nvim-treesitter.configs"]
  loaded["nvim-treesitter.parsers"] = {
    ft_to_lang = function(ft) return vim.treesitter.language.get_lang(ft) or ft end,
  }
  loaded["nvim-treesitter.configs"] = { is_enabled = function() return true end }
  local ok, err = pcall(require("telescope").extensions.neorg.search_headings)
  loaded["nvim-treesitter.parsers"], loaded["nvim-treesitter.configs"] = parsers, configs
  if not ok then error(err, 0) end
end

-- freebsd: nixvim gets norg/norg_meta from allGrammars; nvim-treesitter main lists neither and
-- its tree-sitter build can't compile norg's C++ scanner. built here at the versions neorg pins
-- (lux.toml), written next to nvim-treesitter's parsers. rerun: nvim --headless '+Lazy! build neorg' +qa
local build_parsers = [[
set -e
out=$1 t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
cd "$t"
for g in norg:v0.2.4 norg-meta:v0.1.0; do
  mkdir "${g%:*}"
  curl -fsSL "https://github.com/nvim-neorg/tree-sitter-${g%:*}/archive/refs/tags/${g#*:}.tar.gz" |
    tar -xzf - -C "${g%:*}" --strip-components 1
done
cc -O2 -fPIC -Inorg/src -c norg/src/parser.c
c++ -O2 -fPIC -Inorg/src -c norg/src/scanner.cc
c++ -shared parser.o scanner.o -o "$out/norg.so.tmp"
cc -O2 -fPIC -shared -Inorg-meta/src norg-meta/src/parser.c -o "$out/norg_meta.so.tmp"
# rename, not overwrite: a running nvim may have the old .so mapped
mv -f "$out/norg.so.tmp" "$out/norg.so"
mv -f "$out/norg_meta.so.tmp" "$out/norg_meta.so"
]]

return {
  "nvim-neorg/neorg",
  build = function()
    local dir = vim.fn.stdpath("data") .. "/site/parser"
    vim.fn.mkdir(dir, "p")
    local r = vim.system({ "sh", "-c", build_parsers, "sh", dir }):wait()
    assert(r.code == 0, r.stderr)
  end,
  -- neorg's rocks; lazy.nvim's rocks support is off (init.lua)
  dependencies = {
    "nvim-neorg/lua-utils.nvim",
    "pysan3/pathlib.nvim",
    "nvim-neotest/nvim-nio",
    "MunifTanjim/nui.nvim",
    "nvim-neorg/neorg-telescope",
    "nvim-telescope/telescope.nvim",
  },
  ft = "norg",
  cmd = "Neorg",
  init = function()
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "norg",
      callback = function(ev)
        -- freebsd: the norg parser comes from the build above, it may be missing
        pcall(vim.treesitter.start)
        vim.opt_local.conceallevel = 2

        -- overrides global <CR> clear-search mapping
        vim.keymap.set("n", "<CR>", "<Plug>(neorg.esupports.hop.hop-link)", {
          buffer = ev.buf,
          desc = "Follow Neorg link",
        })
      end,
    })
  end,
  keys = {
    key("<leader>nn", "<cmd>Neorg index<cr>", "Open workspace index"),
    key("<leader>nw", "<cmd>Neorg workspace<cr>", "Switch workspace"),
    key("<leader>nr", "<cmd>Neorg return<cr>", "Close and return"),
    key("<leader>nj", "<cmd>Neorg journal today<cr>", "Journal today"),
    key("<leader>ny", "<cmd>Neorg journal yesterday<cr>", "Journal yesterday"),
    key("<leader>nt", "<cmd>Neorg journal tomorrow<cr>", "Journal tomorrow"),
    key("<leader>ns", picker("find_norg_files"), "Find norg files"),
    key("<leader>nh", search_headings, "Search headings"),
    key("<leader>nl", picker("find_linkable"), "Find linkable"),
    key("<leader>ne", "<cmd>Neorg export to-file<cr>", "Export current file"),
  },
  opts = {
    load = {
      ["core.defaults"] = {},
      ["core.concealer"] = {},
      ["core.dirman"] = {
        config = {
          workspaces = {
            notes = notes,
            nix = notes .. "/nix",
          },
          default_workspace = "notes",
        },
      },
      ["core.journal"] = {
        config = {
          strategy = "flat",
          workspace = "notes",
        },
      },
      ["core.export"] = {},
      ["core.export.markdown"] = {},
      ["core.summary"] = {},
      ["core.integrations.telescope"] = {},
    },
  },
}
