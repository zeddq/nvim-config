# AI Agent Guidelines — Neovim Configuration

This file provides codebase context for AI coding assistants (GitHub Copilot, Cursor, Windsurf, Claude, and others). Follow these conventions when generating or modifying code in this repository.

## Project Summary

A Neovim 0.11+ configuration with:
- **LSP-based development** via Mason + native `vim.lsp` APIs (basedpyright, ruff, pylsp, lua_ls, bashls, jdtls, taplo)
- **Autocompletion** via nvim-cmp (LSP, lazydev, snippets, buffer, path sources)
- **Dual VCS support** — Git and Jujutsu with automatic detection
- **Debugging** via DAP (Python, Lua, Bash/Zsh)
- **Formatting** via conform.nvim (standard tools) + none-ls.nvim (custom AppleScript sources)
- **Plugin management** via [lazy.nvim](https://github.com/folke/lazy.nvim)
- **Leader key**: `<Space>` (global), `\` (local)

## Codebase Conventions

### Lua Module Patterns

All modules use Neovim's `require()` system with dot-separated paths rooted at `lua/`:

```lua
-- File: lua/utils/vcs.lua → require("utils.vcs")
-- File: lua/config/keymaps.lua → require("config.keymaps")
-- File: lua/plugins/lsp.lua → imported via lazy.nvim (see below)
```

### Plugin Spec Pattern

Every file in `lua/plugins/` **must return a table** (or list of tables) conforming to the [lazy.nvim plugin spec](https://lazy.folke.io/spec). This is the most critical convention in the codebase.

```lua
-- lua/plugins/example.lua
return {
  "author/plugin-name",
  dependencies = { "dependency/plugin" },
  event = "VeryLazy",  -- or "BufReadPre", etc.
  config = function()
    require("plugin-name").setup({
      -- configuration here
    })
  end,
}
```

Plugins are imported in `lua/plugins/init.lua` via `{ import = "plugins.<name>" }`. **Import order matters** — dependencies must be listed before dependents. Current import order: snacks → jj → neo-tree → vcs-keymaps → claude-code → lazydev → lsp → completion → treesitter → none-ls → ui → flash → dap → jj-diffconflicts → soil.

### Config Module Pattern

Core configuration in `lua/config/` is loaded directly by `init.lua`:

```lua
-- init.lua load order:
require("config.options")   -- Editor settings
require("config.keymaps")   -- Global keybindings
require("config.autocmds")  -- Autocommands
require("plugins")          -- Plugin management (lazy.nvim)
```

### Utils Module Pattern

Utility modules in `lua/utils/` export a table `M` with functions:

```lua
local M = {}
M.some_function = function() ... end
return M
```

Access via `require("utils.vcs")`, `require("utils.lsp")`, etc.

## Architecture: VCS Duality

The defining architectural feature is dual Git/Jujutsu support:

- **Detection**: `lua/utils/vcs.lua` — the single source of truth. Checks `.jj` before `.git` to handle colocated repos. Results cached for 5 seconds.
- **Keybindings**: `lua/plugins/vcs-keymaps.lua` — same keys dispatch to git or jj based on detected VCS type.
- **UI integration**: `gitsigns` disabled in jj repos; Neo-tree has jj status support.
- **Merge resolution**: `lua/utils/jj_merge.lua` provides 3-way merge keymaps for `jj resolve`.

**Important**: Never check for `.git`/`.jj` directories directly. Always use `require("utils.vcs").detect_vcs_type()`.

## Neovim 0.11+ API Usage

This configuration targets Neovim 0.11+. Use current APIs:

| Use (preferred) | Instead of (deprecated/legacy) |
| --- | --- |
| `vim.hl.on_yank()` | `vim.highlight.on_yank()` (alias, both work) |
| `vim.diagnostic.jump()` | `vim.diagnostic.goto_next()` (deprecated) |
| `vim.uv` | `vim.loop` (deprecated) |
| `vim.lsp.config("name", { ... })` | `lspconfig["name"].setup({})` (old pattern) |
| `vim.lsp.enable("name")` | automatic server start via handlers (old pattern) |
| `LspAttach` autocmd | `on_attach` callback in lspconfig setup |

### LSP Server Responsibilities

Three Python LSP servers with strict separation:
- **basedpyright**: Type checking, hover, completions, go-to-definition, auto-imports
- **ruff**: Code actions (fix all, organize imports) + formatting (hover disabled in on_attach)
- **pylsp**: Refactoring via rope only (all other capabilities disabled in on_attach)

## Testing

Tests use a two-tier model: **unit tests** (mocked, `--noplugin`, fast) and **integration tests** (real plugins, slower).

```bash
./tests/run_all_tests.sh                # Unit tests (default)
./tests/run_all_tests.sh --integration  # Unit + integration tests
./tests/run_single_test.sh tests/test_vcs_detection.lua  # Single suite (from repo root)
```

Unit tests mock external plugin APIs (e.g., `jj.nvim`) via `tests/mocks/` (e.g., `jj_mock.lua`). Integration tests (e.g., `test_jj_integration.lua`) require real plugins loaded by lazy.nvim. Test files live in `tests/` and use a custom assertion framework (no external test library).

Test suites: `test_vcs_detection.lua`, `test_plugin_loading.lua`, `test_commands.lua` (unit); `test_jj_integration.lua` (integration).

## File Reference

| Path | Purpose |
| --- | --- |
| `init.lua` | Entry point — loads config then plugins |
| `lua/config/options.lua` | Editor settings (numbers, search, indent) |
| `lua/config/keymaps.lua` | Global keybindings |
| `lua/config/autocmds.lua` | Autocommands |
| `lua/plugins/init.lua` | lazy.nvim bootstrap + import order |
| `lua/plugins/lsp.lua` | LSP servers (basedpyright, ruff, pylsp, lua_ls, bashls, jdtls, taplo) |
| `lua/plugins/completion.lua` | nvim-cmp (LSP, lazydev, snippets, buffer, path) |
| `lua/plugins/lazydev.lua` | Neovim Lua API support (vim.* completions) |
| `lua/plugins/conform.lua` | Formatting (ruff, stylua, prettier, shfmt) |
| `lua/plugins/none-ls.lua` | Custom LSP sources (AppleScript, markdownlint, gitsigns) |
| `lua/plugins/dap.lua` | Debug Adapter Protocol (Python, Lua, Bash/Zsh) |
| `lua/plugins/vcs-keymaps.lua` | Context-aware Git/Jujutsu keybindings |
| `lua/plugins/jj.lua` | Jujutsu VCS integration (jj.nvim) |
| `lua/plugins/jj-diffconflicts.lua` | Jujutsu merge conflict viewer |
| `lua/plugins/neo-tree.lua` | File explorer (jj-aware) |
| `lua/plugins/snacks.lua` | QoL: dashboard, notifications, indent, terminal |
| `lua/plugins/flash.lua` | Enhanced navigation (s/S jump, treesitter search) |
| `lua/plugins/ui.lua` | Theme (Tokyo Night) + gitsigns + lualine |
| `lua/plugins/toggleterm.lua` | Floating terminal (Ctrl-\) |
| `lua/plugins/soil.lua` | PlantUML preview |
| `lua/plugins/claude-code.lua` | Claude Code AI assistant |
| `lua/plugins/vim-lsp.lua` | Alternative LSP setup (not active by default) |
| `lua/utils/vcs.lua` | VCS detection (source of truth) |
| `lua/utils/jj_merge.lua` | Merge conflict resolution |
| `lua/utils/lsp.lua` | LSP log management |
| `snippets/` | Custom LuaSnip snippets |
| `tests/` | Headless Neovim test suites |
| `tests/mocks/` | Test mocks (jj_mock.lua) |
| `docs/` | Extended docs (JJ_INTEGRATION, SNACKS) |
| `.claude/` | Claude Code config (commands, settings) |
