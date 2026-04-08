# AI Agent Guidelines — Neovim Configuration

This file provides codebase context for AI coding assistants (GitHub Copilot, Cursor, Windsurf, Claude, and others). Follow these conventions when generating or modifying code in this repository.

## Project Summary

A Neovim 0.12+ configuration with:
- **LSP-based development** via Mason + native `vim.lsp` APIs
- **Autocompletion** via nvim-cmp
- **Dual VCS support** — Git and Jujutsu with automatic detection
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

Plugins are imported in `lua/plugins/init.lua` via `{ import = "plugins.<name>" }`. **Import order matters** — dependencies must be listed before dependents.

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

## Neovim 0.12+ API Usage

This configuration targets Neovim 0.12+. Use current APIs:

| Use (preferred) | Instead of (deprecated/legacy) |
| --- | --- |
| `vim.hl.on_yank()` | `vim.highlight.on_yank()` (alias, both work) |
| `vim.diagnostic.jump()` | `vim.diagnostic.goto_next()` (deprecated) |
| `vim.uv` | `vim.loop` (deprecated) |
| `vim.lsp.config("name", { ... })` | `lspconfig["name"].setup({})` (old pattern) |
| `vim.lsp.enable("name")` | automatic server start via handlers (old pattern) |
| `vim.lsp.log.set_level()` | `vim.lsp.set_log_level()` (deprecated in 0.12) |
| `vim.text.diff` | `vim.diff` (renamed in 0.12) |
| `LspAttach` autocmd | `on_attach` callback in lspconfig setup |

### New in 0.12

- **Default LSP keymaps**: `grt` (type definition), `grx` (run codelens) — available without config
- **Built-in commands**: `:lsp` (interactive management), `:DiffTool`, `:Undotree`
- **LSP capabilities**: codeLens as virtual lines, inlineCompletion, documentLink, linkedEditingRange
- **`vim.lsp.buf.code_action()` filter**: now receives client ID for server-targeted actions
- **`vim.lsp.ClientConfig.exit_timeout`**: graduated from experimental to stable (top-level field)
- **`vim.diagnostic.disable()`/`is_disabled()`**: removed — use `vim.diagnostic.enable(false, { bufnr = 0 })` to disable for current buffer
- **`autocomplete` option**: built-in insert-mode auto-completion (alternative to nvim-cmp)
- **Treesitter**: incremental node selection (`v_an`/`v_in`/`v_]n`/`v_[n`), Markdown highlighting enabled by default

## Testing

Tests use a two-tier model: **unit tests** (mocked, `--noplugin`, fast) and **integration tests** (real plugins, slower).

```bash
./tests/run_all_tests.sh                # Unit tests (default)
./tests/run_all_tests.sh --integration  # Unit + integration tests
./tests/run_single_test.sh tests/test_vcs_detection.lua  # Single suite (from repo root)
```

Unit tests mock external plugin APIs (e.g., `jj.nvim`) via `tests/mocks/`. Integration tests (e.g., `test_jj_integration.lua`) require real plugins loaded by lazy.nvim. Test files live in `tests/` and use a custom assertion framework (no external test library). See `tests/README.md` for details.

## File Reference

| Path | Purpose |
| --- | --- |
| `init.lua` | Entry point — loads config then plugins |
| `lua/config/options.lua` | Editor settings (numbers, search, indent) |
| `lua/config/keymaps.lua` | Global keybindings |
| `lua/config/autocmds.lua` | Autocommands |
| `lua/plugins/init.lua` | lazy.nvim bootstrap + import order |
| `lua/plugins/*.lua` | Individual plugin specifications |
| `lua/utils/vcs.lua` | VCS detection (source of truth) |
| `lua/utils/jj_merge.lua` | Merge conflict resolution |
| `lua/utils/lsp.lua` | LSP log management |
| `tests/` | Headless Neovim test suites |
| `docs/` | Extended docs (JJ_INTEGRATION, SNACKS) |
| `scripts/setup.sh` | Install git hooks (symlinks into `.git/hooks/`) |
| `scripts/post-commit` | Git hook: regenerate cheatsheet after commit |
| `cheatsheet/generate.sh` | HTML cheatsheet generator (`--html-only`, `--record`) |
| `cheatsheet/tapes/` | VHS tape files for animated workflow demos |
