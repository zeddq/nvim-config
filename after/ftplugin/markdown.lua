-- Markdown: skip indent override (Neovim's default markdown indent is fine
-- and TS indent for prose can over-indent list continuations).
require("utils.treesitter").activate({ indent = false })
