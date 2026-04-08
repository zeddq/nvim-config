# LSP Workflow — Navigation, diagnostics, code actions
# Records: go-to-definition, hover, references, rename, format
# Requires: nvim with this config, a Python file open

Output cheatsheet/workflows/02-lsp-workflow.webp
Set FontSize 14
Set Width 1200
Set Height 800
Set Theme "TokyoNight"
Set TypingSpeed 60ms

Type "nvim example.py"
Enter
Sleep 2s

# Go to definition
Type "gd"
Sleep 1500ms

# Show hover documentation
Type "K"
Sleep 2s
Escape
Sleep 500ms

# Show references
Type "gr"
Sleep 2s
Escape
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
