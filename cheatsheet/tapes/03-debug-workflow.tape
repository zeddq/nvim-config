# Debug Workflow — DAP breakpoints, stepping, UI
# Records: set breakpoint, start debug, step, inspect, REPL
# Requires: nvim with this config, a Python file open

Output cheatsheet/workflows/03-debug-workflow.webp
Set FontSize 14
Set Width 1200
Set Height 800
Set Theme "TokyoNight"
Set TypingSpeed 60ms

Type "nvim example.py"
Enter
Sleep 2s

# Toggle breakpoint on current line
Type " b"
Sleep 1s

# Move down and set conditional breakpoint
Type "5j"
Sleep 500ms
Type " B"
Sleep 500ms
Type "x > 10"
Enter
Sleep 1s

# Start debugging (F5)
Type@0ms ""
Sleep 500ms

# Step over (F10)
Type@0ms ""
Sleep 1s

# Step into (F11)
Type@0ms ""
Sleep 1s

# Open REPL
Type " dr"
Sleep 1500ms

# Toggle DAP UI
Type " du"
Sleep 2s

Type ":q!"
Enter
Sleep 500ms
