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

### Formatting

Lua is formatted by stylua, configured in `stylua.toml` at the repo root (2-space, 120 col). The same file is read by the stylua CLI, by none-ls, and by the JetBrains Luau plugin. Never pass `extra_args` from none-ls — stylua's CLI flags override the config file and desync the editor from CI. Verify with `stylua --check .`.

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
| `register_server("name", { ... })` | calling `vim.lsp.config` + `vim.lsp.enable` by hand (see below) |
| `vim.lsp.log.set_level()` | `vim.lsp.set_log_level()` (deprecated in 0.12) |
| `vim.text.diff` | `vim.diff` (renamed in 0.12) |
| `LspAttach` autocmd | `on_attach` callback in lspconfig setup |

### Adding a Language Server

`lua/plugins/lsp.lua` wraps the two calls above in a local `register_server(name, config)` helper. Use it rather than calling `vim.lsp.config`/`vim.lsp.enable` directly — it records the server in `lsp_servers`, and the loop below enables it and builds its `<leader>tl<key>` toggle automatically.

Two invariants:

- **Never set `cmd`** unless deliberately overriding. `vim.lsp.config()` merges over nvim-lspconfig's `lsp/<name>.lua`, which already carries the right binary. LSP names are not binary names (`lua_ls` → `lua-language-server`, `bashls` → `bash-language-server start`, `basedpyright` → `basedpyright-langserver --stdio`; the bare `basedpyright` binary is the CLI type checker and never speaks LSP).
- **`mason-lspconfig` runs with `automatic_enable = false`**, so `register_server()` is the only thing that starts a server. Without it, every installed Mason package with an lspconfig entry auto-enables — pyright racing basedpyright, stylua attaching as an LSP server on top of the none-ls copy.

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

To check whether a failure is a regression rather than pre-existing, baseline against `HEAD` in a throwaway worktree:

```bash
git worktree add --detach /tmp/base HEAD && (cd /tmp/base && ./tests/run_single_test.sh tests/<file>.lua)
```

### Headless Neovim Gotchas

- **`nvim -l script.lua` does NOT source `init.lua`** — lazy.nvim never bootstraps, so no plugin or LSP exists. Use the arglist form: `nvim --headless <files> -c 'luafile scripts/foo.lua'`, reading targets from `vim.fn.argv()`.
- **lazy.nvim swallows `config()` errors into `vim.notify`**, which has no sink in headless mode — startup exits 0 with the plugin fully broken. Assert on observable state (`vim.lsp.get_clients()`), never on exit code alone.
- **Don't use early-exit predicates when probing LSP attach.** `vim.wait(ms, function() return #clients >= 4 end)` returns as soon as the fast servers land; `basedpyright`/`pylsp` take ~12s and look broken. Wait the full duration.
- **`scripts/format_lua.lua`** formats via `vim.lsp.buf.format()` through the real editor path — use it to verify format-on-save behaviour rather than shelling out to stylua.
- LSP log lives at `~/.local/state/nvim/lsp.log`. It grows to multiple MB and retains entries from older Neovim versions — move it aside before debugging or you will read stale crashes.

## File Reference

| Path | Purpose |
| --- | --- |
| `init.lua` | Entry point — loads config then plugins |
| `stylua.toml` | Lua formatter config (2-space, 120 col) — read by CLI, none-ls, and JetBrains |
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
| `scripts/format_lua.lua` | Headless formatter driver (`nvim --headless <files> -c 'luafile ...'`) |
| `cheatsheet/generate.sh` | HTML cheatsheet generator (`--html-only`, `--record`) |
| `cheatsheet/tapes/` | VHS tape files for animated workflow demos |
