# Neovim Configuration

Modern Neovim 0.12+ configuration with LSP, autocompletion, dual VCS support (Git + Jujutsu), and auto-generated keybinding cheatsheet.

## Structure

```text
nvim/
├── init.lua                    # Entry point
├── lua/
│   ├── config/
│   │   ├── options.lua         # Vim options
│   │   ├── keymaps.lua         # Key mappings
│   │   └── autocmds.lua        # Autocommands
│   ├── plugins/
│   │   ├── init.lua            # Plugin loader (lazy.nvim)
│   │   ├── lsp.lua             # LSP configuration (Mason + native vim.lsp)
│   │   ├── completion.lua      # Autocompletion (nvim-cmp)
│   │   ├── lazydev.lua         # Neovim Lua API completions
│   │   ├── treesitter.lua      # Syntax highlighting
│   │   ├── none-ls.lua         # Custom LSP sources (AppleScript, markdownlint)
│   │   ├── vcs-keymaps.lua     # Context-aware Git/Jujutsu keybindings
│   │   ├── jj.lua              # Jujutsu VCS integration
│   │   ├── neo-tree.lua        # File explorer (jj-aware)
│   │   ├── claude-code.lua     # Claude Code AI assistant
│   │   ├── ui.lua              # Theme + telescope + gitsigns + lualine
│   │   ├── snacks.lua          # QoL: dashboard, notifications, indent
│   │   ├── flash.lua           # Enhanced navigation
│   │   ├── dap.lua             # Debug Adapter Protocol
│   │   ├── soil.lua            # PlantUML preview
│   │   └── vim-lsp.lua         # Alternative LSP (inactive, kept for reference)
│   └── utils/
│       ├── vcs.lua             # VCS detection (source of truth)
│       ├── jj_merge.lua        # Merge conflict resolution
│       └── lsp.lua             # LSP log utilities
├── scripts/
│   ├── setup.sh                # Install git hooks
│   └── post-commit             # Cheatsheet auto-regeneration hook
├── cheatsheet/
│   ├── generate.sh             # HTML cheatsheet generator
│   └── tapes/                  # VHS tape files for workflow demos
├── tests/                      # Headless Neovim test suites
├── docs/                       # Extended documentation
└── README.md
```

## Features

### Core

- **LSP** via Mason + native `vim.lsp.config()` / `vim.lsp.enable()` (Neovim 0.12+ API)
- **Autocompletion** with nvim-cmp (LSP, snippets, buffer, path sources)
- **Syntax highlighting** via nvim-treesitter
- **Custom LSP sources** via none-ls (AppleScript diagnostics/formatter, markdownlint)
- **Dual VCS support** — Git and Jujutsu with automatic detection and context-aware keybindings

### LSP Servers

| Server | Language | Responsibility |
|--------|----------|---------------|
| basedpyright | Python | Type checking, hover, completions, go-to-def, auto-imports |
| ruff | Python | Code actions (fix all, organize imports), formatting |
| pylsp | Python | Refactoring via rope only |
| lua_ls | Lua | Full LSP + lazydev.nvim workspace management |
| bashls | Shell | Full LSP |
| jdtls | Java | Full LSP (requires `JAVA_HOME`) |
| taplo | TOML | Full LSP + jj config schema |

### UI

- **File Explorer**: Neo-tree with Jujutsu support
- **Fuzzy Finder**: Telescope with FZF native
- **Status Line**: lualine
- **Color Scheme**: Tokyo Night
- **Navigation**: flash.nvim (s/S/r/R)
- **Debug**: DAP (Python, Lua, Bash/Zsh)
- **QoL**: snacks.nvim (dashboard, notifications, indent, statuscolumn, terminal)
- **AI**: Claude Code integration

## Installation

### Prerequisites

1. **Neovim 0.12+**

   ```bash
   brew install neovim
   nvim --version
   ```

2. **Optional tools**

   ```bash
   brew install ripgrep fd cmake node
   brew install vhs  # For recording cheatsheet workflow demos
   ```

### Setup

```bash
# Backup existing config (safe for first-time installs)
[ -d ~/.config/nvim ] && mv ~/.config/nvim ~/.config/nvim.backup

# Clone this config
git clone https://github.com/zeddq/nvim-config.git ~/.config/nvim
cd ~/.config/nvim

# Install git hooks (cheatsheet auto-regeneration)
./scripts/setup.sh

# Launch — plugins auto-install on first run
nvim
```

Verify with `:checkhealth`, `:Mason`, `:Lazy`.

## Key Mappings

Leader: `<Space>` | Local leader: `\`

### Global

| Key | Action |
|-----|--------|
| `<leader>w` | Save file |
| `Ctrl-h/j/k/l` | Move between windows |
| `Tab` / `S-Tab` | Next / previous buffer |
| `<leader>bd` | Delete buffer |
| `<leader>sv` / `<leader>sh` | Split vertical / horizontal |

### Search (Telescope)

| Key | Action |
|-----|--------|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Find buffers |
| `<leader>fh` | Help tags |

### VCS (Context-Aware Git/Jujutsu)

| Key | Git | Jujutsu |
|-----|-----|---------|
| `<leader>gs` | git status | jj status |
| `<leader>gl` | git log | jj log |
| `<leader>gd` | git diff | jj diff |
| `<leader>gc` | git commit | jj describe |
| `<leader>gb` | git blame | git blame (fallback) |
| `<leader>gp` | git push | jj git push |
| `<leader>gB` | git checkout -b | jj bookmark create |
| `<leader>gO` | Open in browser (Snacks) | Open in browser |
| `<leader>gR` | Refresh VCS cache | Refresh VCS cache |

Jujutsu-only: `<leader>gn` (new), `<leader>gS` (squash), `<leader>ge` (edit)

### LSP

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Show references |
| `K` | Hover documentation |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `<leader>cr` | Refactor (via rope) |
| `<leader>f` | Format document |

### Debug (DAP)

| Key | Action |
|-----|--------|
| `F5` | Start / Continue |
| `F10` / `F11` / `F12` | Step over / into / out |
| `<leader>b` | Toggle breakpoint |
| `<leader>du` | Toggle DAP UI |

### Claude Code

| Key | Action |
|-----|--------|
| `Ctrl-,` | Toggle Claude Code |
| `<leader>cc` | Toggle Claude Code |
| `<leader>cC` | Continue conversation |
| `<leader>cR` | Resume conversation (picker) |

## Cheatsheet

An auto-generated HTML cheatsheet documents all keybindings, LSP architecture, and plugins with Tokyo Night styling.

### Generate manually

```bash
# HTML only
./cheatsheet/generate.sh --html-only

# Record animated WebP workflow demos (requires vhs)
./cheatsheet/generate.sh --record

# Both
./cheatsheet/generate.sh
```

### Auto-regeneration

The cheatsheet regenerates automatically after commits via:
- **Git post-commit hook** — install with `./scripts/setup.sh`
- **Claude Code PostToolUse hook** — triggers on `git commit`, `jj commit`, `jj describe`

Generated output is gitignored. Open `cheatsheet/index.html` in a browser to view.

## Adding a Language Server

```lua
-- 1. Add to ensure_installed in lua/plugins/lsp.lua
ensure_installed = { 'basedpyright', 'your_server_here' }

-- 2. Configure the server (Neovim 0.12+ API)
vim.lsp.config('your_server_here', {
  capabilities = capabilities,
  settings = { ... },
})
vim.lsp.enable('your_server_here')
```

## Testing

```bash
./tests/run_all_tests.sh                # Unit tests (mocked, fast)
./tests/run_all_tests.sh --integration  # Unit + integration tests
./tests/run_single_test.sh tests/<file> # Single suite
```

## Troubleshooting

```vim
:checkhealth       " System check
:lsp               " Interactive LSP management (0.12+)
:Mason             " LSP server installation
:Lazy              " Plugin management
```

## Documentation

- [Jujutsu VCS Integration](./docs/JJ_INTEGRATION.md)
- [snacks.nvim Integration](./docs/SNACKS_INTEGRATION.md)
