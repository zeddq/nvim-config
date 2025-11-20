#!/bin/bash
# Master Test Runner for jj.nvim Integration
# Runs all test suites and generates a comprehensive report

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
RESULTS_FILE="$SCRIPT_DIR/test_results.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "========================================"
echo "   jj.nvim Integration Test Suite"
echo "========================================"
echo ""
echo "Config directory: $CONFIG_DIR"
echo "Running tests in headless neovim..."
echo ""

# Initialize results file
cat > "$RESULTS_FILE" << EOF
jj.nvim Integration Test Results
Generated: $(date)
Working Directory: $(pwd)
VCS Type: $(cd "$CONFIG_DIR" && require("utils.vcs").detect_vcs_type() 2>/dev/null || echo "unknown")

EOF

# Track overall results
TOTAL_PASSED=0
TOTAL_FAILED=0
TOTAL_SUITES=0

# Function to run a test suite
run_test_suite() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .lua)

    echo -e "${BLUE}Running: $test_name${NC}"
    echo "----------------------------------------"

    TOTAL_SUITES=$((TOTAL_SUITES + 1))

    # Run test in headless neovim
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

# Run all test suites
run_test_suite "$SCRIPT_DIR/test_vcs_detection.lua"
run_test_suite "$SCRIPT_DIR/test_plugin_loading.lua"
run_test_suite "$SCRIPT_DIR/test_commands.lua"

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
