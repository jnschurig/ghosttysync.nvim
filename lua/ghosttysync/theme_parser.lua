-- Theme Parser Module
-- Handles parsing of Ghostty CLI output and color extraction

local M = {}

-- Data structure for theme configuration
M.ThemeConfig = {
  name = "",        -- Theme name
  mode = "dark",    -- "dark" or "light"
  colors = {
    background = "#000000",
    foreground = "#ffffff", 
    cursor = "#ffffff",
    palette = {
      black = "#000000",
      red = "#ff0000",
      green = "#00ff00",
      yellow = "#ffff00",
      blue = "#0000ff",
      magenta = "#ff00ff",
      cyan = "#00ffff",
      white = "#ffffff",
      bright_black = "#808080",
      bright_red = "#ff8080",
      bright_green = "#80ff80",
      bright_yellow = "#ffff80",
      bright_blue = "#8080ff",
      bright_magenta = "#ff80ff",
      bright_cyan = "#80ffff",
      bright_white = "#ffffff",
    }
  }
}

-- Helper function to validate hex color format
local function is_valid_hex_color(color)
  if not color or type(color) ~= "string" then
    return false
  end
  -- Check for valid hex color format (#RRGGBB)
  return color:match("^#%x%x%x%x%x%x$") ~= nil
end

-- Helper function to normalize color values to hex format
local function normalize_to_hex(color)
  if not color or type(color) ~= "string" then
    return nil
  end
  
  -- Trim whitespace
  color = color:gsub("^%s*(.-)%s*$", "%1")
  
  -- If already valid 6-digit hex, return as-is
  if color:match("^#%x%x%x%x%x%x$") then
    return color:upper()
  end
  
  -- Convert 3-digit hex to 6-digit
  if color:match("^#%x%x%x$") then
    local r, g, b = color:match("^#(%x)(%x)(%x)$")
    return "#" .. r:upper() .. r:upper() .. g:upper() .. g:upper() .. b:upper() .. b:upper()
  end
  
  -- Handle rgb() format
  local r, g, b = color:match("^rgb%((%d+),%s*(%d+),%s*(%d+)%)$")
  if r and g and b then
    local red = math.min(255, math.max(0, tonumber(r)))
    local green = math.min(255, math.max(0, tonumber(g)))
    local blue = math.min(255, math.max(0, tonumber(b)))
    return string.format("#%02X%02X%02X", red, green, blue)
  end
  
  -- Handle rgba() format (ignore alpha)
  r, g, b = color:match("^rgba%((%d+),%s*(%d+),%s*(%d+),%s*[%d%.]+%)$")
  if r and g and b then
    local red = math.min(255, math.max(0, tonumber(r)))
    local green = math.min(255, math.max(0, tonumber(g)))
    local blue = math.min(255, math.max(0, tonumber(b)))
    return string.format("#%02X%02X%02X", red, green, blue)
  end
  
  -- If we can't normalize, return nil
  return nil
end

-- Parse CLI output from `ghostty +show-config`
function M.parse_cli_output(output)
  if not output or type(output) ~= "string" or output == "" then
    return nil, "Invalid or empty CLI output"
  end
  
  local config = {}
  local palette_entries = {}
  
  -- Split output into lines
  local lines = {}
  for line in output:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  
  for _, line in ipairs(lines) do
    -- Trim whitespace
    line = line:gsub("^%s*(.-)%s*$", "%1")
    
    -- Skip empty lines and comments
    if line ~= "" and not line:match("^#") then
      -- Parse key = value format
      local key, value = line:match("^([^=]+)%s*=%s*(.*)$")
      if key and value then
        key = key:gsub("^%s*(.-)%s*$", "%1")
        value = value:gsub("^%s*(.-)%s*$", "%1")
        
        -- Remove quotes from values
        value = value:gsub("^[\"'](.+)[\"']$", "%1")
        
        if value ~= "" then
          -- Special handling for palette entries
          if key == "palette" then
            table.insert(palette_entries, value)
          else
            config[key] = value
          end
        end
      end
    end
  end
  
  -- Add palette entries to config
  if #palette_entries > 0 then
    config.palette_entries = palette_entries
  end
  
  return config, nil
end

-- Extract color palette from parsed configuration data
-- Only extracts: background, foreground, selection-foreground, selection-background, and palette colors 0-15
function M.extract_colors(config_data)
  if not config_data or type(config_data) ~= "table" then
    return nil, "Invalid configuration data"
  end
  
  local colors = {
    background = nil,
    foreground = nil,
    selection_foreground = nil,
    selection_background = nil,
    palette = {}
  }
  
  -- Extract and validate background color
  if config_data.background then
    colors.background = normalize_to_hex(config_data.background)
  end
  
  -- Extract and validate foreground color
  if config_data.foreground then
    colors.foreground = normalize_to_hex(config_data.foreground)
  end
  
  -- Extract selection colors
  if config_data.selection_foreground then
    colors.selection_foreground = normalize_to_hex(config_data.selection_foreground)
  end
  
  if config_data.selection_background then
    colors.selection_background = normalize_to_hex(config_data.selection_background)
  end
  
  -- Extract ONLY terminal color palette (colors 0-15)
  -- Explicitly ignore any colors beyond the standard 16-color palette
  if config_data.palette_entries then
    for _, entry in ipairs(config_data.palette_entries) do
      local color_num, color_value = entry:match("^(%d+)=(.+)$")
      if color_num and color_value then
        local num = tonumber(color_num)
        -- ONLY process standard terminal colors (0-15), ignore 256-color palette
        if num and num >= 0 and num <= 15 then
          local normalized = normalize_to_hex(color_value)
          if normalized then
            colors.palette[num] = normalized
          end
        end
        -- Explicitly ignore colors 16-255 (256-color palette)
      end
    end
  end
  
  -- Note: We don't validate for empty config here since we provide defaults below
  -- This allows the function to work even with minimal or empty configuration
  
  -- Set default values for missing essential colors
  if not colors.background then
    colors.background = "#000000"  -- Default to black background
  end
  
  if not colors.foreground then
    colors.foreground = "#FFFFFF"  -- Default to white foreground
  end
  
  -- Set default selection colors if not provided
  if not colors.selection_background then
    colors.selection_background = "#404040"  -- Default selection background
  end
  
  if not colors.selection_foreground then
    colors.selection_foreground = colors.foreground  -- Default to foreground color
  end
  
  -- Ensure we have a complete standard palette (0-15)
  local default_palette = {
    [0] = "#000000",   -- black
    [1] = "#FF0000",   -- red
    [2] = "#00FF00",   -- green
    [3] = "#FFFF00",   -- yellow
    [4] = "#0000FF",   -- blue
    [5] = "#FF00FF",   -- magenta
    [6] = "#00FFFF",   -- cyan
    [7] = "#FFFFFF",   -- white
    [8] = "#808080",   -- bright black
    [9] = "#FF8080",   -- bright red
    [10] = "#80FF80",  -- bright green
    [11] = "#FFFF80",  -- bright yellow
    [12] = "#8080FF",  -- bright blue
    [13] = "#FF80FF",  -- bright magenta
    [14] = "#80FFFF",  -- bright cyan
    [15] = "#FFFFFF",  -- bright white
  }
  
  -- Fill in missing palette colors with defaults
  for i = 0, 15 do
    if not colors.palette[i] then
      colors.palette[i] = default_palette[i]
    end
  end
  
  return colors, nil
end

-- Detect if theme is light or dark mode based on background color
-- PLACEHOLDER: This function will be implemented in task 3.2 (optional)
-- For now, it returns a default mode to support future integration
function M.detect_mode(colors)
  -- Placeholder implementation - always returns dark mode
  -- Task 3.2 will implement proper light/dark detection based on background brightness
  if not colors or not colors.background then
    return "dark"  -- Default fallback
  end
  
  -- TODO (Task 3.2): Implement brightness calculation
  -- - Parse hex background color to RGB values
  -- - Calculate luminance using standard formula
  -- - Return "light" if luminance > threshold, "dark" otherwise
  
  return "dark"  -- Placeholder return value
end

return M