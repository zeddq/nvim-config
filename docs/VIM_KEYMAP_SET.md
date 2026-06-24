# `vim.keymap.set()` Modes, Options, and Configuration Patterns

A practical reference for defining Neovim key mappings in Lua, with notes
specific to this Neovim configuration.

## Scope and Version

This report was verified on 2026-07-27 against:

- Neovim `0.12.4`
- The installed `vim.keymap.set()` implementation and runtime help
- The current upstream Neovim documentation
- The mappings under `lua/` in this repository

The central API is:

```lua
vim.keymap.set(modes, lhs, rhs, opts)
```

It can be understood as four interacting dimensions:

```text
mode selection × trigger keys × RHS behavior × mapping options
```

The number of theoretical combinations is large. Seven principal mapping
tables alone allow 127 non-empty exact mode subsets, before considering
buffer scope, expression mappings, recursion, prefix resolution, and arbitrary
Lua callbacks. In practice, a smaller set of semantic rules determines which
combinations are useful.

## Neovim 0.12.4 Compatibility Boundary

The installed Neovim `0.12.4` implementation accepts:

```lua
vim.keymap.set(mode_or_modes, single_lhs, rhs, opts)
```

| Parameter | Neovim 0.12.4 |
|---|---|
| `modes` | A string or list of strings |
| `lhs` | One string |
| `rhs` | A string or Lua function |
| `opts` | An optional table |

Current upstream documentation also permits a list for `lhs`, producing a
mapping for every `(mode, lhs)` pair. That syntax is newer than this installed
implementation and must not yet be used in this configuration.

Valid in Neovim 0.12.4:

```lua
vim.keymap.set({ "n", "x" }, "<leader>a", action)
```

Not valid in Neovim 0.12.4:

```lua
vim.keymap.set("n", { "[d", "]d" }, action)
-- lhs: expected string, got table
```

Use a loop when several left-hand sides should share one action:

```lua
for _, lhs in ipairs({ "[d", "]d" }) do
  vim.keymap.set("n", lhs, action)
end
```

Before adopting upstream examples after an upgrade, inspect both:

```vim
:version
:help vim.keymap.set()
```

## Mode Selection

### Principal Modes

| Argument | Applies to | Common uses |
|---|---|---|
| `"n"` | Normal mode | Navigation, commands, toggles, plugin actions |
| `"x"` | Visual mode only | Selection transformations and range actions |
| `"v"` | Visual and Select modes | Behavior intentionally shared by both modes |
| `"s"` | Select mode only | Snippet placeholders and selection replacement |
| `"o"` | Operator-pending mode | Custom motions and text objects |
| `"i"` | Insert and Replace modes | Completion, snippets, editing transformations |
| `"c"` | Command-line mode | History, completion, command-line editing |
| `"t"` | Terminal-job mode | Terminal navigation and leaving terminal mode |
| `"l"` | Language-input contexts | Keyboard-layout and language transformations |

There is no separate mapping prefix for Replace mode. Insert-mode mappings
also apply there. A mode such as `"R"` is invalid.

### Composite and Special Mode Selectors

| Argument | Equivalent behavior |
|---|---|
| `""` | Bare `:map`: Normal, Visual, Select, and Operator-pending |
| `"!"` | `:map!`: Insert and Command-line |
| `"v"` | Visual and Select |
| `{ "n", "x" }` | Exactly Normal and Visual |
| `{ "n", "x", "o" }` | Exactly Normal, Visual, and Operator-pending |

Use a Lua list for an arbitrary combination:

```lua
vim.keymap.set({ "n", "x", "o" }, "H", "^", {
  desc = "First non-blank character",
})
```

Do not concatenate mode names:

```lua
-- Invalid:
vim.keymap.set("nxo", "H", "^")
```

The API also passes the abbreviation modes `"ia"`, `"ca"`, and `"!a"` to
Neovim's lower-level mapping API. These create Insert, Command-line, or
combined abbreviations rather than ordinary key mappings.

### Visual Versus Select Mode

The distinction between `"v"` and `"x"` is easy to overlook:

```lua
-- Visual and Select:
vim.keymap.set("v", "J", action)

-- Visual only:
vim.keymap.set("x", "J", action)
```

In Select mode, typing a printable character normally replaces the selection.
A printable `"v"` mapping overrides that behavior. Use `"x"` for visual
selection actions unless Select-mode behavior is explicitly desired.

### Operator-Pending Mode

Operator-pending mappings compose with every operator:

```lua
vim.keymap.set("o", "L", "$", {
  desc = "To end of line",
})
```

This makes `dL`, `cL`, `yL`, and other operator combinations use the mapped
motion. More sophisticated operator-pending mappings can enter Visual mode to
define custom text objects.

### Multi-Mode Callbacks

A callback shared by several modes receives no automatic mode parameter:

```lua
vim.keymap.set({ "n", "x" }, "<leader>a", function()
  local active_mode = vim.fn.mode(1)
  -- Branch only when the action genuinely differs by mode.
end)
```

Prefer separate mappings when their behavior is substantially different.

## Left-Hand Side: Trigger Keys

The `lhs` is a key or key sequence expressed with Neovim key notation:

```lua
"j"
"gd"
"<leader>w"
"<C-h>"
"<S-Tab>"
"<M-j>"
"<F5>"
"<Esc><Esc>"
```

Common special forms include:

| Form | Purpose |
|---|---|
| `<Leader>` | Expands from `vim.g.mapleader` when the map is defined |
| `<LocalLeader>` | Expands from `vim.g.maplocalleader` |
| `<C-x>` | Control-modified key |
| `<S-x>` | Shift-modified key |
| `<M-x>` or `<A-x>` | Meta/Alt-modified key |
| `<Esc>`, `<CR>`, `<Tab>`, `<BS>` | Named special keys |
| `<Space>` | A literal space |
| `<F1>` through function keys | Function keys |
| `<Plug>(Name)` | A plugin-defined mapping target |

Leader values must be assigned before mappings are created. This configuration
does that correctly: `init.lua` loads `config.options` before
`config.keymaps`, and `lua/config/options.lua` defines:

```lua
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
```

Changing either variable later does not update mappings that have already
expanded `<Leader>` or `<LocalLeader>`.

Some physical keys may be indistinguishable in a terminal unless the terminal
and keyboard protocol support extended key reporting. Common examples are
`<Tab>` versus `<C-I>` and `<CR>` versus `<C-M>`. Alt mappings may also be
encoded as an Escape-prefixed sequence and are affected by terminal timing.

## Right-Hand Side Forms

### Raw Key Sequences

Use a string when the action is naturally expressed by existing editor
commands:

```lua
vim.keymap.set("n", "<C-h>", "<C-w>h", {
  desc = "Move to left window",
})
```

This is useful for motions, window commands, text transformations, and
composing built-in primitives.

### Ex Commands with `<Cmd>`

Use `<Cmd>...<CR>` for an Ex command:

```lua
vim.keymap.set("n", "<leader>w", "<Cmd>write<CR>", {
  desc = "Write buffer",
})
```

Compared with the older `":write<CR>"` form, `<Cmd>`:

- Executes without entering Command-line mode
- Preserves the current mode, including Visual mode
- Does not trigger `CmdlineEnter` or `CmdlineLeave`
- Does not echo the command
- Does not need `silent = true` merely to hide command input

The older form remains valid but has more mode-dependent behavior:

```lua
vim.keymap.set("n", "<leader>w", ":write<CR>")
```

### Lua Callbacks

Use a Lua function for API calls, branching, state inspection, or several
coordinated actions:

```lua
vim.keymap.set("n", "<leader>e", function()
  vim.diagnostic.open_float({
    scope = "cursor",
    focus = false,
  })
end, {
  desc = "Show cursor diagnostic",
})
```

A direct function reference is concise when no arguments are required:

```lua
vim.keymap.set("n", "K", vim.lsp.buf.hover, {
  desc = "Hover documentation",
})
```

Use a closure when passing arguments:

```lua
vim.keymap.set("n", "<leader>f", function()
  vim.lsp.buf.format({ async = true })
end, {
  desc = "Format document",
})
```

The return value of an ordinary callback is ignored. Use `expr = true` when
the returned keys should become input.

### Deferred Module Loading

This loads the module when the mapping is defined:

```lua
vim.keymap.set("n", "<leader>x", require("some-plugin").action)
```

This defers loading until the user invokes the mapping:

```lua
vim.keymap.set("n", "<leader>x", function()
  require("some-plugin").action()
end)
```

This distinction matters when the module is expensive or belongs to a
lazy-loaded plugin. A `keys` entry in a lazy.nvim plugin specification adds
another layer: lazy.nvim can create an initial trigger mapping, load the
plugin on first use, and then execute the action.

### Expression Mappings

An expression mapping calculates and returns keys for Neovim to process:

```lua
vim.keymap.set("n", "j", function()
  return vim.v.count == 0 and "gj" or "j"
end, {
  expr = true,
  silent = true,
  desc = "Down by display line without a count",
})
```

Expression mapping rules:

- The callback should return a string or `nil`.
- `nil` is equivalent to an empty result.
- Key notation such as `"<C-n>"` is converted automatically.
- `replace_keycodes` defaults to `true`.
- `replace_keycodes = true` requires `expr = true`.
- The expression may be evaluated while Neovim is examining typeahead.
- Buffer text changes, editing another buffer, and `:normal` are restricted.
- Cursor or command-line movement performed during evaluation may be restored.

Expression mappings should calculate input, not perform arbitrary side
effects. When a side effect must be deferred, schedule it and return
`"<Ignore>"`:

```lua
vim.keymap.set("n", "]c", function()
  vim.schedule(function()
    require("gitsigns").next_hunk()
  end)
  return "<Ignore>"
end, {
  expr = true,
  desc = "Next hunk",
})
```

### `<Plug>` Targets

Plugins can expose stable, implementation-independent actions:

```lua
vim.keymap.set("n", "[%", "<Plug>(MatchitNormalMultiBackward)", {
  desc = "Previous outer block",
})
```

`<Plug>` mappings are expanded even when the user-facing mapping is
nonrecursive. This is the deliberate exception to the normal
`remap = false` behavior.

### Disabling a Key

An empty RHS is equivalent to `<Nop>`:

```lua
vim.keymap.set({ "n", "x" }, "Q", "", {
  desc = "Disable Ex mode",
})
```

## Option Reference

| Option | Type | Purpose |
|---|---|---|
| `desc` | string | Human-readable description for listing and discovery |
| `buf` | integer | Create a buffer-local mapping; `0` means current buffer |
| `remap` | boolean | Allow RHS keys to invoke other mappings |
| `expr` | boolean | Treat the RHS result as input |
| `replace_keycodes` | boolean | Expand key notation returned by an expression |
| `silent` | boolean | Do not echo the mapped command sequence |
| `nowait` | boolean | Do not wait for a possible longer mapping |
| `unique` | boolean | Fail if an equivalent mapping already exists |
| `script` | boolean | Remap only script-local `<SID>` mappings |

### `desc`

Descriptions improve:

- `:map` output
- `maparg()` and mapping API results
- which-key displays
- Plugin and configuration debugging

Every user-facing or plugin-created mapping should normally have a
description:

```lua
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, {
  desc = "Open diagnostic location list",
})
```

### `buf`

Mappings are global by default:

```lua
vim.keymap.set("n", "<leader>w", "<Cmd>write<CR>")
```

Use `buf` for filetype, LSP, terminal, merge, and temporary UI mappings:

```lua
vim.keymap.set("n", "q", "<Cmd>close<CR>", {
  buf = event.buf,
  desc = "Close window",
})
```

Buffer-local mappings:

- Take precedence over global mappings with the same mode and LHS
- Survive buffer unloading
- Are removed when the buffer is deleted

In the installed `0.12.4` implementation, `buf` must be a number:

```lua
{ buf = 0 }       -- Current buffer
{ buf = bufnr }   -- Specific buffer
```

`buf = true` fails in this build. The compatibility alias
`buffer = true|number` still works, but the installed source marks `buffer`
for soft deprecation in 0.13 and removal in 0.15. New and migrated mappings
should use `buf`.

### `remap`

Mappings created by `vim.keymap.set()` are nonrecursive by default:

```lua
vim.keymap.set("n", "j", "gj")
```

If `j` is itself mapped, the RHS above still uses built-in `j`.

Set `remap = true` when creating an alias that should follow another mapping:

```lua
vim.keymap.set("n", "<Down>", "j", {
  remap = true,
  desc = "Follow the configured down motion",
})
```

Recursive mappings can form cycles. Neovim eventually reports a recursive
mapping after reaching `maxmapdepth`, but the mapping should be designed to
avoid that state.

Do not pass `noremap` to `vim.keymap.set()`. The wrapper exposes the inverse
as `remap`; in the installed implementation, a supplied `noremap = false` is
overwritten by the wrapper's default nonrecursive behavior.

### `silent`

`silent = true` prevents the mapping's command sequence from being echoed.
It does not suppress messages produced by the command itself:

```lua
vim.keymap.set("n", "<leader>x", "<Cmd>SomeCommand<CR>", {
  silent = true,
})
```

Use command-level silencing separately when command output must also be
suppressed. Avoid suppressing errors that users need to diagnose.

### `nowait`

Mappings may share prefixes:

```lua
vim.keymap.set("n", "<leader>a", action_a)
vim.keymap.set("n", "<leader>abc", action_abc)
```

After the shorter sequence, Neovim waits to see whether the user is typing
the longer mapping. The wait is controlled by `timeout` and `timeoutlen`.

`nowait = true` executes a complete mapping immediately rather than waiting
for a possible longer match:

```lua
vim.keymap.set("n", "q", "<Cmd>close<CR>", {
  buf = event.buf,
  nowait = true,
  desc = "Close temporary window",
})
```

This can make longer mappings with the same prefix unreachable. It is most
useful for short buffer-local mappings that would otherwise be delayed by a
longer global mapping.

### `unique`

`unique = true` makes mapping creation fail instead of silently replacing an
existing mapping:

```lua
vim.keymap.set("n", "<leader>z", action, {
  unique = true,
  desc = "Protected action",
})
```

When creating a buffer-local mapping, Neovim also checks for an equal global
mapping. `unique` is useful for libraries, reusable modules, and debugging,
but is often undesirable in personal configuration where intentional
overrides are common.

### `script`

`script = true` allows only mappings local to the defining Vimscript, using
`<SID>`, to be remapped inside the RHS. It prevents unrelated user mappings
from interfering while retaining script-local composition.

This is primarily a Vimscript compatibility feature and is rarely useful in
ordinary Lua configuration.

## Precedence, Prefixes, and Timing

### Replacement and Scope

Without `unique = true`, a later mapping with the same scope, mode, and LHS
replaces the earlier mapping.

When global and buffer-local mappings both match, the buffer-local mapping
wins.

### Ambiguous Prefixes

When one mapping is a prefix of another, Neovim waits up to `timeoutlen` for
more input unless `nowait` resolves the complete mapping immediately.

This configuration sets:

```lua
vim.opt.timeoutlen = 300
```

That value affects leader sequences and every other ambiguous mapping prefix.
`ttimeoutlen` is separate: it controls how long the terminal UI waits for the
rest of a terminal keycode, such as an Escape-prefixed Alt sequence.

### Counts, Registers, and Editor State

Callbacks can inspect mapping context through values such as:

```lua
vim.v.count
vim.v.count1
vim.v.register
vim.v.operator
vim.fn.mode(1)
```

A Normal-mode mapping triggered after a count receives the count as if it
were typed before the RHS. If the RHS begins with its own numeric count, the
digits may concatenate rather than multiply. A callback can calculate the
desired behavior explicitly.

While a Normal-mode count is being entered, a mapping for `0` is disabled so
that counts such as `10` remain possible.

## Pattern Catalog

### Exact Multi-Mode Action

```lua
vim.keymap.set({ "n", "x" }, "<leader>a", action, {
  desc = "Action",
})
```

### Count-Aware Motion

```lua
vim.keymap.set("n", "j", function()
  return vim.v.count == 0 and "gj" or "j"
end, {
  expr = true,
  silent = true,
  desc = "Down by display line without a count",
})
```

### Conditional Insert Completion

```lua
vim.keymap.set("i", "<Tab>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-n>"
  end
  return "<Tab>"
end, {
  expr = true,
  desc = "Completion item or tab",
})
```

### Terminal Escape

```lua
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", {
  desc = "Leave terminal mode",
})
```

### LSP Buffer-Local Mappings

```lua
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, {
      buf = event.buf,
      silent = true,
      desc = "Hover documentation",
    })

    vim.keymap.set({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, {
      buf = event.buf,
      silent = true,
      desc = "Code action",
    })
  end,
})
```

### Filetype-Local Close Mapping

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "help", "qf", "man" },
  callback = function(event)
    vim.keymap.set("n", "q", "<Cmd>close<CR>", {
      buf = event.buf,
      nowait = true,
      desc = "Close window",
    })
  end,
})
```

### Alias That Follows Another Mapping

```lua
vim.keymap.set("n", "<Down>", "j", {
  remap = true,
  desc = "Down",
})
```

### Plugin `<Plug>` Action

```lua
vim.keymap.set("n", "<leader>p", "<Plug>(PluginAction)", {
  desc = "Plugin action",
})
```

## Local Configuration Audit

### Strong Existing Patterns

The count-aware `j` and `k` mappings in `lua/config/keymaps.lua` are a strong
use of expression mappings:

```lua
vim.keymap.set("n", "j", function()
  return vim.v.count == 0 and "gj" or "j"
end, { expr = true, silent = true, desc = "Down (visual line if no count)" })
```

Their default nonrecursive behavior is essential. Returning `"j"` invokes the
built-in motion instead of recursively invoking the mapping.

The arrow-key mappings deliberately use `remap = true`, allowing `<Down>` and
`<Up>` to inherit the count-aware `j` and `k` behavior.

The gitsigns navigation mappings in `lua/plugins/ui.lua` correctly schedule
side effects outside expression evaluation and return `"<Ignore>"`.

Most mappings include `desc`, which improves which-key discovery and
inspection.

### Visual/Select Scope to Review

Several visual actions use mode `"v"`:

- Indent and line-moving mappings in `lua/config/keymaps.lua`
- LSP code-action and extraction mappings in `lua/plugins/lsp.lua`
- Formatting mappings in `lua/plugins/none-ls.lua`
- Visual hunk actions in `lua/plugins/ui.lua`

Because `"v"` also includes Select mode, these mappings should be reviewed
and changed to `"x"` where they are intended only for Visual mode.

For example:

```lua
-- Current broad scope:
vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

-- Exact Normal plus Visual scope:
vim.keymap.set({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, opts)
```

### Legacy Buffer Option to Migrate

The compatibility key `buffer = bufnr` appears in:

- `lua/config/autocmds.lua`
- `lua/plugins/lsp.lua`
- `lua/plugins/ui.lua`
- `lua/utils/jj_merge.lua`

It should eventually become:

```lua
{ buf = bufnr }
```

This migration is behavior-preserving in Neovim 0.12.4 and prepares the
configuration for the removal noted in the installed implementation.

### Command RHS Modernization

Several global mappings use the older colon-command form:

```lua
":write<CR>"
":bnext<CR>"
":split<CR>"
```

They can be modernized to:

```lua
"<Cmd>write<CR>"
"<Cmd>bnext<CR>"
"<Cmd>split<CR>"
```

This is not required for correctness in Normal mode, but it gives clearer,
mode-preserving command semantics.

## Inspection and Conflict Diagnosis

### Interactive Commands

```vim
:map
:nmap
:xmap
:imap
:verbose nmap <leader>w
:verbose xmap K
```

`:verbose` is particularly useful because it reports where a mapping was last
defined.

### Lua Inspection

Inspect one mapping:

```lua
vim.print(vim.fn.maparg("<leader>w", "n", false, true))
```

Inspect global mappings:

```lua
vim.print(vim.api.nvim_get_keymap("n"))
```

Inspect mappings local to the current buffer:

```lua
vim.print(vim.api.nvim_buf_get_keymap(0, "n"))
```

Check whether a mapping or prefix already exists:

```lua
vim.print(vim.fn.mapcheck("<leader>a", "n"))
```

### Removing Mappings

Deletion mirrors mode and scope:

```lua
vim.keymap.del({ "n", "x" }, "<leader>a")
vim.keymap.del("n", "q", { buf = 0 })
```

On Neovim 0.12.4, `vim.keymap.del()` also requires a single string `lhs`.

## Recommended Decision Guide

Choose the mode:

- `"n"` for commands and navigation.
- `"x"` for actions on a Visual selection.
- `"o"` for reusable motions or text objects.
- `"i"` for editing and completion.
- `"c"` for command-line behavior.
- `"t"` for terminal-job input.
- A list for an exact combination.

Choose the RHS:

- Raw keys for composing editor primitives.
- `<Cmd>...<CR>` for one or more Ex commands.
- A Lua callback for API calls, arguments, branching, or coordinated actions.
- An expression callback only when calculating input keys.
- `<Plug>` when consuming a plugin's public mapping interface.
- An empty string to disable a key.

Choose the options:

- Add `desc` by default.
- Add `buf` for contextual behavior.
- Keep the default `remap = false` unless aliasing another mapping.
- Add `expr` only when the return value is input.
- Add `nowait` only after checking prefix conflicts.
- Use `unique` when replacement should be treated as an error.

## References

- [Neovim Lua API: `vim.keymap.set()`](https://neovim.io/doc/user/lua.html#vim.keymap.set())
- [Neovim Lua mapping guide](https://neovim.io/doc/user/lua-guide.html#lua-guide-mappings)
- [Neovim mapping modes and semantics](https://neovim.io/doc/user/map.html#map-modes)
- [Neovim mapping arguments](https://neovim.io/doc/user/map.html#map-arguments)
- [Neovim API: `nvim_set_keymap()`](https://neovim.io/doc/user/api.html#nvim_set_keymap())
- Local runtime help: `:help vim.keymap.set()`
- Local runtime help: `:help map-modes`
- Local runtime help: `:help map-arguments`
- Local runtime help: `:help map-expression`
- Local runtime help: `:help map-precedence`
