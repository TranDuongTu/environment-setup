return {
  {
    "nvim-tree/nvim-web-devicons",
    config = function()
      -- Nerd Fonts have no protobuf glyph and nvim-web-devicons ships no proto
      -- entry, so Neo-tree falls back to its plain "*" file icon. Register
      -- custom icons: 󰏓 is nf-md-package (U+F03D3) — box = proto buffers.
      require("nvim-web-devicons").set_icon({
        ["proto"]         = { icon = "󰏓", color = "#e8863c", cterm_color = "173", name = "Proto" },
        ["buf.yaml"]      = { icon = "󰏓", color = "#58a6ff", cterm_color = "75",  name = "BufYaml" },
        ["buf.gen.yaml"]  = { icon = "󰏓", color = "#58a6ff", cterm_color = "75",  name = "BufGenYaml" },
        ["buf.policy.yaml"] = { icon = "󰏓", color = "#58a6ff", cterm_color = "75", name = "BufPolicyYaml" },
        ["buf.lock"]      = { icon = "󰏓", color = "#58a6ff", cterm_color = "75",  name = "BufLock" },
      })
    end,
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
      -- Needed because setup/init.lua drops any source_selector tab whose
      -- source isn't in this top-level list (defaults omit document_symbols).
      sources = {
        "filesystem",
        "buffers",
        "git_status",
        "document_symbols",
      },
      -- Clickable tabs in the tree's winbar (top-level key: selector.lua reads
      -- config.source_selector directly with no `window.` fallback). Shows
      -- every source with the active one highlighted (NeoTreeTabActive);
      -- click a tab to switch. display_name falls back to each source's own
      -- defaults when omitted.
      source_selector = {
        winbar = true,
        statusline = false,
        sources = {
          { source = "filesystem" },
          { source = "buffers" },
          { source = "git_status" },
          { source = "document_symbols" },
        },
      },
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
}