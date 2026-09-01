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

require("lazy").setup("plugins")

vim.cmd.colorscheme "tokyonight"

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

vim.keymap.set('n', '<leader>e', ':Neotree reveal<CR>', { desc = 'Reveal file in Neo-tree', silent = true })
vim.keymap.set('n', '<leader>o', ':Neotree focus<CR>', { desc = 'Focus Neo-tree', silent = true })

-- Git keymaps
vim.keymap.set('n', '<leader>gd', ':DiffviewOpen<CR>', { desc = 'Diffview: open changed files', silent = true })
vim.keymap.set('n', '<leader>gc', ':DiffviewClose<CR>', { desc = 'Diffview: close', silent = true })
vim.keymap.set('n', '<leader>gh', ':DiffviewFileHistory %<CR>', { desc = 'Diffview: current file history', silent = true })
vim.keymap.set('n', '<leader>hb', function() require('gitsigns').blame_line() end, { desc = 'Git blame line' })
vim.keymap.set('n', '<leader>gn', function() require('neogit').open() end, { desc = 'Neogit: open' })

-- Octo (GitHub) keymaps
vim.keymap.set('n', '<leader>go', ':Octo<CR>', { desc = 'Octo: dashboard', silent = true })
vim.keymap.set('n', '<leader>gp', ':Octo pr list<CR>', { desc = 'Octo: PR list', silent = true })
vim.keymap.set('n', '<leader>gv', ':Octo pr view<CR>', { desc = 'Octo: view current PR', silent = true })
vim.keymap.set('n', '<leader>gs', ':Octo review start<CR>', { desc = 'Octo: start review', silent = true })
vim.keymap.set('n', '<leader>gu', ':Octo review submit<CR>', { desc = 'Octo: submit review', silent = true })