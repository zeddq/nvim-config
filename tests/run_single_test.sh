#!/bin/bash
# Run a single test suite

if [ -z "$1" ]; then
    echo "Usage: $0 <test_file.lua>"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
TEST_FILE="$1"

if [ ! -f "$TEST_FILE" ]; then
    echo "Error: Test file not found: $TEST_FILE"
    exit 1
fi

echo "Running test: $(basename "$TEST_FILE")"
echo "Config: $CONFIG_DIR"
echo ""

nvim --headless --noplugin -u "$CONFIG_DIR/init.lua" -l "$TEST_FILE"
