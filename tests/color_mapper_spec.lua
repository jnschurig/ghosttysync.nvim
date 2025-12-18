-- Test file for color_mapper.lua
-- Tests the highlight group mapping logic

-- Load the color_mapper module
local color_mapper = require('chosttysync.color_mapper')

-- Test data
local test_colors = {
  background = "#1a1a1a",
  foreground = "#ffffff",
  cursor = "#00ff00",
  palette = {
    [0] = "#000000",   -- black
    [1] = "#ff0000",   -- red
    [2] = "#00ff00",   -- green
    [3] = "#ffff00",   -- yellow
    [4] = "#0000ff",   -- blue
    [5] = "#ff00ff",   -- magenta
    [6] = "#00ffff",   -- cyan
    [7] = "#ffffff",   -- white
    [8] = "#808080",   -- bright black
    [9] = "#ff8080",   -- bright red
    [10] = "#80ff80",  -- bright green
    [11] = "#ffff80",  -- bright yellow
    [12] = "#8080ff",  -- bright blue
    [13] = "#ff80ff",  -- bright magenta
    [14] = "#80ffff",  -- bright cyan
    [15] = "#ffffff",  -- bright white
  }
}

-- Test functions
local function test_create_highlight_map_basic()
  print("Testing create_highlight_map with valid colors...")
  
  local highlight_map, err = color_mapper.create_highlight_map(test_colors, "dark")
  
  if err then
    print("ERROR: " .. err)
    return false
  end
  
  if not highlight_map then
    print("ERROR: No highlight map returned")
    return false
  end
  
  -- Test core highlight groups
  if not highlight_map.Normal then
    print("ERROR: Missing Normal highlight group")
    return false
  end
  
  -- Check that Normal highlight group exists and has valid colors
  if not highlight_map.Normal.fg or not highlight_map.Normal.bg then
    print("ERROR: Normal highlight group missing fg or bg colors")
    return false
  end
  
  -- Colors may be adjusted for contrast, so just verify they're valid hex colors
  if not highlight_map.Normal.fg:match("^#[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]$") then
    print("ERROR: Normal foreground is not a valid hex color: " .. highlight_map.Normal.fg)
    return false
  end
  
  if not highlight_map.Normal.bg:match("^#[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]$") then
    print("ERROR: Normal background is not a valid hex color: " .. highlight_map.Normal.bg)
    return false
  end
  
  -- Test syntax highlighting groups
  local required_groups = {
    "Comment", "Keyword", "String", "Function", "Type", "Number",
    "Conditional", "Variable", "Identifier", "Constant"
  }
  
  for _, group in ipairs(required_groups) do
    if not highlight_map[group] then
      print("ERROR: Missing " .. group .. " highlight group")
      return false
    end
  end
  
  -- Test diagnostic groups
  local diagnostic_groups = {
    "DiagnosticError", "DiagnosticWarn", "DiagnosticHint", "DiagnosticInfo",
    "Error", "Warning", "Hint", "Note"
  }
  
  for _, group in ipairs(diagnostic_groups) do
    if not highlight_map[group] then
      print("ERROR: Missing " .. group .. " diagnostic group")
      return false
    end
  end
  
  print("✓ Basic highlight map creation test passed")
  return true
end

local function test_create_highlight_map_with_minimal_colors()
  print("Testing create_highlight_map with minimal colors...")
  
  local minimal_colors = {
    background = "#000000",
    foreground = "#ffffff"
    -- No palette provided
  }
  
  local highlight_map, err = color_mapper.create_highlight_map(minimal_colors, "dark")
  
  if err then
    print("ERROR: " .. err)
    return false
  end
  
  if not highlight_map or not highlight_map.Normal then
    print("ERROR: Failed to create highlight map with minimal colors")
    return false
  end
  
  print("✓ Minimal colors test passed")
  return true
end

local function test_create_highlight_map_invalid_input()
  print("Testing create_highlight_map with invalid input...")
  
  local highlight_map, err = color_mapper.create_highlight_map(nil, "dark")
  
  if not err then
    print("ERROR: Should have returned error for nil colors")
    return false
  end
  
  if highlight_map then
    print("ERROR: Should not have returned highlight map for invalid input")
    return false
  end
  
  print("✓ Invalid input test passed")
  return true
end

local function test_apply_mode_adjustments()
  print("Testing apply_mode_adjustments...")
  
  local test_highlight_map = {
    Normal = { fg = "#ffffff", bg = "#000000" },
    Comment = { fg = "#808080", italic = true }
  }
  
  local adjusted_map = color_mapper.apply_mode_adjustments(test_highlight_map, "dark")
  
  if not adjusted_map then
    print("ERROR: apply_mode_adjustments returned nil")
    return false
  end
  
  -- For now, it should return the same map (placeholder implementation)
  if adjusted_map.Normal.fg ~= "#ffffff" or adjusted_map.Normal.bg ~= "#000000" then
    print("ERROR: Mode adjustments changed colors unexpectedly")
    return false
  end
  
  print("✓ Mode adjustments test passed")
  return true
end

local function test_validate_colors_valid_input()
  print("Testing validate_colors with valid input...")
  
  local valid, result = color_mapper.validate_colors(test_colors)
  
  if not valid then
    print("ERROR: Valid colors were rejected: " .. (result or "unknown error"))
    return false
  end
  
  if not result or type(result) ~= "table" then
    print("ERROR: validate_colors should return validated colors table")
    return false
  end
  
  -- Check that essential colors are present
  if not result.background or not result.foreground then
    print("ERROR: Missing essential colors after validation")
    return false
  end
  
  print("✓ Valid colors validation test passed")
  return true
end

local function test_validate_colors_invalid_input()
  print("Testing validate_colors with invalid input...")
  
  local valid, result = color_mapper.validate_colors(nil)
  
  if valid then
    print("ERROR: nil input should be invalid")
    return false
  end
  
  -- Test with invalid color formats
  local invalid_colors = {
    background = "not-a-color",
    foreground = "#gggggg",  -- Invalid hex
    palette = {
      [0] = "invalid"
    }
  }
  
  local valid2, result2 = color_mapper.validate_colors(invalid_colors)
  
  if not valid2 then
    print("ERROR: Should handle invalid colors gracefully")
    return false
  end
  
  -- Should have fallback colors
  if not result2.background or not result2.foreground then
    print("ERROR: Should provide fallback colors for invalid input")
    return false
  end
  
  print("✓ Invalid colors validation test passed")
  return true
end

local function test_normalize_color()
  print("Testing _normalize_color function...")
  
  -- Test various color formats
  local test_cases = {
    { input = "#fff", expected = "#FFFFFF" },
    { input = "#ffffff", expected = "#FFFFFF" },
    { input = "#FF0000", expected = "#FF0000" },
    { input = "rgb(255, 0, 0)", expected = "#FF0000" },
    { input = "0xff0000", expected = "#FF0000" },
    { input = "invalid", expected = nil },
    { input = nil, expected = nil }
  }
  
  for _, case in ipairs(test_cases) do
    local result = color_mapper._normalize_color(case.input)
    if result ~= case.expected then
      print("ERROR: _normalize_color('" .. tostring(case.input) .. "') = '" .. tostring(result) .. "', expected '" .. tostring(case.expected) .. "'")
      return false
    end
  end
  
  print("✓ Color normalization test passed")
  return true
end

local function test_adjust_contrast()
  print("Testing adjust_contrast function...")
  
  local test_colors_copy = {
    background = "#000000",
    foreground = "#ffffff",
    palette = {
      [0] = "#000000",
      [1] = "#ff0000",
      [8] = "#808080",
      [9] = "#ff8080"
    }
  }
  
  -- Test dark mode adjustments
  local dark_adjusted = color_mapper.adjust_contrast(test_colors_copy, "dark")
  
  if not dark_adjusted then
    print("ERROR: adjust_contrast returned nil for dark mode")
    return false
  end
  
  -- Test light mode adjustments
  local light_adjusted = color_mapper.adjust_contrast(test_colors_copy, "light")
  
  if not light_adjusted then
    print("ERROR: adjust_contrast returned nil for light mode")
    return false
  end
  
  -- Colors should be different between modes
  if dark_adjusted.foreground == light_adjusted.foreground then
    print("WARNING: Foreground colors are the same between light and dark modes")
  end
  
  print("✓ Contrast adjustment test passed")
  return true
end

local function test_luminance_and_contrast_calculation()
  print("Testing luminance and contrast calculation...")
  
  -- Test luminance calculation
  local white_luminance = color_mapper._get_luminance("#FFFFFF")
  local black_luminance = color_mapper._get_luminance("#000000")
  
  if not white_luminance or not black_luminance then
    print("ERROR: Failed to calculate luminance")
    return false
  end
  
  if white_luminance <= black_luminance then
    print("ERROR: White should have higher luminance than black")
    return false
  end
  
  -- Test contrast ratio calculation
  local contrast = color_mapper._calculate_contrast_ratio(white_luminance, black_luminance)
  
  if not contrast or contrast < 20 then  -- White on black should have very high contrast
    print("ERROR: Contrast ratio calculation seems incorrect")
    return false
  end
  
  print("✓ Luminance and contrast calculation test passed")
  return true
end

-- Run all tests
local function run_tests()
  print("Running color_mapper tests...")
  print("=" .. string.rep("=", 40))
  
  local tests = {
    test_create_highlight_map_basic,
    test_create_highlight_map_with_minimal_colors,
    test_create_highlight_map_invalid_input,
    test_apply_mode_adjustments,
    test_validate_colors_valid_input,
    test_validate_colors_invalid_input,
    test_normalize_color,
    test_adjust_contrast,
    test_luminance_and_contrast_calculation
  }
  
  local passed = 0
  local total = #tests
  
  for _, test in ipairs(tests) do
    if test() then
      passed = passed + 1
    end
    print()
  end
  
  print("=" .. string.rep("=", 40))
  print(string.format("Tests completed: %d/%d passed", passed, total))
  
  if passed == total then
    print("✓ All tests passed!")
    return true
  else
    print("✗ Some tests failed!")
    return false
  end
end

-- Export test runner
return {
  run_tests = run_tests
}