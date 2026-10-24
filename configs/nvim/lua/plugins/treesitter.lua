return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      -- The nvim-treesitter main branch (2025 rewrite) no longer honors the
      -- legacy `ensure_installed` / `auto_install` / `highlight` opts — parsers
      -- are installed via `install()`, and highlighting/indentation are not
      -- turned on automatically. So: install parsers, then wire up highlighting
      -- and treesitter indentation per filetype.
      -- (Runs async; on first install it finishes in the background.)
      local parsers = { "lua", "vim", "json", "bash", "markdown", "markdown_inline", "python", "go", "typescript", "tsx", "javascript", "dart" }
      require("nvim-treesitter").install(parsers)

      local filetypes = { "lua", "vim", "json", "bash", "markdown", "python", "go", "typescript", "typescriptreact", "javascript", "dart" }
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter-features", { clear = true }),
        pattern = filetypes,
        callback = function(args)
          -- start() errors for filetypes whose parser isn't installed yet;
          -- init.lua's pcall wrap turns that into a no-op.
          vim.treesitter.start(args.buf)
          -- Treesitter indentation (Enter/o/O keep block indent, `=` reindents).
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
}