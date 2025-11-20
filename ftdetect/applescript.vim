" AppleScript filetype detection
" Detect .applescript and .scpt files as applescript filetype

au BufRead,BufNewFile *.applescript setfiletype applescript
au BufRead,BufNewFile *.scpt setfiletype applescript
