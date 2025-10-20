# Jujutsu VCS Integration Guide

Complete guide for using Jujutsu (jj) and Git seamlessly in Neovim.

## Overview

This Neovim configuration provides **unified VCS support** for both Git and Jujutsu repositories with:

- **Smart VCS Detection**: Automatically detects `.jj` or `.git` directories
- **Context-Aware Keybindings**: Same keys work for both Git and jj
- **Unified File Explorer**: Neo-tree with jj status integration  
- **Conditional Gitsigns**: Disabled in jj repos, active in git repos
- **Zero Manual Configuration**: Everything works automatically

## Architecture

### Core Components

1. **`lua/utils/vcs.lua`** - VCS Detection Module
   - Detects repository type (jj, git, or none)
   - 5-second caching for performance
   - Priority: `.jj` checked before `.git` (handles colocated repos)

2. **`lua/plugins/jj.lua`** - Jujutsu Plugin
   - Commands: `:J status`, `:J log`, `:J describe`, etc.
   - Always loaded (works in any directory)
   - Snacks.nvim picker integration

3. **`lua/plugins/neo-tree.lua`** - File Explorer
   - **REPLACES nvim-tree** entirely
   - Works for git, jj, and non-VCS directories
   - Sources: filesystem, git_status, jj

4. **`lua/plugins/vcs-keymaps.lua`** - Unified Keybindings
   - Context-aware: `<leader>gs` → git status OR jj status
   - 25+ unified VCS keybindings
   - Jj-specific operations with dedicated keys

5. **`lua/plugins/ui.lua`** - Modified Gitsigns
   - Conditionally attaches based on VCS type
   - Disabled in jj repos (returns `false` from `on_attach`)
   - Active in git repos with full feature set

### VCS Detection Logic

```lua
-- Priority order (CRITICAL for colocated repos):
1. Check for .jj directory  (Jujutsu)
2. Check for .git directory (Git)
3. Return "none" if neither found

-- Colocated repos: jj repos often have .git as backend
-- .jj takes priority to prevent git operations in jj repos
```

### Caching Strategy

- **Cache Duration**: 5 seconds (balances accuracy vs performance)
- **Cache Invalidation**: Auto on `DirChanged`, manual with `<leader>gR`
- **Performance**: <1ms cache hit, ~6ms cache miss
- **Cache Key**: Absolute file/directory path

## Installation & Setup

### Prerequisites

1. **Jujutsu Binary**: Install jj command-line tool
   ```bash
   # macOS
   brew install jj
   
   # Check installation
   jj --version
   ```

2. **Neovim 0.10+**: Required for latest plugin features

### Sync Configuration

Use the provided sync script:

```bash
cd ~/homedir-config
./sync-nvim.sh
```

On first launch:
- lazy.nvim will auto-install all plugins
- Mason will NOT install jj (it's a system binary)
- Neo-tree and jj.nvim will be available immediately

### Verify Installation

```vim
:checkhealth          " General health check
:Lazy                 " Verify jj.nvim and neo-tree loaded
:lua print(require("utils.vcs").detect_vcs_type())  " Test VCS detection
```

## Keybindings Reference

### File Explorer

| Key | Command | Description |
|-----|---------|-------------|
| `<leader>e` | Neotree toggle | Toggle file explorer (VCS-aware) |
| `<leader>eg` | Neotree git_status | Git status view |
| `<leader>ej` | Neotree jj | Jujutsu status view |

**Within Neo-tree:**
- `l` / `<CR>` - Open file
- `h` - Close directory
- `a` - Add file/directory
- `d` - Delete
- `r` - Rename
- `c` / `x` / `p` - Copy / Cut / Paste
- `s` - Open in split
- `v` - Open in vsplit
- `R` - Refresh
- `H` - Toggle hidden files
- `?` - Show help

### VCS Status & Info

| Key | Git Command | JJ Command | Description |
|-----|-------------|------------|-------------|
| `<leader>gs` | `git status` | `:J status` | Show working directory status |
| `<leader>gl` | `git log` | `:J log` | Show commit/change history |
| `<leader>gd` | `git diff` | `:J diff` | Show uncommitted changes |
| `<leader>gb` | `git blame` | `git blame` | Show line-by-line authorship |

### Commit/Describe Operations

| Key | Git Command | JJ Command | Description |
|-----|-------------|------------|-------------|
| `<leader>gc` | `git commit` | `:J describe` | Create commit/describe change |
| `<leader>gC` | `git commit --amend` | `:J describe` | Amend last commit/redescribe |

### Branch/Bookmark Management

| Key | Git Command | JJ Command | Description |
|-----|-------------|------------|-------------|
| `<leader>gB` | `git checkout -b <name>` | `jj bookmark create <name>` | Create new branch/bookmark |
| `<leader>gL` | `git branch -avv` | `jj bookmark list` | List branches/bookmarks |

### Remote Operations

| Key | Git Command | JJ Command | Description |
|-----|-------------|------------|-------------|
| `<leader>gp` | `git push` | `jj git push` | Push changes to remote |
| `<leader>gP` | `git pull` | `jj git fetch` | Pull/fetch from remote |
| `<leader>gf` | `git fetch` | `jj git fetch` | Fetch from remote |

### Jujutsu-Specific Operations

These keys only work in jj repositories:

| Key | Command | Description |
|-----|---------|-------------|
| `<leader>gn` | `:J new` | Create new empty change |
| `<leader>gS` | `:J squash` | Squash changes to parent |
| `<leader>ge` | `:J edit` | Edit arbitrary change |
| `<leader>gj` | `jj.picker.status` | Picker: select changed files |
| `<leader>gh` | `jj.picker.file_history` | Picker: file history |

### Git-Specific Operations (via Gitsigns)

These keys only work in git repositories (gitsigns disabled in jj):

| Key | Command | Description |
|-----|---------|-------------|
| `]c` | Next hunk | Jump to next git hunk |
| `[c` | Previous hunk | Jump to previous git hunk |
| `<leader>hs` | Stage hunk | Stage current hunk |
| `<leader>hr` | Reset hunk | Reset current hunk |
| `<leader>hp` | Preview hunk | Preview hunk diff |
| `<leader>hS` | Stage buffer | Stage entire buffer |
| `<leader>hR` | Reset buffer | Reset entire buffer |
| `<leader>hb` | Blame line | Show blame for line |
| `<leader>hd` | Diff this | Diff current file |
| `ih` | Select hunk | Text object for hunk |

### Utility Commands

| Key | Command | Description |
|-----|---------|-------------|
| `<leader>gR` | Clear VCS cache | Force VCS re-detection |
| `<leader>g?` | Show VCS info | Display VCS type, root, cache stats |

## Usage Scenarios

### Scenario 1: Working in a Git Repository

```vim
" Open Neovim in a git repo
cd ~/my-git-project
nvim .

" File explorer shows git status
<leader>e                    " Opens neo-tree with git icons

" VCS commands use git
<leader>gs                   " Runs: git status
<leader>gc                   " Runs: git commit
<leader>gd                   " Runs: git diff

" Gitsigns is active
]c                           " Jump to next git hunk
<leader>hs                   " Stage hunk
```

### Scenario 2: Working in a Jujutsu Repository

```vim
" Open Neovim in a jj repo
cd ~/my-jj-project
nvim .

" File explorer shows jj status
<leader>e                    " Opens neo-tree with jj source

" VCS commands use jj
<leader>gs                   " Runs: :J status (jj status)
<leader>gc                   " Runs: :J describe
<leader>gd                   " Runs: :J diff

" Gitsigns is disabled (no ]c, [c, etc.)

" Jj-specific operations available
<leader>gn                   " Creates new change (:J new)
<leader>gS                   " Squash changes (:J squash)
```

### Scenario 3: Switching Between Repos

```vim
" Start in git repo
cd ~/git-project
nvim file.txt
<leader>gs                   " Shows git status

" Change to jj repo
:cd ~/jj-project
:e another.txt
<leader>gs                   " Shows jj status (auto-detected!)

" Cache is cleared automatically on :cd
" No manual intervention needed
```

### Scenario 4: Colocated Repository (jj + git)

Jujutsu repos can use Git as a backend, creating both `.jj` and `.git`:

```vim
" In a colocated repo (has both .jj and .git)
cd ~/colocated-project
nvim .

" VCS detection prioritizes .jj
:lua print(require("utils.vcs").detect_vcs_type())  " Returns: "jj"

" All commands use jj
<leader>gs                   " Uses: :J status (NOT git status)

" Git commands still available via terminal
:terminal git status         " Manual git if needed

" This prevents accidental git operations that could corrupt jj state
```

## Commands Reference

### Jujutsu Commands (jj.nvim)

**Via `:J` command:**
```vim
:J status           " Show working directory status
:J log              " Show change history
:J describe         " Edit change description
:J new              " Create new empty change
:J edit             " Edit arbitrary change
:J diff             " Show diff
:J squash           " Squash diff to parent
```

**Via User Commands:**
```vim
:JJStatus           " Equivalent to :J status
:JJLog              " Equivalent to :J log
:JJDescribe         " Equivalent to :J describe
:JJNew              " Equivalent to :J new
:JJEdit             " Equivalent to :J edit
:JJDiff             " Equivalent to :J diff
:JJSquash           " Equivalent to :J squash
:JJPickerStatus     " Interactive picker for changed files
:JJPickerHistory    " Interactive picker for file history
```

**Via Lua Functions:**
```vim
:lua require("jj").status()
:lua require("jj").log()
:lua require("jj").describe()
```

### Neo-tree Commands

```vim
:Neotree toggle             " Toggle file explorer
:Neotree filesystem         " Show filesystem view
:Neotree git_status         " Show git status (git repos)
:Neotree jj                 " Show jj status (jj repos)
:Neotree buffers            " Show open buffers
```

### VCS Utility Commands

```vim
" Check VCS type
:lua print(require("utils.vcs").detect_vcs_type())

" Get repository root
:lua print(require("utils.vcs").get_repo_root())

" Clear VCS cache
:lua require("utils.vcs").clear_cache()

" Enable debug mode
:lua require("utils.vcs").debug = true

" View cache statistics
:lua print(vim.inspect(require("utils.vcs").get_cache_stats()))
```

## Troubleshooting

### Issue: VCS Commands Don't Work

**Symptom**: `<leader>gs` shows "Not in a VCS repository"

**Solution**:
```vim
" Check VCS detection
:lua print(require("utils.vcs").detect_vcs_type())

" If returns "none" but you're in a repo:
" 1. Verify .jj or .git exists
:!ls -la | grep -E '\.jj|\.git'

" 2. Clear cache and retry
<leader>gR
<leader>gs
```

### Issue: Gitsigns Appears in JJ Repo

**Symptom**: Git signs (│, ~, +) appear in jj repository

**Solution**:
```vim
" This should NOT happen. If it does:
" 1. Check VCS detection
:lua print(require("utils.vcs").detect_vcs_type())  " Should return "jj"

" 2. Manually detach gitsigns
:lua require("gitsigns").detach()

" 3. Check gitsigns on_attach logic in ui.lua
```

### Issue: Neo-tree Doesn't Show JJ Status

**Symptom**: Neo-tree opens but no jj source/tab

**Solution**:
```vim
" 1. Verify neo-tree-jj.nvim is loaded
:Lazy

" 2. Manually open jj source
:Neotree jj

" 3. Check if in jj repo
:lua print(require("utils.vcs").detect_vcs_type())
```

### Issue: JJ Binary Not Found

**Symptom**: "jj binary not found in PATH" warning

**Solution**:
```bash
# Install jj
brew install jj  # macOS
# or build from source

# Verify installation
which jj
jj --version

# Restart Neovim
```

### Issue: Slow VCS Detection

**Symptom**: Noticeable delay when pressing VCS keybindings

**Solution**:
```vim
" Check cache hit rate
:lua print(vim.inspect(require("utils.vcs").get_cache_stats()))

" If valid_entries is low, cache might be expiring too quickly
" Edit lua/utils/vcs.lua and increase CACHE_TTL from 5000 to 10000

" Enable debug mode to see cache behavior
:lua require("utils.vcs").debug = true
<leader>gs  " Watch for cache hit/miss messages
```

### Issue: Wrong VCS Type Detected

**Symptom**: In jj repo but uses git commands (or vice versa)

**Solution**:
```vim
" 1. Check directory contents
:!ls -la | grep -E '\.jj|\.git'

" 2. Force cache clear
<leader>gR

" 3. Check detection priority
:lua vim.pretty_print(require("utils.vcs").detect_vcs_type())

" 4. If both .jj and .git exist, .jj should win
" If not, there's a bug - report to maintainer
```

## Advanced Configuration

### Customize VCS Cache Duration

Edit `lua/utils/vcs.lua`:

```lua
-- Change from 5 seconds to 10 seconds
local CACHE_TTL = 10000  -- milliseconds
```

### Add Custom VCS Keybindings

Edit `lua/plugins/vcs-keymaps.lua`:

```lua
-- Add after existing keybindings
vim.keymap.set("n", "<leader>gx", function()
  exec_vcs_cmd(
    function() run_terminal("git custom-command") end,
    function() run_terminal("jj custom-command") end
  )
end, { desc = "Custom VCS Command" })
```

### Change JJ Describe Editor

Edit `lua/plugins/jj.lua`:

```lua
require("jj").setup({
  -- Change from "buffer" to "input" for single-line prompts
  describe_editor = "input",  -- or "buffer"
})
```

### Customize Neo-tree Appearance

Edit `lua/plugins/neo-tree.lua`:

```lua
opts.window = {
  position = "right",  -- Change from "left"
  width = 40,          -- Change from 30
}
```

## Performance Benchmarks

Expected performance on typical hardware:

| Operation | Time | Notes |
|-----------|------|-------|
| VCS detection (cache hit) | <1ms | Cached result |
| VCS detection (cache miss) | ~6ms | Filesystem walk |
| Plugin load (jj.nvim) | ~50ms | Always loaded |
| Plugin load (neo-tree) | ~100ms | Lazy-loaded on :Neotree |
| Keybinding execution | <5ms | Includes VCS detection |

Total startup impact: **~50ms** (jj.nvim always loaded, others lazy)

## Migration from nvim-tree

### Key Differences

| nvim-tree | neo-tree | Impact |
|-----------|----------|---------|
| `:NvimTreeToggle` | `:Neotree toggle` | Keybinding unchanged (`<leader>e`) |
| `g?` for help | `?` for help | Different key |
| File operations in `m` menu | Direct keys (`a`, `d`, `r`) | Faster workflow |
| Git status optional | Git/jj status built-in | Better VCS integration |

### Muscle Memory Tips

Most common operations are **identical or similar**:

- `<leader>e` - Still toggles tree
- `<CR>` / `l` - Still opens files
- `h` - Still closes directories
- `a`, `d`, `r` - Still add, delete, rename

### Breaking Changes

1. **Command names**: `:NvimTreeToggle` → `:Neotree toggle`
2. **Help key**: `g?` → `?`
3. **Configuration**: Old nvim-tree config in `ui.lua` removed

## FAQ

**Q: Can I use both Git and jj in the same project?**

A: Yes! Jujutsu can use Git as a backend (colocated mode). The config prioritizes `.jj` detection, so jj commands will be used. You can still run git commands manually in terminal if needed.

**Q: Will this break my existing Git workflow?**

A: No. In Git repos, everything works identically. The only visible change is using neo-tree instead of nvim-tree for file browsing.

**Q: What happens if jj is not installed?**

A: You'll see a warning on startup, but everything else works normally. Git repos are unaffected. JJ commands will show error messages if invoked.

**Q: Can I disable jj support and only use Git?**

A: Yes. Remove these lines from `lua/plugins/init.lua`:
```lua
{ import = "plugins.jj" },
{ import = "plugins.vcs-keymaps" },
```

**Q: How do I add more VCS types (e.g., Mercurial)?**

A: Edit `lua/utils/vcs.lua` to add detection for `.hg` directory and extend keybindings in `lua/plugins/vcs-keymaps.lua` to include hg commands.

**Q: Does this work on Windows?**

A: Yes, but jj support on Windows varies. VCS detection uses cross-platform Lua functions.

## Resources

### Jujutsu Documentation
- [Official Docs](https://jj-vcs.github.io/jj/)
- [Tutorial](https://jj-vcs.github.io/jj/latest/tutorial/)
- [Git Comparison](https://jj-vcs.github.io/jj/latest/git-comparison/)

### Plugin Documentation
- [jj.nvim GitHub](https://github.com/NicolasGB/jj.nvim)
- [neo-tree.nvim GitHub](https://github.com/nvim-neo-tree/neo-tree.nvim)
- [neo-tree-jj.nvim GitHub](https://github.com/Cretezy/neo-tree-jj.nvim)
- [gitsigns.nvim GitHub](https://github.com/lewis6991/gitsigns.nvim)

### Community
- [Jujutsu Discord](https://discord.gg/dkmfj3aGQN)
- [r/neovim](https://reddit.com/r/neovim)

## License

This configuration is free to use and modify. Individual plugins have their own licenses.
