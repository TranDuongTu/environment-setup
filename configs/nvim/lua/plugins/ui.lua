return {
  { "folke/which-key.nvim" },
  { "nvim-tree/nvim-web-devicons", opts = {} },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    -- bufferline integration keeps the tab bar colors in sync with catppuccin
    opts = { integrations = { bufferline = true } },
  },
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        -- show open buffers as tabs (vs. vim tab pages)
        mode = "buffers",
        -- show LSP error/warning counts on each buffer tab
        diagnostics = "nvim_lsp",
        -- keep the bar visible even with a single buffer
        always_show_bufferline = true,
        -- push the tabs right of the Neo-tree sidebar
        -- show the current git repo name, bold and centered, over the
        -- Neo-tree sidebar area
        offsets = {
          {
            filetype = "neo-tree",
            text = function()
              local root = vim.fs.root(0, ".git")
              return root and vim.fn.fnamemodify(root, ":t") or ""
            end,
            text_align = "center",
            highlight = "BufferlineRepoName",
          },
        },
      },
    },
  },
  {
    'everviolet/nvim',
    name = 'evergarden',
    priority = 1000, -- Colorscheme plugin is loaded first before any other plugins
    opts = {
      theme = {
        variant = 'fall', -- 'winter'|'fall'|'spring'|'summer'
        accent = 'green',
      },
      editor = {
        transparent_background = false,
        sign = { color = 'none' },
        float = {
          color = 'mantle',
          solid_border = false,
        },
        completion = {
          color = 'surface0',
        },
      },
    }
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
