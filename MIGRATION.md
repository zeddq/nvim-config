# Migration Guide: none-ls vs vim-lsp-settings

This guide explains the differences between the new **none-ls** setup and your previous **vim-lsp-settings** configuration.

## Overview

### Previous Setup (vim-lsp-settings)
- Used `vim-lsp` as the LSP client (VimScript-based)
- Used `vim-lsp-settings` for auto-configuration
- Used `efm-langserver` for formatting with prettierd
- Format-on-save via vim-lsp autocmds

### New Setup (none-ls)
- Uses **Neovim's built-in LSP client** (faster, native)
- Uses **nvim-lspconfig** for LSP server configs
- Uses **none-ls** for formatting/linting (cleaner integration)
- Uses **Mason** for automatic tool installation

## Key Differences

### 1. Configuration Language

**Before (VimScript):**
```vim
let g:lsp_settings = {
  \ 'efm-langserver': {
  \   'disabled': v:false,
  \   ...
  \ }
\}
```

**Now (Lua):**
```lua
require('null-ls').setup({
  sources = {
    formatting.prettier,
    diagnostics.eslint_d,
  }
})
```

### 2. Tool Installation

**Before:**
- Manual installation or vim-lsp-settings auto-download
- Tools installed to `~/.local/share/vim-lsp-settings/servers/`

**Now:**
- Mason automatically installs and manages tools
- Tools installed to `~/.local/share/nvim/mason/`
- Use `:Mason` UI to manage installations

### 3. Formatting Approach

**Before (efm-langserver):**
```vim
" efm-langserver acts as a proxy for prettierd
" Complex configuration for each language
```

**Now (none-ls):**
```lua
-- Direct integration with formatters
formatting.prettier.with({
  prefer_local = 'node_modules/.bin',
})
```

### 4. Format-on-Save

**Before:**
```vim
autocmd User lsp_buffer_enabled
  \ autocmd BufWritePre <buffer> call lsp#internal#document_formatting#format()
```

**Now:**
```lua
vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function()
    vim.lsp.buf.format({ timeout_ms = 2000 })
  end,
})
```

## Feature Comparison

| Feature | vim-lsp-settings | none-ls |
|---------|------------------|---------|
| **LSP Client** | vim-lsp (plugin) | Built-in (native) |
| **Speed** | Good | Excellent |
| **Config Language** | VimScript | Lua |
| **Formatter Proxy** | efm-langserver | Direct integration |
| **Tool Management** | Manual/auto-download | Mason |
| **Diagnostics** | Via LSP | Via none-ls |
| **Code Actions** | Via LSP | Via none-ls |
| **Ecosystem** | Smaller | Larger (Lua) |

## Benefits of the New Setup

### ✅ Performance
- Native LSP client is faster (C + LuaJIT)
- No intermediary proxy (efm-langserver)
- Less memory overhead

### ✅ Simplicity
- Cleaner configuration
- Less indirection (no efm-langserver layer)
- Direct tool integration

### ✅ Ecosystem
- Better integration with modern Neovim plugins
- Larger community and support
- More active development

### ✅ Tool Management
- Mason provides unified tool installation
- Easy updates via `:Mason` or `:MasonUpdate`
- Visual UI for managing tools

### ✅ Flexibility
- Easy to add/remove formatters per project
- Fine-grained control over sources
- Better error messages and debugging

## Migration Steps

### 1. Backup Your Current Config
```bash
cp ~/.config/nvim/init.lua ~/.config/nvim/init.lua.backup
```

### 2. Remove Old Plugins
If you're switching from vim-lsp:
```bash
rm -rf ~/.local/share/nvim/lazy/vim-lsp*
```

### 3. Install New Config
```bash
# Copy the new config
cp -r /path/to/homedir-config/nvim ~/.config/

# Launch Neovim
nvim
```

### 4. Let Plugins Install
- lazy.nvim will auto-install
- Mason will download tools
- Wait for everything to complete

### 5. Verify Installation
```vim
:checkhealth
:Mason
:LspInfo
:NullLsInfo
```

## Tool Equivalents

### Formatters

| Before (efm) | Now (none-ls) |
|--------------|---------------|
| prettierd | prettier / prettier_d_slim |
| - | black (Python) |
| - | isort (Python) |
| - | stylua (Lua) |
| - | rustfmt (Rust) |
| - | gofmt (Go) |

### Linters

| Before (efm) | Now (none-ls) |
|--------------|---------------|
| Via efm-langserver | eslint_d |
| - | pylint |
| - | shellcheck |
| - | markdownlint |

## Keeping Both Configurations

You can keep both setups available:

### Option 1: Switch via Environment Variable
```bash
# In your shell config
export NVIM_LSP=none-ls  # or 'vim-lsp'
```

```lua
-- In plugins/init.lua
local lsp_choice = vim.env.NVIM_LSP or 'none-ls'
if lsp_choice == 'vim-lsp' then
  { import = "plugins.vim-lsp" }
else
  { import = "plugins.lsp" }
  { import = "plugins.none-ls" }
end
```

### Option 2: Separate Configs
```bash
# Create profile directories
~/.config/nvim-modern/    # none-ls setup
~/.config/nvim-classic/   # vim-lsp setup

# Launch with specific config
NVIM_APPNAME=nvim-modern nvim
NVIM_APPNAME=nvim-classic nvim
```

## Troubleshooting

### Formatter Not Working

1. **Check if tool is installed:**
   ```vim
   :Mason
   ```

2. **Check none-ls status:**
   ```vim
   :NullLsInfo
   ```

3. **View logs:**
   ```vim
   :NullLsLog
   ```

4. **Manual format:**
   ```vim
   :lua vim.lsp.buf.format()
   ```

### LSP Not Attaching

1. **Check LSP status:**
   ```vim
   :LspInfo
   ```

2. **Restart LSP:**
   ```vim
   :LspRestart
   ```

3. **Check logs:**
   ```vim
   :LspLog
   ```

### Mason Installation Issues

1. **Update Mason:**
   ```vim
   :MasonUpdate
   ```

2. **Reinstall a tool:**
   ```vim
   :Mason
   " Press 'X' to uninstall, then 'i' to install
   ```

3. **Check system dependencies:**
   ```bash
   # Some tools need these
   brew install node python rust go
   ```

## Reverting to vim-lsp

If you need to revert:

1. **Edit plugins/init.lua:**
   ```lua
   { import = "plugins.vim-lsp" },  -- Enable
   -- { import = "plugins.lsp" },   -- Disable
   -- { import = "plugins.none-ls" },  -- Disable
   ```

2. **Restart Neovim:**
   ```vim
   :Lazy sync
   ```

Your vim-lsp configuration is preserved in `lua/plugins/vim-lsp.lua` with all your efm-langserver and prettierd settings intact.

## Getting Help

- **none-ls issues:** https://github.com/nvimtools/none-ls.nvim/issues
- **LSP issues:** https://github.com/neovim/nvim-lspconfig/issues
- **Mason issues:** https://github.com/williamboman/mason.nvim/issues
- **Neovim help:** `:help lsp`

## Conclusion

The new setup offers better performance, cleaner configuration, and better ecosystem integration. While the transition requires learning Lua syntax, the benefits outweigh the initial learning curve.

Give it a try for a week - you'll likely find it faster and more pleasant to work with! 🚀
