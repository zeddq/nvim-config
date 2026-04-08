local M = {}

-- Toggle LSP log level (cycles DEBUG → INFO → WARN → DEBUG)
function M.toggle_log_level()
  local current = vim.lsp.log.get_level()
  if current == vim.log.levels.DEBUG then
    vim.lsp.log.set_level(vim.log.levels.INFO)
    vim.notify("LSP log level: INFO", vim.log.levels.INFO)
  elseif current == vim.log.levels.INFO then
    vim.lsp.log.set_level(vim.log.levels.WARN)
    vim.notify("LSP log level: WARN", vim.log.levels.WARN)
  else
    vim.lsp.log.set_level(vim.log.levels.DEBUG)
    vim.notify("LSP log level: DEBUG", vim.log.levels.INFO)
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
  local fname = vim.lsp.log.get_filename()
  vim.cmd("edit " .. vim.fn.fnameescape(fname))
end

-- Tail log in split
function M.tail_log()
  local fname = vim.lsp.log.get_filename()
  vim.cmd("split")
  vim.cmd("term tail -f " .. vim.fn.shellescape(fname))
end

return M
