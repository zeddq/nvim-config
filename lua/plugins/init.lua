-- Plugin Management with lazy.nvim
-- Bootstrap and configuration

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
vim.lsp.set_log_level("debug")

-- Load plugins
require("lazy").setup({
  -- Import plugin specifications
  -- Order matters: dependencies load first
  { import = "plugins.snacks" }, -- Priority 1000 (QoL enhancements)
  { import = "plugins.jj" }, -- Jujutsu VCS (always loaded)
  { import = "plugins.neo-tree" }, -- File explorer with jj support
  { import = "plugins.vcs-keymaps" }, -- Context-aware VCS keybindings
  { import = "plugins.claude-code" }, -- Claude Code AI assistant
  { import = "plugins.lsp" }, -- Language servers
  { import = "plugins.completion" }, -- Autocompletion
  { import = "plugins.treesitter" }, -- Syntax highlighting
  { import = "plugins.none-ls" }, -- Formatting & linting
  { import = "plugins.ui" }, -- UI plugins (includes gitsigns)
  { import = "plugins.dap" }, -- Debug Adapter Protocol (Python debugging)
}, {
  ui = {
    border = "rounded",
  },
  change_detection = {
    notify = false,
  },
})
