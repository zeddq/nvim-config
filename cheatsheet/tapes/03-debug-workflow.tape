# Debug Workflow — DAP breakpoints, stepping, UI
# Records: set breakpoint, start debug, step, inspect, REPL
# Requires: nvim with this config, example.py in current directory

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
F5
Sleep 2s

# Step over (F10)
F10
Sleep 1s

# Step into (F11)
F11
Sleep 1s

# Open REPL
Type " dr"
Sleep 1500ms

# Toggle DAP UI
Type " du"
Sleep 2s

# Terminate debug session before exiting
Type ":DapTerminate"
Enter
Sleep 500ms

Type ":q!"
Enter
Sleep 500ms
