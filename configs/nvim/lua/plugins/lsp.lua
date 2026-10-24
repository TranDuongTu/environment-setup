return {
  { "williamboman/mason.nvim", opts = {} },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { "pyright", "ruff", "gopls", "ts_ls" },
      automatic_enable = true,
    },
  },

  -- mason-nvim-dap: auto-installs debugpy via Mason
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { "python", "delve" },
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

      local on_attach = function(client, bufnr)
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

        -- Highlight every usage of the symbol under the cursor while it sits
        -- idle, and clear the highlight as soon as the cursor moves.
        if client:supports_method("textDocument/documentHighlight") then
          local group = vim.api.nvim_create_augroup("lsp-document-highlight", { clear = false })
          vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            group = group,
            buffer = bufnr,
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave" }, {
            group = group,
            buffer = bufnr,
            callback = vim.lsp.buf.clear_references,
          })
        end
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

      -- gopls: navigation, refactoring, formatting, imports, test code lens
      vim.lsp.config("gopls", {
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          on_attach(client, bufnr)
          vim.keymap.set("n", "<leader>gf", function()
            vim.lsp.buf.format({ bufnr = bufnr, id = client.id, async = true })
          end, { buffer = bufnr, desc = "gopls: format buffer" })
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.code_action({
                context = { only = { "source.organizeImports" } },
                apply = true,
              })
              vim.lsp.buf.format({ bufnr = bufnr, id = client.id, async = false })
            end,
          })
        end,
        settings = {
          gopls = {
            gofumpt = true,
            staticcheck = true,
            analyses = {
              unusedparams = true,
              unusedvariable = true,
              unreachable = true,
              shadow = true,
            },
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
            codelenses = {
              test = true,
              tidy = true,
              vendor = true,
            },
          },
        },
      })

      -- ts_ls: TypeScript/JavaScript language server
      vim.lsp.config("ts_ls", {
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          on_attach(client, bufnr)
          vim.keymap.set("n", "<leader>gf", function()
            vim.lsp.buf.format({ bufnr = bufnr, id = client.id, async = true })
          end, { buffer = bufnr, desc = "ts_ls: format buffer" })
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.code_action({
                context = { only = { "source.organizeImports" } },
                apply = true,
              })
              vim.lsp.buf.format({ bufnr = bufnr, id = client.id, async = false })
            end,
          })
        end,
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
          },
          javascript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
          },
        },
      })

      -- dartls: Dart/Flutter. The server ships inside the Dart SDK (not in
      -- mason), so it is enabled directly and requires `dart` on PATH.
      vim.lsp.config("dartls", {
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          on_attach(client, bufnr)
          -- <leader>gf: format via the LSP (dartls registers formatting
          -- dynamically at attach, so vim.lsp.buf.format handles it).
          vim.keymap.set("n", "<leader>gf", function()
            vim.lsp.buf.format({ bufnr = bufnr, id = client.id, async = true })
          end, { buffer = bufnr, desc = "dartls: format buffer" })
          -- On save: strip unused imports, then format — both synchronously
          -- so edits land before :write completes. Note: dartls's "Organize /
          -- Fix All" source actions are server commands whose workspace edits
          -- arrive async (after :write is done), so unused-import removal
          -- instead replays dartls's synchronous per-diagnostic quick fix
          -- ("Remove unused import"). Sorting imports stays manual:
          -- <leader>ca -> Organize Imports.
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            callback = function()
              local diags = vim.diagnostic.get(bufnr)
              for i = #diags, 1, -1 do  -- bottom-up so earlier edits don't shift later ranges
                local d = diags[i]
                if d.code == "unused_import" or d.message:find("Unused import") then
                  local res = client:request_sync("textDocument/codeAction", {
                    textDocument = vim.lsp.util.make_text_document_params(bufnr),
                    range = {
                      start = { line = d.lnum, character = d.col },
                      ["end"] = { line = d.end_lnum, character = d.end_col },
                    },
                    context = { diagnostics = {} },
                  }, 10000, bufnr)
                  for _, action in ipairs(res and res.result or {}) do
                    if action.kind == "quickfix.remove.unusedImport" and action.edit then
                      vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
                    end
                  end
                end
              end
              vim.lsp.buf.format({ bufnr = bufnr, id = client.id, async = false })
            end,
          })
        end,
      })
      vim.lsp.enable("dartls")

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
}