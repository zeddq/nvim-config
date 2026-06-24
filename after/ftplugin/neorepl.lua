-- Buffer-local setup for neorepl REPL buffers.
--
-- Keybind-conflict analysis (why this file is short):
-- neorepl installs every mapping with nvim_buf_set_keymap, i.e. buffer-local,
-- so they take precedence over the *global* maps from other plugins:
--   * nvim-cmp's insert maps (<CR>, <Tab>, <C-N>, <C-P>) — shadowed here, and
--     neorepl additionally guards <Tab>/<C-N>/<C-P> behind pumvisible() so a
--     popup never fights the REPL's own completion/history.
--   * flash.nvim's s / S / r / R — different keys, no overlap with neorepl.
--   * the built-in section motions ]] [[ ][ [] — neorepl rebinds them
--     buffer-locally for its own section navigation.
-- No plugin in this config sets *buffer-local* maps on a neorepl buffer (LSP
-- and gitsigns don't attach to this nofile scratch buffer), so nothing can
-- clobber neorepl's keys. The remaining work is silencing overlay features
-- that would otherwise stay active in the buffer.

-- nvim-cmp: disable popup completion here — neorepl ships its own <Tab>
-- completion. Recommended by :help neorepl-using-with-other-plugins.
local ok_cmp, cmp = pcall(require, "cmp")
if ok_cmp then
  cmp.setup.buffer({ enabled = false })
end

-- minuet: stop as-you-type ghost text (and the Codestral request it fires on
-- every keystroke) in the REPL. Its accept keys are <A-*>, so they never
-- collided with neorepl's keys — this just keeps the buffer quiet. The
-- authoritative opt-out lives in minuet's `auto_trigger_ignore_ft`
-- (lua/plugins/minuet.lua); this is a belt-and-suspenders guard for the case
-- where minuet hasn't loaded yet when this buffer is created.
vim.b.minuet_virtual_text_auto_trigger = false

-- snacks.nvim indent guides: off for this buffer. (Supersedes the old
-- `vim.b.indent_blankline_enabled` line — indent-blankline.nvim isn't used in
-- this config; snacks.nvim draws the indent guides.)
vim.b.snacks_indent = false
