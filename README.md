# GhosttySync

A Neovim plugin that automatically synchronizes Ghostty terminal themes with Neovim colorschemes.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "jnschurig/ghosttysync.nvim",
  config = function()
    require("ghosttysync").setup()
  end
}
```

## Configuration

```lua
return {
  "jnschurig/ghosttysync.nvim",
  branch = "v0.1",
  lazy = false,
  priority = 1001,
  config = function()
    require("ghosttysync").setup({
      disable = {
        background = false,
      },
      plugins = {
        -- "neo-tree",
      },
      styles = {
        comments = {},
        functions = { bold = true },
        strings = { italic = true },
      },
    })
    vim.cmd.colorscheme("ghosttysync")
  end,
}
```

## Usage

The plugin automatically syncs your Ghostty theme with Neovim on startup. You can also manually trigger synchronization:

```vim
:GhosttySyncTheme
```

## Requirements

- Neovim 0.7+
- Ghostty terminal emulator
- Ghostty must be accessible via CLI (`ghostty +show-config`)

## Plugin Structure

```
lua/ghosttysync/
├── init.lua           # Main controller and plugin entry point
├── ghostty_config.lua # Ghostty CLI execution and config parsing
├── theme_parser.lua   # Theme parsing and color extraction
├── color_mapper.lua   # Color mapping to Neovim highlight groups
└── nvim_applier.lua   # Neovim highlight group application
```
