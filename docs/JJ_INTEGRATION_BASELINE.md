# jj.nvim Integration Baseline Document

**Document Version:** 1.0
**Date:** 2025-11-10
**Status:** PRE-FIX BASELINE
**Config Location:** `/Users/cezary/.config/nvim`

---

## Executive Summary

This document captures the current state of jj.nvim integration in the Neovim configuration. The integration includes three major components:

1. **jj.nvim** - Core Jujutsu VCS plugin
2. **neo-tree-jj.nvim** - File explorer integration
3. **VCS utilities** - Context-aware keymaps and repository detection

**Current Status:** Partially functional with reported issues.

**Known Issues:**
- Commands don't work via picker (expected - picker is disabled)
- Commands don't work via keymaps (unexpected - should work)
- Error messages appear when executing commands (investigation needed)

---

## 1. Architecture Overview

### 1.1 Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        init.lua                             │
│  Loads: config.options, config.keymaps, config.autocmds,   │
│         plugins (lazy.nvim)                                 │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                 plugins/init.lua (lazy.nvim)                │
│  Load Order (dependencies first):                           │
│  1. snacks.lua (priority 1000)                              │
│  2. jj.lua (lazy=false, always loaded)                      │
│  3. neo-tree.lua (cmd="Neotree")                            │
│  4. vcs-keymaps.lua (priority 50, lazy=false)               │
│  5. other plugins...                                        │
└───────────────────────┬─────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
┌───────────────┐ ┌──────────┐ ┌──────────────────┐
│  jj.nvim      │ │ neo-tree │ │  vcs-keymaps.lua │
│  (core VCS)   │ │ with jj  │ │  (keybindings)   │
└───────┬───────┘ └────┬─────┘ └────────┬─────────┘
        │              │                 │
        │              └─────────┬───────┘
        │                        │
        └────────────┬───────────┘
                     ▼
           ┌──────────────────┐
           │   utils/vcs.lua  │
           │ (VCS detection)  │
           └──────────────────┘
```

### 1.2 Data Flow

**Command Execution Paths:**

```
Path 1: Direct jj.nvim commands
User → :J status → jj.nvim → jj CLI → Display output
User → :JJStatus → jj.status() → jj CLI → Display output

Path 2: Context-aware keymaps
User → <leader>gs → vcs-keymaps.lua → utils/vcs.lua (detect type)
                                     → jj.nvim (:J status) OR git CLI
                                     → Display output

Path 3: Picker (DISABLED)
User → <leader>gj → vcs-keymaps.lua → require("jj.picker")
                                     → [ERROR: picker disabled in snacks.lua]
```

### 1.3 Load Order & Dependencies

```
Priority 1000: snacks.nvim (infrastructure, picker disabled)
  ↓
Eager load:    jj.nvim (lazy=false)
  ├─ Dependencies: plenary.nvim, snacks.nvim (for picker, unused)
  ├─ Creates: :J command, :JJStatus, :JJLog, etc.
  └─ Config: describe_editor="buffer", picker commented out
  ↓
Priority 50:   vcs-keymaps.lua (lazy=false)
  ├─ Depends on: utils/vcs.lua
  ├─ Creates: <leader>gs, <leader>gl, <leader>gn, etc.
  └─ Uses: exec_vcs_cmd() wrapper for context-aware execution
  ↓
Lazy load:     neo-tree.nvim (cmd="Neotree")
  ├─ Dependencies: neo-tree-jj.nvim
  ├─ Sources: filesystem, buffers, git_status, jj
  └─ Auto-switches to jj source in jj repos
```

### 1.4 Critical Design Decisions

| Decision | Rationale | Impact |
|----------|-----------|--------|
| **Picker disabled** | Snacks.nvim picker disabled; keeping telescope.nvim. jj.nvim only supports Snacks picker (no Telescope support yet). | Picker commands (`<leader>gj`, `<leader>gh`) won't work. Neo-tree still functional. |
| **Always loaded** | jj.nvim loaded with `lazy=false` | Commands available everywhere, gracefully fail in non-jj repos |
| **VCS detection priority** | `.jj` checked before `.git` | Handles colocated repos (jj + git backend) correctly |
| **Context-aware keymaps** | Same keybindings work for both git and jj | Unified UX, automatic detection via utils/vcs.lua |
| **describe_editor="buffer"** | Full editor with syntax highlighting | Better UX than single-line input for commit messages |

---

## 2. Current State Analysis

### 2.1 What's Configured

#### jj.nvim Core (lua/plugins/jj.lua)

**Status:** Configured ✓
**Version:** commit a33cbba4
**Load Strategy:** Always loaded (`lazy = false`)

**Configuration:**
- `describe_editor = "buffer"` - Full editor mode
- `picker` - Commented out (disabled)
- Custom highlights - TokyoNight theme colors
- Auto-refresh highlights on colorscheme change

**Commands Created:**

| Command | Function | Status |
|---------|----------|--------|
| `:J status` | Show working copy status | Should work ⚠️ |
| `:J log` | Show commit history | Should work ⚠️ |
| `:J describe` | Edit change description | Should work ⚠️ |
| `:J new` | Create new change | Should work ⚠️ |
| `:J edit` | Edit existing change | Should work ⚠️ |
| `:J diff` | Show diff | Should work ⚠️ |
| `:J squash` | Squash to parent | Should work ⚠️ |
| `:JJStatus` | Alias for :J status | Should work ⚠️ |
| `:JJLog` | Alias for :J log | Should work ⚠️ |
| `:JJDescribe` | Alias for :J describe | Should work ⚠️ |
| `:JJNew` | Alias for :J new | Should work ⚠️ |
| `:JJEdit` | Alias for :J edit | Should work ⚠️ |
| `:JJDiff` | Alias for :J diff | Should work ⚠️ |
| `:JJSquash` | Alias for :J squash | Should work ⚠️ |
| `:JJPickerStatus` | Picker for changed files | Won't work ✗ (picker disabled) |
| `:JJPickerHistory` | Picker for file history | Won't work ✗ (picker disabled) |

**Note:** ⚠️ = Should work but reported as not working

#### Neo-tree Integration (lua/plugins/neo-tree.lua)

**Status:** Configured ✓
**Version:** neo-tree.nvim v3.x (commit f3df514), neo-tree-jj.nvim (commit c653493)
**Load Strategy:** Lazy loaded on `:Neotree` command

**Features:**
- Four sources: filesystem, buffers, git_status, **jj**
- Auto-switches to jj source in jj repos
- Integrates with VCS cache via autocmd
- Source selector tabs in UI

**Commands:**

| Command | Function | Status |
|---------|----------|--------|
| `:Neotree toggle` | Toggle main explorer | Works ✓ |
| `:Neotree jj` | Open jj status source | Should work ⚠️ |
| `<leader>e` | Toggle neo-tree | Works ✓ |
| `<leader>ej` | Open jj source | Should work ⚠️ |

#### VCS Keymaps (lua/plugins/vcs-keymaps.lua)

**Status:** Configured ✓
**Load Strategy:** Always loaded (`lazy = false`, priority 50)

**Context-Aware Keymaps:**

| Keymap | Git Action | JJ Action | Status |
|--------|-----------|-----------|--------|
| `<leader>gs` | Terminal: git status | :J status | Reported broken ⚠️ |
| `<leader>gl` | Terminal: git log | :J log | Reported broken ⚠️ |
| `<leader>gd` | Terminal: git diff | :J diff | Reported broken ⚠️ |
| `<leader>gb` | Terminal: git blame | git blame (fallback) | Reported broken ⚠️ |
| `<leader>gc` | Terminal: git commit | :J describe | Reported broken ⚠️ |
| `<leader>gC` | Terminal: git commit --amend | :J describe | Reported broken ⚠️ |
| `<leader>gp` | Terminal: git push | Terminal: jj git push | Reported broken ⚠️ |
| `<leader>gP` | Terminal: git pull | Terminal: jj git fetch | Reported broken ⚠️ |
| `<leader>gf` | Terminal: git fetch | Terminal: jj git fetch | Reported broken ⚠️ |

**JJ-Specific Keymaps (only work in jj repos):**

| Keymap | Action | Status |
|--------|--------|--------|
| `<leader>gn` | :J new | Reported broken ⚠️ |
| `<leader>gS` | :J squash | Reported broken ⚠️ |
| `<leader>ge` | :J edit | Reported broken ⚠️ |
| `<leader>gj` | jj.picker.status() | Won't work ✗ (picker disabled) |
| `<leader>gh` | jj.picker.file_history() | Won't work ✗ (picker disabled) |

**Utility Keymaps:**

| Keymap | Action | Status |
|--------|--------|--------|
| `<leader>gR` | Clear VCS cache | Should work ✓ |
| `<leader>g?` | Show VCS info | Should work ✓ |

**JJ Resolve Merge Keymaps (Neovim vimdiff):**

These are available in the **OUTPUT** window of the Neovim 3-way merge layout (LEFT/BASE/RIGHT on top, OUTPUT on bottom):

| Keymap | Action |
|--------|--------|
| `<leader>ml` | Take LEFT into OUTPUT |
| `<leader>mb` | Take BASE into OUTPUT |
| `<leader>mr` | Take RIGHT into OUTPUT |

#### VCS Utilities (lua/utils/vcs.lua)

**Status:** Configured ✓
**Features:**
- Detects git vs jj repositories
- Caching with 5-second TTL
- `.jj` prioritized over `.git` (colocated repos)
- Max traversal depth: 100 directories
- Cache invalidation on DirChanged autocmd

**API:**

```lua
-- Detection
vcs.detect_vcs_type(path)       -- Returns "jj"|"git"|"none"
vcs.is_jj_repo(path)            -- Returns boolean
vcs.is_git_repo(path)           -- Returns boolean

-- Root finding
vcs.get_repo_root(path, type)   -- Returns string|nil

-- Cache management
vcs.get_cached_vcs_type(path)   -- Fast path (no re-detection)
vcs.clear_cache(path)           -- Clear cache for path or all
vcs.get_cache_stats()           -- Debug info

-- Debug mode
vcs.debug = true                -- Enable logging
```

### 2.2 Expected Behavior vs Reality

#### Direct Commands (`:J`, `:JJStatus`, etc.)

**Expected:**
- Commands available in all directories
- Gracefully fail with message if not in jj repo
- Display output in buffer/terminal

**Reality (User Report):**
- Commands don't work properly
- Error messages appear

**Analysis:**
- Commands are properly registered in jj.lua (lines 44-82)
- They call `jj.status()`, `jj.log()`, etc. from jj.nvim
- Error likely in jj.nvim itself or jj CLI path

#### Context-Aware Keymaps

**Expected:**
- Detect VCS type via utils/vcs.lua
- Execute appropriate command (git or jj)
- Show clear error if not in a repo

**Reality (User Report):**
- Keymaps don't work properly
- Error messages appear

**Analysis:**
- Keymaps use `exec_vcs_cmd()` wrapper (vcs-keymaps.lua lines 25-62)
- Should have error handling with notifications
- Likely failing at command execution stage

#### Picker Commands

**Expected:**
- `<leader>gj`, `<leader>gh` should fail with clear message
- Reason: Snacks picker is disabled

**Reality:**
- Commands properly protected with pcall (vcs-keymaps.lua lines 242-246)
- Should show "jj.nvim picker not available" warning

### 2.3 Integration Points

#### snacks.nvim

**Status:** Loaded, picker disabled
**Impact on jj.nvim:**
- jj.nvim lists snacks.nvim as dependency for picker
- Picker config commented out in jj.lua (lines 28-30)
- Picker commands (`JJPickerStatus`, `JJPickerHistory`) will fail gracefully

**Code Evidence:**
```lua
-- jj.lua line 180
picker = { enabled = false },
```

#### neo-tree.nvim

**Status:** Functional ✓
**Integration:**
- `neo-tree-jj.nvim` provides jj source
- Auto-switches to jj source in jj repos (neo-tree.lua lines 255-271)
- Listens to VCSCacheCleared event

**Code Evidence:**
```lua
-- neo-tree.lua line 49
table.insert(opts.sources, "jj")

-- neo-tree.lua lines 261-265
if vcs_type == "jj" then
  vim.defer_fn(function()
    require("neo-tree.sources.manager").show("jj")
  end, 100)
end
```

#### gitsigns.nvim

**Status:** Loaded (via ui.lua)
**Integration:**
- Works independently of jj.nvim
- Neo-tree listens to GitSignsUpdate events
- VCS cache cleared on updates

---

## 3. Configuration Inventory

### 3.1 All jj-Related Commands

**Plugin-provided commands (from jj.nvim):**

```vim
:J status              " Show working copy status
:J log                 " Show commit/change history
:J describe            " Edit change description
:J new                 " Create new change
:J edit                " Edit existing change
:J diff                " Show diff
:J squash              " Squash diff to parent change
```

**Custom user commands (from jj.lua config):**

```vim
:JJStatus              " Alias for :J status
:JJLog                 " Alias for :J log
:JJDescribe            " Alias for :J describe
:JJNew                 " Alias for :J new
:JJEdit                " Alias for :J edit
:JJDiff                " Alias for :J diff
:JJSquash              " Alias for :J squash
:JJPickerStatus        " Picker: select changed files (DISABLED)
:JJPickerHistory       " Picker: file history (DISABLED)
```

**Neo-tree commands:**

```vim
:Neotree jj            " Open neo-tree jj source
:Neotree toggle        " Toggle (auto-switches to jj in jj repos)
```

**VCS utility commands:**

```vim
:lua require("utils.vcs").detect_vcs_type()
:lua require("utils.vcs").clear_cache()
:lua require("utils.vcs").get_cache_stats()
```

### 3.2 All jj-Related Keymaps

**Context-aware keymaps (work in both git and jj):**

```vim
<leader>e              " Toggle neo-tree
<leader>gs             " VCS status
<leader>gl             " VCS log
<leader>gd             " VCS diff
<leader>gb             " VCS blame (git only, fallback in jj)
<leader>gc             " VCS commit/describe
<leader>gC             " VCS amend/redescribe
<leader>gB             " Create branch/bookmark
<leader>gL             " List branches/bookmarks
<leader>gp             " VCS push
<leader>gP             " VCS pull/fetch
<leader>gf             " VCS fetch
```

**JJ-specific keymaps (only work in jj repos):**

```vim
<leader>gn             " jj new (create new change)
<leader>gS             " jj squash (squash to parent)
<leader>ge             " jj edit (edit existing change)
<leader>gj             " jj picker: status (DISABLED)
<leader>gh             " jj picker: file history (DISABLED)
```

**Utility keymaps:**

```vim
<leader>gR             " Clear VCS cache
<leader>g?             " Show VCS info
```

**Neo-tree keymaps:**

```vim
<leader>e              " Toggle neo-tree
<leader>eg             " Neo-tree: git status
<leader>ej             " Neo-tree: jj status
```

### 3.3 Should Work vs Won't Work

**Should Work (configured and enabled):**

| Type | Item | Expected Behavior |
|------|------|-------------------|
| Direct Command | `:J status`, `:J log`, `:J describe`, etc. | Display output in buffer/terminal |
| User Command | `:JJStatus`, `:JJLog`, etc. | Same as :J commands |
| Keymap | `<leader>gs`, `<leader>gl`, `<leader>gd` | Context-aware execution |
| Keymap | `<leader>gn`, `<leader>gS`, `<leader>ge` | JJ-specific operations |
| Neo-tree | `:Neotree jj`, `<leader>ej` | Show jj status in tree |
| Utility | `<leader>gR`, `<leader>g?` | Cache management and info |

**Won't Work (explicitly disabled):**

| Type | Item | Reason |
|------|------|--------|
| Picker Command | `:JJPickerStatus` | Snacks picker disabled |
| Picker Command | `:JJPickerHistory` | Snacks picker disabled |
| Keymap | `<leader>gj` | Calls disabled picker |
| Keymap | `<leader>gh` | Calls disabled picker |

**Will Fail Gracefully:**

| Type | Item | Error Message |
|------|------|---------------|
| Picker keymap | `<leader>gj` | "jj.nvim picker not available" |
| JJ keymap in git | `<leader>gn` | "jj new is only available in Jujutsu repositories" |
| Any VCS outside repo | `<leader>gs` | "Not in a VCS repository" |

---

## 4. Testing Matrix

### 4.1 Environment Setup

**Prerequisites:**
- [ ] Neovim config loaded successfully (no errors on startup)
- [ ] In a jj repository: `jj status` works in terminal
- [ ] In a git repository: `git status` works in terminal
- [ ] Not in any repository: test directory without .git/.jj

**Verification:**
```vim
:checkhealth jj
:checkhealth neo-tree
:Lazy load jj.nvim
```

### 4.2 Core Functionality Tests

#### Test Group 1: Direct Commands (jj repo)

**Location:** Inside jj repository

| Test | Command | Expected Result | Pass/Fail |
|------|---------|-----------------|-----------|
| 1.1 | `:J status` | Show jj status in buffer | ⚠️ |
| 1.2 | `:JJStatus` | Same as :J status | ⚠️ |
| 1.3 | `:J log` | Show jj log in buffer | ⚠️ |
| 1.4 | `:JJLog` | Same as :J log | ⚠️ |
| 1.5 | `:J describe` | Open describe buffer | ⚠️ |
| 1.6 | `:JJDescribe` | Same as :J describe | ⚠️ |
| 1.7 | `:J diff` | Show diff in buffer | ⚠️ |
| 1.8 | `:JJDiff` | Same as :J diff | ⚠️ |

**Success Criteria:** All commands execute without errors and show expected output.

#### Test Group 2: Direct Commands (git repo)

**Location:** Inside git repository (not jj)

| Test | Command | Expected Result | Pass/Fail |
|------|---------|-----------------|-----------|
| 2.1 | `:J status` | Error: "not in jj repo" or similar | ? |
| 2.2 | `:JJStatus` | Same error as :J status | ? |

**Success Criteria:** Graceful failure with clear error message (not crash).

#### Test Group 3: Context-Aware Keymaps (jj repo)

**Location:** Inside jj repository

| Test | Keymap | Expected Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------------|-----------|
| 3.1 | `<leader>gs` | Run :J status | Show jj status | ⚠️ |
| 3.2 | `<leader>gl` | Run :J log | Show jj log | ⚠️ |
| 3.3 | `<leader>gd` | Run :J diff | Show jj diff | ⚠️ |
| 3.4 | `<leader>gc` | Run :J describe | Open describe buffer | ⚠️ |
| 3.5 | `<leader>gn` | Run :J new | Create new change | ⚠️ |
| 3.6 | `<leader>gS` | Run :J squash | Squash to parent | ⚠️ |
| 3.7 | `<leader>ge` | Run :J edit | Edit change | ⚠️ |

**Success Criteria:** All keymaps execute appropriate jj commands.

#### Test Group 4: Context-Aware Keymaps (git repo)

**Location:** Inside git repository (not jj)

| Test | Keymap | Expected Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------------|-----------|
| 4.1 | `<leader>gs` | Terminal: git status | Show git status in split | ? |
| 4.2 | `<leader>gl` | Terminal: git log | Show git log in split | ? |
| 4.3 | `<leader>gd` | Terminal: git diff | Show git diff in split | ? |
| 4.4 | `<leader>gn` | N/A | Warn: "jj only" | ? |

**Success Criteria:** Git commands work; jj-specific commands show clear warning.

#### Test Group 5: Neo-tree Integration

| Test | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 5.1 | `:Neotree jj` (in jj repo) | Open neo-tree with jj source | ? |
| 5.2 | `<leader>ej` (in jj repo) | Same as 5.1 | ? |
| 5.3 | `<leader>e` (in jj repo) | Auto-switch to jj source | ? |
| 5.4 | `:Neotree jj` (in git repo) | Open but show empty/error | ? |

**Success Criteria:** jj source shows changed files in jj repos.

#### Test Group 6: Picker (Expected to Fail)

| Test | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 6.1 | `:JJPickerStatus` | Error: "picker not available" | ? |
| 6.2 | `<leader>gj` | Notify: "picker not available" | ? |
| 6.3 | `<leader>gh` | Notify: "picker not available" | ? |

**Success Criteria:** Clear notification that picker is disabled (not crash).

#### Test Group 7: VCS Utilities

| Test | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 7.1 | `<leader>g?` (in jj repo) | Show "Type: jj" + root path | ? |
| 7.2 | `<leader>g?` (in git repo) | Show "Type: git" + root path | ? |
| 7.3 | `<leader>g?` (no repo) | Show "Type: none" | ? |
| 7.4 | `<leader>gR` | Notify: "Cache cleared" | ? |

**Success Criteria:** VCS detection works correctly for all repo types.

### 4.3 Error Handling Tests

| Test | Scenario | Expected Behavior | Pass/Fail |
|------|----------|-------------------|-----------|
| E1 | `:J status` in non-jj directory | Graceful error message | ? |
| E2 | `<leader>gn` in git repo | Warn: "jj only" | ? |
| E3 | `<leader>gs` with no VCS | Warn: "Not in VCS repo" | ? |
| E4 | Malformed jj command | Show jj CLI error | ? |
| E5 | VCS detection failure | Fallback to "none" | ? |

**Success Criteria:** No crashes; clear, actionable error messages.

### 4.4 Integration Tests

| Test | Scenario | Expected Behavior | Pass/Fail |
|------|----------|-------------------|-----------|
| I1 | Change directory with `<leader>gR` | Cache clears, re-detect VCS | ? |
| I2 | DirChanged autocmd | Cache auto-clears | ? |
| I3 | Colorscheme change | jj highlights refresh | ? |
| I4 | Neo-tree jj source in jj repo | Shows changed files | ? |
| I5 | Neo-tree auto-switch | Switches to jj in jj repos | ? |

**Success Criteria:** Components communicate correctly; no stale state.

---

## 5. Known Issues

### 5.1 User-Reported Issues

**Issue 1: Commands Don't Work via Keymaps**

**Report:** "Commands don't work via keymaps"
**Severity:** HIGH
**Expected:** `<leader>gs` executes `:J status` in jj repo
**Actual:** Unknown (error messages appear)

**Investigation Points:**
- Does `exec_vcs_cmd()` detect VCS type correctly?
- Does the vim.cmd("J status") call execute?
- What error message is shown to the user?
- Does manual `:J status` work when keymap fails?

**Code Locations:**
- vcs-keymaps.lua lines 90-98 (`<leader>gs` definition)
- vcs-keymaps.lua lines 25-62 (`exec_vcs_cmd()` implementation)
- utils/vcs.lua lines 132-177 (`detect_vcs_type()`)

**Debugging Steps:**
1. Enable VCS debug mode: `:lua require("utils.vcs").debug = true`
2. Press `<leader>gs` in jj repo
3. Check messages: `:messages`
4. Try manual: `:J status`
5. Compare output

**Issue 2: Commands Don't Work in Picker**

**Report:** "Commands don't work in picker"
**Severity:** LOW (expected)
**Expected:** Picker commands fail gracefully
**Actual:** Unknown (may be throwing errors instead of warnings)

**Investigation Points:**
- Does pcall properly catch picker loading failure?
- Is notification shown with correct severity?
- Are JJPickerStatus/JJPickerHistory commands created?

**Code Locations:**
- jj.lua lines 73-82 (picker command creation)
- vcs-keymaps.lua lines 240-270 (picker keymap protection)

**Debugging Steps:**
1. Try `:JJPickerStatus` - should fail gracefully
2. Try `<leader>gj` - should show notification
3. Check if error is WARN level or ERROR level

**Issue 3: Error Messages Appear**

**Report:** "Error messages appear"
**Severity:** MEDIUM
**Expected:** Clear, actionable error messages
**Actual:** Unknown (what messages? when?)

**Investigation Points:**
- What triggers the errors?
- Are they vim errors, Lua errors, or jj CLI errors?
- Do they show in :messages, notifications, or statusline?

**Debugging Steps:**
1. Clear messages: `:messages clear`
2. Execute suspected command
3. Check `:messages` immediately
4. Check notification history: `<leader>sn`
5. Check if jj CLI works: `:terminal jj status`

### 5.2 Potential Issues (Not Yet Confirmed)

**Potential Issue A: jj CLI Not in PATH**

**Hypothesis:** jj executable not found
**Symptoms:** All jj commands fail with "command not found"
**Check:** `:terminal which jj` or `:!jj --version`
**Fix:** Add jj to PATH or configure jj.nvim with full path

**Potential Issue B: Colocated Repo Confusion**

**Hypothesis:** In jj+git colocated repo, wrong VCS detected
**Symptoms:** Git commands run instead of jj commands
**Check:** VCS detection should prioritize .jj over .git
**Verify:** utils/vcs.lua lines 155-159 (jj checked first)

**Potential Issue C: Buffer vs Terminal Output**

**Hypothesis:** jj.nvim trying to show output in buffer, but failing
**Symptoms:** Commands run but no visible output
**Check:** jj.nvim configuration for output mode
**Verify:** jj.lua line 22 (`describe_editor = "buffer"`)

**Potential Issue D: Autocmd Interference**

**Hypothesis:** Another plugin's autocmd interfering with jj.nvim
**Symptoms:** Commands work sometimes, fail other times
**Check:** `:au BufEnter`, `:au VimEnter`
**Verify:** Disable other plugins one by one

---

## 6. Investigation Checklist

Before making any fixes, verify the following:

### 6.1 Basic Verification

- [ ] Neovim version: `:version` (should be 0.9+)
- [ ] jj CLI installed: `:!jj --version`
- [ ] jj.nvim loaded: `:Lazy load jj.nvim`
- [ ] Currently in jj repo: `:!jj status` (in terminal)
- [ ] VCS detection: `:lua print(require("utils.vcs").detect_vcs_type())`

### 6.2 Command Verification

- [ ] `:J` command exists: `:command J`
- [ ] `:JJStatus` command exists: `:command JJStatus`
- [ ] Try manual `:J status` - does it work?
- [ ] Try manual `:JJStatus` - does it work?
- [ ] Try `require("jj").status()` in Lua - does it work?

### 6.3 Keymap Verification

- [ ] Keymaps registered: `:map <leader>gs`
- [ ] VCS utils loaded: `:lua print(vim.inspect(require("utils.vcs")))`
- [ ] Debug mode enabled: `:lua require("utils.vcs").debug = true`
- [ ] Press `<leader>gs` - check `:messages` for debug output
- [ ] Check if keymap function even runs: add print statement

### 6.4 Error Analysis

- [ ] Clear messages: `:messages clear`
- [ ] Execute failing command
- [ ] Check `:messages` - copy full error
- [ ] Check notification history: `<leader>sn`
- [ ] Check LSP log if relevant: `:LspLogOpen`
- [ ] Check if error is Lua or jj CLI: `:terminal jj status`

### 6.5 Picker Verification (Should Fail)

- [ ] Snacks picker disabled: `:lua print(require("snacks.config").picker.enabled)`
- [ ] Try `:JJPickerStatus` - should fail gracefully
- [ ] Try `<leader>gj` - should show notification
- [ ] Error message is WARN, not ERROR

---

## 7. Next Steps

This baseline document should be used as a reference during debugging. The investigation should follow this order:

1. **Verify Environment** (Section 6.1)
   - Confirm jj CLI works
   - Confirm jj.nvim is loaded
   - Confirm VCS detection works

2. **Test Direct Commands** (Section 4.2, Test Group 1)
   - Does `:J status` work manually?
   - If yes: Issue is in keymaps
   - If no: Issue is in jj.nvim or jj CLI

3. **Test Keymaps** (Section 4.2, Test Group 3)
   - Enable debug mode
   - Test one keymap at a time
   - Isolate where failure occurs

4. **Analyze Errors** (Section 6.4)
   - Collect actual error messages
   - Determine if Lua error, vim error, or CLI error
   - Trace back to source

5. **Fix Issues**
   - Update configuration
   - Add error handling
   - Improve notifications

6. **Re-test** (Section 4)
   - Run full testing matrix
   - Verify all expected behaviors
   - Confirm graceful failures

7. **Document Fixes**
   - Update this baseline with "FIXED" status
   - Create FIXES.md with solutions
   - Update README.md with working examples

---

## 8. Appendix

### 8.1 File Locations

```
/Users/cezary/.config/nvim/
├── init.lua                          # Entry point
├── lua/
│   ├── config/
│   │   ├── keymaps.lua              # Global keymaps
│   │   ├── options.lua              # Vim options
│   │   └── autocmds.lua             # Autocommands
│   ├── plugins/
│   │   ├── init.lua                 # Lazy.nvim setup
│   │   ├── jj.lua                   # jj.nvim configuration ⭐
│   │   ├── neo-tree.lua             # Neo-tree with jj support ⭐
│   │   ├── vcs-keymaps.lua          # Context-aware keymaps ⭐
│   │   ├── snacks.lua               # Snacks.nvim (picker disabled)
│   │   └── ui.lua                   # UI plugins (gitsigns, etc.)
│   └── utils/
│       ├── vcs.lua                  # VCS detection utility ⭐
│       └── lsp.lua                  # LSP utilities
└── docs/
    └── JJ_INTEGRATION_BASELINE.md   # This document
```

### 8.2 Key Code Snippets

**VCS Detection (utils/vcs.lua):**

```lua
function M.detect_vcs_type(path)
  -- Check cache first
  local cached = get_from_cache(path)
  if cached then return cached end

  -- CRITICAL: Check .jj BEFORE .git
  local jj_root = find_vcs_root(path, ".jj")
  if jj_root then
    set_cache(path, "jj", jj_root)
    return "jj"
  end

  local git_root = find_vcs_root(path, ".git")
  if git_root then
    set_cache(path, "git", git_root)
    return "git"
  end

  set_cache(path, "none", nil)
  return "none"
end
```

**Command Execution Wrapper (vcs-keymaps.lua):**

```lua
local function exec_vcs_cmd(git_cmd, jj_cmd, opts)
  -- Detect VCS type
  local vcs_type = vcs.detect_vcs_type()

  if vcs_type == "none" then
    vim.notify("Not in a VCS repository", vim.log.levels.WARN)
    return
  end

  -- Select command
  local cmd = (vcs_type == "git") and git_cmd or jj_cmd

  -- Execute
  if type(cmd) == "function" then
    cmd()
  else
    vim.cmd(cmd)
  end
end
```

**jj.nvim Setup (jj.lua):**

```lua
require("jj").setup({
  describe_editor = "buffer",
  -- picker = {
  --   snacks = {},
  -- },  -- DISABLED
  highlights = {
    added = { fg = "#9ece6a" },
    modified = { fg = "#e0af68" },
    deleted = { fg = "#f7768e" },
    renamed = { fg = "#7aa2f7" },
  },
})
```

### 8.3 Useful Debug Commands

```vim
" Check if jj CLI is available
:!jj --version

" Check VCS detection
:lua print(require("utils.vcs").detect_vcs_type())

" Enable VCS debug logging
:lua require("utils.vcs").debug = true

" Get VCS info
:lua print(vim.inspect(require("utils.vcs").get_cache_stats()))

" Test jj.nvim directly
:lua require("jj").status()

" Check if commands exist
:command J
:command JJStatus

" Check if keymaps exist
:map <leader>gs

" Check messages
:messages

" Check notification history
:lua Snacks.notifier.show_history()

" Check if picker is loaded
:lua print(pcall(require, "jj.picker"))

" Load lazy.nvim UI
:Lazy

" Check health
:checkhealth jj
:checkhealth neo-tree
```

### 8.4 Related Documentation

- **Main README:** `/Users/cezary/.config/nvim/README.md`
- **Migration Doc:** `/Users/cezary/.config/nvim/MIGRATION.md`
- **JJ Integration:** `/Users/cezary/.config/nvim/JJ_INTEGRATION.md`
- **Snacks Integration:** `/Users/cezary/.config/nvim/SNACKS_INTEGRATION.md`

### 8.5 Version Information

**Installed Versions (from lazy-lock.json):**

```json
{
  "jj.nvim": {
    "branch": "main",
    "commit": "a33cbba40f18393d47e2ac2c4b00c2bc3047b571"
  },
  "neo-tree-jj.nvim": {
    "branch": "main",
    "commit": "c6534930c6f79893e12eafbb722ee23e6a83e80e"
  },
  "neo-tree.nvim": {
    "branch": "v3.x",
    "commit": "f3df514fff2bdd4318127c40470984137f87b62e"
  },
  "snacks.nvim": {
    "branch": "main",
    "commit": "<version in lock file>"
  }
}
```

---

**Document Status:** BASELINE ESTABLISHED
**Next Action:** Begin systematic testing and debugging per Section 7
**Owner:** User + Documentation Writer Agent
**Last Updated:** 2025-11-10
