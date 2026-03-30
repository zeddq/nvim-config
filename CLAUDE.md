# Neovim Configuration — Claude Code Project Guide

## Project Overview

Modern Neovim 0.11+ configuration featuring LSP-based development, autocompletion, and **dual VCS support** (Git + Jujutsu). Plugin management uses [lazy.nvim](https://github.com/folke/lazy.nvim). Leader key is `<Space>`, local leader is `\`.

## Directory Structure

```text
init.lua                 # Entry point — loads config modules then plugins
lua/
  config/
    options.lua          # Editor settings (numbers, search, indent, UI)
    keymaps.lua          # Global keybindings + LSP log commands
    autocmds.lua         # Autocommands (whitespace, yank, filetype, jj merge)
  plugins/
    init.lua             # lazy.nvim bootstrap + plugin import ordering
    lsp.lua              # LSP + Mason configuration
    completion.lua       # nvim-cmp autocompletion
    treesitter.lua       # Syntax highlighting
    vcs-keymaps.lua      # Context-aware Git/Jujutsu keybindings
    jj.lua               # Jujutsu VCS integration
    neo-tree.lua         # File explorer (jj-aware)
    claude-code.lua      # Claude Code AI assistant plugin
    ui.lua               # Theme (Tokyo Night) + gitsigns
    snacks.lua           # QoL: dashboard, notifications, indent guides
    ...                  # See lua/plugins/ for full list
  utils/
    vcs.lua              # VCS detection (source of truth, 5s cache)
    jj_merge.lua         # 3-way merge conflict resolution for jj resolve
    lsp.lua              # LSP log management utilities
    init.lua             # Utils loader
tests/                   # Headless Neovim test suites
docs/                    # Extended documentation (JJ_INTEGRATION, SNACKS)
```

## Key Architectural Patterns

### VCS Duality (Git / Jujutsu)

- `utils.vcs` is the **single source of truth** for VCS detection
- Priority: `.jj` directory checked before `.git` (handles colocated repos where jj uses git as backend)
- Detection results are cached for 5 seconds (`CACHE_TTL = 5000`)
- `vcs-keymaps.lua` provides context-aware keybindings — same keys dispatch to git or jj commands
- `gitsigns` is conditionally disabled in jj repositories

### lazy.nvim Plugin Management

- Bootstrap in `lua/plugins/init.lua` — auto-clones lazy.nvim if missing
- Plugin specs live in `lua/plugins/*.lua`, each returning a table (or list of tables)
- Import order in `init.lua` matters — dependencies load first
- `snacks.lua` has priority 1000 (loads earliest)

### Neovim 0.11+ APIs

- Uses `vim.lsp.*` native APIs (not deprecated `vim.lsp.buf_*`)
- Uses `vim.hl.on_yank()` (not deprecated `vim.highlight.on_yank()`)
- Uses `vim.uv` for filesystem and timing operations
- Uses `vim.diagnostic.jump()` for diagnostic navigation

## Important Conventions

- **Plugin specs**: Every `lua/plugins/*.lua` file MUST return a table. Use `{ import = "plugins.<name>" }` to load.
- **Keymaps**: Use `<leader>` prefix for normal-mode commands. VCS keymaps are centralized in `vcs-keymaps.lua`.
- **Autocommands**: Use the `UserAutoCommands` augroup. Always provide a `desc` field.
- **Utils modules**: Access via `require("utils.vcs")`, `require("utils.lsp")`, etc.
- **VCS detection**: Always use `require("utils.vcs").detect_vcs_type()` — never check `.git`/`.jj` directly.
- **Leader key**: Space (`<Space>`) for global leader, backslash (`\`) for local leader.

## Test Execution

Tests use a **two-tier model**: unit tests (fast, mocked) and integration tests (require real plugins).

```bash
# Run unit tests (default — uses mocks, runs with --noplugin)
./tests/run_all_tests.sh

# Run unit + integration tests (loads real plugins via lazy.nvim)
./tests/run_all_tests.sh --integration

# Run a single test file
./tests/run_single_test.sh tests/<test_file>.lua
```

Unit tests run via `nvim --headless --noplugin -u init.lua -l <test_file>`. Integration tests (e.g., `test_jj_integration.lua`) run without `--noplugin` so lazy.nvim can initialize plugins. Results saved to `tests/test_results.txt`.

Unit suites: `test_vcs_detection.lua`, `test_plugin_loading.lua`, `test_commands.lua`.
Integration suite: `test_jj_integration.lua` (real jj.nvim plugin required).

## Common Development Tasks

### Adding a New Plugin

1. Create `lua/plugins/<name>.lua` returning a lazy.nvim spec table
2. Add `{ import = "plugins.<name>" }` to `lua/plugins/init.lua` in the appropriate position
3. Run `:Lazy sync` to install

### Adding a Language Server

1. Add the server name to the `servers` table in `lua/plugins/lsp.lua`
2. Mason will auto-install it on next launch

### Modifying Keymaps

- Global keymaps: `lua/config/keymaps.lua`
- VCS keymaps: `lua/plugins/vcs-keymaps.lua` (context-aware git/jj)
- LSP keymaps: defined in `lua/plugins/lsp.lua` on_attach
- Merge keymaps: `lua/utils/jj_merge.lua`

### Extending VCS Support

- VCS detection logic: `lua/utils/vcs.lua`
- VCS-aware keybindings: `lua/plugins/vcs-keymaps.lua`
- Neo-tree jj integration: `lua/plugins/neo-tree.lua`
- Gitsigns conditional loading: `lua/plugins/ui.lua`
