# Integration Test Guide: Neovim 0.11+ Compatibility Changes

This guide validates that all 4 subtask changes work together correctly.

## Overview of Changes

| Task | File | Change | Purpose |
|------|------|--------|---------|
| **ST-A** | `lua/plugins/lsp.lua` | Complete refactor to `vim.lsp.config` + `vim.lsp.enable` pattern | Neovim 0.11+ API |
| **ST-B** | `lua/plugins/init.lua` | `vim.loop.fs_stat` → `vim.uv.fs_stat` | Libuv API migration |
| **ST-C** | `lua/utils/vcs.lua` | `vim.loop.hrtime` → `vim.uv.hrtime` | Libuv API migration |
| **ST-D** | `lua/plugins/none-ls.lua` | Removed `automatic_installation` from mason-null-ls | Simplification |

---

## Test Suite

### Test 1: Startup Without Errors
**Validates:** ST-B (init.lua changes), all syntax is correct

```bash
# Start Neovim and check for immediate startup errors
nvim --noplugin +qa!
```

**Expected Output:**
- Neovim exits cleanly without error messages
- No stack traces in terminal

**What Could Go Wrong:**
- `vim.uv` is not available (wrong Neovim version < 0.10)
- Syntax errors in modified files

---

### Test 2: Check :messages for Deprecation Warnings
**Validates:** All changes use modern APIs

```vim
:messages
```

**Expected Output:**
- No deprecation warnings mentioning:
  - `vim.loop` (should be `vim.uv`)
  - `vim.lsp.handlers` (old LSP setup pattern)
  - `on_attach` callbacks (deprecated in 0.11+)
  - `automatic_installation` in mason-null-ls

**What Could Go Wrong:**
- `vim.loop.*` references still exist somewhere
- Old LSP setup pattern producing warnings

---

### Test 3: Verify LSP Info Shows All 5 Servers
**Validates:** ST-A (lsp.lua refactor), server configuration

```vim
:LspInfo
```

**Expected Output:**
```
Language client log: /path/to/.local/state/nvim/lsp.log

 Language server name: basedpyright
   filetypes:       python
   autostart:       true
   attached_buffers: <buffer list>
   cmd:              /path/to/basedpyright

 Language server name: ruff
   filetypes:       python
   autostart:       true
   attached_buffers: <buffer list>
   cmd:              /path/to/ruff

 Language server name: pylsp
   filetypes:       python
   autostart:       true
   attached_buffers: <buffer list>
   cmd:              /path/to/pylsp

 Language server name: lua_ls
   filetypes:       lua
   autostart:       true
   attached_buffers: <buffer list>
   cmd:              /path/to/lua-language-server

 Language server name: bashls
   filetypes:       sh, bash, zsh
   autostart:       true
   attached_buffers: <buffer list>
   cmd:              /path/to/bash-language-server
```

**What Could Go Wrong:**
- Some servers show as "not installed" - run `:Mason` and install missing servers
- Servers show `autostart: false` - vim.lsp.enable() didn't work
- Fewer than 5 servers listed - lsp.lua config incomplete

---

### Test 4: Test VCS Detection
**Validates:** ST-C (vcs.lua hrtime change), VCS functionality

```vim
" In a git repository:
:lua require("utils.vcs").debug = true
:lua local vcs = require("utils.vcs").detect_vcs_type()
:lua print("VCS Type: " .. vcs)

" Check debug output in :messages - should show cache operations
:messages
```

**Expected Output:**
```
[VCS] Detecting VCS for: /path/to/your/git/repo
[VCS] Cached: /path/to/your/git/repo -> git
VCS Type: git
```

**Alternative (in a Jujutsu repo):**
```
[VCS] Detecting VCS for: /path/to/your/jj/repo
[VCS] Cached: /path/to/your/jj/repo -> jj
VCS Type: jj
```

**What Could Go Wrong:**
- `vim.uv.hrtime()` not available or returns wrong type
- Cache timestamps are wrong
- Returns "none" when in a valid repo

---

### Test 5: Test Formatting Works
**Validates:** ST-D (none-ls changes), formatting pipeline

```bash
# Create a test Python file
cat > /tmp/test.py << 'EOF'
def hello(x,y):
    return x+y
EOF

# Open it in Neovim
nvim /tmp/test.py
```

```vim
" Inside Neovim:
:lua vim.lsp.buf.format()
" Or use the keymap:
:<leader>f

" Check if code is formatted (spaces around operators)
:messages
```

**Expected Output:**
- Python code reformatted with proper spacing
- No error messages about formatting
- Message shows formatting was applied: `"Formatting with ruff"`

**What Could Go Wrong:**
- `automatic_installation = false` breaks formatting setup
- None-ls not properly attached
- Mason tools not installed

**Fix if needed:**
```vim
:Mason
" Install: stylua, ruff, prettier, shfmt
```

---

### Test 6: Verify Mason UI Works
**Validates:** LSP and formatting tool installation, ST-A UI config

```vim
:Mason
```

**Expected Output:**
- Mason window opens with rounded borders
- Shows package manager UI
- List includes:
  - basedpyright ✓
  - ruff ✓
  - pylsp ✓
  - lua-language-server ✓
  - bash-language-server ✓
  - stylua, prettier, shfmt, sqlformat

**Icons should show:**
- ✓ for installed packages
- ✗ for uninstalled packages
- ➜ for pending installation

**What Could Go Wrong:**
- Mason doesn't open (not installed)
- Border styling not applied (UI config in lsp.lua)
- Packages not found in registry

---

## Quick Test Run (5 minutes)

```bash
# 1. Start clean
nvim --noplugin +qa!
echo "✓ Startup clean"

# 2. Open a file and run all tests
nvim ~/.config/nvim/lua/plugins/lsp.lua
```

Inside Neovim:
```vim
" Quick test sequence
:LspInfo              " Should see all 5 servers
:lua require("utils.vcs").detect_vcs_type()
:messages             " Check for deprecation warnings
:Mason                " Verify UI works
:qa!                  " Exit
```

---

## Comprehensive Test Run (10-15 minutes)

### Step 1: Validate Startup
```bash
time nvim --noplugin +qa!
```
Expected: Exits cleanly in < 2 seconds

### Step 2: Open a Lua File and Check LSP
```bash
nvim ~/.config/nvim/lua/plugins/lsp.lua
```
Inside: `:LspInfo` → Verify lua_ls is attached and shows capabilities

### Step 3: Open a Python File and Check All Servers
```bash
nvim ~/.config/nvim/init.lua  # Or any .py file
```
Inside: `:LspInfo` → Should show basedpyright, ruff, pylsp attached

### Step 4: Test Formatting
```vim
" In any file with a formatter
:lua vim.lsp.buf.format()
:messages
```
Check no errors, formatting applied correctly

### Step 5: Test VCS Detection in Different Repos
```bash
# Test in git repo
cd /path/to/git/repo
nvim .

# Inside Neovim:
:lua print(require("utils.vcs").detect_vcs_type())
```

### Step 6: Check Messages Log
```vim
:messages
```
Should be clean - no deprecation warnings

---

## Potential Issues & Fixes

### Issue: Some Servers Not Starting
**Symptom:** `:LspInfo` shows fewer than 5 servers, or servers show errors

**Cause:** Server binaries not installed in Mason

**Fix:**
```vim
:Mason
" Search for and install each missing server
```

---

### Issue: vim.uv Not Found Error
**Symptom:** Error on startup: `attempt to call field 'fs_stat' (a nil value)`

**Cause:** Neovim < 0.10 doesn't have vim.uv

**Fix:** Upgrade Neovim to 0.11+
```bash
nvim --version  # Should show v0.11.0 or later
```

---

### Issue: Deprecation Warning: vim.loop Detected
**Symptom:** Message showing `vim.loop.fs_stat` or `vim.loop.hrtime`

**Cause:** ST-B or ST-C changes not applied correctly

**Fix:** Verify changes:
```bash
grep -n "vim.uv.fs_stat" ~/.config/nvim/lua/plugins/init.lua
grep -n "vim.uv.hrtime" ~/.config/nvim/lua/utils/vcs.lua
```

Both should return results. If not, reapply the changes.

---

### Issue: Formatting Fails or Doesn't Run
**Symptom:** `:lua vim.lsp.buf.format()` fails silently or shows error

**Cause:** `automatic_installation = false` and tools not installed, OR none-ls not properly configured

**Fix:**
```vim
:Mason           " Install stylua, ruff, prettier
:lua require("null-ls").setup()  " Force reload
```

Then try formatting again.

---

### Issue: :Mason Shows Different Border or Icons
**Symptom:** Mason UI looks different than expected

**Cause:** ST-A changes to Mason setup in lsp.lua not applied

**Fix:** Verify lsp.lua has:
```lua
require("mason").setup({
  ui = {
    border = "rounded",
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗",
    },
  },
})
```

---

## File Verification Checklist

Use this to manually verify each change was applied:

### ST-A: lua/plugins/lsp.lua
```bash
# Should exist: vim.lsp.config[] pattern
grep -c "vim.lsp.config\[" ~/.config/nvim/lua/plugins/lsp.lua

# Should NOT exist: old on_attach pattern
grep -c "on_attach = function" ~/.config/nvim/lua/plugins/lsp.lua

# Should exist: vim.lsp.enable() calls
grep -c "vim.lsp.enable" ~/.config/nvim/lua/plugins/lsp.lua

# Should exist: LspAttach autocmd
grep -c "LspAttach" ~/.config/nvim/lua/plugins/lsp.lua
```

**Expected:**
```
8    (vim.lsp.config calls for 5 servers + basedpyright + ruff + pylsp)
0    (old on_attach)
5    (vim.lsp.enable calls)
1    (LspAttach autocmd)
```

### ST-B: lua/plugins/init.lua
```bash
# Should exist: vim.uv.fs_stat
grep -c "vim.uv.fs_stat" ~/.config/nvim/lua/plugins/init.lua

# Should NOT exist: vim.loop.fs_stat
grep -c "vim.loop.fs_stat" ~/.config/nvim/lua/plugins/init.lua
```

**Expected:**
```
1    (vim.uv.fs_stat exists)
0    (vim.loop.fs_stat doesn't exist)
```

### ST-C: lua/utils/vcs.lua
```bash
# Should exist: vim.uv.hrtime
grep -c "vim.uv.hrtime" ~/.config/nvim/lua/utils/vcs.lua

# Should NOT exist: vim.loop.hrtime
grep -c "vim.loop.hrtime" ~/.config/nvim/lua/utils/vcs.lua
```

**Expected:**
```
1    (vim.uv.hrtime exists)
0    (vim.loop.hrtime doesn't exist)
```

### ST-D: lua/plugins/none-ls.lua
```bash
# Should NOT have automatic_installation in mason-null-ls.setup
grep -A5 "mason-null-ls" ~/.config/nvim/lua/plugins/none-ls.lua | grep -c "automatic_installation"

# Should have handlers block but no automatic_installation
grep -c "handlers = {" ~/.config/nvim/lua/plugins/none-ls.lua
```

**Expected:**
```
0    (automatic_installation not found)
1    (handlers block exists)
```

---

## Test Result Summary Template

Copy and fill this out after running tests:

```
## Integration Test Results - [DATE]

### Startup Test
- [ ] nvim --noplugin +qa! exits cleanly

### Messages Check
- [ ] No vim.loop deprecation warnings
- [ ] No vim.lsp.handlers warnings
- [ ] No automatic_installation warnings

### LspInfo Test
- [ ] basedpyright shows
- [ ] ruff shows
- [ ] pylsp shows
- [ ] lua_ls shows
- [ ] bashls shows
- [ ] All marked as autostart: true

### VCS Detection Test
- [ ] detect_vcs_type() works in git repo
- [ ] detect_vcs_type() works in jj repo
- [ ] Cache timestamps are valid
- [ ] No vim.loop.hrtime errors

### Formatting Test
- [ ] Python formatting applies (ruff)
- [ ] Lua formatting applies (stylua)
- [ ] No error messages in :messages

### Mason UI Test
- [ ] :Mason opens successfully
- [ ] Border is rounded
- [ ] Icons display correctly (✓, ✗, ➜)
- [ ] All servers listed

### File Verification
- [ ] ST-A: vim.lsp.config pattern found (5 servers)
- [ ] ST-A: vim.lsp.enable calls found (5)
- [ ] ST-A: LspAttach autocmd found
- [ ] ST-B: vim.uv.fs_stat found
- [ ] ST-B: vim.loop.fs_stat not found
- [ ] ST-C: vim.uv.hrtime found
- [ ] ST-C: vim.loop.hrtime not found
- [ ] ST-D: automatic_installation not present
- [ ] ST-D: handlers block present

### Summary
- [ ] All tests passed
- [ ] No deprecation warnings
- [ ] All 5 servers running
- [ ] Formatting works
- [ ] VCS detection works
```

---

## Next Steps if All Tests Pass

1. **Commit the changes:**
   ```bash
   git add lua/plugins/lsp.lua lua/plugins/init.lua lua/utils/vcs.lua lua/plugins/none-ls.lua
   git commit -m "Migrate to Neovim 0.11+ APIs: vim.lsp.config/enable, vim.uv, remove automatic_installation"
   ```

2. **Update documentation** - Mark Neovim 0.11+ as minimum version requirement

3. **Monitor** - Watch lsp.log and :messages for any new warnings over next few days

---

## Support

If any test fails:

1. Check the "What Could Go Wrong" section for that test
2. Run file verification grep commands
3. Check Neovim version: `:lua print(vim.version())`
4. Check for plugin conflicts: `nvim --noplugin` startup test
5. Review changes in the original commit

---

## References

- [Neovim 0.11 Breaking Changes](https://neovim.io/doc/user/news.html)
- [vim.lsp.config Documentation](https://neovim.io/doc/user/lsp.html)
- [vim.uv API](https://neovim.io/doc/user/lua.html#vim.uv)
- [vim.loop Deprecation](https://neovim.io/doc/user/deprecated.html)
