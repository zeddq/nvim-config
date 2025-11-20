-- AppleScript snippets for LuaSnip
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local fmt = require("luasnip.extras.fmt").fmt

return {
  -- Tell block
  s("tell", fmt([[
tell application "{}"
  {}
end tell]], {
    i(1, "Finder"),
    i(0)
  })),

  -- Tell with error handling
  s("tellerr", fmt([[
tell application "{}"
  try
    {}
  on error errMsg number errNum
    display dialog "Error " & errNum & ": " & errMsg
  end try
end tell]], {
    i(1, "Finder"),
    i(0)
  })),

  -- Repeat loop (times)
  s("repeat", fmt([[
repeat {} times
  {}
end repeat]], {
    i(1, "5"),
    i(0)
  })),

  -- Repeat with list
  s("repeatlist", fmt([[
repeat with {} in {}
  {}
end repeat]], {
    i(1, "item"),
    i(2, "myList"),
    i(0)
  })),

  -- Repeat while
  s("repeatwhile", fmt([[
repeat while {}
  {}
end repeat]], {
    i(1, "condition"),
    i(0)
  })),

  -- If statement
  s("if", fmt([[
if {} then
  {}
end if]], {
    i(1, "condition"),
    i(0)
  })),

  -- If-else statement
  s("ifelse", fmt([[
if {} then
  {}
else
  {}
end if]], {
    i(1, "condition"),
    i(2, "-- true branch"),
    i(0, "-- false branch")
  })),

  -- If-else if-else statement
  s("ifelseif", fmt([[
if {} then
  {}
else if {} then
  {}
else
  {}
end if]], {
    i(1, "condition1"),
    i(2, "-- first branch"),
    i(3, "condition2"),
    i(4, "-- second branch"),
    i(0, "-- else branch")
  })),

  -- Try-catch block
  s("try", fmt([[
try
  {}
on error errMsg number errNum
  {}
end try]], {
    i(1, "-- code that might error"),
    i(0, "display dialog \"Error: \" & errMsg")
  })),

  -- Display dialog
  s("dialog", fmt([[
display dialog "{}" buttons {{"{}"}}{} default button 1]], {
    i(1, "Message"),
    i(2, "OK"),
    c(3, {
      t(""),
      t(' with icon note'),
      t(' with icon caution'),
      t(' with icon stop'),
    })
  })),

  -- Display notification
  s("notify", fmt([[
display notification "{}" with title "{}"{}]], {
    i(1, "Notification message"),
    i(2, "Title"),
    c(3, {
      t(""),
      fmt(' subtitle "{}"', { i(1, "Subtitle") }),
      fmt(' sound name "{}"', { i(1, "Ping") })
    })
  })),

  -- Choose from list
  s("choose", fmt([[
set chosen to choose from list {{{}}} with prompt "{}" default items {{"{}"}}
if chosen is not false then
  set selected to item 1 of chosen
  {}
end if]], {
    i(1, '"Option 1", "Option 2", "Option 3"'),
    i(2, "Select an option:"),
    i(3, "Option 1"),
    i(0, "-- handle selection")
  })),

  -- Set variable
  s("set", fmt([[
set {} to {}]], {
    i(1, "variable"),
    i(0, "value")
  })),

  -- Get application property
  s("get", fmt([[
tell application "{}"
  get {}
end tell]], {
    i(1, "Finder"),
    i(0, "name of front window")
  })),

  -- Activate application
  s("activate", fmt([[
tell application "{}" to activate]], {
    i(1, "Finder")
  })),

  -- Quit application
  s("quit", fmt([[
tell application "{}" to quit]], {
    i(1, "Safari")
  })),

  -- Open file/folder
  s("open", fmt([[
tell application "Finder"
  open {} as alias
end tell]], {
    i(0, '"Macintosh HD:Users:username:file.txt"')
  })),

  -- Delay
  s("delay", fmt([[
delay {}]], {
    i(1, "1")
  })),

  -- Log message
  s("log", fmt([[
log "{}"]], {
    i(0, "debug message")
  })),

  -- Handler/Function definition
  s("handler", fmt([[
on {}({})
  {}
end {}]], {
    i(1, "handlerName"),
    i(2, "param1, param2"),
    i(3, "-- handler body"),
    f(function(args) return args[1][1] end, {1})
  })),

  -- Handler with return value
  s("handlerret", fmt([[
on {}({})
  {}
  return {}
end {}]], {
    i(1, "handlerName"),
    i(2, "param1"),
    i(3, "-- handler body"),
    i(4, "result"),
    f(function(args) return args[1][1] end, {1})
  })),

  -- Property definition
  s("property", fmt([[
property {} : {}]], {
    i(1, "propertyName"),
    i(0, "defaultValue")
  })),

  -- Script object
  s("script", fmt([[
script {}
  property {} : {}

  on {}({})
    {}
  end {}
end script]], {
    i(1, "scriptName"),
    i(2, "propertyName"),
    i(3, "value"),
    i(4, "handlerName"),
    i(5, "params"),
    i(6, "-- handler body"),
    f(function(args) return args[4][1] end, {4})
  })),

  -- File operations - read
  s("readfile", fmt([[
set theFile to POSIX file "{}"
set fileRef to open for access theFile
set fileContent to read fileRef
close access fileRef]], {
    i(0, "/path/to/file.txt")
  })),

  -- File operations - write
  s("writefile", fmt([[
set theFile to POSIX file "{}"
set fileRef to open for access theFile with write permission
set eof fileRef to 0 -- clear file
write {} to fileRef
close access fileRef]], {
    i(1, "/path/to/file.txt"),
    i(0, '"content"')
  })),

  -- Do shell script
  s("shell", fmt([[
do shell script "{}"]], {
    i(0, "command")
  })),

  -- Do shell script with admin privileges
  s("shelladmin", fmt([[
do shell script "{}" with administrator privileges]], {
    i(0, "command")
  })),

  -- Current date/time
  s("date", {
    t("set currentDate to current date")
  }),

  -- String concatenation
  s("concat", fmt([[
set result to {} & {}]], {
    i(1, '"string1"'),
    i(0, '"string2"')
  })),

  -- List creation
  s("list", fmt([[
set {} to {{{}}}]], {
    i(1, "myList"),
    i(0, "item1, item2, item3")
  })),

  -- Record creation
  s("record", fmt([[
set {} to {{{}:{}}}]], {
    i(1, "myRecord"),
    i(2, "key"),
    i(0, "value")
  })),

  -- Get clipboard
  s("clipboard", {
    t("set clipboardContent to the clipboard")
  }),

  -- Set clipboard
  s("setclipboard", fmt([[
set the clipboard to {}]], {
    i(0, '"text"')
  })),

  -- System Events - keystroke
  s("keystroke", fmt([[
tell application "System Events"
  keystroke "{}"{}
end tell]], {
    i(1, "text"),
    c(2, {
      t(""),
      t(' using {command down}'),
      t(' using {control down}'),
      t(' using {option down}'),
      t(' using {shift down}'),
      t(' using {command down, shift down}')
    })
  })),

  -- System Events - key code
  s("keycode", fmt([[
tell application "System Events"
  key code {}{}
end tell]], {
    i(1, "36"), -- 36 is return key
    c(2, {
      t(""),
      t(' using {command down}'),
      t(' using {control down}'),
      t(' using {option down}'),
      t(' using {shift down}')
    })
  })),

  -- System Events - click button
  s("click", fmt([[
tell application "System Events"
  tell process "{}"
    click button "{}" of window 1
  end tell
end tell]], {
    i(1, "Application Name"),
    i(0, "Button Name")
  })),

  -- Finder - get selection
  s("selection", {
    t({
      "tell application \"Finder\"",
      "\tset selectedItems to selection",
      "\tif selectedItems is {} then",
      "\t\tdisplay dialog \"No items selected\"",
      "\telse",
      "\t\t-- process selection",
      "\tend if",
      "end tell"
    })
  }),

  -- Finder - new folder
  s("newfolder", fmt([[
tell application "Finder"
  make new folder at {} with properties {{name:"{}"}}
end tell]], {
    i(1, "desktop"),
    i(0, "New Folder")
  })),

  -- Path conversion - POSIX to HFS
  s("posix2hfs", fmt([[
set hfsPath to POSIX file "{}" as text]], {
    i(0, "/Users/username/Desktop/file.txt")
  })),

  -- Path conversion - HFS to POSIX
  s("hfs2posix", fmt([[
set posixPath to POSIX path of {}]], {
    i(0, "file \"Macintosh HD:Users:username:file.txt\"")
  })),
}
