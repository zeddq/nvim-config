# Integration Test Suite - Master Index

**Status:** COMPLETE & READY TO USE

**Location:** `/Users/cezary/.config/nvim/`

**Created:** February 2, 2026

---

## Quick Navigation

### For the Impatient (5 minutes)
1. Read: `QUICK_VALIDATION.md`
2. Run 6 tests in Neovim
3. Done

### For Details (15 minutes)
1. Read: `INTEGRATION_TEST_GUIDE.md`
2. Run: `bash VALIDATION_COMMANDS.sh`

### For Reference (Quick lookup)
1. Check: `TEST_MATRIX.md`
2. Find: Decision trees and command reference

### For Complete Understanding (25 minutes)
1. Read: `VALIDATION_README.md`
2. Read: `INTEGRATION_TEST_GUIDE.md`
3. Run: `bash VALIDATION_COMMANDS.sh`

---

## All Documents

### Entry Point
- **VALIDATION_START_HERE.txt** - Visual guide for choosing your path

### Test Guides
- **QUICK_VALIDATION.md** - 5-minute checklist (FASTEST)
- **INTEGRATION_TEST_GUIDE.md** - Detailed explanations (MOST COMPLETE)
- **VALIDATION_README.md** - Overview and orientation

### References
- **TEST_MATRIX.md** - Matrices, decision trees, command reference
- **VALIDATION_COMMANDS.sh** - Executable test script

### This File
- **INDEX.md** - Master index (you are here)

---

## What Gets Tested

### 4 Subtask Changes
1. ST-A: `lua/plugins/lsp.lua` - vim.lsp.config + vim.lsp.enable
2. ST-B: `lua/plugins/init.lua` - vim.loop.fs_stat → vim.uv.fs_stat
3. ST-C: `lua/utils/vcs.lua` - vim.loop.hrtime → vim.uv.hrtime
4. ST-D: `lua/plugins/none-ls.lua` - Removed automatic_installation

### 6 Integration Tests
1. Clean Startup (30 sec)
2. No Deprecation Warnings (30 sec)
3. LSP Servers Running (1 min)
4. VCS Detection (1 min)
5. Formatting Works (1 min)
6. Mason UI (30 sec)

---

## Expected Results

Pass Criteria:
- ✓ Clean startup (no errors)
- ✓ 5 LSP servers in :LspInfo
- ✓ No deprecation warnings
- ✓ VCS detection returns "git" or "jj"
- ✓ Formatting works
- ✓ Mason UI displays correctly

---

## File Commands

```bash
# Start here
cat VALIDATION_START_HERE.txt

# Quick path (5 min)
cat QUICK_VALIDATION.md

# Detailed path (15 min)
cat INTEGRATION_TEST_GUIDE.md

# Reference path
cat TEST_MATRIX.md

# Full orientation
cat VALIDATION_README.md

# Run automated tests
bash VALIDATION_COMMANDS.sh
```

---

## Next Steps

1. Choose your time commitment (5, 15, or 25 minutes)
2. Read the appropriate document(s)
3. Run the tests
4. Verify all pass
5. Use Neovim normally

---

**Start with:** VALIDATION_START_HERE.txt or QUICK_VALIDATION.md
