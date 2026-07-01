return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "lua", "vim", "json", "bash", "markdown", "markdown_inline", "python", "go", "typescript", "tsx", "javascript" },
      auto_install = true,
      highlight = { enable = true },
    },
  },
}