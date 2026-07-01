return {
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
}