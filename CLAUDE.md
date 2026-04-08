# Neovim Configuration — Claude Code Project Guide

## Project Overview

Modern Neovim 0.12+ configuration featuring LSP-based development, autocompletion, and **dual VCS support** (Git + Jujutsu). Plugin management uses [lazy.nvim](https://github.com/folke/lazy.nvim). Leader key is `<Space>`, local leader is `\`.

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
    lsp.lua              # LSP + Mason (basedpyright, ruff, pylsp, lua_ls, bashls, jdtls, taplo)
    completion.lua       # nvim-cmp autocompletion (sources: LSP, lazydev, snippets, buffer, path)
    lazydev.lua          # Neovim Lua API support (vim.* completions, luvit-meta)
    treesitter.lua       # Syntax highlighting
    none-ls.lua          # Custom LSP sources (AppleScript diagnostics/formatter/actions, markdownlint)
    vcs-keymaps.lua      # Context-aware Git/Jujutsu keybindings
    jj.lua               # Jujutsu VCS integration (jj.nvim)
    jj-diffconflicts.lua # Jujutsu merge conflict viewer
    neo-tree.lua         # File explorer (jj-aware via neo-tree-jj.nvim)
    claude-code.lua      # Claude Code AI assistant plugin
    ui.lua               # Theme (Tokyo Night) + telescope + gitsigns + lualine
    snacks.lua           # QoL: dashboard, notifications, indent, statuscolumn, terminal
    flash.lua            # Enhanced f/t/s navigation (flash.nvim)
    dap.lua              # Debug Adapter Protocol (Python, Lua, Bash/Zsh)
    soil.lua             # PlantUML preview
    vim-lsp.lua          # Alternative LSP setup (vim-lsp + efm — inactive, kept for reference)
  utils/
    vcs.lua              # VCS detection (source of truth, 5s cache)
    jj_merge.lua         # 3-way merge conflict resolution for jj resolve
    lsp.lua              # LSP log management utilities
    init.lua             # Utils loader
snippets/                # Custom LuaSnip snippets
tests/                   # Headless Neovim test suites
  mocks/                 # Test mocks (jj_mock.lua)
  run_all_tests.sh       # Test runner (--integration flag for real plugins)
  run_single_test.sh     # Single test runner
docs/                    # Extended documentation (JJ_INTEGRATION, SNACKS)
scripts/
  post-commit            # Git hook: regenerate cheatsheet after commit
  setup.sh               # Install git hooks (symlinks scripts/ → .git/hooks/)
cheatsheet/
  generate.sh            # Cheatsheet generator (HTML + optional VHS tape recording)
  tapes/                 # VHS .tape files for reproducible workflow demos
  workflows/             # Generated WebP/GIF output (gitignored)
  index.html             # Generated HTML cheatsheet (gitignored)
.claude/
  settings.json          # Claude Code permissions + PostToolUse hook
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

### LSP Server Architecture

Three Python LSP servers work together with separated responsibilities:
- **basedpyright**: Type checking, go-to-definition, hover, completions, auto-imports
- **ruff**: Code actions (fix all, organize imports) + formatting only (hover disabled)
- **pylsp**: Refactoring via rope only (diagnostics via python-lsp-ruff; all other capabilities disabled)

Other servers: `lua_ls` (with lazydev.nvim workspace management), `bashls`, `jdtls` (Java, requires `JAVA_HOME`), `taplo` (TOML with jj config schema)

### Dual Formatting Setup

- **none-ls.nvim** (`none-ls.lua`): Custom LSP sources — AppleScript osacompile diagnostics/formatter/code-actions, markdownlint diagnostics, gitsigns code actions. Format-on-save for its own sources.
- **Ruff**: Python formatting via LSP code actions (not conform.nvim — conform was removed).

### Neovim 0.12+ APIs

- Uses `vim.lsp.config()` / `vim.lsp.enable()` for LSP server management
- Uses `vim.lsp.log.set_level()` (replaces deprecated `vim.lsp.set_log_level()`)
- Uses `vim.hl.on_yank()` (preferred over `vim.highlight.on_yank()` alias)
- Uses `vim.uv` for filesystem and timing operations
- Uses `vim.diagnostic.jump()` for diagnostic navigation
- Uses `vim.text.diff` (renamed from `vim.diff` in 0.12)
- New 0.12 default keymaps available: `grt` (type definition), `grx` (run codelens)
- New built-in commands: `:lsp` (interactive LSP management), `:DiffTool`, `:Undotree`

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

Unit suites: `test_vcs_detection.lua`, `test_plugin_loading.lua`, `test_commands.lua`.
Integration suite: `test_jj_integration.lua` (real jj.nvim plugin required).
Mocks: `tests/mocks/jj_mock.lua` — provides fake jj.nvim API for unit tests.

## Cheatsheet Generation

The cheatsheet is a Tokyo Night-themed HTML reference of all keybindings, LSP architecture, and plugins.

```bash
# Generate HTML cheatsheet only
./cheatsheet/generate.sh --html-only

# Record animated WebP workflow demos (requires: brew install vhs)
./cheatsheet/generate.sh --record

# Both (default)
./cheatsheet/generate.sh
```

Generated output (`cheatsheet/index.html`, `cheatsheet/workflows/`) is gitignored. The cheatsheet auto-regenerates via:
- **Claude Code PostToolUse hook** — triggers on `git commit`, `jj commit`, `jj describe` (see `.claude/settings.json`)
- **Git post-commit hook** — install via `./scripts/setup.sh`

## Common Development Tasks

### Adding a New Plugin

1. Create `lua/plugins/<name>.lua` returning a lazy.nvim spec table
2. Add `{ import = "plugins.<name>" }` to `lua/plugins/init.lua` in the appropriate position
3. Run `:Lazy sync` to install

### Adding a Language Server

1. Add the server to `ensure_installed` in `mason-lspconfig.setup()` in `lua/plugins/lsp.lua`
2. Add `vim.lsp.config("server_name", { capabilities = capabilities, settings = { ... } })` block
3. Add `vim.lsp.enable("server_name")` call
4. Mason will auto-install on next launch

### Modifying Keymaps

- Global keymaps: `lua/config/keymaps.lua`
- VCS keymaps: `lua/plugins/vcs-keymaps.lua` (context-aware git/jj)
- LSP keymaps: defined in `lua/plugins/lsp.lua` via `LspAttach` autocmd
- DAP keymaps: `lua/plugins/dap.lua` (F5/F10/F11/F12, `<leader>b`, `<leader>d*`)
- Merge keymaps: `lua/utils/jj_merge.lua`
- Flash navigation: `lua/plugins/flash.lua` (s/S for jump, r/R for remote/treesitter)

### Extending VCS Support

- VCS detection logic: `lua/utils/vcs.lua`
- VCS-aware keybindings: `lua/plugins/vcs-keymaps.lua`
- Neo-tree jj integration: `lua/plugins/neo-tree.lua`
- Gitsigns conditional loading: `lua/plugins/ui.lua`

### Installing Git Hooks

```bash
./scripts/setup.sh
```

This symlinks `scripts/post-commit` into `.git/hooks/`. The hook regenerates the cheatsheet HTML after every commit (runs in background, never blocks).
