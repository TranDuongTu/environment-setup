-- AI agents: opencode + Claude Code, embedded in Neovim.
-- Shared leader family: \a{t,a,e,n,s,+,c,r,v} ("a" for agents).
-- \o is taken by Neo-tree, so opencode uses two-char \a? maps below.
return {
  -- Enhances opencode.nvim's ask() with an input popup + completions.
  -- Optional upstream (ask() falls back to vim.ui.input); input only.
  { "folke/snacks.nvim", opts = { input = { enabled = true } } },

  {
    "NickvanDyke/opencode.nvim",
    -- main branch targets OpenCode v2: the plugin drives the OpenCode
    -- server/TUI (starts an integrated instance if none is running) and
    -- injects editor context via '@this' placeholders.
    config = function()
      ---@type opencode.Opts
      vim.g.opencode_opts = {}

      local oc = require("opencode")
      -- Snacks input popup enhances ask() (required for its completion UI)
      vim.keymap.set({ "n", "x" }, "<leader>aa", function()
        oc.ask("@this: ")
      end, { desc = "opencode: ask (cursor/selection context)" })
      vim.keymap.set({ "n", "x" }, "<leader>as", function()
        oc.select()
      end, { desc = "opencode: select prompt" })
      vim.keymap.set({ "n", "x" }, "<leader>ae", function()
        return oc.operator("Explain @this")
      end, { desc = "opencode: explain", expr = true })
      vim.keymap.set("n", "<leader>aee", function()
        return oc.operator("Explain @this") .. "_"
      end, { desc = "opencode: explain line", expr = true })
      -- Send lines/motions to OpenCode, README-recommended `go` operator
      vim.keymap.set({ "n", "x" }, "go", function()
        return oc.operator("@this")
      end, { desc = "opencode: send range", expr = true })
      vim.keymap.set("n", "goo", function()
        return oc.operator("@this") .. "_"
      end, { desc = "opencode: send line", expr = true })
    end,
  },

  {
    "greggh/claude-code.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      -- Botright vertical split = right-most pane (~30%), mirroring the
      -- tmuxinator dev/dev-lite layouts where the agent pane sits right.
      window = { position = "botright vertical" },
      keymaps = {
        toggle = {
          normal = "<leader>ac",
          variants = {
            resume = "<leader>ar",
            verbose = "<leader>av",
          },
        },
      },
    },
    config = function(_, opts)
      require("claude-code").setup(opts)
      -- One-shot question: claude -p (print mode) with the lightweight
      -- haiku alias; the single answer streams a right-side terminal split.
      vim.keymap.set("n", "<leader>aq", function()
        vim.ui.input({ prompt = "claude  " }, function(input)
          if not input or input == "" then
            return
          end
          vim.cmd("rightb vsplit")
          vim.cmd("terminal claude -p " .. vim.fn.shellescape(input) .. " --model haiku")
        end)
      end, { desc = "claude: one-shot ask (haiku)" })
    end,
  },
}