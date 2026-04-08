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
    lsp.lua              # LSP + Mason (basedpyright, ruff, pylsp, lua_ls, bashls, jdtls, taplo)
    completion.lua       # nvim-cmp autocompletion (sources: LSP, lazydev, snippets, buffer, path)
    lazydev.lua          # Neovim Lua API support (vim.* completions, luvit-meta)
    treesitter.lua       # Syntax highlighting
    conform.lua          # Modern formatting (ruff, stylua, prettier, shfmt) — format-on-save
    none-ls.lua          # Custom LSP sources (AppleScript diagnostics/formatter/actions, markdownlint)
    vcs-keymaps.lua      # Context-aware Git/Jujutsu keybindings
    jj.lua               # Jujutsu VCS integration (jj.nvim)
    jj-diffconflicts.lua # Jujutsu merge conflict viewer
    neo-tree.lua         # File explorer (jj-aware via neo-tree-jj.nvim)
    claude-code.lua      # Claude Code AI assistant plugin
    ui.lua               # Theme (Tokyo Night) + gitsigns + lualine
    snacks.lua           # QoL: dashboard, notifications, indent, statuscolumn, terminal
    flash.lua            # Enhanced f/t/s navigation (flash.nvim)
    dap.lua              # Debug Adapter Protocol (Python, Lua, Bash/Zsh)
    toggleterm.lua       # Floating terminal (Ctrl-\)
    soil.lua             # PlantUML preview
    vim-lsp.lua          # Alternative LSP setup (vim-lsp + efm — not active by default)
  utils/
    vcs.lua              # VCS detection (source of truth, 5s cache)
    jj_merge.lua         # 3-way merge conflict resolution for jj resolve
    lsp.lua              # LSP log management utilities
    init.lua             # Utils loader
snippets/                # Custom LuaSnip snippets (loaded from lua/plugins/completion.lua)
tests/                   # Headless Neovim test suites
  mocks/                 # Test mocks (jj_mock.lua)
  run_all_tests.sh       # Test runner (--integration flag for real plugins)
  run_single_test.sh     # Single test runner
docs/                    # Extended documentation (JJ_INTEGRATION, SNACKS)
cheatsheet/
  generate.sh            # Cheatsheet generator (HTML + optional VHS tape recording)
  tapes/                 # VHS .tape files for reproducible workflow demos
  workflows/             # Generated WebP/GIF output (gitignored)
  index.html             # Generated HTML cheatsheet (gitignored)
.claude/
  commands/run-tests.md  # Claude Code slash command for test execution
  settings.json          # Claude Code permissions + post-commit hook
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
- `change_detection.notify = true` — notifies when plugin files change on disk

### LSP Server Architecture

Three Python LSP servers work together with separated responsibilities:
- **basedpyright**: Type checking, go-to-definition, hover, completions, auto-imports
- **ruff**: Code actions (fix all, organize imports) + formatting only (hover disabled)
- **pylsp**: Refactoring via rope only (diagnostics via python-lsp-ruff; all other capabilities disabled)

Other servers: `lua_ls` (with lazydev.nvim workspace management), `bashls`, `jdtls` (Java), `taplo` (TOML with jj config schema)

### Dual Formatting Setup

- **conform.nvim** (`conform.lua`): Primary formatter for standard tools — ruff (Python), stylua (Lua), prettier (JS/TS/JSON/YAML/MD), shfmt (shell). Format-on-save enabled.
- **none-ls.nvim** (`none-ls.lua`): Custom LSP sources that can't be expressed through conform — AppleScript osacompile diagnostics/formatter/code-actions, markdownlint diagnostics, gitsigns code actions. Also has format-on-save for its own sources.

### Neovim 0.11+ APIs

- Uses `vim.lsp.*` native APIs (not deprecated `vim.lsp.buf_*`)
- Uses `vim.hl.on_yank()` (preferred over `vim.highlight.on_yank()` alias)
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
Mocks: `tests/mocks/jj_mock.lua` — provides fake jj.nvim API for unit tests.

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

### Cheatsheet Generation

`cheatsheet/generate.sh` produces a Tokyo Night-themed HTML cheatsheet with all keybindings, LSP architecture, and plugin overview. Regenerated automatically after `git commit`, `jj commit`, or `jj describe` via a Claude Code `PostToolUse` hook (see `.claude/settings.json`). An optional git post-commit hook can be installed manually — see `.git/hooks/post-commit`.

```bash
./cheatsheet/generate.sh              # HTML + record VHS tapes (if vhs installed)
./cheatsheet/generate.sh --html-only  # HTML only
./cheatsheet/generate.sh --record     # Record animated GIF demos (requires: brew install vhs ffmpeg ttyd)
```

VHS tape files in `cheatsheet/tapes/` define reproducible workflow demos (VCS, LSP, DAP, navigation). Output goes to `cheatsheet/workflows/` (gitignored).
