# GhosttySync

A Neovim plugin that automatically synchronizes Ghostty terminal themes with Neovim colorschemes.

Adapted from the [material.nvim](https://github.com/marko-cerovac/material.nvim) color theme.

Many thanks to Marko Cerovac who is the original author of material.nvim and whose code
is the foundation of this work.

This colorscheme plugin is designed to be an out-of-the-box solution which adapts your existing
theme from the Ghostty terminal emulator and applies it to nvim. As such, this project adopts
the following design philosophies:

1. If possible, colors should move straight across from the terminal theme.
2. Minimal configuration and customization.
3. If additional colors are needed, they should be adapted from original colors.
4. Highlights are checked for WCAG contrast against their background and adjusted
   along OKLCH lightness when needed — hue is preserved so the theme's character
   stays intact. See `lua/ghosttysync/colors/README.md` for the readability
   pipeline and `:GhosttysyncAudit` for live inspection.

This is why so much customization has been removed from the source theme, and why there will
be even more options removed in the future.

## FAQ

* Why Ghostty?
A: Ghostty has a great api command which returns information from the configuration,
including information about the terminal colors and palette.

* Why not just get the colors directly from the terminal?
A: I tried this approach, but couldn't get a satisfactory solution. If there is a
reasonable solution out there, I'd be happy to see it. It would be great if this
colorscheme was terminal emulator agnostic.

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
-- In a dedicated setup file (ie ghosttysync.lua).
return {
  "jnschurig/ghosttysync.nvim",
  branch = "v0.1",
  lazy = false,
  priority = 1001,
  config = function()
    require("ghosttysync").setup({
      disable = {
        background = false,  -- set true for a transparent terminal
        eob_lines = true,    -- hide end-of-buffer ~ tildes
      },
      plugins = {
        -- "neo-tree",
      },
      styles = {
        comments = { italic = true },
        functions = { bold = true },
        -- keywords, strings, variables, operators, types, ...
      },
      -- lualine_theme = "ghosttysync",  -- or false to keep your existing theme
      -- lualine_style = "default",       -- or "stealth"
      -- async_loading = false,
      -- contrast_thresholds = {},        -- override readability thresholds
    })
    vim.cmd.colorscheme("ghosttysync")
  end,
}
```

## Usage

The plugin automatically syncs your Ghostty theme with Neovim on startup. You can also manually trigger synchronization:

```vim
:colorscheme ghosttysync
```

## Requirements

- Neovim 0.7+
- Ghostty terminal emulator
- Ghostty must be accessible via CLI (`ghostty +show-config`)

## Known limitations

- **lazygit diff colors are not theme-synced.** lazygit runs in a separate
  process with its own config; bridging the live palette requires a
  config-file write + reload that's out of scope for this plugin. gitsigns
  and the lualine diff tier do pick up the active palette.

## Plugin Structure

```
lua/ghosttysync/
├── init.lua           # Main controller and plugin entry point
├── ghostty_config.lua # Ghostty CLI execution and config parsing
├── theme_parser.lua   # Theme parsing and color extraction
├── color_mapper.lua   # Color mapping to Neovim highlight groups
└── nvim_applier.lua   # Neovim highlight group application
```
