-- Wrap vim.treesitter.start so it doesn't error when parsers aren't installed yet
local _ts_start = vim.treesitter.start
vim.treesitter.start = function(...)
  pcall(_ts_start, ...)
end

vim.g.mapleader = "\\"
vim.opt.clipboard = "unnamedplus"

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.wo.number = true
vim.opt.conceallevel = 2
vim.opt.concealcursor = "n"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
  {
    "christoomey/vim-tmux-navigator",
    init = function()
      vim.g.tmux_navigator_no_mappings = 1
    end,
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>",  silent = true },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>",  silent = true },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>",    silent = true },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", silent = true },
    },
  },
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
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "lua", "vim", "json", "bash", "markdown", "markdown_inline" },
      auto_install = true,
      highlight = { enable = true },
    },
  },
  { 'nvim-telescope/telescope.nvim', version = '*', dependencies = {
        'nvim-lua/plenary.nvim',
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    }
  },
  { 'lewis6991/gitsigns.nvim', opts = {} },
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      integrations = {
        diffview = true,
        telescope = true,
      },
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
        },
      },
    },
  },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      open_mapping = [[<C-\>]],
      direction = "float",
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
  {
    "kdheepak/lazygit.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    ft = { "markdown" },
    opts = {},
  },
}

require("lazy").setup(plugins)

vim.cmd.colorscheme "tokyonight"

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', { desc = 'Toggle Neo-tree', silent = true })
vim.keymap.set('n', '<leader>o', ':Neotree focus<CR>', { desc = 'Focus Neo-tree', silent = true })

-- Git keymaps
vim.keymap.set('n', '<leader>gd', ':DiffviewOpen<CR>', { desc = 'Diffview: open changed files', silent = true })
vim.keymap.set('n', '<leader>gc', ':DiffviewClose<CR>', { desc = 'Diffview: close', silent = true })
vim.keymap.set('n', '<leader>gh', ':DiffviewFileHistory %<CR>', { desc = 'Diffview: current file history', silent = true })
vim.keymap.set('n', '<leader>gn', function() require('neogit').open() end, { desc = 'Neogit: open' })
