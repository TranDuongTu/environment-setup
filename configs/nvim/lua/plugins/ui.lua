return {
  { "folke/which-key.nvim" },
  { "nvim-tree/nvim-web-devicons", opts = {} },
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    opts = {
      style = "night",
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "auto",
      },
    },
  },
}