# Navigation Workflow — Flash, Neo-tree, Snacks
# Records: flash jump, file explorer, dashboard, scratch buffer
# Requires: nvim with this config

Output cheatsheet/workflows/04-navigation-workflow.webp
Set FontSize 14
Set Width 1200
Set Height 800
Set Theme "TokyoNight"
Set TypingSpeed 60ms

Type "nvim"
Enter
Sleep 2s

# Toggle file explorer
Type " e"
Sleep 2s

# Close explorer
Type " e"
Sleep 500ms

# Open a file first
Type ":e lua/config/keymaps.lua"
Enter
Sleep 1500ms

# Flash jump (s + chars)
Type "sfu"
Sleep 1500ms
Escape
Sleep 500ms

# Flash treesitter (S)
Type "S"
Sleep 2s
Escape
Sleep 500ms

# Toggle scratch buffer
Type " ss"
Sleep 2s
Type ":q"
Enter
Sleep 500ms

# Show dashboard
Type " sd"
Sleep 2s

# Notification history
Type " sn"
Sleep 2s

Type ":q!"
Enter
Sleep 500ms
