-- desktop theme id -> colorscheme, background (polarity in themes.json) and base46 (statusline, tabs) theme
-- freebsd: nixvim generates this from themes.nix and asserts every id is here; keep it in
-- step with private_theming/private_themes.json by hand. unknown ids fall back to catppuccin-mocha
return {
  ["catppuccin-frappe"] = { background = "dark", base46 = "nvx-catppuccin-frappe", colorscheme = "catppuccin-frappe" },
  ["catppuccin-latte"] = { background = "light", base46 = "catppuccin-latte", colorscheme = "catppuccin-latte" },
  ["catppuccin-macchiato"] = { background = "dark", base46 = "nvx-catppuccin-macchiato", colorscheme = "catppuccin-macchiato" },
  ["catppuccin-mocha"] = { background = "dark", base46 = "catppuccin", colorscheme = "catppuccin-mocha" },
  ["dracula"] = { background = "dark", base46 = "chadracula", colorscheme = "dracula" },
  ["everforest-dark"] = { background = "dark", base46 = "everforest", colorscheme = "everforest" },
  ["gruvbox-dark"] = { background = "dark", base46 = "gruvbox", colorscheme = "gruvbox" },
  ["kanagawa"] = { background = "dark", base46 = "kanagawa", colorscheme = "kanagawa-wave" },
  ["nord"] = { background = "dark", base46 = "nord", colorscheme = "nord" },
  ["one-dark"] = { background = "dark", base46 = "onedark", colorscheme = "onedark" },
  ["rose-pine"] = { background = "dark", base46 = "rosepine", colorscheme = "rose-pine-main" },
  ["solarized-dark"] = { background = "dark", base46 = "solarized_dark", colorscheme = "solarized-osaka" },
  ["tokyo-night"] = { background = "dark", base46 = "tokyonight", colorscheme = "tokyonight-night" },
  ["work-dark"] = { background = "dark", base46 = "github_dark", colorscheme = "github_dark" },
  ["work-light"] = { background = "light", base46 = "github_light", colorscheme = "github_light" },
}
