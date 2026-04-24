-- Neovim Configuration
-- Location: ~/.config/nvim/init.lua

-- Add this file's directory to runtimepath so `require("config.*")` resolves
-- even when invoked via `nvim -u /path/to/init.lua` outside stdpath("config")
-- (e.g. CI checkouts at $GITHUB_WORKSPACE).
local init_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
vim.opt.runtimepath:prepend(init_dir)

-- Set LSP log level (WARN for production, toggle with <leader>ld)
vim.lsp.log.set_level(vim.log.levels.WARN)

-- Load core configuration modules
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Load plugin management
require("plugins")
