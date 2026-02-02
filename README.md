# Neovim Configuration

Modern Neovim configuration with LSP, formatting, linting, and completion
support.

## Structure

```text
nvim/
├── init.lua                    # Entry point
├── lua/
│   ├── config/
│   │   ├── options.lua        # Vim options
│   │   ├── keymaps.lua        # Key mappings
│   │   └── autocmds.lua       # Autocommands
│   └── plugins/
│       ├── init.lua           # Plugin loader (lazy.nvim)
│       ├── snacks.lua         # QoL enhancements (NEW)
│       ├── lsp.lua            # LSP configuration (nvim-lspconfig + Mason)
│       ├── completion.lua     # Autocompletion (nvim-cmp)
│       ├── treesitter.lua     # Syntax highlighting
│       ├── none-ls.lua        # Formatting & linting (none-ls)
│       ├── ui.lua             # UI enhancements
│       └── vim-lsp.lua        # Alternative LSP (inactive)
├── README.md                   # This file
└── docs/
    ├── JJ_INTEGRATION.md       # Jujutsu VCS integration guide
    └── SNACKS_INTEGRATION.md   # snacks.nvim integration docs
```

## Features

### 🔧 Core Features

- **LSP Support** via nvim-lspconfig with Mason for automatic server
  installation
- **Autocompletion** with nvim-cmp and LSP integration
- **Syntax Highlighting** using nvim-treesitter
- **Formatting & Linting** with none-ls (null-ls successor)
- **🆕 Unified VCS Support** for both Git and Jujutsu (jj) repositories

### 🎨 UI Enhancements

- **File Explorer**: Neo-tree with Jujutsu (jj) support
- **Fuzzy Finder**: Telescope with FZF native extension
- **Status Line**: lualine
- **Color Scheme**: Tokyo Night
- **Register Viewer**: registers.nvim
- **Key Discovery**: which-key
- **VCS Integration** (NEW):
  - Git: gitsigns (conditional - disabled in jj repos)
  - Jujutsu: jj.nvim with full command support
  - Smart VCS detection with automatic switching
- **QoL Suite** (NEW): snacks.nvim
  - Dashboard with recent files and projects
  - Enhanced notifications for LSP/Mason
  - Indent guides for better readability
  - Statuscolumn with git signs and diagnostics
  - LSP word highlighting
  - Large file optimization
  - Fast file loading

### 📦 Supported Languages

#### Python

- LSP: Pyright
- Formatting: black, isort
- Linting: pylint

#### JavaScript/TypeScript

- LSP: typescript-language-server
- Formatting: prettier
- Linting: eslint_d

#### Lua

- LSP: lua_ls
- Formatting: stylua

#### Other Languages

- Go (gofmt, goimports)
- Rust (rustfmt)
- Shell (shfmt, shellcheck)
- Markdown (prettier, markdownlint)
- JSON/YAML (prettier)
- SQL (sqlformat)

## Installation

### Prerequisites

1. **Neovim 0.11+** (required for `vim.lsp.config` API)

   ```bash
   # macOS
   brew install neovim

   # Check version
   nvim --version
   ```

2. **Required Tools** (auto-installed via Mason)
   - Language servers (pyright, lua_ls, etc.)
   - Formatters (black, prettier, stylua, etc.)
   - Linters (pylint, eslint_d, etc.)

3. **Optional Dependencies**

   ```bash
   # For Telescope fzf-native (better performance)
   brew install cmake

   # For better searching
   brew install ripgrep fd

   # Node.js for some formatters/linters
   brew install node
   ```

### Setup

1. **Backup existing config** (if any)

   ```bash
   mv ~/.config/nvim ~/.config/nvim.backup
   ```

2. **Copy this configuration**

   ```bash
   cp -r nvim ~/.config/
   ```

3. **Launch Neovim**

   ```bash
   nvim
   ```

   On first launch:

   - lazy.nvim will auto-install
   - All plugins will be downloaded
   - Mason will install language servers
   - Treesitter parsers will be installed

4. **Verify Installation**

   ```vim
   :checkhealth
   :checkhealth snacks  " Verify snacks.nvim modules
   :Mason
   :Lazy
   ```

   The dashboard should appear on startup showing recent files.

## Key Mappings

### Leader Keys

- `<Space>` - Leader key
- `,` - Local leader key

### File Operations

- `<leader>w` - Save file
- `<leader>q` - Quit
- `<leader>e` - Toggle file explorer (Neo-tree, VCS-aware)

### Finding (Telescope)

- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `<leader>fb` - Find buffers
- `<leader>fh` - Help tags
- `<leader>fr` - Registers

### VCS Operations (NEW - Context-Aware)

- `<leader>gs` - VCS status (git/jj)
- `<leader>gl` - VCS log (git/jj)
- `<leader>gd` - VCS diff (git/jj)
- `<leader>gc` - VCS commit/describe (git/jj)
- `<leader>gb` - VCS blame (git/jj)
- `<leader>gp` - VCS push (git/jj)
- `<leader>gP` - VCS pull/fetch (git/jj)
- `<leader>gB` - Create branch/bookmark (git/jj)
- `<leader>gL` - List branches/bookmarks (git/jj)
- `<leader>gR` - Refresh VCS cache
- `<leader>g?` - Show VCS info

### Jujutsu-Specific Operations

- `<leader>gn` - JJ new (create change)
- `<leader>gS` - JJ squash
- `<leader>ge` - JJ edit
- `<leader>gj` - JJ picker: status
- `<leader>gh` - JJ picker: file history

### Conflict Resolution (jj resolve)

In the Neovim 3-way merge layout (LEFT/BASE/RIGHT on top, OUTPUT on bottom):

- `<leader>ml` - Merge: take LEFT into OUTPUT
- `<leader>mb` - Merge: take BASE into OUTPUT
- `<leader>mr` - Merge: take RIGHT into OUTPUT

### Snacks (QoL Features)

- `<leader>sn` - Notification history
- `<leader>snd` - Dismiss all notifications
- `<leader>sd` - Open dashboard
- `<leader>ss` - Toggle scratch buffer

### LSP Operations

- `gd` - Go to definition
- `gD` - Go to declaration
- `gi` - Go to implementation
- `gr` - Show references
- `K` - Hover documentation
- `<C-k>` - Signature help
- `<leader>rn` - Rename symbol
- `<leader>ca` - Code action
- `<leader>f` - Format document (auto on save)
- `<leader>gf` - Manual format

### Diagnostics

- `[d` - Previous diagnostic
- `]d` - Next diagnostic
- `<leader>e` - Open diagnostic float
- `<leader>q` - Diagnostic quickfix list

### Clipboard

- `<leader>y` - Yank to system clipboard (normal/visual)
- `<leader>p` - Paste from system clipboard

## Configuration

### Formatting on Save

Formatting is **enabled by default** for all supported filetypes. To disable:

```lua
-- In lua/plugins/none-ls.lua, comment out the on_attach function
```

### Adding More Language Servers

1. **Add to Mason ensure_installed**:

   ```lua
   -- In lua/plugins/lsp.lua
   ensure_installed = { 'basedpyright', 'your_server_here' }
   ```

2. **Configure the server** (Neovim 0.11+ API):

   ```lua
   -- In lua/plugins/lsp.lua
   vim.lsp.config['your_server_here'] = {
     capabilities = capabilities,
     settings = { ... },
   }
   vim.lsp.enable('your_server_here')
   ```

### Adding More Formatters/Linters

1. **Add to none-ls sources**:

   ```lua
   -- In lua/plugins/none-ls.lua
   sources = {
     formatting.your_formatter,
     diagnostics.your_linter,
   }
   ```

2. **Add to Mason auto-install**:

   ```lua
   ensure_installed = { 'your_tool_here' }
   ```

## Troubleshooting

### LSP Not Working

```vim
:LspInfo          " Check LSP status
:LspLog           " View LSP logs
:LspRestart       " Restart LSP
```

### Formatting Issues

```vim
:NullLsInfo       " Check none-ls status
:NullLsLog        " View none-ls logs
```

### Plugin Issues

```vim
:Lazy check       " Check for updates
:Lazy clean       " Remove unused plugins
:Lazy restore     " Restore to lockfile state
```

### General Health Check

```vim
:checkhealth      " Comprehensive system check
```

## Alternative Configurations

### vim-lsp Alternative

If you prefer vim-lsp over nvim-lspconfig:

1. Edit `lua/plugins/init.lua`:

   ```lua
   { import = "plugins.vim-lsp" },  -- Enable
   -- { import = "plugins.lsp" },   -- Disable
   ```

2. The vim-lsp configuration includes:
   - efm-langserver integration
   - prettierd formatting
   - Multiple servers per filetype

## Customization

### Change Color Scheme

Edit `lua/plugins/ui.lua`:

```lua
-- Replace tokyonight with your preferred theme
{ 'folke/tokyonight.nvim' }
```

### Modify Key Mappings

Edit `lua/config/keymaps.lua`:

```lua
vim.keymap.set('mode', 'key', 'command', { desc = 'Description' })
```

### Adjust Options

Edit `lua/config/options.lua`:

```lua
vim.opt.option_name = value
```

## Resources

### Documentation

- [Neovim Documentation](https://neovim.io/doc/)
- **[Jujutsu VCS Integration Guide](./docs/JJ_INTEGRATION.md)** - Complete guide
  for Git + Jujutsu support
- **[snacks.nvim Integration Guide](./docs/SNACKS_INTEGRATION.md)** - snacks.nvim
  quick reference

### Plugin Documentation

- [lazy.nvim](https://github.com/folke/lazy.nvim)
- [snacks.nvim](https://github.com/folke/snacks.nvim)
- [jj.nvim](https://github.com/NicolasGB/jj.nvim) - Jujutsu integration
- [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) - File
  explorer
- [neo-tree-jj.nvim](https://github.com/Cretezy/neo-tree-jj.nvim) - Jujutsu
  for neo-tree
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- [none-ls.nvim](https://github.com/nvimtools/none-ls.nvim)
- [Mason](https://github.com/williamboman/mason.nvim)

## License

This configuration is free to use and modify.
