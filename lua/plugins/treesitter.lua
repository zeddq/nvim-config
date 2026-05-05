-- Treesitter (new `main` branch API)
--
-- Highlight start / fold / indent are configured per-filetype in
-- `after/ftplugin/<lang>.lua` (after/ so we override `$VIMRUNTIME` defaults
-- like Neovim's bundled lua/python indentexpr). This module only owns
-- parser installation.
--
-- Unknown filetypes are auto-installed on first encounter; the buffer is then
-- (re-)started so highlight kicks in once the parser lands.

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      local nts = require("nvim-treesitter")

      local ensure = {
        "python", "lua", "vim", "vimdoc", "query",
        "typescript", "javascript", "tsx",
        "markdown", "markdown_inline", "json",
      }
      nts.install(ensure)

      -- Auto-install parser for any filetype that doesn't have one yet.
      -- The corresponding `ftplugin/<lang>.lua` (if present) will have already
      -- attempted vim.treesitter.start(); we re-fire it once install resolves.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserTreesitterAutoInstall", { clear = true }),
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if not lang then
            return
          end
          if pcall(vim.treesitter.language.add, lang) then
            return -- already available; ftplugin handles start
          end
          nts.install({ lang }):await(function()
            if vim.api.nvim_buf_is_valid(args.buf) then
              pcall(vim.treesitter.start, args.buf, lang)
              vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end
          end)
        end,
      })
    end,
  },
}
