# snacks.nvim Integration

Quality-of-life enhancements via [snacks.nvim](https://github.com/folke/snacks.nvim).

## Enabled Modules

| Module | Purpose |
|--------|---------|
| **bigfile** | Auto-disable heavy features for files >1.5MB |
| **dashboard** | Start screen with recent files and projects |
| **notifier** | Beautiful notifications for LSP/Mason |
| **statuscolumn** | Enhanced line numbers with git signs |
| **indent** | Visual indent guides |
| **words** | LSP word highlighting under cursor |
| **quickfile** | Fast file loading optimization |

## Disabled Modules

| Module | Reason |
|--------|--------|
| scroll | Paste corruption risk (Issue #384) |
| picker | Keep telescope.nvim |
| explorer | Keep neo-tree.nvim |

## Keybindings

| Key | Function |
|-----|----------|
| `<leader>sn` | Notification history |
| `<leader>snd` | Dismiss notifications |
| `<leader>sd` | Open dashboard |
| `<leader>ss` | Toggle scratch buffer |

## Configuration

Located in `lua/plugins/snacks.lua`.

### Adjust notification timeout

```lua
notifier = {
  timeout = 5000,  -- 5 seconds
}
```

### Change indent character

```lua
indent = {
  char = "┊",
}
```

### Adjust bigfile threshold

```lua
bigfile = {
  size = 3 * 1024 * 1024,  -- 3MB
}
```

## Troubleshooting

### Dashboard doesn't open

```vim
:lua Snacks.dashboard()    " Manual open
:checkhealth snacks        " Check health
```

### Notifications not appearing

```vim
:lua vim.notify("test")    " Test notification
<leader>sn                 " Check history
```

### Git signs missing

```vim
:Gitsigns toggle_signs     " Toggle gitsigns
:lua vim.print(require('snacks').config.statuscolumn)
```

## Resources

- [snacks.nvim GitHub](https://github.com/folke/snacks.nvim)
- [Documentation](https://github.com/folke/snacks.nvim/tree/main/docs)
