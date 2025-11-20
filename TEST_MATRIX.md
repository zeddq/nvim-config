# Integration Test Matrix

## Change Validation Matrix

This matrix shows which tests validate which subtask changes.

```
┌─────────────────────────────┬─────┬─────┬─────┬─────┐
│ Test                        │ ST-A│ ST-B│ ST-C│ ST-D│
├─────────────────────────────┼─────┼─────┼─────┼─────┤
│ Clean Startup               │  ✓  │  ✓  │  ✓  │  ✓  │
│ No Deprecation Warnings     │  ✓  │  ✓  │  ✓  │  ✓  │
│ :LspInfo (5 servers)        │  ✓  │     │     │     │
│ VCS Detection               │     │     │  ✓  │     │
│ Formatting Works            │  ✓  │     │     │  ✓  │
│ Mason UI Works              │  ✓  │     │     │     │
│ File Verification (grep)    │  ✓  │  ✓  │  ✓  │  ✓  │
└─────────────────────────────┴─────┴─────┴─────┴─────┘

Legend:
✓ = Test validates this subtask
  = Test doesn't directly validate this subtask
```

---

## Subtask Dependency Chain

```
ST-B (vim.uv in init.lua)
    ↓
    └─→ Startup works
    └─→ No vim.loop errors

ST-C (vim.uv in vcs.lua)
    ↓
    └─→ VCS detection works
    └─→ No vim.loop.hrtime errors

ST-A (vim.lsp.config in lsp.lua)
    ↓
    ├─→ :LspInfo shows 5 servers
    ├─→ LSP attach autocmd works
    ├─→ Formatting works
    └─→ Mason UI displays correctly

ST-D (remove automatic_installation)
    ↓
    └─→ Formatting still works
    └─→ No automatic installation errors
```

---

## Expected Test Output Reference

### Test 1: Clean Startup
```bash
$ nvim --noplugin +qa!
# Expected: Exits silently in < 2 seconds
# Exit code: 0
```

### Test 2: LSP Servers (from :LspInfo)
```
Language server name: basedpyright
  filetypes:       python
  autostart:       true
  cmd:             /path/to/basedpyright

Language server name: ruff
  filetypes:       python
  autostart:       true
  cmd:             /path/to/ruff

Language server name: pylsp
  filetypes:       python
  autostart:       true
  cmd:             /path/to/pylsp

Language server name: lua_ls
  filetypes:       lua
  autostart:       true
  cmd:             /path/to/lua-language-server

Language server name: bashls
  filetypes:       sh, bash, zsh
  autostart:       true
  cmd:             /path/to/bash-language-server
```

### Test 3: Messages Check
```vim
:messages
# Expected: No lines containing:
#   - "vim.loop"
#   - "deprecated"
#   - "handlers"
#   - "on_attach"
```

### Test 4: VCS Detection
```lua
:lua print(require("utils.vcs").detect_vcs_type())
# Expected: "git" or "jj" (depending on repo)
# NOT: "none"
```

### Test 5: Formatting
```vim
:lua vim.lsp.buf.format()
:messages
# Expected: No error messages
# Code should be reformatted if formatter available
```

### Test 6: Mason UI
```vim
:Mason
# Expected:
# - Window opens with rounded border
# - Shows list of packages
# - Icons display: ✓ ✗ ➜
```

---

## Command Quick Reference

### File Verification (Copy-paste these)

**ST-A Verification:**
```bash
grep -n "vim.lsp.config\[" ~/.config/nvim/lua/plugins/lsp.lua | head -3
grep -c "vim.lsp.enable" ~/.config/nvim/lua/plugins/lsp.lua
grep -c "LspAttach" ~/.config/nvim/lua/plugins/lsp.lua
```

**ST-B Verification:**
```bash
grep -n "vim.uv.fs_stat" ~/.config/nvim/lua/plugins/init.lua
grep -c "vim.loop.fs_stat" ~/.config/nvim/lua/plugins/init.lua
```

**ST-C Verification:**
```bash
grep -n "vim.uv.hrtime" ~/.config/nvim/lua/utils/vcs.lua
grep -c "vim.loop.hrtime" ~/.config/nvim/lua/utils/vcs.lua
```

**ST-D Verification:**
```bash
grep "automatic_installation" ~/.config/nvim/lua/plugins/none-ls.lua
```

### Interactive Tests (Inside Neovim)

```vim
" Test 1: Startup
:LspInfo

" Test 2: Check warnings
:messages

" Test 3: Mason UI
:Mason

" Test 4: VCS Detection
:lua print(require("utils.vcs").detect_vcs_type())

" Test 5: Formatting
:lua vim.lsp.buf.format()
```

---

## Failure Decision Tree

```
START: Run all tests
│
├─→ Clean Startup FAILS?
│   ├─→ Check Neovim version: nvim --version
│   │   └─→ Need 0.11.0+? Upgrade Neovim
│   └─→ Check for syntax errors in modified files
│
├─→ Deprecation Warnings Found?
│   ├─→ vim.loop warnings?
│   │   └─→ ST-B or ST-C not applied, check grep results
│   └─→ on_attach warnings?
│       └─→ ST-A not applied correctly, check lsp.lua
│
├─→ LSP Servers Missing from :LspInfo?
│   └─→ Run :Mason and install missing servers
│
├─→ VCS Detection Returns "none"?
│   ├─→ Check you're in a git/jj repo
│   ├─→ Enable debug: :lua require("utils.vcs").debug = true
│   └─→ Check :messages for error details
│
├─→ Formatting Fails?
│   ├─→ Run :Mason and install formatters
│   └─→ Check :messages for error details
│
├─→ Mason UI Doesn't Open?
│   └─→ Check ST-A Mason setup in lsp.lua
│
└─→ All Tests Pass!
    └─→ Integration successful, changes working together
```

---

## Test Execution Time Estimate

| Test | Time | Type |
|------|------|------|
| Clean Startup | 2 sec | Auto |
| File Verification | 30 sec | Auto |
| LSP Servers | 1 min | Manual |
| Deprecation Check | 1 min | Manual |
| VCS Detection | 1 min | Manual |
| Formatting | 1 min | Manual |
| Mason UI | 30 sec | Manual |
| **TOTAL** | **~7 minutes** | Mixed |

---

## Test Status Tracking

Use this template to track test results:

```markdown
## Validation Run - [DATE/TIME]

### Automated Tests
- [ ] Clean startup: PASS/FAIL
- [ ] File verification: PASS/FAIL
- [ ] Deprecation search: PASS/FAIL

### Interactive Tests
- [ ] :LspInfo shows 5 servers: PASS/FAIL
- [ ] :messages clean: PASS/FAIL
- [ ] :Mason opens: PASS/FAIL
- [ ] VCS detection works: PASS/FAIL
- [ ] Formatting works: PASS/FAIL

### Overall Result
- [ ] All tests passed
- [ ] Some tests failed (specify which)

### Notes
[Add any observations, errors, or issues found]
```

---

## Related Documentation

- **QUICK_VALIDATION.md** - 5-minute quick check
- **INTEGRATION_TEST_GUIDE.md** - Detailed test descriptions
- **VALIDATION_COMMANDS.sh** - Copy-paste command script
- **TEST_MATRIX.md** - This file (reference)

---

## Version Requirements

| Component | Minimum | Tested |
|-----------|---------|--------|
| Neovim | 0.11.0 | 0.11.0+ |
| Mason | Latest | Current |
| lazy.nvim | Latest | Current |
| Lua | 5.1+ | LuaJIT |

---

## Known Issues & Workarounds

### Issue: vim.lsp.enable() Not Recognized
**Cause:** Neovim < 0.11
**Fix:** Upgrade Neovim to 0.11+

### Issue: Some Servers Don't Start
**Cause:** Binaries not in PATH
**Fix:** Use Mason to install servers

### Issue: Formatting Silent Failure
**Cause:** Formatter not installed
**Fix:** Install via Mason (:Mason)

### Issue: VCS Cache Stale
**Cause:** Cache TTL expires (5 seconds)
**Fix:** Expected behavior, cache will refresh

### Issue: :Mason Crashes
**Cause:** Old Mason version
**Fix:** Update plugins: `:PluginSync`
