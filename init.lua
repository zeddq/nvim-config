-- Neovim Configuration
-- Location: ~/.config/nvim/init.lua

-- Set LSP log level (WARN for production, toggle with <leader>ld)
vim.lsp.log.set_level(vim.log.levels.WARN)

-- Load core configuration modules
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Load plugin management
require("plugins")
