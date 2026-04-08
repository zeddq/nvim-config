#!/usr/bin/env bash
# Install git hooks for the Neovim config repository.
# Usage: ./scripts/setup.sh
#
# Hooks installed:
#   post-commit — regenerates cheatsheet HTML after every commit (background)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$REPO_DIR/.git/hooks"

echo "Installing git hooks..."

# post-commit hook
src="$SCRIPT_DIR/post-commit"
dst="$HOOKS_DIR/post-commit"

if [ -f "$dst" ] && [ ! -L "$dst" ]; then
  echo "  ⚠ $dst already exists (not a symlink). Backing up to ${dst}.bak"
  mv "$dst" "${dst}.bak"
fi

ln -sf "$src" "$dst"
chmod +x "$src"
echo "  ✓ post-commit → scripts/post-commit"

echo "Done. Hooks installed to .git/hooks/"
