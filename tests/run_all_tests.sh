#!/bin/bash
# Master Test Runner for Neovim Configuration
# Auto-discovers unit/integration tests from tests/test_*.lua.
#
# Unit tests:    test_*.lua (not matching *_integration.lua) — run with --noplugin
# Integration:   test_*_integration.lua — run without --noplugin (plugins loaded by lazy.nvim)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
RESULTS_FILE="$SCRIPT_DIR/test_results.txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

RUN_INTEGRATION=false
for arg in "$@"; do
  case "$arg" in
    --integration) RUN_INTEGRATION=true ;;
    --help|-h)
      echo "Usage: $0 [--integration]"
      echo ""
      echo "  --integration   Also run plugin integration tests (requires lazy.nvim plugins)"
      echo ""
      echo "Unit tests (test_*.lua except *_integration.lua) run with --noplugin."
      echo "Integration tests (test_*_integration.lua) run without --noplugin."
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Run with --help for usage." >&2
      exit 2
      ;;
  esac
done

# Discover tests. `find -print0 | sort -z` gives deterministic order.
UNIT_TESTS=()
while IFS= read -r -d '' f; do
  UNIT_TESTS+=("$f")
done < <(find "$SCRIPT_DIR" -maxdepth 1 -type f -name 'test_*.lua' -not -name '*_integration.lua' -print0 | sort -z)

INTEGRATION_TESTS=()
while IFS= read -r -d '' f; do
  INTEGRATION_TESTS+=("$f")
done < <(find "$SCRIPT_DIR" -maxdepth 1 -type f -name 'test_*_integration.lua' -print0 | sort -z)

if [ ${#UNIT_TESTS[@]} -eq 0 ]; then
  echo -e "${RED}Error: no unit test files discovered in $SCRIPT_DIR (pattern: test_*.lua)${NC}" >&2
  exit 1
fi

if $RUN_INTEGRATION && [ ${#INTEGRATION_TESTS[@]} -eq 0 ]; then
  echo -e "${YELLOW}Warning: --integration passed but no test_*_integration.lua files found${NC}" >&2
fi

echo "========================================"
echo "   Neovim Configuration Test Suite"
echo "========================================"
echo ""
echo "Config directory: $CONFIG_DIR"
if $RUN_INTEGRATION; then
  echo -e "${YELLOW}Mode: unit + integration${NC}"
else
  echo "Mode: unit only (use --integration for full suite)"
fi
echo ""
echo "Discovered unit tests (${#UNIT_TESTS[@]}):"
for f in "${UNIT_TESTS[@]}"; do echo "  - $(basename "$f")"; done
if $RUN_INTEGRATION; then
  echo "Discovered integration tests (${#INTEGRATION_TESTS[@]}):"
  for f in "${INTEGRATION_TESTS[@]}"; do echo "  - $(basename "$f")"; done
fi
echo ""

cat > "$RESULTS_FILE" << EOF
Neovim Configuration Test Results
Generated: $(date)
Working Directory: $(pwd)
VCS Type: $(cd "$CONFIG_DIR" && if [ -d .jj ]; then echo "jj"; elif git rev-parse --is-inside-work-tree >/dev/null 2>&1; then echo "git"; else echo "unknown"; fi)
Mode: $(if $RUN_INTEGRATION; then echo "unit + integration"; else echo "unit only"; fi)

EOF

TOTAL_PASSED=0
TOTAL_FAILED=0
TOTAL_SUITES=0

run_suite() {
  local test_file="$1"
  local label="$2"
  local color="$3"
  local noplugin="$4"
  local test_name
  test_name=$(basename "$test_file" .lua)

  echo -e "${color}Running (${label}): $test_name${NC}"
  echo "----------------------------------------"
  TOTAL_SUITES=$((TOTAL_SUITES + 1))

  local cmd=(nvim --headless)
  if [ "$noplugin" = "1" ]; then cmd+=(--noplugin); fi
  cmd+=(-u "$CONFIG_DIR/init.lua" -l "$test_file")

  if "${cmd[@]}" 2>&1 | tee -a "$RESULTS_FILE"; then
    echo -e "${GREEN}✓ $test_name PASSED${NC}"
    TOTAL_PASSED=$((TOTAL_PASSED + 1))
  else
    echo -e "${RED}✗ $test_name FAILED${NC}"
    TOTAL_FAILED=$((TOTAL_FAILED + 1))
  fi
  echo ""
  echo "" >> "$RESULTS_FILE"
}

echo -e "${BLUE}━━━ Unit Tests ━━━${NC}"
echo ""
for f in "${UNIT_TESTS[@]}"; do
  run_suite "$f" "unit" "$BLUE" "1"
done

if $RUN_INTEGRATION && [ ${#INTEGRATION_TESTS[@]} -gt 0 ]; then
  echo -e "${YELLOW}━━━ Integration Tests ━━━${NC}"
  echo ""
  for f in "${INTEGRATION_TESTS[@]}"; do
    run_suite "$f" "integration" "$YELLOW" "0"
  done
fi

echo "========================================"
echo "           Final Summary"
echo "========================================"
echo -e "Test Suites Run: $TOTAL_SUITES"
echo -e "${GREEN}Passed: $TOTAL_PASSED${NC}"
echo -e "${RED}Failed: $TOTAL_FAILED${NC}"
echo ""

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

if [ $TOTAL_FAILED -gt 0 ]; then
  echo -e "${RED}Some tests failed. Please review the output above.${NC}"
  exit 1
else
  echo -e "${GREEN}All test suites passed!${NC}"
  exit 0
fi
