-- Neovim Configuration
-- Location: ~/.config/nvim/init.lua

-- Set LSP log level to reduce log file bloat
vim.lsp.set_log_level("WARN")
-- Add to init.aalua or a debug utils file
_G.trace = function()
  local info = debug.getinfo(2, "Snl")
  local variables = {}

  -- Get local variables
  local i = 1
  while true do
    local name, value = debug.getlocal(2, i)
    if not name then
      break
    end
    if not name:match("^%(") then -- Skip internal variables
      variables[name] = value
    end
    i = i + 1
  end

  print(string.format("\n=== TRACE: %s:%d ===", info.short_src, info.currentline))
  print("Function:", info.name or "(anonymous)")
  print("Variables:")
  print(vim.inspect(variables))
  print("=================\n")
end
-- Load core configuration modules
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Load plugin management
require("plugins")
