-- Color Mapper Module
-- Maps Ghostty terminal colors to Neovim highlight groups

local M = {}

-- Example highlight group mapping structure
-- This serves as documentation for the expected highlight map format
M.HighlightMap = {
  -- Core highlight groups
  Normal = { fg = "#ffffff", bg = "#000000" },
  Comment = { fg = "#808080", italic = true },
  
  -- Syntax highlighting groups
  Keyword = { fg = "#ff6b6b", bold = true },
  Conditional = { fg = "#ff6b6b" },
  String = { fg = "#4ecdc4" },
  Function = { fg = "#45b7d1" },
  Variable = { fg = "#ffffff" },
  Type = { fg = "#96ceb4" },
  Number = { fg = "#feca57" },
  Identifier = { fg = "#ffffff" },
  Constant = { fg = "#ff00ff" },
  Special = { fg = "#80ffff" },
  Statement = { fg = "#ff8080" },
  PreProc = { fg = "#ff80ff" },
  Operator = { fg = "#ffffff" },
  
  -- Diagnostic highlight groups (modern)
  DiagnosticError = { fg = "#ff8080" },
  DiagnosticWarn = { fg = "#ffff80" },
  DiagnosticHint = { fg = "#80ffff" },
  DiagnosticInfo = { fg = "#8080ff" },
  
  -- Legacy diagnostic highlight groups
  Error = { fg = "#ff6b6b", bg = "#2d1b1b" },
  Warning = { fg = "#feca57", bg = "#2d2a1b" },
  Hint = { fg = "#4ecdc4", bg = "#1b2d2a" },
  Note = { fg = "#45b7d1", bg = "#1b252d" },
  
  -- UI elements
  Cursor = { fg = "#000000", bg = "#ffffff" },
  CursorLine = { bg = "#000000" },
  Visual = { bg = "#808080" },
  Search = { fg = "#000000", bg = "#ffff00" },
}

-- Create highlight group mappings from Ghostty colors
function M.create_highlight_map(colors, mode)
  if not colors or type(colors) ~= "table" then
    return nil, "Invalid colors provided"
  end
  
  -- Validate and normalize colors first
  local valid, validated_colors = M.validate_colors(colors)
  if not valid then
    return nil, "Color validation failed: " .. (validated_colors or "unknown error")
  end
  
  -- Default mode to dark if not provided
  mode = mode or "dark"
  
  -- Apply contrast adjustments for readability
  local adjusted_colors = M.adjust_contrast(validated_colors, mode)
  
  -- Extract essential colors with fallbacks
  local bg = adjusted_colors.background or "#000000"
  local fg = adjusted_colors.foreground or "#FFFFFF"
  local cursor = adjusted_colors.cursor or fg
  local palette = adjusted_colors.palette or {}
  
  -- Create base highlight map
  local highlight_map = {}
  
  -- Core Neovim highlight groups
  highlight_map.Normal = { fg = fg, bg = bg }
  highlight_map.Comment = { 
    fg = palette[8] or "#808080",  -- Use bright black for comments
    italic = true 
  }
  
  -- Syntax highlighting groups
  highlight_map.Keyword = { 
    fg = palette[1] or "#FF0000",  -- Red for keywords
    bold = true 
  }
  highlight_map.Conditional = { 
    fg = palette[1] or "#FF0000"   -- Red for conditionals (if, else, etc.)
  }
  highlight_map.String = { 
    fg = palette[2] or "#00FF00"   -- Green for strings
  }
  highlight_map.Function = { 
    fg = palette[4] or "#0000FF"   -- Blue for functions
  }
  highlight_map.Variable = { 
    fg = fg                        -- Use foreground color for variables
  }
  highlight_map.Type = { 
    fg = palette[6] or "#00FFFF"   -- Cyan for types
  }
  highlight_map.Number = { 
    fg = palette[3] or "#FFFF00"   -- Yellow for numbers
  }
  
  -- Additional syntax groups
  highlight_map.Identifier = { 
    fg = fg                        -- Use foreground for identifiers
  }
  highlight_map.Constant = { 
    fg = palette[5] or "#FF00FF"   -- Magenta for constants
  }
  highlight_map.Special = { 
    fg = palette[14] or "#80FFFF"  -- Bright cyan for special characters
  }
  highlight_map.Statement = { 
    fg = palette[9] or "#FF8080"   -- Bright red for statements
  }
  highlight_map.PreProc = { 
    fg = palette[13] or "#FF80FF"  -- Bright magenta for preprocessor
  }
  highlight_map.Operator = { 
    fg = palette[7] or "#FFFFFF"   -- White for operators
  }
  
  -- Diagnostic highlight groups with background colors for visibility
  highlight_map.DiagnosticError = { 
    fg = palette[9] or "#FF8080"   -- Bright red for errors
  }
  highlight_map.DiagnosticWarn = { 
    fg = palette[11] or "#FFFF80"  -- Bright yellow for warnings
  }
  highlight_map.DiagnosticHint = { 
    fg = palette[14] or "#80FFFF"  -- Bright cyan for hints
  }
  highlight_map.DiagnosticInfo = { 
    fg = palette[12] or "#8080FF"  -- Bright blue for info
  }
  
  -- Legacy diagnostic names for compatibility
  highlight_map.Error = { 
    fg = palette[9] or "#FF8080",
    bg = "#2D1B1B"                 -- Dark red background
  }
  highlight_map.Warning = { 
    fg = palette[11] or "#FFFF80",
    bg = "#2D2A1B"                 -- Dark yellow background
  }
  highlight_map.Hint = { 
    fg = palette[14] or "#80FFFF",
    bg = "#1B2D2A"                 -- Dark cyan background
  }
  highlight_map.Note = { 
    fg = palette[12] or "#8080FF",
    bg = "#1B252D"                 -- Dark blue background
  }
  
  -- UI elements
  highlight_map.Cursor = { 
    fg = bg, 
    bg = cursor 
  }
  highlight_map.CursorLine = { 
    bg = palette[0] or "#000000"   -- Slightly different background for cursor line
  }
  highlight_map.Visual = { 
    bg = palette[8] or "#808080"   -- Gray background for visual selection
  }
  highlight_map.Search = { 
    fg = bg,
    bg = palette[3] or "#FFFF00"   -- Yellow background for search
  }
  
  -- Apply mode-specific adjustments (placeholder for future enhancement)
  highlight_map = M.apply_mode_adjustments(highlight_map, mode)
  
  return highlight_map, nil
end

-- Validate color values before applying to Neovim
function M.validate_colors(colors)
  if not colors or type(colors) ~= "table" then
    return false, "Colors must be a table"
  end
  
  local validated_colors = {}
  
  -- Validate and normalize individual color values
  for key, value in pairs(colors) do
    if key == "palette" and type(value) == "table" then
      -- Validate palette colors
      validated_colors.palette = {}
      for i, color in pairs(value) do
        local normalized = M._normalize_color(color)
        if normalized then
          validated_colors.palette[i] = normalized
        end
      end
    else
      -- Validate individual color values (background, foreground, cursor)
      local normalized = M._normalize_color(value)
      if normalized then
        validated_colors[key] = normalized
      end
    end
  end
  
  -- Ensure we have at least basic colors with fallbacks
  validated_colors.background = validated_colors.background or "#000000"
  validated_colors.foreground = validated_colors.foreground or "#FFFFFF"
  validated_colors.cursor = validated_colors.cursor or validated_colors.foreground
  validated_colors.palette = validated_colors.palette or {}
  
  return true, validated_colors
end

-- Internal function to normalize and validate individual color values
function M._normalize_color(color)
  if not color or type(color) ~= "string" then
    return nil
  end
  
  -- Remove whitespace
  color = color:gsub("%s+", "")
  
  -- Handle different color formats
  if color:match("^#[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$") then
    -- 3-digit hex: #RGB -> #RRGGBB
    local r, g, b = color:match("^#([0-9a-fA-F])([0-9a-fA-F])([0-9a-fA-F])$")
    return ("#" .. r .. r .. g .. g .. b .. b):upper()
  elseif color:match("^#[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$") then
    -- 6-digit hex: #RRGGBB (already valid)
    return color:upper()
  elseif color:match("^rgb%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*%)$") then
    -- RGB format: rgb(r, g, b)
    local r, g, b = color:match("^rgb%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*%)$")
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    if r and g and b and r >= 0 and r <= 255 and g >= 0 and g <= 255 and b >= 0 and b <= 255 then
      return string.format("#%02X%02X%02X", r, g, b)
    end
  elseif color:match("^0x[0-9a-fA-F]+$") then
    -- Hex with 0x prefix
    local hex = color:sub(3)
    if #hex == 3 then
      local r, g, b = hex:match("^([0-9a-fA-F])([0-9a-fA-F])([0-9a-fA-F])$")
      return ("#" .. r .. r .. g .. g .. b .. b):upper()
    elseif #hex == 6 then
      return "#" .. hex:upper()
    end
  end
  
  -- Invalid color format
  return nil
end

-- Adjust colors for better contrast and readability
function M.adjust_contrast(colors, mode)
  if not colors or type(colors) ~= "table" then
    return colors
  end
  
  mode = mode or "dark"
  local adjusted_colors = {}
  
  -- Copy all colors first
  for key, value in pairs(colors) do
    if key == "palette" and type(value) == "table" then
      adjusted_colors.palette = {}
      for i, color in pairs(value) do
        adjusted_colors.palette[i] = color
      end
    else
      adjusted_colors[key] = value
    end
  end
  
  -- Apply contrast adjustments based on mode
  if mode == "light" then
    -- For light mode, ensure text is dark enough for readability
    adjusted_colors.foreground = M._ensure_min_contrast(adjusted_colors.foreground, adjusted_colors.background, 4.5)
    
    -- Adjust palette colors for light backgrounds
    if adjusted_colors.palette then
      for i, color in pairs(adjusted_colors.palette) do
        if i >= 0 and i <= 7 then -- Standard colors
          adjusted_colors.palette[i] = M._darken_color(color, 0.3)
        elseif i >= 8 and i <= 15 then -- Bright colors
          adjusted_colors.palette[i] = M._darken_color(color, 0.2)
        end
      end
    end
  else
    -- For dark mode, ensure text is light enough for readability
    adjusted_colors.foreground = M._ensure_min_contrast(adjusted_colors.foreground, adjusted_colors.background, 4.5)
    
    -- Adjust palette colors for dark backgrounds
    if adjusted_colors.palette then
      for i, color in pairs(adjusted_colors.palette) do
        if i >= 0 and i <= 7 then -- Standard colors
          adjusted_colors.palette[i] = M._lighten_color(color, 0.2)
        elseif i >= 8 and i <= 15 then -- Bright colors
          adjusted_colors.palette[i] = M._lighten_color(color, 0.1)
        end
      end
    end
  end
  
  return adjusted_colors
end

-- Internal function to ensure minimum contrast ratio between two colors
function M._ensure_min_contrast(fg_color, bg_color, min_ratio)
  if not fg_color or not bg_color then
    return fg_color
  end
  
  local fg_luminance = M._get_luminance(fg_color)
  local bg_luminance = M._get_luminance(bg_color)
  
  if not fg_luminance or not bg_luminance then
    return fg_color
  end
  
  local contrast = M._calculate_contrast_ratio(fg_luminance, bg_luminance)
  
  if contrast >= min_ratio then
    return fg_color -- Already has sufficient contrast
  end
  
  -- Adjust foreground color to meet minimum contrast
  if bg_luminance > 0.5 then
    -- Light background, darken foreground
    return M._darken_color(fg_color, 0.5)
  else
    -- Dark background, lighten foreground
    return M._lighten_color(fg_color, 0.5)
  end
end

-- Internal function to calculate relative luminance of a color
function M._get_luminance(color)
  if not color or type(color) ~= "string" then
    return nil
  end
  
  local r, g, b = color:match("^#([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])$")
  if not r or not g or not b then
    return nil
  end
  
  r = tonumber(r, 16) / 255
  g = tonumber(g, 16) / 255
  b = tonumber(b, 16) / 255
  
  -- Apply gamma correction
  local function gamma_correct(c)
    if c <= 0.03928 then
      return c / 12.92
    else
      return math.pow((c + 0.055) / 1.055, 2.4)
    end
  end
  
  r = gamma_correct(r)
  g = gamma_correct(g)
  b = gamma_correct(b)
  
  -- Calculate relative luminance
  return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

-- Internal function to calculate contrast ratio between two luminance values
function M._calculate_contrast_ratio(l1, l2)
  local lighter = math.max(l1, l2)
  local darker = math.min(l1, l2)
  return (lighter + 0.05) / (darker + 0.05)
end

-- Internal function to lighten a color by a given factor
function M._lighten_color(color, factor)
  if not color or type(color) ~= "string" or not factor then
    return color
  end
  
  local r, g, b = color:match("^#([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])$")
  if not r or not g or not b then
    return color
  end
  
  r = tonumber(r, 16)
  g = tonumber(g, 16)
  b = tonumber(b, 16)
  
  -- Lighten by moving towards white
  r = math.min(255, math.floor(r + (255 - r) * factor))
  g = math.min(255, math.floor(g + (255 - g) * factor))
  b = math.min(255, math.floor(b + (255 - b) * factor))
  
  return string.format("#%02X%02X%02X", r, g, b)
end

-- Internal function to darken a color by a given factor
function M._darken_color(color, factor)
  if not color or type(color) ~= "string" or not factor then
    return color
  end
  
  local r, g, b = color:match("^#([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])$")
  if not r or not g or not b then
    return color
  end
  
  r = tonumber(r, 16)
  g = tonumber(g, 16)
  b = tonumber(b, 16)
  
  -- Darken by moving towards black
  r = math.max(0, math.floor(r * (1 - factor)))
  g = math.max(0, math.floor(g * (1 - factor)))
  b = math.max(0, math.floor(b * (1 - factor)))
  
  return string.format("#%02X%02X%02X", r, g, b)
end

-- Apply mode-specific color adjustments
-- PLACEHOLDER: This function provides a foundation for future mode-specific adjustments
-- Task 3.2 will implement proper light/dark mode detection and adjustments
function M.apply_mode_adjustments(highlight_map, mode)
  if not highlight_map or type(highlight_map) ~= "table" then
    return highlight_map
  end
  
  -- Default mode to dark if not provided
  mode = mode or "dark"
  
  -- PLACEHOLDER: Currently returns the highlight map unchanged
  -- Future implementation (task 3.2) will:
  -- - Adjust contrast for light mode themes
  -- - Modify background colors for better readability
  -- - Apply brightness adjustments based on detected mode
  -- - Handle edge cases for very light or very dark themes
  
  -- For now, we simply return the original highlight map
  -- This ensures the function is callable and doesn't break the flow
  return highlight_map
end

return M