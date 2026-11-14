-- The old ftdetect used :setfiletype, so apparmor only claimed files nothing
-- else matched by name; a negative priority keeps that (runs after the
-- extension table)
-- freebsd: no syntax/apparmor.vim (nixvim takes it from apparmor-utils, no pkg here)
local apparmor = { "apparmor", { priority = -math.huge } }

vim.filetype.add({
  extension = {
    hujson = "hjson",
    aa = "apparmor",
  },
  pattern = {
    -- Ansible: YAML in a project with ansible.cfg, except dot-paths
    -- (.github/, .gitlab-ci.yml, .pre-commit-config.yaml, ...)
    [".*%.ya?ml"] = function(path)
      local root = vim.fs.root(path, "ansible.cfg")
      if root and not path:find("/%.", #root + 1) then
        return "yaml.ansible"
      end
    end,
    [".*/apparmor%.d/.*"] = apparmor,
    [".*/apparmor/profiles/.*"] = apparmor,
  },
})
