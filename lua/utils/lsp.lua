local M = {}

-- Toggle LSP log level
function M.toggle_log_level()
  local current = vim.lsp.log.get_level()
  if current == vim.log.levels["DEBUG"] then
    vim.lsp.set_log_level(vim.lsp.log_levels.WARN)
    vim.notify("LSP log level: info", vim.log.levels.WARN)
  else
    vim.lsp.set_log_level(vim.lsp.log_levels.DEBUG)
    vim.notify("LSP log level: debug", vim.log.levels.WARN)
  end
end

function M.show_log_level()
  local levels = {
    [vim.log.levels.TRACE] = "TRACE",
    [vim.log.levels.DEBUG] = "DEBUG",
    [vim.log.levels.INFO] = "INFO",
    [vim.log.levels.WARN] = "WARN",
    [vim.log.levels.ERROR] = "ERROR",
    [vim.log.levels.OFF] = "OFF",
  }
  local current = vim.lsp.log.get_level()
  print("Current LSP log level: " .. (levels[current] or "UNKNOWN"))
end

-- Open log file
function M.open_log()
  vim.cmd("edit " .. vim.lsp.get_log_path())
end

-- Tail log in split
function M.tail_log()
  vim.cmd("split")
  vim.cmd("term tail -f " .. vim.lsp.get_log_path())
end

return M
