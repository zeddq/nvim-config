# VCS Workflow — Context-aware Git/Jujutsu keybindings
# Records: status, log, diff, info
# Requires: nvim with this config in a git or jj repo

Output cheatsheet/workflows/01-vcs-workflow.gif
Set FontSize 14
Set Width 1200
Set Height 800
Set Theme "TokyoNight"
Set TypingSpeed 60ms

Type "nvim"
Enter
Sleep 3s

# Show VCS status (jj.nvim opens an hsplit terminal buffer in normal mode)
Type " gs"
Sleep 3s

# Close the hsplit. Ctrl+\ Ctrl+N is a no-op here (jj.nvim calls stopinsert),
# kept as a safety net for pure-git repos where the terminal stays in insert mode.
Ctrl+\
Ctrl+n
Type ":q"
Enter
Sleep 500ms

# Show VCS log (hsplit terminal buffer)
Type " gl"
Sleep 3s
Ctrl+\
Ctrl+n
Type ":q"
Enter
Sleep 500ms

# Show VCS diff (jj.nvim opens a floating window, not a split)
Type " gd"
Sleep 3s
Ctrl+\
Ctrl+n
Type ":q"
Enter
Sleep 500ms

# Show VCS info
Type " g?"
Sleep 3s

# Exit
Type ":q!"
Enter
Sleep 500ms
