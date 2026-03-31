#!/bin/bash
# Master Test Runner for Neovim Configuration
# Runs unit tests by default. Use --integration to also run plugin integration tests.
#
# Unit tests:    Use mocks, run with --noplugin (fast, no external deps)
# Integration:   Require real plugins loaded by lazy.nvim (slower, run without --noplugin)

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
RESULTS_FILE="$SCRIPT_DIR/test_results.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse flags
RUN_INTEGRATION=false
for arg in "$@"; do
  case "$arg" in
    --integration) RUN_INTEGRATION=true ;;
    --help|-h)
      echo "Usage: $0 [--integration]"
      echo ""
      echo "  --integration   Also run plugin integration tests (requires lazy.nvim plugins)"
      echo ""
      echo "Unit tests use mocks and run with --noplugin (fast)."
      echo "Integration tests require real plugins and run without --noplugin."
      exit 0
      ;;
  esac
done

echo "========================================"
echo "   Neovim Configuration Test Suite"
echo "========================================"
echo ""
echo "Config directory: $CONFIG_DIR"
echo "Running tests in headless neovim..."
if $RUN_INTEGRATION; then
  echo -e "${YELLOW}Mode: unit + integration${NC}"
else
  echo "Mode: unit only (use --integration for full suite)"
fi
echo ""

# Initialize results file
cat > "$RESULTS_FILE" << EOF
Neovim Configuration Test Results
Generated: $(date)
Working Directory: $(pwd)
VCS Type: $(cd "$CONFIG_DIR" && if [ -d .jj ]; then echo "jj"; elif git rev-parse --is-inside-work-tree >/dev/null 2>&1; then echo "git"; else echo "unknown"; fi)
Mode: $(if $RUN_INTEGRATION; then echo "unit + integration"; else echo "unit only"; fi)

EOF

# Track overall results
TOTAL_PASSED=0
TOTAL_FAILED=0
TOTAL_SUITES=0

# Function to run a unit test suite (with --noplugin)
run_unit_test() {
    local test_file="$1"
    local test_name
    test_name=$(basename "$test_file" .lua)

    echo -e "${BLUE}Running (unit): $test_name${NC}"
    echo "----------------------------------------"

    TOTAL_SUITES=$((TOTAL_SUITES + 1))

    if nvim --headless --noplugin -u "$CONFIG_DIR/init.lua" -l "$test_file" 2>&1 | tee -a "$RESULTS_FILE"; then
        echo -e "${GREEN}✓ $test_name PASSED${NC}"
        TOTAL_PASSED=$((TOTAL_PASSED + 1))
    else
        echo -e "${RED}✗ $test_name FAILED${NC}"
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    fi

    echo ""
    echo "" >> "$RESULTS_FILE"
}

# Function to run an integration test suite (WITHOUT --noplugin)
run_integration_test() {
    local test_file="$1"
    local test_name
    test_name=$(basename "$test_file" .lua)

    echo -e "${YELLOW}Running (integration): $test_name${NC}"
    echo "----------------------------------------"

    TOTAL_SUITES=$((TOTAL_SUITES + 1))

    if nvim --headless -u "$CONFIG_DIR/init.lua" -l "$test_file" 2>&1 | tee -a "$RESULTS_FILE"; then
        echo -e "${GREEN}✓ $test_name PASSED${NC}"
        TOTAL_PASSED=$((TOTAL_PASSED + 1))
    else
        echo -e "${RED}✗ $test_name FAILED${NC}"
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    fi

    echo ""
    echo "" >> "$RESULTS_FILE"
}

# === Unit Tests (always run) ===
echo -e "${BLUE}━━━ Unit Tests ━━━${NC}"
echo ""

run_unit_test "$SCRIPT_DIR/test_vcs_detection.lua"
run_unit_test "$SCRIPT_DIR/test_plugin_loading.lua"
run_unit_test "$SCRIPT_DIR/test_commands.lua"

# === Integration Tests (only with --integration flag) ===
if $RUN_INTEGRATION; then
    echo -e "${YELLOW}━━━ Integration Tests ━━━${NC}"
    echo ""

    run_integration_test "$SCRIPT_DIR/test_jj_integration.lua"
fi

# Print final summary
echo "========================================"
echo "           Final Summary"
echo "========================================"
echo -e "Test Suites Run: $TOTAL_SUITES"
echo -e "${GREEN}Passed: $TOTAL_PASSED${NC}"
echo -e "${RED}Failed: $TOTAL_FAILED${NC}"
echo ""

# Append summary to results file
cat >> "$RESULTS_FILE" << EOF

========================================
Final Summary
========================================
Test Suites Run: $TOTAL_SUITES
Passed: $TOTAL_PASSED
Failed: $TOTAL_FAILED
EOF

echo "Full results saved to: $RESULTS_FILE"
echo ""

# Exit with appropriate code
if [ $TOTAL_FAILED -gt 0 ]; then
    echo -e "${RED}Some tests failed. Please review the output above.${NC}"
    exit 1
else
    echo -e "${GREEN}All test suites passed!${NC}"
    exit 0
fi
