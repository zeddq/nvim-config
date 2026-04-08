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

# Show VCS status
Type " gs"
Sleep 3s

# Close terminal split — must escape terminal mode first (Ctrl+\ Ctrl+N)
Ctrl+\
Ctrl+n
Type ":q"
Enter
Sleep 500ms

# Show VCS log
Type " gl"
Sleep 3s
Ctrl+\
Ctrl+n
Type ":q"
Enter
Sleep 500ms

# Show VCS diff
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
