#!/bin/bash
# Headless startup smoke test (ZED-51).
#
# Boots the full configuration in an isolated, throwaway HOME to catch
# "works locally, fails in CI" runtimepath/path bugs — the class of bug
# where init.lua loads fine from ~/.config/nvim but breaks when invoked
# via `nvim -u /path/to/init.lua` from a CI checkout.
#
# Why run TWICE:
#   A pristine HOME forces lazy.nvim to clone every plugin on first launch.
#   That first launch is therefore noisy and NOT a trustworthy signal — it
#   emits transient "No specs found for module" lines while plugin specs are
#   still resolving mid-bootstrap, and it exits 0 regardless. So:
#     run #1  = warm-up. Clones the plugin cache. Logs + exit code DISCARDED.
#     run #2  = the real check, against a now-warm cache.
#
# On success the throwaway HOME is deleted. On failure it is kept and its
# path printed so the log can be inspected.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"

TEST_HOME="$(mktemp -d "${TMPDIR:-/tmp}/nvim-headless-XXXXXX")"
LOG_FILE="$TEST_HOME/startup.log"

echo "Config dir:  $CONFIG_DIR"
echo "Test HOME:   $TEST_HOME"
echo ""

# --- Run #1: warm the plugin cache. Output and exit code intentionally discarded.
echo "==> Warm-up run (cloning plugins; output discarded)..."
HOME="$TEST_HOME" nvim --headless -u "$CONFIG_DIR/init.lua" +qall >/dev/null 2>&1 || true

# --- Run #2: the real smoke test, against a warm cache.
echo "==> Verification run..."
HOME="$TEST_HOME" nvim --headless -u "$CONFIG_DIR/init.lua" +qall >"$LOG_FILE" 2>&1
exit_code=$?

# ---------------------------------------------------------------------------
# has_errors LOG_FILE EXIT_CODE  ->  returns 0 (true) if the run had errors.
#
# This predicate is the pass/fail gate for the whole test AND the condition
# that decides whether the throwaway HOME gets deleted. Getting it right is
# the crux: we proved above that EXIT_CODE alone lies (it was 0 despite a
# real init.lua error), so this must also scan the log contents.
#
# TODO(you): implement the body. Decide which signals count as a failure.
#   Things to weigh:
#     - nvim prints startup failures as lines beginning with "Error" and as
#       Lua error codes like "E5108"/"E5113"; runtime Lua faults read
#       "stack traceback" / "attempt to call|index".
#     - lazy.nvim import failures read "No specs found for module" — on a
#       WARM cache (run #2) these should never appear, so treat them as real.
#     - Plugin clone/build chatter may contain the word "error" harmlessly,
#       so prefer anchored/specific patterns over a bare case-insensitive
#       "error" match to avoid false positives.
#     - Should a non-zero EXIT_CODE also count, even if the log looks clean?
# ---------------------------------------------------------------------------
has_errors() {
  local log="$1"
  local code="$2"

  # TODO(you): replace this stub with the real detection logic.
  return 1
}

echo ""
if has_errors "$LOG_FILE" "$exit_code"; then
  echo "✗ Headless startup FAILED (exit=$exit_code)"
  echo "  Log and isolated HOME preserved at: $TEST_HOME"
  echo "  Offending lines:"
  rg -n -i 'error|no specs found|attempt to|stack traceback|E[0-9]{3,}' "$LOG_FILE" | head -20 || true
  exit 1
else
  echo "✓ Headless startup PASSED (exit=$exit_code) — no errors detected"
  rm -rf "$TEST_HOME"
  echo "  Cleaned up test HOME."
  exit 0
fi
