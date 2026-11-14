-- freebsd: no native opencode; the plugin needs the Linux opencode binary on PATH (Linux compat layer, untested)
return {
  "nickjvandyke/opencode.nvim",
  init = function()
    vim.g.opencode_opts = vim.g.opencode_opts or {}
  end
}
