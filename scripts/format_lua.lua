-- Headless formatter driver: format Lua files through Neovim's own LSP format
-- API (vim.lsp.buf.format) rather than by shelling out to stylua directly.
--
-- This exercises the real editor path — lazy.nvim loads none-ls, none-ls spawns
-- stylua, stylua discovers stylua.toml — so a green run proves format-on-save
-- will behave identically.
--
--   nvim --headless <file>... -c 'luafile scripts/format_lua.lua'
--
-- NOTE: do NOT invoke via `nvim -l`. That flag skips sourcing init.lua, so
-- lazy.nvim never bootstraps and no formatter is ever registered. The files
-- must be passed as the arglist so the config completes normal startup first.
--
-- Exits 0 on success, 1 if any file failed to attach a formatter.

-- argv() is typed `string|string[]` because the 1-arg overload returns a single
-- entry; the 0-arg form always returns the full list.
local targets = vim.fn.argv() --[[@as string[] ]]
if #targets == 0 then
  io.stderr:write("usage: nvim --headless <file>... -c 'luafile scripts/format_lua.lua'\n")
  vim.cmd("cquit 1")
end

local failures = {}

for _, target in ipairs(targets) do
  local path = vim.fn.fnamemodify(target, ":p")
  vim.cmd.edit({ args = { vim.fn.fnameescape(path) }, bang = true })
  local bufnr = vim.api.nvim_get_current_buf()

  -- none-ls registers itself as an LSP client named "null-ls"; it only attaches
  -- once the filetype has been detected and its sources match. vim.wait pumps
  -- the event loop so those async callbacks actually get a chance to run.
  local attached = vim.wait(15000, function()
    return #vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/formatting" }) > 0
  end, 50)

  if not attached then
    table.insert(failures, path .. ": no formatting-capable LSP client attached")
  else
    local before = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
    vim.lsp.buf.format({ bufnr = bufnr, async = false, timeout_ms = 15000 })
    local after = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")

    local names = vim.tbl_map(function(c)
      return c.name
    end, vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/formatting" }))

    if vim.bo[bufnr].modified then
      vim.cmd("silent write")
    end

    print(
      string.format(
        "%s  via [%s]  %s",
        vim.fn.fnamemodify(path, ":."),
        table.concat(names, ", "),
        before == after and "already formatted" or "REFORMATTED"
      )
    )
  end
end

if #failures > 0 then
  for _, msg in ipairs(failures) do
    io.stderr:write("FAIL: " .. msg .. "\n")
  end
  vim.cmd("cquit 1")
end

vim.cmd("qall!")
