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
      ensure_installed = { "lua", "vim", "json", "bash", "markdown", "markdown_inline", "python" },
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
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function() vim.fn["mkdp#util#install"](1) end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown preview toggle", ft = "markdown" },
    },
  },

  -- ── LSP ──────────────────────────────────────────────────────────────────

  { "williamboman/mason.nvim", opts = {} },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { "pyright", "ruff" },
      automatic_enable = true,  -- calls vim.lsp.enable() for each installed server
    },
  },

  -- mason-nvim-dap: auto-installs debugpy via Mason
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { "debugpy" },
    },
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local on_attach = function(_, bufnr)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
        end
        local tb = require("telescope.builtin")

        map("gd",         tb.lsp_definitions,                                         "LSP: go to definition")
        map("gD",         vim.lsp.buf.declaration,                                    "LSP: go to declaration")
        map("gi",         tb.lsp_implementations,                                     "LSP: go to implementation")
        map("gr",         tb.lsp_references,                                          "LSP: find references")
        map("K",          vim.lsp.buf.hover,                                          "LSP: hover docs")
        map("<leader>rn", vim.lsp.buf.rename,                                         "LSP: rename symbol")
        map("<leader>ca", vim.lsp.buf.code_action,                                    "LSP: code action")
        map("<leader>ds", tb.lsp_document_symbols,                                    "LSP: document symbols")
        map("<leader>ws", tb.lsp_dynamic_workspace_symbols,                           "LSP: workspace symbols")
        map("<leader>xl", tb.diagnostics,                                             "LSP: diagnostics list")
        map("<leader>xd", vim.diagnostic.open_float,                                  "LSP: show diagnostic")
        map("]d",         function() vim.diagnostic.goto_next({ float = true }) end,  "LSP: next diagnostic")
        map("[d",         function() vim.diagnostic.goto_prev({ float = true }) end,  "LSP: prev diagnostic")
      end

      -- Pyright: type checking + navigation (gd, gr, rename, hover, symbols)
      vim.lsp.config("pyright", {
        capabilities = capabilities,
        on_attach = on_attach,
        before_init = function(_, config)
          -- Prefer an already-activated venv, then scan common folder names
          local venv = os.getenv("VIRTUAL_ENV")
          if not venv then
            local root = config.root_dir or vim.fn.getcwd()
            for _, name in ipairs({ ".venv", "venv", "env", ".env" }) do
              local python = root .. "/" .. name .. "/bin/python"
              if vim.fn.executable(python) == 1 then
                venv = root .. "/" .. name
                break
              end
            end
          end
          if venv then
            config.settings.python.pythonPath = venv .. "/bin/python"
          end
        end,
        settings = {
          pyright = {
            disableOrganizeImports = true,  -- ruff handles imports
          },
          python = {
            analysis = {
              typeCheckingMode = "standard",
            },
          },
        },
      })

      -- Ruff: linting + formatting + auto-fix on save
      vim.lsp.config("ruff", {
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          on_attach(client, bufnr)
          client.server_capabilities.hoverProvider = false  -- defer hover to pyright
          vim.keymap.set("n", "<leader>f", function()
            vim.lsp.buf.format({ bufnr = bufnr, id = client.id, async = true })
          end, { buffer = bufnr, desc = "Ruff: format buffer" })
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ bufnr = bufnr, id = client.id, async = false })
            end,
          })
        end,
      })

      vim.diagnostic.config({
        virtual_text = { prefix = "●" },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = { border = "rounded", source = true },
      })
    end,
  },

  -- ── Completion ───────────────────────────────────────────────────────────

  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"]     = cmp.mapping.select_next_item(),
          ["<C-p>"]     = cmp.mapping.select_prev_item(),
          ["<C-d>"]     = cmp.mapping.scroll_docs(-4),
          ["<C-f>"]     = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"]     = cmp.mapping.abort(),
          ["<CR>"]      = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- ── Debugging ────────────────────────────────────────────────────────────

  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "nvim-neotest/nvim-nio",
      {
        "rcarriga/nvim-dap-ui",
        config = function()
          local dap, dapui = require("dap"), require("dapui")
          dapui.setup()
          -- Auto-open/close UI when a debug session starts/ends
          dap.listeners.after.event_initialized["dapui_config"]  = function() dapui.open() end
          dap.listeners.before.event_terminated["dapui_config"]  = function() dapui.close() end
          dap.listeners.before.event_exited["dapui_config"]      = function() dapui.close() end
        end,
      },
      {
        "mfussenegger/nvim-dap-python",
        config = function()
          -- debugpy installed by mason-nvim-dap
          require("dap-python").setup(
            vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
          )
        end,
      },
    },
    keys = {
      { "<F5>",        function() require("dap").continue() end,         desc = "Debug: start / continue" },
      { "<F9>",        function() require("dap").toggle_breakpoint() end, desc = "Debug: toggle breakpoint" },
      { "<F10>",       function() require("dap").step_over() end,         desc = "Debug: step over" },
      { "<F11>",       function() require("dap").step_into() end,         desc = "Debug: step into" },
      { "<F12>",       function() require("dap").step_out() end,          desc = "Debug: step out" },
      { "<leader>db",  function() require("dap").toggle_breakpoint() end, desc = "Debug: toggle breakpoint" },
      { "<leader>dc",  function() require("dap").continue() end,          desc = "Debug: continue" },
      { "<leader>du",  function() require("dapui").toggle() end,          desc = "Debug: toggle UI" },
      { "<leader>dr",  function() require("dap").repl.open() end,         desc = "Debug: open REPL" },
      { "<leader>dq",  function() require("dap").terminate() end,         desc = "Debug: terminate" },
    },
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
