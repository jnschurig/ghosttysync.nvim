-- Ghostty Configuration Reader Module
-- Handles execution of Ghostty CLI and parsing of configuration output

local M = {}

-- Helper function to validate color format
local function is_valid_color(color)
  if not color or type(color) ~= "string" then
    return false
  end
  
  -- Check for hex color format (#RRGGBB or #RGB)
  if color:match("^#%x%x%x%x%x%x$") or color:match("^#%x%x%x$") then
    return true
  end
  
  -- Check for rgb() format
  if color:match("^rgb%(%d+,%s*%d+,%s*%d+%)$") then
    return true
  end
  
  return false
end

-- Helper function to normalize color values
local function normalize_color(color)
  if not color then
    return nil
  end
  
  -- Convert to string and trim
  color = tostring(color):gsub("^%s*(.-)%s*$", "%1")
  
  -- If it's already a valid hex color, return as-is
  if color:match("^#%x%x%x%x%x%x$") then
    return color
  end
  
  -- Convert 3-digit hex to 6-digit
  if color:match("^#%x%x%x$") then
    local r, g, b = color:match("^#(%x)(%x)(%x)$")
    return "#" .. r .. r .. g .. g .. b .. b
  end
  
  -- Handle rgb() format
  local r, g, b = color:match("^rgb%((%d+),%s*(%d+),%s*(%d+)%)$")
  if r and g and b then
    return string.format("#%02x%02x%02x", tonumber(r), tonumber(g), tonumber(b))
  end
  
  -- If we can't normalize it, return nil
  return nil
end

-- Execute `ghostty +show-config` command and return output
function M.execute_show_config()
  -- Check if we're in a test environment
  if not vim or not vim.fn or not vim.fn.executable then
    return nil, "Test environment: Ghostty CLI not available"
  end
  
  -- Check if ghostty command is available
  local ghostty_check = vim.fn.executable('ghostty')
  if ghostty_check == 0 then
    return nil, "Ghostty executable not found in PATH"
  end

  -- Execute the ghostty +show-config command
  local cmd = { 'ghostty', '+show-config' }
  local result = vim.fn.system(cmd)
  local exit_code = vim.v and vim.v.shell_error or 1

  -- Handle command execution errors
  if exit_code ~= 0 then
    local error_msg = string.format("Ghostty command failed with exit code %d: %s", exit_code, result)
    return nil, error_msg
  end

  -- Check if we got valid output
  if not result or result == "" then
    return nil, "Ghostty command returned empty output"
  end

  return result, nil
end

-- Helper function to split string (compatible with both vim and standalone lua)
local function split_string(str, delimiter)
  if vim and vim.split then
    return vim.split(str, delimiter, { plain = true })
  else
    local result = {}
    local pattern = "([^" .. delimiter .. "]*)" .. delimiter .. "?"
    for match in str:gmatch(pattern) do
      if match ~= "" then
        table.insert(result, match)
      end
    end
    return result
  end
end

-- Helper function to trim whitespace (compatible with both vim and standalone lua)
local function trim_string(str)
  if vim and vim.trim then
    return vim.trim(str)
  else
    return str:gsub("^%s*(.-)%s*$", "%1")
  end
end

-- Parse the CLI output from `ghostty +show-config`
function M.parse_config_output(output)
  if not output or output == "" then
    return nil, "Empty or nil output provided"
  end

  -- Handle case where output is not a string
  if type(output) ~= "string" then
    return nil, "Output must be a string"
  end

  local config = {}
  local palette_entries = {}  -- Special handling for palette entries
  local lines = split_string(output, '\n')
  
  for _, line in ipairs(lines) do
    -- Skip empty lines and comments
    line = trim_string(line)
    if line ~= "" and not line:match("^#") and not line:match("^%s*$") then
      -- Parse key = value format
      local key, value = line:match("^([^=]+)%s*=%s*(.*)$")
      if key and value then
        key = trim_string(key)
        value = trim_string(value)
        
        -- Remove quotes from values if present
        value = value:gsub("^[\"'](.+)[\"']$", "%1")
        
        -- Only add non-empty values
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
  
  -- Check if we parsed any configuration
  if next(config) == nil then
    return nil, "No valid configuration found in output"
  end
  
  return config, nil
end

-- Extract theme information from parsed configuration
function M.extract_theme_info(config)
  if not config or type(config) ~= "table" then
    return nil, "Invalid or empty configuration provided"
  end

  local theme_info = {
    name = nil,
    colors = {}
  }

  -- Extract theme name
  theme_info.name = config.theme or "unknown"

  -- Extract and normalize basic colors
  local background = normalize_color(config.background)
  local foreground = normalize_color(config.foreground)
  local cursor_color = normalize_color(config.cursor_color or config["cursor-color"])

  if background then
    theme_info.colors.background = background
  end
  if foreground then
    theme_info.colors.foreground = foreground
  end
  if cursor_color then
    theme_info.colors.cursor_color = cursor_color
  end

  -- Extract terminal color palette
  -- Ghostty uses format: palette = N=#color
  local palette = {}
  
  -- Process palette entries from the special palette_entries array
  if config.palette_entries then
    for _, entry in ipairs(config.palette_entries) do
      local color_num, color_value = entry:match("^(%d+)=(.+)$")
      if color_num and color_value then
        local normalized = normalize_color(color_value)
        if normalized then
          palette[tonumber(color_num)] = normalized
        end
      end
    end
  end
  
  -- If we have palette colors, add them to theme info
  if next(palette) then
    theme_info.colors.palette = palette
  end

  -- Extract selection colors if available
  local selection_bg = normalize_color(config.selection_background or config["selection-background"])
  local selection_fg = normalize_color(config.selection_foreground or config["selection-foreground"])
  
  if selection_bg then
    theme_info.colors.selection_background = selection_bg
  end
  if selection_fg then
    theme_info.colors.selection_foreground = selection_fg
  end

  -- Validate that we have at least basic colors
  if not theme_info.colors.background and not theme_info.colors.foreground then
    return nil, "No basic color information found in configuration"
  end

  return theme_info, nil
end

-- Main function to get theme information from Ghostty
-- Combines CLI execution, parsing, and theme extraction
function M.get_theme_info()
  -- Execute the CLI command
  local output, err = M.execute_show_config()
  if not output then
    return nil, "Failed to execute Ghostty CLI: " .. (err or "unknown error")
  end

  -- Parse the CLI output
  local config, parse_err = M.parse_config_output(output)
  if not config then
    return nil, "Failed to parse Ghostty configuration: " .. (parse_err or "unknown error")
  end

  -- Extract theme information
  local theme_info, extract_err = M.extract_theme_info(config)
  if not theme_info then
    return nil, "Failed to extract theme information: " .. (extract_err or "unknown error")
  end

  return theme_info, nil
end

return M