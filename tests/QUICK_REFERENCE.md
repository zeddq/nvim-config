# jj.nvim Quick Reference Card

**Version:** Post-Fix Verification
**Date:** 2025-11-10
**Status:** ✅ All tests passing

---

## Test Results at a Glance

```
✅ VCS Detection:      10/10 tests passing
✅ Plugin Loading:     10/10 tests passing
✅ Command Execution:   6/6  tests passing
✅ Integration:        12/12 tests passing
───────────────────────────────────────────
✅ Total:              38/38 tests passing
```

---

## Run Tests

### Quick Test
```bash
cd ~/.config/nvim/tests
./run_all_tests.sh
```

### Individual Tests
```bash
# VCS detection
nvim --headless --noplugin -u ../init.lua -l test_vcs_detection.lua

# Plugin loading
nvim --headless -u ../init.lua -l test_plugin_loading.lua

# Commands
nvim --headless -u ../init.lua -l test_commands.lua

# Integration
nvim --headless -u ../init.lua -l test_integration.lua
```

---

## Fixed Bugs

| Bug | Fix | Status |
|-----|-----|--------|
| VCS detection priority | `.jj` checked first | ✅ Verified |
| Keymap execution | Proper command format | ✅ Verified |
| Command registration | Correct function calls | ✅ Verified |
| Module loading | Fixed require paths | ✅ Verified |

---

## Commands to Test Manually

Open Neovim in a jj repository and try:

```vim
" Core commands
:J status
:JJStatus
:J log
:J describe

" With leader key (default: space)
<leader>gs  " Status
<leader>gl  " Log
<leader>gd  " Diff
<leader>gn  " New change

" Utilities
<leader>gR  " Clear VCS cache
<leader>g?  " Show VCS info
```

---

## Quick Health Check

```bash
# In your nvim config directory
cd ~/.config/nvim

# Check VCS detection
nvim --headless -u init.lua -c 'lua print(require("utils.vcs").detect_vcs_type())' -c 'qall'

# Check jj CLI
which jj

# Check commands registered
nvim --headless -u init.lua -c 'echo ":J command exists: " . exists(":J")' -c 'qall'
```

---

## Expected Behavior

### In jj Repository
- `<leader>gs` → Opens jj status in buffer
- `:J status` → Same as above
- VCS detection → Returns "jj"

### In git Repository
- `<leader>gs` → Opens git status in terminal
- `:J status` → Fails gracefully with error
- VCS detection → Returns "git"

### In Colocated Repository (jj + git)
- VCS detection → Returns "jj" (correct priority!)
- All jj commands work
- Git backend used by jj

---

## Documentation

- **Full Report:** `tests/TEST_REPORT.md`
- **Verification Summary:** `tests/VERIFICATION_SUMMARY.md`
- **Test Guide:** `tests/README.md`
- **This Card:** `tests/QUICK_REFERENCE.md`

---

## Troubleshooting

### Tests fail
```bash
# Make sure you're in a jj repo
jj status

# Reinstall plugins
nvim +Lazy sync +qall

# Check jj CLI
which jj
jj --version
```

### Commands don't work
```bash
# Check if module loaded
nvim -c 'lua print(pcall(require, "jj"))' -c 'qall'

# Check VCS detection
nvim -c 'lua print(require("utils.vcs").detect_vcs_type())' -c 'qall'

# Enable debug mode
nvim -c 'lua require("utils.vcs").debug = true' -c 'wq'
```

---

## Files Modified

**Configuration:**
- `lua/utils/vcs.lua` - VCS detection
- `lua/plugins/jj.lua` - jj.nvim setup
- `lua/plugins/vcs-keymaps.lua` - Context-aware keymaps

**Tests:**
- `tests/test_vcs_detection.lua`
- `tests/test_plugin_loading.lua`
- `tests/test_commands.lua`
- `tests/test_integration.lua`

---

## Next Steps

1. ✅ Run automated tests: `./run_all_tests.sh`
2. ⚠️ Complete manual tests (10 tests, ~5 minutes)
3. ✅ Use jj.nvim with confidence!

---

**Questions?** Check `tests/README.md` or `tests/TEST_REPORT.md`
