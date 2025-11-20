# Validation Test Suite - Complete Guide

## Overview

This test suite validates that all 4 subtask changes work together correctly in your Neovim 0.11+ configuration.

### Changes Being Validated

1. **ST-A**: `lua/plugins/lsp.lua` - Refactored to use `vim.lsp.config` + `vim.lsp.enable` (Neovim 0.11+ API)
2. **ST-B**: `lua/plugins/init.lua` - Changed `vim.loop.fs_stat` → `vim.uv.fs_stat`
3. **ST-C**: `lua/utils/vcs.lua` - Changed `vim.loop.hrtime` → `vim.uv.hrtime`
4. **ST-D**: `lua/plugins/none-ls.lua` - Removed `automatic_installation` configuration

---

## Quick Start (5 Minutes)

**Choose your experience level:**

### I'm in a hurry
→ Read: `/Users/cezary/.config/nvim/QUICK_VALIDATION.md` (5 min)

```bash
# One command to verify everything
bash /Users/cezary/.config/nvim/VALIDATION_COMMANDS.sh
```

### I want detailed explanations
→ Read: `/Users/cezary/.config/nvim/INTEGRATION_TEST_GUIDE.md` (15 min)

### I need a reference matrix
→ Read: `/Users/cezary/.config/nvim/TEST_MATRIX.md` (5 min)

---

## Files Included

| File | Purpose | Time | For Whom |
|------|---------|------|----------|
| **QUICK_VALIDATION.md** | 5-minute checklist | 5 min | Everyone starting here |
| **INTEGRATION_TEST_GUIDE.md** | Comprehensive test guide | 15 min | Those who want details |
| **VALIDATION_COMMANDS.sh** | Executable test script | 10 min | Terminal-based validation |
| **TEST_MATRIX.md** | Reference matrix & decision tree | 5 min | Quick lookup |
| **VALIDATION_README.md** | This file (orientation) | 3 min | Getting oriented |

---

## Test Summary

### 6 Tests Across All Changes

```
┌──────────────────────────────────────┬──────────┬──────────┐
│ Test                                 │ Duration │ Type     │
├──────────────────────────────────────┼──────────┼──────────┤
│ 1. Clean Startup                     │ 30 sec   │ Auto     │
│ 2. No Deprecation Warnings           │ 30 sec   │ Auto     │
│ 3. LSP Servers Running (:LspInfo)    │ 1 min    │ Manual   │
│ 4. VCS Detection Works               │ 1 min    │ Manual   │
│ 5. Formatting Functional             │ 1 min    │ Manual   │
│ 6. Mason UI Displays Correctly       │ 30 sec   │ Manual   │
└──────────────────────────────────────┴──────────┴──────────┘

Total Time: 7-10 minutes
```

---

## How to Run Tests

### Method 1: Quick Command Sequence (Fastest)

```bash
# In terminal:
cd ~/.config/nvim

# Run automated checks
bash VALIDATION_COMMANDS.sh

# Then manually run in Neovim:
nvim lua/plugins/lsp.lua +LspInfo
# Inside: :messages, :Mason, etc.
```

### Method 2: Follow Checklist (Most Thorough)

```bash
# Read the checklist first
cat QUICK_VALIDATION.md

# Then execute each test manually
nvim lua/plugins/lsp.lua
# Inside: :LspInfo, :messages, :Mason, etc.
```

### Method 3: Reference Guide (Most Detail)

```bash
# Read detailed explanations
cat INTEGRATION_TEST_GUIDE.md

# Run specific tests you care about
```

---

## Expected Results

### Clean Startup
```bash
nvim --noplugin +qa!
# ✓ Should exit immediately with exit code 0
```

### LSP Servers (from :LspInfo)
```vim
:LspInfo
# ✓ Should show exactly 5 servers:
#   - basedpyright
#   - ruff
#   - pylsp
#   - lua_ls
#   - bashls
# ✓ All marked as autostart: true
```

### Messages Log
```vim
:messages
# ✓ Should be clean - no deprecation warnings
# ✗ Should NOT contain:
#   - vim.loop (deprecated)
#   - on_attach deprecation notices
#   - vim.lsp.handlers warnings
```

### VCS Detection
```lua
:lua print(require("utils.vcs").detect_vcs_type())
# ✓ Should return "git" or "jj"
# ✗ Should NOT return "none" (unless not in a repo)
```

### Formatting
```vim
:lua vim.lsp.buf.format()
:messages
# ✓ Should apply formatting without errors
# ✗ Should NOT show error messages
```

### Mason UI
```vim
:Mason
# ✓ Window opens with rounded border
# ✓ Icons display correctly (✓, ✗, ➜)
# ✗ Should NOT fail to open
```

---

## Troubleshooting Quick Links

### Problem: vim.uv Not Found
**Solution:** Upgrade Neovim to 0.11+
```bash
nvim --version  # Should show v0.11.0+
brew upgrade neovim  # macOS
```

### Problem: Some LSP Servers Missing
**Solution:** Install via Mason
```vim
:Mason
# Search for and install each missing server
```

### Problem: Deprecation Warnings
**Solution:** Verify changes were applied
```bash
# Check ST-B and ST-C changes
grep "vim.uv.fs_stat" lua/plugins/init.lua
grep "vim.uv.hrtime" lua/utils/vcs.lua
```

### Problem: Formatting Fails
**Solution:** Install formatters
```vim
:Mason
# Install: stylua, ruff, prettier
```

### Problem: :Mason Doesn't Open
**Solution:** Reload LSP config
```vim
:e lua/plugins/lsp.lua
:source %
:Mason
```

---

## File Verification Reference

Quick grep commands to verify each subtask change:

### ST-A: lsp.lua Changes
```bash
# Should exist: vim.lsp.config pattern (5 servers)
grep -c "vim.lsp.config\[" lua/plugins/lsp.lua
# Expected: 5

# Should exist: vim.lsp.enable calls
grep -c "vim.lsp.enable" lua/plugins/lsp.lua
# Expected: 5

# Should exist: LspAttach autocmd
grep -c "LspAttach" lua/plugins/lsp.lua
# Expected: 1
```

### ST-B: init.lua Changes
```bash
# Should exist: vim.uv.fs_stat
grep -c "vim.uv.fs_stat" lua/plugins/init.lua
# Expected: 1

# Should NOT exist: vim.loop.fs_stat
grep -c "vim.loop.fs_stat" lua/plugins/init.lua
# Expected: 0
```

### ST-C: vcs.lua Changes
```bash
# Should exist: vim.uv.hrtime
grep -c "vim.uv.hrtime" lua/utils/vcs.lua
# Expected: 1

# Should NOT exist: vim.loop.hrtime
grep -c "vim.loop.hrtime" lua/utils/vcs.lua
# Expected: 0
```

### ST-D: none-ls.lua Changes
```bash
# Should NOT exist: automatic_installation
grep -c "automatic_installation" lua/plugins/none-ls.lua
# Expected: 0
```

---

## Documentation Structure

```
VALIDATION_README.md (this file)
│
├─→ START HERE (5 min)
│   └─→ QUICK_VALIDATION.md
│       └─→ Run 6 quick tests
│
├─→ WANT MORE DETAIL? (15 min)
│   └─→ INTEGRATION_TEST_GUIDE.md
│       ├─→ Detailed test explanations
│       ├─→ Expected outputs
│       ├─→ Troubleshooting guide
│       └─→ File verification
│
├─→ NEED A REFERENCE? (5 min)
│   └─→ TEST_MATRIX.md
│       ├─→ Test coverage matrix
│       ├─→ Decision tree
│       └─→ Command reference
│
└─→ PREFER TERMINAL? (10 min)
    └─→ VALIDATION_COMMANDS.sh
        └─→ Execute all tests
```

---

## Success Criteria

All tests pass when:

- [ ] Clean startup works (nvim --noplugin +qa!)
- [ ] No deprecation warnings in :messages
- [ ] :LspInfo shows all 5 servers with autostart: true
- [ ] VCS detection returns "git" or "jj"
- [ ] Formatting works without errors
- [ ] Mason UI opens with correct border and icons
- [ ] All file verification grep commands return expected results

---

## After Testing

### If All Tests Pass
1. Your configuration is fully compatible with Neovim 0.11+
2. All 4 subtasks are working together correctly
3. No further action needed - use Neovim normally

### If Any Test Fails
1. Check the specific test section in INTEGRATION_TEST_GUIDE.md
2. Run the corresponding file verification grep command
3. Review the "What Could Go Wrong" section for that test
4. Check Neovim version requirement (must be 0.11+)
5. Look at :messages and lsp.log for error details

---

## Getting Help

For each test, these documents have detailed sections:

| Test | QUICK_VALIDATION | INTEGRATION_TEST | TEST_MATRIX |
|------|------------------|-----------------|------------|
| Startup | 30 sec | ✓ | ✓ |
| Messages | 1 min | ✓ | ✓ |
| LSP Servers | 1 min | ✓ | ✓ |
| VCS Detection | 1 min | ✓ | ✓ |
| Formatting | 1 min | ✓ | ✓ |
| Mason | 30 sec | ✓ | ✓ |

---

## Key Points to Remember

1. **Neovim 0.11+** is required - older versions don't have vim.uv or vim.lsp.config
2. **All 5 servers** must appear in :LspInfo for full functionality
3. **No vim.loop** references should appear anywhere - all changed to vim.uv
4. **Mason tools** must be installed separately - run :Mason to install
5. **Formatting** requires both LSP servers AND formatter tools (stylua, ruff, prettier)

---

## File Locations

```
~/.config/nvim/
├── lua/
│   ├── plugins/
│   │   ├── lsp.lua (ST-A)
│   │   ├── init.lua (ST-B)
│   │   └── none-ls.lua (ST-D)
│   └── utils/
│       └── vcs.lua (ST-C)
│
└── Test Documentation (NEW)
    ├── VALIDATION_README.md ← You are here
    ├── QUICK_VALIDATION.md
    ├── INTEGRATION_TEST_GUIDE.md
    ├── TEST_MATRIX.md
    └── VALIDATION_COMMANDS.sh
```

---

## Next Steps

**Ready to validate?**

1. Start with QUICK_VALIDATION.md (5 minutes)
2. Run the tests in order
3. Check results against expected outputs
4. Use INTEGRATION_TEST_GUIDE.md if any test fails

**Questions about specific tests?**

- Check TEST_MATRIX.md for quick reference
- Check INTEGRATION_TEST_GUIDE.md for detailed explanation
- Run VALIDATION_COMMANDS.sh for automated verification

---

## Version Info

- **Test Suite Version:** 1.0
- **Created:** February 2, 2026
- **For:** Neovim 0.11+ configuration
- **Status:** Ready for use

---

## Summary

You have 4 comprehensive documents to validate the integration of all 4 subtask changes:

1. **QUICK_VALIDATION.md** - Start here, 5 minutes
2. **VALIDATION_COMMANDS.sh** - Run this for automated tests
3. **INTEGRATION_TEST_GUIDE.md** - Detailed explanations
4. **TEST_MATRIX.md** - Reference and decision tree

**Choose your path and validate your changes!**
