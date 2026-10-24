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