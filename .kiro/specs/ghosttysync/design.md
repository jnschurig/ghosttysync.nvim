# GhosttySync Design Document

## Overview

GhosttySync is a Neovim plugin that automatically synchronizes terminal themes from Ghostty with Neovim's colorscheme. The plugin reads Ghostty's configuration files, extracts color information, detects light/dark mode, and applies corresponding colors to Neovim highlight groups on startup.

## Architecture

The plugin follows a modular architecture with clear separation of concerns:

```
GhosttySync Plugin
├── Configuration Reader (ghostty_config.lua)
├── Theme Parser (theme_parser.lua)  
├── Color Mapper (color_mapper.lua)
├── Neovim Applier (nvim_applier.lua)
└── Main Controller (init.lua)
```

### Data Flow

1. **Startup**: Plugin initializes on Neovim startup
2. **Immediate Sync**: Execute theme synchronization before UI is visible
3. **Config Retrieval**: Execute `ghostty +show-config` to get current configuration
4. **Theme Parsing**: Extract active theme and color values from CLI output
5. **Mode Detection**: Determine light/dark mode preference from colors
6. **Color Application**: Apply colors to Neovim highlight groups immediately
7. **Caching**: Store results for subsequent operations

## Components and Interfaces

### Configuration Reader (`ghostty_config.lua`)

**Purpose**: Execute Ghostty CLI to retrieve current configuration

**Key Functions**:
- `execute_show_config()` - Run `ghostty +show-config` command
- `parse_config_output(output)` - Parse the CLI output
- `extract_theme_info(config)` - Extract theme and color information

**CLI Command**: `ghostty +show-config`
- Returns current active configuration including theme and colors
- Handles all configuration merging and theme resolution internally
- More reliable than manual file parsing

### Theme Parser (`theme_parser.lua`)

**Purpose**: Parse CLI output and extract color information

**Key Functions**:
- `parse_cli_output(output)` - Parse `ghostty +show-config` output
- `extract_colors(config_data)` - Extract color palette from parsed config
- `detect_mode(colors)` - Determine if theme is light or dark mode

**Color Extraction Strategy**:
- Parse color values directly from CLI output (already resolved)
- Extract background, foreground, cursor colors
- Handle standard terminal color palette (0-15)

### Color Mapper (`color_mapper.lua`)

**Purpose**: Map Ghostty colors to Neovim highlight groups

**Key Functions**:
- `create_highlight_map(colors, mode)` - Generate highlight group mappings
- `validate_colors(colors)` - Ensure color values are valid
- `apply_mode_adjustments(colors, mode)` - Adjust colors for light/dark mode

**Core Highlight Groups**:
- `Normal` - Main text and background
- `Comment` - Code comments
- `Keyword` - Language keywords
- `Conditional` - Conditional statements (if, else, etc.)
- `String` - String literals
- `Function` - Function names
- `Variable` - Variable names
- `Type` - Type definitions and structures
- `Number` - Numeric literals
- `Error` - Error highlighting
- `Warning` - Warning highlighting
- `Hint` - Hint highlighting
- `Note` - Note highlighting

### Neovim Applier (`nvim_applier.lua`)

**Purpose**: Apply color mappings to Neovim

**Key Functions**:
- `apply_highlights(highlight_map)` - Set highlight groups
- `set_colorscheme_name(name)` - Set colorscheme identifier
- `clear_existing_highlights()` - Reset current highlights

### Main Controller (`init.lua`)

**Purpose**: Orchestrate the synchronization process

**Key Functions**:
- `setup(opts)` - Initialize plugin with options
- `sync_theme()` - Main synchronization function
- `get_cache()` - Retrieve cached theme data
- `set_cache(data)` - Store theme data for performance

## Data Models

### Theme Configuration
```lua
{
  name = "theme_name",
  mode = "dark" | "light",
  colors = {
    background = "#000000",
    foreground = "#ffffff",
    cursor = "#ffffff",
    palette = {
      black = "#000000",
      red = "#ff0000",
      -- ... additional colors
    }
  }
}
```

### Highlight Mapping
```lua
{
  Normal = { fg = "#ffffff", bg = "#000000" },
  Comment = { fg = "#808080", italic = true },
  Keyword = { fg = "#ff6b6b", bold = true },
  Conditional = { fg = "#ff6b6b" },
  String = { fg = "#4ecdc4" },
  Function = { fg = "#45b7d1" },
  Type = { fg = "#96ceb4" },
  Number = { fg = "#feca57" },
  Error = { fg = "#ff6b6b", bg = "#2d1b1b" },
  Warning = { fg = "#feca57", bg = "#2d2a1b" },
  Hint = { fg = "#4ecdc4", bg = "#1b2d2a" },
  Note = { fg = "#45b7d1", bg = "#1b252d" },
  -- ... additional mappings
}
```

## Error Handling

### Configuration Errors
- **Ghostty Not Found**: Log warning, use Neovim defaults
- **CLI Command Failed**: Handle command execution errors gracefully
- **Invalid CLI Output**: Parse what's possible, fallback for invalid sections

### Theme Errors  
- **Invalid CLI Output**: Handle malformed command output gracefully
- **Invalid Colors**: Validate and sanitize color values from CLI
- **Parse Errors**: Skip invalid lines, continue with valid data

### Neovim Errors
- **Invalid Highlight Groups**: Skip invalid groups, continue with valid ones
- **Color Format Errors**: Convert colors to valid Neovim format

## Testing Strategy

### Unit Tests
- Configuration file parsing with various formats
- Color extraction and validation
- Highlight group mapping logic
- Error handling for edge cases

### Integration Tests  
- End-to-end theme synchronization
- Multiple configuration file scenarios
- Light/dark mode switching
- Performance benchmarks

### Manual Testing
- Test with various Ghostty themes
- Verify visual consistency between terminal and editor
- Test startup performance impact
- Validate error handling with corrupted configs

## Performance Considerations

### Caching Strategy
- Cache CLI output to avoid repeated command execution
- Cache color mappings to avoid recomputation
- Use reasonable cache timeout (e.g., 30 seconds) for theme changes

### Startup Optimization
- Execute theme synchronization immediately on startup to avoid visual flicker
- Cache CLI output to avoid repeated command executions
- Use efficient Lua patterns for parsing CLI output
- Ensure theme is applied before user sees the editor to prevent theme switching

### Memory Management
- Release cached data when not needed
- Avoid storing large theme data structures
- Use weak references where appropriate