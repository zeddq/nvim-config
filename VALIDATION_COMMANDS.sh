#!/bin/bash
# Integration Test Commands - Copy and paste these to validate changes

# =============================================================================
# INTEGRATION TEST: Neovim 0.11+ Compatibility Changes
# =============================================================================
# This script contains all commands needed to validate the 4 subtask changes
# Run each section and verify the expected output

# =============================================================================
# SETUP
# =============================================================================

echo "=== Integration Test Setup ==="
echo "Current directory: $(pwd)"
echo "Neovim version:"
nvim --version | head -1
echo ""

# =============================================================================
# TEST 1: CLEAN STARTUP (Expected: exits immediately)
# =============================================================================

echo "=== TEST 1: Clean Startup ==="
echo "Running: nvim --noplugin +qa!"
time nvim --noplugin +qa!
if [ $? -eq 0 ]; then
    echo "✓ PASS: Startup successful"
else
    echo "✗ FAIL: Startup failed"
fi
echo ""

# =============================================================================
# TEST 2: FILE VERIFICATION (Expected: files modified correctly)
# =============================================================================

echo "=== TEST 2: File Verification ==="
echo ""

echo "ST-A: Checking lua/plugins/lsp.lua for vim.lsp.config pattern..."
grep -c "vim.lsp.config\[" lua/plugins/lsp.lua
echo "Expected: 5 (for basedpyright, ruff, pylsp, lua_ls, bashls)"
echo ""

echo "ST-A: Checking for vim.lsp.enable() calls..."
grep -c "vim.lsp.enable" lua/plugins/lsp.lua
echo "Expected: 5"
echo ""

echo "ST-A: Checking for LspAttach autocmd..."
grep -c "LspAttach" lua/plugins/lsp.lua
echo "Expected: 1"
echo ""

echo "ST-B: Checking for vim.uv.fs_stat..."
grep -n "vim.uv.fs_stat" lua/plugins/init.lua
echo "Expected: One line with vim.uv.fs_stat"
echo ""

echo "ST-B: Checking vim.loop.fs_stat is NOT present..."
grep -c "vim.loop.fs_stat" lua/plugins/init.lua
echo "Expected: 0 (not found)"
echo ""

echo "ST-C: Checking for vim.uv.hrtime..."
grep -n "vim.uv.hrtime" lua/utils/vcs.lua
echo "Expected: One line with vim.uv.hrtime"
echo ""

echo "ST-C: Checking vim.loop.hrtime is NOT present..."
grep -c "vim.loop.hrtime" lua/utils/vcs.lua
echo "Expected: 0 (not found)"
echo ""

echo "ST-D: Checking automatic_installation is NOT present..."
grep "automatic_installation" lua/plugins/none-ls.lua
echo "Expected: No output (not found)"
echo ""

# =============================================================================
# TEST 3: INTERACTIVE TESTS (Must be done in Neovim)
# =============================================================================

cat << 'EOF'
=== TEST 3: Interactive Tests (Run inside Neovim) ===

These tests must be run inside Neovim. Copy the nvim command below:

1. OPEN NEOVIM AND CHECK LSP:
   nvim lua/plugins/lsp.lua

   Inside Neovim, run:
   :LspInfo

   Expected: All 5 servers listed
   - basedpyright
   - ruff
   - pylsp
   - lua_ls
   - bashls

2. CHECK MESSAGES FOR DEPRECATION WARNINGS:
   Inside Neovim:
   :messages

   Expected: No warnings about vim.loop, vim.lsp.handlers, or on_attach

3. TEST MASON UI:
   Inside Neovim:
   :Mason

   Expected:
   - Window opens with rounded border
   - Shows icons: ✓ (installed), ✗ (not installed), ➜ (pending)

4. TEST VCS DETECTION (requires a git/jj repo):
   Inside Neovim:
   :lua print(require("utils.vcs").detect_vcs_type())

   Expected: "git" or "jj" (depending on repo type)

5. TEST FORMATTING:
   Inside Neovim:
   :lua vim.lsp.buf.format()
   :messages

   Expected: No error messages, formatting applies

EOF

# =============================================================================
# TEST 4: MASON TOOL VERIFICATION
# =============================================================================

echo ""
echo "=== TEST 4: Mason Tools Check ==="
echo "Opening Mason to verify formatters are available..."
echo ""
echo "Run this inside Neovim:"
echo "  nvim lua/plugins/lsp.lua +Mason"
echo ""
echo "Expected tools to be installed:"
echo "  - stylua (Lua formatter)"
echo "  - ruff (Python linter/formatter)"
echo "  - prettier (JavaScript/JSON/Markdown)"
echo "  - shfmt (Shell script formatter)"
echo ""

# =============================================================================
# TEST 5: VCS DETECTION IN GIT REPO
# =============================================================================

cat << 'EOF'

=== TEST 5: VCS Detection in Git Repository ===

To test VCS detection in a real git repository:

1. Navigate to a git repository:
   cd /path/to/git/repo

2. Open Neovim:
   nvim .

3. Run VCS detection test:
   :lua print(require("utils.vcs").detect_vcs_type())

   Expected: "git"

4. Enable debug output to see cache operations:
   :lua require("utils.vcs").debug = true
   :lua print(require("utils.vcs").detect_vcs_type())
   :messages

   Expected: Debug output showing cache hit/miss and timing info

EOF

# =============================================================================
# TEST 6: DEPRECATION WARNING DETECTION
# =============================================================================

echo ""
echo "=== TEST 6: Searching for Deprecation Patterns ==="
echo ""

echo "Searching for vim.loop references (should be 0):"
grep -r "vim\.loop" lua/ --include="*.lua" 2>/dev/null | grep -v "vim\.loop\|vim\.uv" | wc -l
echo "Expected: 0"
echo ""

echo "Searching for old on_attach patterns (should be 0):"
grep -r "on_attach = function" lua/plugins/ --include="*.lua" 2>/dev/null | wc -l
echo "Expected: 0 (not using old pattern)"
echo ""

echo "Searching for vim.lsp.handlers (should be 0):"
grep -r "vim\.lsp\.handlers" lua/ --include="*.lua" 2>/dev/null | wc -l
echo "Expected: 0 (not using old pattern)"
echo ""

# =============================================================================
# SUMMARY
# =============================================================================

cat << 'EOF'

=== SUMMARY ===

To complete the integration test:

1. ✓ Run file verification above (automated)
2. ✓ Run clean startup test above (automated)
3. ⊕ Run interactive tests in Neovim (manual):
   - :LspInfo              (check all 5 servers)
   - :messages             (check for warnings)
   - :Mason                (check UI)
   - VCS detection test    (check git/jj detection)
   - Formatting test       (check :lua vim.lsp.buf.format())

If all tests pass:
- All 4 subtask changes are working together
- No deprecation warnings
- All servers properly configured
- VCS detection functional
- Formatting pipeline operational

If any test fails:
1. Check the specific test section above
2. Review "What Could Go Wrong" section in INTEGRATION_TEST_GUIDE.md
3. Verify Neovim version is 0.11+
4. Check :messages for error details

EOF

echo ""
echo "=== Integration Test Commands Complete ==="
echo "See INTEGRATION_TEST_GUIDE.md for detailed explanations"
echo ""
