# Debug Workflow — DAP breakpoints, stepping, UI
# Records: set breakpoint, start debug, step, inspect, REPL
# Requires: nvim with this config, cheatsheet/fixtures/example.py

Output cheatsheet/workflows/03-debug-workflow.gif
Set FontSize 14
Set Width 1200
Set Height 800
Set Theme "TokyoNight"
Set TypingSpeed 60ms

Type "nvim cheatsheet/fixtures/example.py"
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

# Start debugging
# NOTE: VHS does not support function keys (F1-F12). Use :lua equivalents.
Type ":lua require('dap').continue()"
Enter
Sleep 2s

# Step over
Type ":lua require('dap').step_over()"
Enter
Sleep 1s

# Step into
Type ":lua require('dap').step_into()"
Enter
Sleep 1s

# Open REPL
Type " dr"
Sleep 1500ms

# Toggle DAP UI
Type " du"
Sleep 2s

# Terminate debug session and exit all windows
Type ":DapTerminate"
Enter
Sleep 500ms

Type ":qa!"
Enter
Sleep 500ms
