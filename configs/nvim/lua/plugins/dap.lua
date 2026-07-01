return {
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
      {
        "leoluz/nvim-dap-go",
        dependencies = { "mfussenegger/nvim-dap" },
        config = function()
          require("dap-go").setup()
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