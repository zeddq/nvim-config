# Zsh Debugging with nvim-dap

Complete guide for debugging zsh scripts in Neovim using the Debug Adapter Protocol (DAP).

## 📋 Table of Contents

1. [Setup](#setup)
2. [Basic Usage](#basic-usage)
3. [Key Bindings](#key-bindings)
4. [Configuration Details](#configuration-details)
5. [Troubleshooting](#troubleshooting)
6. [Advanced Features](#advanced-features)

---

## Setup

### 1. Install bash-debug-adapter

Open Neovim and run:

```vim
:MasonInstall bash-debug-adapter
```

Or use the Mason UI:

```vim
:Mason
```

Then search for "bash-debug-adapter" and press `i` to install.

### 2. Verify Installation

After installation, restart Neovim. You should see a notification:

```
✓ Bash/Zsh debugger configured successfully
```

If you see a warning instead, ensure the adapter is installed via Mason.

### 3. Test the Setup

Open the test script:

```vim
:e ~/.config/nvim/test_debug.zsh
```

---

## Basic Usage

### Starting a Debug Session

1. **Open a zsh script** (`.zsh` or `.sh` file)
2. **Set a breakpoint**: Press `<leader>b` (default: `<Space>b`) on any executable line
3. **Start debugging**: Press `<F5>`
4. **The DAP UI will open automatically** showing:
   - Variables (scopes)
   - Breakpoints
   - Call stack
   - Watches
   - REPL console

### Debug Controls

| Key | Action | Description |
|-----|--------|-------------|
| `<F5>` | Continue | Start debugging or continue to next breakpoint |
| `<F10>` | Step Over | Execute current line and move to next |
| `<F11>` | Step Into | Enter function calls |
| `<F12>` | Step Out | Exit current function |
| `<leader>b` | Toggle Breakpoint | Add/remove breakpoint at cursor |
| `<leader>B` | Conditional Breakpoint | Set breakpoint with condition |
| `<leader>dr` | Open REPL | Open debug console |
| `<leader>du` | Toggle UI | Show/hide debug UI |
| `<leader>dl` | Run Last | Repeat last debug session |

---

## Configuration Details

### Adapter Configuration

The bash debugger uses `bash-debug-adapter` from Mason:

```lua
dap.adapters.bashdb = {
  type = "executable",
  command = mason_path .. "/bash-debug-adapter",
  name = "bashdb",
}
```

### Launch Configurations

Two configurations are available:

#### 1. Launch file (no arguments)

```lua
{
  type = "bashdb",
  request = "launch",
  name = "Launch file",
  program = "${file}",  -- Current file
  cwd = "${workspaceFolder}",
  -- ... other settings
}
```

#### 2. Launch file with arguments

```lua
{
  type = "bashdb",
  request = "launch",
  name = "Launch file with arguments",
  program = "${file}",
  args = function()
    -- Prompts for arguments
    local args_string = vim.fn.input("Arguments: ")
    return vim.split(args_string, " +")
  end,
  -- ... other settings
}
```

### Supported Filetypes

The configuration works for both:
- `.sh` files (bash)
- `.zsh` files (zsh)

Both use the same debugger configurations.

---

## Key Bindings Reference

### Breakpoint Management

```vim
" Toggle breakpoint at current line
<Space>b

" Set conditional breakpoint
<Space>B
" Then enter condition, e.g.: $x -gt 10
```

### Debug Session Control

```vim
" Start/Continue debugging
<F5>

" Step over (next line)
<F10>

" Step into (enter function)
<F11>

" Step out (exit function)
<F12>
```

### Debug UI Management

```vim
" Toggle debug UI
<Space>du

" Open debug REPL
<Space>dr

" Run last debug configuration
<Space>dl
```

---

## Troubleshooting

### Issue: "bash-debug-adapter not installed"

**Solution**: Install the adapter via Mason:

```vim
:MasonInstall bash-debug-adapter
```

Then restart Neovim.

### Issue: Breakpoints not hitting

**Possible causes**:

1. **Script not executable**: Ensure your script has a shebang and is executable

   ```bash
   chmod +x your_script.zsh
   ```

2. **Wrong interpreter**: Check the shebang line

   ```zsh
   #!/usr/bin/env zsh
   ```

3. **Syntax error**: Fix any syntax errors in your script before debugging

### Issue: Debug UI not showing

**Solution**: Manually toggle the UI:

```vim
:lua require('dapui').toggle()
```

Or press `<leader>du` (default: `<Space>du`)

### Issue: Variables not showing values

**Possible causes**:

1. **Not stopped at breakpoint**: Variables only show when execution is paused
2. **Variable scope**: Local variables only visible in their scope
3. **Uninitialized variables**: Variables must have values assigned

---

## Advanced Features

### Conditional Breakpoints

Set breakpoints that only trigger when a condition is true:

1. Press `<leader>B` (Space+Shift+B)
2. Enter condition: `$count -gt 5`
3. Press Enter

The breakpoint will only pause execution when `count > 5`.

### Watch Expressions

Monitor variable values in real-time:

1. Open DAP UI: `<leader>du`
2. Navigate to "Watches" panel
3. Add expressions to watch

### Debug REPL

Execute commands during debugging:

1. Press `<leader>dr` to open REPL
2. Type zsh commands
3. Inspect variables: `echo $myvar`
4. Call functions: `myfunction arg1 arg2`

### Debugging with Arguments

When you start a debug session with "Launch file with arguments":

1. Press `<F5>`
2. Select "Launch file with arguments"
3. Enter arguments when prompted: `arg1 arg2 --flag`
4. Debugging starts with those arguments

### Configuration Variables

Available in launch configurations:

| Variable | Description |
|----------|-------------|
| `${file}` | Current file path |
| `${workspaceFolder}` | Current working directory |
| `${fileBasename}` | Current file name |
| `${fileDirname}` | Current file directory |

---

## Example Debugging Session

### Step-by-Step Example

1. **Open test script**:

   ```vim
   :e ~/.config/nvim/test_debug.zsh
   ```

2. **Set breakpoints**:
   - Go to line 30 (inside `main` function)
   - Press `<Space>b`
   - You should see 🔴 in the sign column

3. **Start debugging**:
   - Press `<F5>`
   - Select "Launch file"
   - DAP UI opens automatically

4. **Step through code**:
   - Press `<F10>` to step over lines
   - Watch variables update in the Scopes panel
   - Press `<F11>` to step into the `greet` function

5. **Inspect variables**:
   - In the Scopes panel, see local variables: `name`, `greeting`
   - In REPL (`<Space>dr`), type: `echo $name`

6. **Continue execution**:
   - Press `<F5>` to continue to next breakpoint or end

7. **End session**:
   - Let script complete, or
   - Press `<Space>du` to close UI
   - DAP UI auto-closes when script ends

---

## Tips & Best Practices

### 1. Use Meaningful Variable Names

Easier to track in the debugger:

```zsh
# Good
user_count=10

# Less clear in debugger
c=10
```

### 2. Add Logging for Production

Debugger is for development. Add logging for production:

```zsh
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

log "Processing user: $user_name"
```

### 3. Test Edge Cases

Use conditional breakpoints to catch edge cases:

```zsh
# Breakpoint condition: $count -eq 0
if [[ $count -eq 0 ]]; then
  # This line - set conditional breakpoint here
  echo "Edge case: count is zero"
fi
```

### 4. Combine with Tests

Debug failing tests:

1. Add breakpoint in test script
2. Run test with debugger
3. Step through to find failure

### 5. Use REPL for Exploration

During debugging, use REPL to:
- Test expressions
- Call functions
- Check command availability

---

## Configuration Location

The DAP configuration for zsh debugging is in:

```
~/.config/nvim/lua/plugins/dap.lua
```

Lines 220-287 contain the bash/zsh debugging setup.

---

## Additional Resources

- [nvim-dap GitHub](https://github.com/mfussenegger/nvim-dap)
- [nvim-dap Debug Adapter Installation](https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation)
- [bash-debug-adapter](https://github.com/rogalmic/vscode-bash-debug)
- [bashdb Documentation](http://bashdb.sourceforge.net/)

---

## Quick Reference Card

```
╔═══════════════════════════════════════════════════════════╗
║              Zsh Debugging Quick Reference                ║
╠═══════════════════════════════════════════════════════════╣
║ Setup                                                     ║
║   :MasonInstall bash-debug-adapter                        ║
║                                                           ║
║ Breakpoints                                               ║
║   <Space>b  - Toggle breakpoint                           ║
║   <Space>B  - Conditional breakpoint                      ║
║                                                           ║
║ Debug Controls                                            ║
║   F5        - Start/Continue                              ║
║   F10       - Step Over                                   ║
║   F11       - Step Into                                   ║
║   F12       - Step Out                                    ║
║                                                           ║
║ Debug UI                                                  ║
║   <Space>du - Toggle UI                                   ║
║   <Space>dr - Open REPL                                   ║
║   <Space>dl - Run Last                                    ║
╚═══════════════════════════════════════════════════════════╝
```

---

**Last Updated**: 2025-11-22
**Maintainer**: Your Neovim Configuration
**Version**: 1.0
