# LSP Workflow — Navigation, diagnostics, code actions
# Records: go-to-definition, hover, references, rename, format
# Requires: nvim with this config, cheatsheet/fixtures/example.py

Output cheatsheet/workflows/02-lsp-workflow.gif
Set FontSize 14
Set Width 1200
Set Height 800
Set Theme "TokyoNight"
Set TypingSpeed 60ms

Type "nvim cheatsheet/fixtures/example.py"
Enter
# Wait for the LSP (basedpyright/ruff) to attach before the first LSP action.
Sleep 6s

# Go to definition
Type "gd"
Sleep 1500ms

# Show hover documentation
Type "K"
Sleep 2s
Escape
Sleep 500ms

# Show references (populates and opens the quickfix list)
Type "gr"
Sleep 2s
# Escape does not close a quickfix window — use :cclose
Type ":cclose"
Enter
Sleep 500ms

# Rename symbol
Type " rn"
Sleep 1s
Type "new_name"
Enter
Sleep 1500ms

# Code actions
Type " ca"
Sleep 2s
Escape
Sleep 500ms

# Fix all (Ruff)
Type " cf"
Sleep 1500ms

# Organize imports
Type " co"
Sleep 1500ms

# Format document
Type " f"
Sleep 1500ms

Type ":q!"
Enter
Sleep 500ms
