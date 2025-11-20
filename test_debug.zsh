#!/usr/bin/env zsh
# Test script for DAP zsh debugging
# Usage: Open this file in Neovim and press F5 to start debugging

function greet() {
  local name="$1"
  local greeting="Hello, ${name}!"
  echo "${greeting}"
  return 0
}

function calculate() {
  local a=$1
  local b=$2
  local sum=$((a + b))
  local product=$((a * b))

  echo "Numbers: a=${a}, b=${b}"
  echo "Sum: ${sum}"
  echo "Product: ${product}"

  return ${sum}
}

function main() {
  echo "=== Zsh Debug Test Script ==="

  # Test 1: Simple function call
  greet "World"

  # Test 2: Variables and arithmetic
  local x=10
  local y=20
  echo "Variables: x=${x}, y=${y}"

  # Test 3: Function with return value
  calculate ${x} ${y}
  local result=$?
  echo "Function returned: ${result}"

  # Test 4: Loop
  echo "Loop test:"
  for i in {1..5}; do
    echo "  Iteration ${i}"
  done

  # Test 5: Conditional
  if [[ ${x} -lt ${y} ]]; then
    echo "x is less than y"
  else
    echo "x is not less than y"
  fi

  echo "=== Test Complete ==="
}

# Run main function
main
