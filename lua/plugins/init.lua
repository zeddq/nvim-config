-- Plugin Management with lazy.nvim
-- Bootstrap and configuration

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
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
  { import = "plugins.lazydev" },   -- Neovim Lua API (vim.* completions)
  { import = "plugins.completion" }, -- Autocompletion
  { import = "plugins.treesitter" }, -- Syntax highlighting
  { import = "plugins.none-ls" }, -- Formatting & linting
  { import = "plugins.ui" }, -- UI plugins (includes gitsigns)
  { import = "plugins.flash" }, -- Enhanced f/t navigation
  { import = "plugins.dap" }, -- Debug Adapter Protocol (Python debugging)
  { import = "plugins.jj-diffconflicts" }, -- Jujutsu aware merge plugin
  { import = "plugins.soil" }, -- soil plugin (preview for plantuml)
}, {
  ui = {
    border = "rounded",
  },
  change_detection = {
    notify = false,
  },
})
