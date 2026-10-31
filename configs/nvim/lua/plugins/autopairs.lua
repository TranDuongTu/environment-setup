-- nvim-autopairs: types the closing partner of `(`, `[`, `{` and quotes as
-- you type, and on <CR> between an empty pair turns `{|}` into an indented
-- block with `}` on its own line. When a completion menu is open it yields
-- <CR> back to the completion plugin, so cmp's confirm mapping still fires.
return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    -- check_ts: use treesitter to skip pairing inside strings/comments
    -- (per-language node lists; languages without one default to no veto).
    opts = {
      check_ts = true,
    },
  },
}