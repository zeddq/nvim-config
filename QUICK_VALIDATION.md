# Quick Validation Checklist (Run This First!)

Use this 5-minute checklist to confirm all changes work together.

## Pre-Test Setup

```bash
# Ensure you're running Neovim 0.11+
nvim --version
# Should show: NVIM v0.11.0 or later

# Navigate to your Neovim config
cd ~/.config/nvim
```

---

## 🚀 Quick Test Sequence

### 1. **Clean Startup** (30 seconds)
```bash
nvim --noplugin +qa!
```
✓ **Pass if:** Exits immediately with no errors

❌ **Fail if:** Shows error messages or hangs

---

### 2. **LSP Server Verification** (1 minute)
```bash
nvim lua/plugins/lsp.lua +LspInfo
```

Inside Neovim:
- Type `:LspInfo` and press Enter
- Look for this list:
  ```
  basedpyright
  ruff
  pylsp
  lua_ls
  bashls
  ```

✓ **Pass if:** All 5 servers appear with `autostart: true`

❌ **Fail if:** Missing servers or marked `autostart: false`

---

### 3. **Deprecation Warning Check** (1 minute)
```bash
nvim lua/plugins/lsp.lua +messages
```

Inside Neovim:
- Type `:messages` and press Enter
- Scan for any mentions of:
  - `vim.loop` ← FAIL if present
  - `vim.lsp.handlers` ← FAIL if present
  - `on_attach` deprecation ← FAIL if present

✓ **Pass if:** Messages are clean (no deprecation warnings)

❌ **Fail if:** Any deprecation warnings appear

---

### 4. **Mason UI Check** (1 minute)
```bash
nvim lua/plugins/lsp.lua +Mason
```

Inside Neovim:
- Type `:Mason` and press Enter
- Verify:
  - Window has rounded border
  - Shows package manager UI
  - Display includes checkmarks (✓), X's (✗), arrows (➜)

✓ **Pass if:** UI displays with rounded borders and correct icons

❌ **Fail if:** No border, missing icons, or error opening Mason

---

### 5. **VCS Detection Test** (1 minute)
```bash
# Test in a git repo
cd /path/to/git/repo
nvim .
```

Inside Neovim:
```vim
:lua print(require("utils.vcs").detect_vcs_type())
```

✓ **Pass if:** Shows `git` or `jj` (appropriate for your repo)

❌ **Fail if:** Shows `none` or produces error

---

### 6. **Format Test** (1 minute)
```bash
nvim lua/plugins/lsp.lua
```

Inside Neovim:
```vim
:lua vim.lsp.buf.format()
:messages
```

✓ **Pass if:** No error messages, formatting applies (or shows "No formatting client")

❌ **Fail if:** Error message about formatting failure

---

## 📋 Summary

- [ ] Clean startup works
- [ ] All 5 LSP servers present
- [ ] No deprecation warnings
- [ ] Mason UI displays correctly
- [ ] VCS detection works
- [ ] Formatting doesn't error

**If all checked:** ✓ Integration successful!

**If any failed:** See "What Could Go Wrong" section below.

---

## 🔧 What Could Go Wrong (Quick Fixes)

### `vim.uv` Not Found
**Error message:** `attempt to call field 'fs_stat' (a nil value)`

**Cause:** Neovim version too old

**Fix:**
```bash
nvim --version  # Should be v0.11.0+
# If older: Update Neovim
brew upgrade neovim  # macOS
```

---

### Only 1-4 Servers Show in `:LspInfo`
**Cause:** Mason server binaries not installed

**Fix:**
```vim
:Mason
" Install missing servers interactively
```

---

### See `vim.loop` in `:messages`
**Cause:** ST-B or ST-C changes not applied

**Fix:** Verify changes exist:
```bash
grep "vim.uv.fs_stat" lua/plugins/init.lua
grep "vim.uv.hrtime" lua/utils/vcs.lua
```

Both should return a line.

---

### `:Mason` Fails or Looks Wrong
**Cause:** lsp.lua configuration didn't apply

**Fix:** Reload config:
```vim
:e ~/.config/nvim/lua/plugins/lsp.lua
:source %
:Mason
```

---

### VCS Detection Returns `none` in a Real Repo
**Cause:** `vim.uv.hrtime` issue or path detection bug

**Fix:** Enable debug mode:
```vim
:lua require("utils.vcs").debug = true
:lua print(require("utils.vcs").detect_vcs_type())
:messages
```

Check output for error details.

---

### Formatting Shows Error
**Cause:** Tools not installed in Mason

**Fix:**
```vim
:Mason
" Install: stylua, ruff, prettier
```

---

## 📄 File Verification (Run in Terminal)

These commands verify each subtask change:

```bash
# ST-A: Should have vim.lsp.config pattern
grep -n "vim.lsp.config\[" ~/.config/nvim/lua/plugins/lsp.lua | head -3
# Expected: Shows lines with vim.lsp.config["basedpyright"], vim.lsp.config["ruff"], etc.

# ST-B: Should use vim.uv.fs_stat
grep -n "vim.uv.fs_stat" ~/.config/nvim/lua/plugins/init.lua
# Expected: Shows one line with vim.uv.fs_stat

# ST-C: Should use vim.uv.hrtime
grep -n "vim.uv.hrtime" ~/.config/nvim/lua/utils/vcs.lua
# Expected: Shows one line with vim.uv.hrtime

# ST-D: Should NOT have automatic_installation
grep "automatic_installation" ~/.config/nvim/lua/plugins/none-ls.lua
# Expected: No output (not found)
```

---

## 🎯 Next Steps

**All tests passing?**
1. Run `:PluginSync` if using lazy.nvim
2. Restart Neovim fresh: `nvim`
3. Use normally - all changes integrated

**Anything failing?**
1. Check the "What Could Go Wrong" section above
2. Run full Integration Test Guide: `Integration_Test_Guide.md`
3. Check Neovim version requirement (0.11+)

---

## Need More Help?

See `/Users/cezary/.config/nvim/INTEGRATION_TEST_GUIDE.md` for:
- Detailed test explanations
- Expected output examples
- Comprehensive troubleshooting
- File verification with grep commands
