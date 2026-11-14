-- the DrKJeff16 fork (module `project`, :Project <sub> commands), as nixvim ships;
-- settings keep ahmedkhalf's pattern-only behavior
return {
  "DrKJeff16/project.nvim",
  -- main after this tag closes the history fd twice: every exit with an empty history errors.
  -- its tags carry a -1 suffix, which lazy's semver treats as prerelease, so version = "*" misses them
  -- ponytail: pinned by hand, bump when a release fixes write_history
  tag = "v6.5.0-1",
  lazy = false,
  dependencies = { "nvim-telescope/telescope.nvim" },
  init = function()
    -- otherwise every exit errors "No data available to write!" until the first project
    -- is visited (empty history); nothing is lost by skipping that write
    vim.g.project_history_no_data_notified = 1
  end,
  config = function()
    require("project").setup({
      -- was detection_methods = { "pattern" }
      lsp = { enabled = false },
      use_git = false, -- runs git rev-parse in the cwd, not the buffer's dir
      patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json", "pom.xml" },

      -- ahmedkhalf only chdir'd for buftype "" / acwrite; the fork's default list lets
      -- prompt buffers (snacks.input, neorg popups) through
      disable_on = { bt = { "help", "nofile", "nowrite", "quickfix", "terminal", "prompt" } },

      -- the fork never chdirs into another user's dir; allow only silences the error it
      -- would raise on every BufEnter there
      different_owners = {
        allow = true,
        notify = false,
      },

      -- default save_dir, created first: the fork warns when it is missing (fresh $HOME)
      history = {
        save_dir = (function()
          local dir = vim.fn.stdpath("data")
          vim.fn.mkdir(dir, "p")
          return dir
        end)(),
      },
    })
    require("telescope").load_extension("projects")
  end,
}
