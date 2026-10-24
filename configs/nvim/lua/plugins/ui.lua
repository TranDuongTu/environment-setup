return {
  { "folke/which-key.nvim" },
  { "nvim-tree/nvim-web-devicons", opts = {} },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "auto",
      },
      sections = {
        -- path = 1 → relative path from the project root (nvim's cwd) instead
        -- of the bare filename. Use 2 for absolute, 3 for absolute with ~/.
        lualine_c = { { "filename", path = 1 } },
      },
    },
  },
}