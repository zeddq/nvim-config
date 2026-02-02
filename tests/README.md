# jj.nvim Integration Test Suite

Comprehensive automated tests for verifying jj.nvim integration functionality.

## Quick Start

Run all tests:

```bash
cd /Users/cezary/.config/nvim/tests
./run_all_tests.sh
```

Run individual test:

```bash
./run_single_test.sh test_vcs_detection.lua
```

## Test Suites

### 1. VCS Detection Tests (`test_vcs_detection.lua`)

Tests the `utils.vcs` module for correct VCS type detection.

**What it tests:**

- VCS type detection (jj, git, none)
- Cache functionality (hit/miss, TTL, invalidation)
- Repository root finding
- Helper functions (`is_jj_repo`, `is_git_repo`)
- Error handling for invalid paths

**Run:**

```bash
nvim --headless --noplugin -u ../init.lua -l test_vcs_detection.lua
```

**Expected result:** 10/10 tests passing

---

### 2. Plugin Loading Tests (`test_plugin_loading.lua`)

Tests that jj.nvim and related plugins load correctly.

**What it tests:**

- Module loading (`jj`, `jj.cmd`, `jj.utils`)
- Command registration (`:J`, `:JJStatus`, etc.)
- Lazy.nvim integration
- Configuration correctness
- jj CLI availability

**Run:**

```bash
nvim --headless -u ../init.lua -l test_plugin_loading.lua
```

**Expected result:** 10/10 tests passing (1 warning for keymaps in headless mode)

---

### 3. Command Execution Tests (`test_commands.lua`)

Tests that commands execute correctly.

**What it tests:**

- Command callability
- Direct jj CLI execution
- VCS command routing
- Error handling outside jj repos
- Helper function availability

**Run:**

```bash
nvim --headless -u ../init.lua -l test_commands.lua
```

**Expected result:** 6/6 automated tests passing, 10 manual tests listed

---

### 4. Integration Tests (`test_integration.lua`)

Tests end-to-end integration between components.

**What it tests:**

- VCS detection ↔ jj.nvim integration
- Command routing based on VCS type
- Cache management and autocmds
- Multiple operation sequences
- Error handling across components
- Overall health check

**Run:**

```bash
nvim --headless -u ../init.lua -l test_integration.lua
```

**Expected result:** 12/12 tests passing (2 non-critical warnings)

---

## Test Results

See `TEST_REPORT.md` for comprehensive test results and analysis.

**Latest Results:**

- Total Tests: 38 automated
- Passed: 38 (100%)
- Failed: 0
- Warnings: 4 (non-critical)

---

## Manual Testing Checklist

Some tests require interactive Neovim session. Complete these manually:

### Commands

- [ ] `:J status` - Status appears in buffer
- [ ] `:JJStatus` - Same as `:J status`
- [ ] `:J log` - Log appears with graph
- [ ] `:J describe` - Editor opens for description

### Keymaps

- [ ] `<leader>gs` - Status appears
- [ ] `<leader>gl` - Log appears
- [ ] `<leader>gd` - Diff appears
- [ ] `<leader>gn` - Creates new change

### Utilities

- [ ] `<leader>gR` - Shows "Cache cleared" notification
- [ ] `<leader>g?` - Shows VCS info notification

---

## Test Environment

**Requirements:**

- Neovim 0.9+
- jj CLI installed (`jj --version`)
- Full nvim config loaded
- In a jj repository (for jj-specific tests)

**Test Directory Structure:**

```
tests/
├── README.md                 # This file
├── TEST_REPORT.md            # Comprehensive test report
├── run_all_tests.sh          # Run all test suites
├── run_single_test.sh        # Run individual test
├── test_vcs_detection.lua    # VCS detection tests
├── test_plugin_loading.lua   # Plugin loading tests
├── test_commands.lua         # Command execution tests
└── test_integration.lua      # Integration tests
```

---

## Troubleshooting

### Tests fail in headless mode

Some tests (especially keymaps) may fail in headless mode. This is expected behavior. Run manual tests in interactive Neovim.

### "jj CLI not found" warning

Install jj CLI:

```bash
brew install jj  # macOS
```

### "Not in jj repo" warnings

Some tests require being in a jj repository. Navigate to a jj repo:

```bash
cd /path/to/jj/repo
nvim --headless -u /Users/cezary/.config/nvim/init.lua -l test_commands.lua
```

### Module loading failures

Ensure lazy.nvim has installed all plugins:

```bash
nvim +Lazy sync +qall
```

---

## Adding New Tests

Create a new test file following this template:

```lua
-- Test Suite: Your Test Name
local results = { passed = 0, failed = 0, tests = {} }

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    results.passed = results.passed + 1
    print(string.format("✓ %s", name))
  else
    results.failed = results.failed + 1
    print(string.format("✗ %s: %s", name, err))
  end
end

-- Your tests here
test("Test name", function()
  -- Test logic
end)

-- Summary
print(string.format("\nPassed: %d, Failed: %d", results.passed, results.failed))
vim.cmd(results.failed > 0 and "cquit 1" or "qall!")
```

---

## CI/CD Integration

To integrate with CI/CD pipelines:

```bash
# Run tests and capture exit code
./run_all_tests.sh
EXIT_CODE=$?

# Tests pass if exit code is 0
if [ $EXIT_CODE -eq 0 ]; then
  echo "All tests passed"
else
  echo "Tests failed"
  exit 1
fi
```

---

## Related Documentation

- **Baseline Document:** `../docs/JJ_INTEGRATION_BASELINE.md`
- **Bug Fix Report:** `../docs/JJNVIM_RUNTIME_FIX_REPORT.md`
- **Configuration Files:**
  - `../lua/utils/vcs.lua`
  - `../lua/plugins/jj.lua`
  - `../lua/plugins/vcs-keymaps.lua`

---

**Last Updated:** 2025-11-10
**Maintainer:** Claude Code Testing Specialist
