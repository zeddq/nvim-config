-- Per-buffer feature activation for nvim-treesitter (main branch API).
-- Called from `ftplugin/<lang>.lua`. Safe to invoke even when the parser
-- is missing — start() is pcall'd, and the auto-install autocmd in
-- `plugins/treesitter.lua` will retry once the parser is on disk.

local M = {}

---@param opts? { fold?: boolean, indent?: boolean }
function M.activate(opts)
  opts = opts or {}
  local buf = vim.api.nvim_get_current_buf()

  if not pcall(vim.treesitter.start, buf) then
    return false
  end

  if opts.fold then
    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.wo.foldmethod = "expr"
  end

  if opts.indent ~= false then
    -- Deferred so $VIMRUNTIME/indent/<lang>.vim (which loads AFTER all
    -- ftplugin files) doesn't clobber our setting.
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buf) then
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end)
  end

  return true
end

return M
