-- ibl joins these onto its default excludes; help, packer and the
-- terminal/nofile buftypes are already defaults, so they were dropped
return {
  "lukas-reineke/indent-blankline.nvim",
  config = function()
          require("ibl").setup({
              exclude = {
                filetypes = {
                  "NvimTree",
                  "Trouble",
                  "dashboard",
                  "lazy",
                  "neogitstatus",
                  "startify",
                  "text",
                },
              },
          })
  end
}
