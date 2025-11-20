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
└── SNACKS_INTEGRATION.md       # snacks.nvim integration docs (NEW)
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

1. **Neovim 0.10+**

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
   ensure_installed = { 'pyright', 'your_server_here' }
   ```

2. **Configure the server**:

   ```lua
   lspconfig.your_server_here.setup({
     on_attach = on_attach,
     capabilities = capabilities,
   })
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
- **[Jujutsu VCS Integration Guide](./JJ_INTEGRATION.md)** - Complete guide
  for Git + Jujutsu support
- **[snacks.nvim Integration Guide](./SNACKS_INTEGRATION.md)** - Comprehensive
  snacks.nvim documentation

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

---

## jj.nvim Plugin Documentation

⚠️ **WORK IN PROGRESS** ⚠️

A Neovim plugin for
[Jujutsu (jj)](https://github.com/jj-vcs/jj) version control system.

### About

This plugin aims to be something like vim-fugitive but for driving the jj-vcs
CLI. The goal is to eventually provide features similar to git status, diffs,
and pickers for managing Jujutsu repositories directly from Neovim.

![Demo](https://github.com/NicolasGB/jj.nvim/raw/main/assets/demo.gif)

### Current Features

- Basic jj command execution through `:J` command
- Terminal-based output display for jj commands
- Support jj subcommands including your aliases through the cmdline.
- First class citizens with ui integration
  - `describe` / `desc` - Set change descriptions with a Git-style commit
    message editor
  - `status` / `st` - Show repository status
  - `log` - Display log history with configurable options
  - `diff` - Show changes
  - `new` - Create a new change
  - `edit` - Edit a change
  - `squash` - Squash the current diff to it's parent
- Picker for for [Snacks.nvim](https://github.com/folke/snacks.nvim)
  - `jj status` Displays the current changes diffs
  - `jj file_history` Displays a buffer's history changes and allows to edit
    it's change (including immutable changes)

### Enhanced integrations

Here are some cool features you can do with jj.nvim

#### Diff any change

You can diff any change in your log history by simply pressing `d` on it's
line, yeah just like that!
![Diff-from-log](https://github.com/NicolasGB/jj.nvim/raw/main/assets/diff-log.gif)

#### Edit mutable changes

Jumping up and down your log history ?

In your log ouptut press `CR` in a line to directly edit a `mutable` change.
![Edit-from-log](https://github.com/NicolasGB/jj.nvim/raw/main/assets/edit-log.gif)

#### Open a changed file

Just press enter to open the a file from the `status` output in your current
window.
![Open-status](https://github.com/NicolasGB/jj.nvim/raw/main/assets/enter-status.gif)

#### Restore a changed file

Press `X` on a file from the `status` output and that's it, it's restored.

![Restore-status](https://github.com/NicolasGB/jj.nvim/raw/main/assets/x-status.gif)

### jj.nvim Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "nicolasgb/jj.nvim",
  config = function()
    require("jj").setup({})
  end,
}
```

### Cmdline Usage

The plugin provides a `:J` command that accepts jj subcommands:

```sh
:J status
:J log
:J describe "Your change description"
:J new
:J # This will use your defined default command
:J <your-alias>
```

### Setup config

```lua
{
  -- Setup snacks as a picker
  picker = {
    -- Here you can pass the options as you would for snacks.
    -- It will be used when using the picker
    snacks = {

    }
  },

  -- Choose the editor mode for describe command
  -- "buffer" - Opens a Git-style commit message buffer with syntax
  --            highlighting (default)
  -- "input" - Uses a simple vim.ui.input prompt
  describe_editor = "buffer",

  -- Customize syntax highlighting colors for the describe buffer
  highlights = {
    added = { fg = "#3fb950", ctermfg = "Green" },      -- Added files
    modified = { fg = "#56d4dd", ctermfg = "Cyan" },    -- Modified files
    deleted = { fg = "#f85149", ctermfg = "Red" },      -- Deleted files
    renamed = { fg = "#d29922", ctermfg = "Yellow" },   -- Renamed files
  }
}

```

#### Describe Editor Modes

The `describe_editor` option lets you choose how you want to write commit
descriptions:

- **`"buffer"`** (default) - Opens a full buffer editor similar to Git's
  commit message editor
  - Shows file changes with syntax highlighting
  - Multi-line editing with proper formatting
  - Close with `q` or `<Esc>`, save with `:w` or `:wq`

- **`"input"`** - Simple single-line input prompt
  - Quick and minimal
  - Good for short, single-line descriptions
  - Uses `vim.ui.input()` which can be customized by UI plugins like
    dressing.nvim

Example:

```lua
require("jj").setup({
  describe_editor = "input", -- Use simple input mode
})
```

#### Highlight Customization

The `highlights` option allows you to customize the colors used in the describe
buffer's file status display. Each highlight accepts standard Neovim highlight
attributes:

- `fg` - Foreground color (hex or color name)
- `bg` - Background color
- `ctermfg` - Terminal foreground color
- `ctermbg` - Terminal background color
- `bold`, `italic`, `underline` - Text styles

Example with custom colors:

```lua
require("jj").setup({
  highlights = {
    modified = { fg = "#89ddff", bold = true },
    added = { fg = "#c3e88d", ctermfg = "LightGreen" },
  }
})
```

### Example config

```lua
{
  "nicolasgb/jj.nvim",
  dependencies = {
    "folke/snacks.nvim", -- Optional only if you use picker's
  },
  config = function()
    require("jj").setup({
      highlights = {
        -- Customize colors if desired
        modified = { fg = "#89ddff" },
      }
    })

    local cmd = require("jj.cmd")
    vim.keymap.set("n", "<leader>jd", cmd.describe,
      { desc = "JJ describe" })
    vim.keymap.set("n", "<leader>jl", cmd.log, { desc = "JJ log" })
    vim.keymap.set("n", "<leader>je", cmd.edit, { desc = "JJ edit" })
    vim.keymap.set("n", "<leader>jn", cmd.new, { desc = "JJ new" })
    vim.keymap.set("n", "<leader>js", cmd.status, { desc = "JJ status" })
    vim.keymap.set("n", "<leader>dj", cmd.diff, { desc = "JJ diff" })
    vim.keymap.set("n", "<leader>sj", cmd.squash, { desc = "JJ squash" })

    -- Pickers
    local picker = require("jj.picker")
    vim.keymap.set("n", "<leader>gj", picker.status,
      { desc = "JJ Picker status" })
    vim.keymap.set("n", "<leader>gl", picker.file_history,
      { desc = "JJ Picker file history" })

    -- Some functions like `describe` or `log` can take parameters
    vim.keymap.set("n", "<leader>jL", function()
      jj.log {
        revisions = "all()",
      }
    end, { desc = "JJ log all" })

    -- This is an alias i use for moving bookmarks its so good
    vim.keymap.set("n", "<leader>jt", function()
      cmd.j "tug"
      cmd.log {}
    end, { desc = "JJ tug" })
  end,
}

```

### Requirements

- [Jujutsu](https://github.com/jj-vcs/jj) installed and available in PATH

### Contributing

This is an early-stage project. Contributions are welcome, but please be aware
that the API and features are likely to change significantly.

### jj.nvim Plugin Documentation Details

Once the plugin is more complete i'll write docs for each of the commands.

### FAQ

- Telescope Suport? Planned but i don't use it, it's already thought of by
  design, will implement it at some point or if someone submits a PR i'll
  accept it gladly.

### jj.nvim License

[MIT](License)
