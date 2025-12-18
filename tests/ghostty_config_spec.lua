-- Unit tests for ghostty_config.lua module
-- Tests CLI command execution, output parsing, and error handling

-- Mock vim functions for testing environment
local function setup_vim_mocks()
  if not _G.vim then
    _G.vim = {}
  end
  
  -- Mock vim.fn functions
  _G.vim.fn = _G.vim.fn or {}
  _G.vim.v = _G.vim.v or {}
  
  -- Mock vim.split function
  _G.vim.split = function(str, delimiter, opts)
    local result = {}
    local pattern = "([^" .. delimiter .. "]*)" .. delimiter .. "?"
    for match in str:gmatch(pattern) do
      if match ~= "" then
        table.insert(result, match)
      end
    end
    return result
  end
  
  -- Mock vim.trim function
  _G.vim.trim = function(str)
    return str:gsub("^%s*(.-)%s*$", "%1")
  end
end

-- Setup mocks before requiring the module
setup_vim_mocks()

-- Load the module under test
local ghostty_config = require('lua.chosttysync.ghostty_config')

-- Test helper functions
local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message or "Assertion failed", tostring(expected), tostring(actual)))
  end
end

local function assert_nil(value, message)
  if value ~= nil then
    error(string.format("%s: expected nil, got %s", message or "Assertion failed", tostring(value)))
  end
end

local function assert_not_nil(value, message)
  if value == nil then
    error(message or "Expected non-nil value")
  end
end

local function assert_table_equal(actual, expected, message)
  if type(actual) ~= "table" or type(expected) ~= "table" then
    error(string.format("%s: both values must be tables", message or "Table assertion failed"))
  end
  
  for k, v in pairs(expected) do
    if actual[k] ~= v then
      error(string.format("%s: key '%s' expected %s, got %s", message or "Table assertion failed", k, tostring(v), tostring(actual[k])))
    end
  end
  
  for k, v in pairs(actual) do
    if expected[k] == nil then
      error(string.format("%s: unexpected key '%s' with value %s", message or "Table assertion failed", k, tostring(v)))
    end
  end
end

-- Sample Ghostty configuration outputs for testing
local SAMPLE_CONFIGS = {
  valid_basic = [[
theme = dracula
background = #282a36
foreground = #f8f8f2
cursor-color = #f8f8f2
palette = 0=#21222c
palette = 1=#ff5555
palette = 2=#50fa7b
palette = 3=#f1fa8c
palette = 4=#bd93f9
palette = 5=#ff79c6
palette = 6=#8be9fd
palette = 7=#f8f8f2
palette = 8=#6272a4
palette = 9=#ff6e6e
palette = 10=#69ff94
palette = 11=#ffffa5
palette = 12=#d6acff
palette = 13=#ff92df
palette = 14=#a4ffff
palette = 15=#ffffff
]],
  
  valid_with_selection = [[
theme = nord
background = #2e3440
foreground = #d8dee9
cursor-color = #d8dee9
selection-background = #4c566a
selection-foreground = #eceff4
palette = 0=#3b4252
palette = 1=#bf616a
palette = 2=#a3be8c
palette = 3=#ebcb8b
]],
  
  minimal_config = [[
theme = minimal
background = #000000
foreground = #ffffff
]],
  
  with_comments = [[
# This is a comment
theme = test-theme
# Another comment
background = #123456
foreground = #abcdef
# More comments
palette = 0=#000000
]],
  
  with_quotes = [[
theme = "quoted-theme"
background = '#282a36'
foreground = "#f8f8f2"
]],
  
  malformed_lines = [[
theme = valid-theme
background = #282a36
invalid line without equals
= value without key
key without value =
foreground = #f8f8f2
]],
  
  empty_values = [[
theme = 
background = #282a36
foreground = 
cursor-color = #f8f8f2
]],
  
  rgb_colors = [[
theme = rgb-theme
background = rgb(40, 42, 54)
foreground = rgb(248, 248, 242)
cursor-color = rgb(248, 248, 242)
]]
}

-- Test suite for execute_show_config function
local function test_execute_show_config()
  print("Testing execute_show_config...")
  
  -- Test 1: Ghostty executable not found
  _G.vim.fn.executable = function(cmd)
    if cmd == 'ghostty' then
      return 0  -- Not found
    end
    return 1
  end
  
  local result, err = ghostty_config.execute_show_config()
  assert_nil(result, "Should return nil when ghostty not found")
  assert_equal(err, "Ghostty executable not found in PATH", "Should return appropriate error message")
  
  -- Test 2: Ghostty command execution failure
  _G.vim.fn.executable = function(cmd)
    return 1  -- Found
  end
  
  _G.vim.fn.system = function(cmd)
    return "Command failed"
  end
  
  _G.vim.v.shell_error = 1  -- Non-zero exit code
  
  result, err = ghostty_config.execute_show_config()
  assert_nil(result, "Should return nil when command fails")
  assert_not_nil(err, "Should return error message when command fails")
  
  -- Test 3: Empty output
  _G.vim.fn.system = function(cmd)
    return ""
  end
  
  _G.vim.v.shell_error = 0  -- Success
  
  result, err = ghostty_config.execute_show_config()
  assert_nil(result, "Should return nil for empty output")
  assert_equal(err, "Ghostty command returned empty output", "Should return appropriate error message")
  
  -- Test 4: Successful execution
  _G.vim.fn.system = function(cmd)
    return SAMPLE_CONFIGS.valid_basic
  end
  
  _G.vim.v.shell_error = 0  -- Success
  
  result, err = ghostty_config.execute_show_config()
  assert_not_nil(result, "Should return output on success")
  assert_nil(err, "Should not return error on success")
  assert_equal(result, SAMPLE_CONFIGS.valid_basic, "Should return the actual command output")
  
  print("✓ execute_show_config tests passed")
end

-- Test suite for parse_config_output function
local function test_parse_config_output()
  print("Testing parse_config_output...")
  
  -- Test 1: Nil input
  local config, err = ghostty_config.parse_config_output(nil)
  assert_nil(config, "Should return nil for nil input")
  assert_equal(err, "Empty or nil output provided", "Should return appropriate error message")
  
  -- Test 2: Empty string input
  config, err = ghostty_config.parse_config_output("")
  assert_nil(config, "Should return nil for empty input")
  assert_equal(err, "Empty or nil output provided", "Should return appropriate error message")
  
  -- Test 3: Non-string input
  config, err = ghostty_config.parse_config_output(123)
  assert_nil(config, "Should return nil for non-string input")
  assert_equal(err, "Output must be a string", "Should return appropriate error message")
  
  -- Test 4: Valid basic configuration
  config, err = ghostty_config.parse_config_output(SAMPLE_CONFIGS.valid_basic)
  assert_not_nil(config, "Should parse valid configuration")
  assert_nil(err, "Should not return error for valid config")
  assert_equal(config.theme, "dracula", "Should parse theme correctly")
  assert_equal(config.background, "#282a36", "Should parse background color")
  assert_equal(config.foreground, "#f8f8f2", "Should parse foreground color")
  assert_not_nil(config.palette_entries, "Should have palette entries")
  
  -- Test 5: Configuration with comments
  config, err = ghostty_config.parse_config_output(SAMPLE_CONFIGS.with_comments)
  assert_not_nil(config, "Should parse config with comments")
  assert_nil(err, "Should not return error for config with comments")
  assert_equal(config.theme, "test-theme", "Should ignore comments and parse theme")
  assert_equal(config.background, "#123456", "Should parse background ignoring comments")
  
  -- Test 6: Configuration with quotes
  config, err = ghostty_config.parse_config_output(SAMPLE_CONFIGS.with_quotes)
  assert_not_nil(config, "Should parse config with quotes")
  assert_nil(err, "Should not return error for config with quotes")
  assert_equal(config.theme, "quoted-theme", "Should remove quotes from theme")
  assert_equal(config.background, "#282a36", "Should remove quotes from background")
  
  -- Test 7: Malformed lines (should skip invalid lines)
  config, err = ghostty_config.parse_config_output(SAMPLE_CONFIGS.malformed_lines)
  assert_not_nil(config, "Should parse valid lines from malformed config")
  assert_nil(err, "Should not return error for partially malformed config")
  assert_equal(config.theme, "valid-theme", "Should parse valid theme line")
  assert_equal(config.background, "#282a36", "Should parse valid background line")
  assert_equal(config.foreground, "#f8f8f2", "Should parse valid foreground line")
  
  -- Test 8: Empty values (should skip empty values)
  config, err = ghostty_config.parse_config_output(SAMPLE_CONFIGS.empty_values)
  assert_not_nil(config, "Should parse config with some empty values")
  assert_nil(err, "Should not return error for config with empty values")
  assert_nil(config.theme, "Should skip empty theme value")
  assert_equal(config.background, "#282a36", "Should parse non-empty background")
  assert_nil(config.foreground, "Should skip empty foreground value")
  
  -- Test 9: Only comments and empty lines
  config, err = ghostty_config.parse_config_output("# Only comments\n\n# More comments\n")
  assert_nil(config, "Should return nil for config with only comments")
  assert_equal(err, "No valid configuration found in output", "Should return appropriate error message")
  
  print("✓ parse_config_output tests passed")
end

-- Test suite for extract_theme_info function
local function test_extract_theme_info()
  print("Testing extract_theme_info...")
  
  -- Test 1: Nil input
  local theme_info, err = ghostty_config.extract_theme_info(nil)
  assert_nil(theme_info, "Should return nil for nil input")
  assert_equal(err, "Invalid or empty configuration provided", "Should return appropriate error message")
  
  -- Test 2: Non-table input
  theme_info, err = ghostty_config.extract_theme_info("not a table")
  assert_nil(theme_info, "Should return nil for non-table input")
  assert_equal(err, "Invalid or empty configuration provided", "Should return appropriate error message")
  
  -- Test 3: Empty table
  theme_info, err = ghostty_config.extract_theme_info({})
  assert_nil(theme_info, "Should return nil for empty config")
  assert_equal(err, "No basic color information found in configuration", "Should return appropriate error message")
  
  -- Test 4: Valid basic configuration
  local basic_config = {
    theme = "test-theme",
    background = "#282a36",
    foreground = "#f8f8f2",
    ["cursor-color"] = "#f8f8f2",
    palette_entries = {"0=#21222c", "1=#ff5555", "2=#50fa7b"}
  }
  
  theme_info, err = ghostty_config.extract_theme_info(basic_config)
  assert_not_nil(theme_info, "Should extract theme info from valid config")
  assert_nil(err, "Should not return error for valid config")
  assert_equal(theme_info.name, "test-theme", "Should extract theme name")
  assert_equal(theme_info.colors.background, "#282a36", "Should extract background color")
  assert_equal(theme_info.colors.foreground, "#f8f8f2", "Should extract foreground color")
  assert_equal(theme_info.colors.cursor_color, "#f8f8f2", "Should extract cursor color")
  assert_not_nil(theme_info.colors.palette, "Should have palette colors")
  assert_equal(theme_info.colors.palette[0], "#21222c", "Should extract palette color 0")
  assert_equal(theme_info.colors.palette[1], "#ff5555", "Should extract palette color 1")
  
  -- Test 5: Configuration with selection colors
  local selection_config = {
    theme = "selection-theme",
    background = "#2e3440",
    foreground = "#d8dee9",
    ["selection-background"] = "#4c566a",
    ["selection-foreground"] = "#eceff4"
  }
  
  theme_info, err = ghostty_config.extract_theme_info(selection_config)
  assert_not_nil(theme_info, "Should extract theme info with selection colors")
  assert_nil(err, "Should not return error for config with selection colors")
  assert_equal(theme_info.colors.selection_background, "#4c566a", "Should extract selection background")
  assert_equal(theme_info.colors.selection_foreground, "#eceff4", "Should extract selection foreground")
  
  -- Test 6: Configuration with RGB colors
  local rgb_config = {
    theme = "rgb-theme",
    background = "rgb(40, 42, 54)",
    foreground = "rgb(248, 248, 242)"
  }
  
  theme_info, err = ghostty_config.extract_theme_info(rgb_config)
  assert_not_nil(theme_info, "Should extract theme info with RGB colors")
  assert_nil(err, "Should not return error for RGB colors")
  assert_equal(theme_info.colors.background, "#282a36", "Should normalize RGB background to hex")
  assert_equal(theme_info.colors.foreground, "#f8f8f2", "Should normalize RGB foreground to hex")
  
  -- Test 7: Configuration with 3-digit hex colors
  local short_hex_config = {
    theme = "short-hex",
    background = "#123",
    foreground = "#abc"
  }
  
  theme_info, err = ghostty_config.extract_theme_info(short_hex_config)
  assert_not_nil(theme_info, "Should extract theme info with 3-digit hex")
  assert_nil(err, "Should not return error for 3-digit hex")
  assert_equal(theme_info.colors.background, "#112233", "Should expand 3-digit hex background")
  assert_equal(theme_info.colors.foreground, "#aabbcc", "Should expand 3-digit hex foreground")
  
  -- Test 8: Configuration with invalid colors (should skip invalid ones)
  local invalid_color_config = {
    theme = "invalid-colors",
    background = "invalid-color",
    foreground = "#f8f8f2"  -- Valid color
  }
  
  theme_info, err = ghostty_config.extract_theme_info(invalid_color_config)
  assert_not_nil(theme_info, "Should extract valid colors and skip invalid ones")
  assert_nil(err, "Should not return error when some colors are valid")
  assert_nil(theme_info.colors.background, "Should skip invalid background color")
  assert_equal(theme_info.colors.foreground, "#f8f8f2", "Should extract valid foreground color")
  
  -- Test 9: Configuration with no theme name (should use default)
  local no_theme_config = {
    background = "#000000",
    foreground = "#ffffff"
  }
  
  theme_info, err = ghostty_config.extract_theme_info(no_theme_config)
  assert_not_nil(theme_info, "Should extract theme info without theme name")
  assert_nil(err, "Should not return error without theme name")
  assert_equal(theme_info.name, "unknown", "Should use default theme name")
  
  print("✓ extract_theme_info tests passed")
end

-- Test suite for get_theme_info function (integration test)
local function test_get_theme_info()
  print("Testing get_theme_info (integration)...")
  
  -- Test 1: Ghostty not found
  _G.vim.fn.executable = function(cmd)
    return 0  -- Not found
  end
  
  local theme_info, err = ghostty_config.get_theme_info()
  assert_nil(theme_info, "Should return nil when ghostty not found")
  assert_not_nil(err, "Should return error when ghostty not found")
  
  -- Test 2: Command execution failure
  _G.vim.fn.executable = function(cmd)
    return 1  -- Found
  end
  
  _G.vim.fn.system = function(cmd)
    return "Command failed"
  end
  
  _G.vim.v.shell_error = 1  -- Non-zero exit code
  
  theme_info, err = ghostty_config.get_theme_info()
  assert_nil(theme_info, "Should return nil when command fails")
  assert_not_nil(err, "Should return error when command fails")
  
  -- Test 3: Successful end-to-end execution
  _G.vim.fn.system = function(cmd)
    return SAMPLE_CONFIGS.valid_basic
  end
  
  _G.vim.v.shell_error = 0  -- Success
  
  theme_info, err = ghostty_config.get_theme_info()
  assert_not_nil(theme_info, "Should return theme info on success")
  assert_nil(err, "Should not return error on success")
  assert_equal(theme_info.name, "dracula", "Should extract correct theme name")
  assert_equal(theme_info.colors.background, "#282a36", "Should extract correct background")
  assert_not_nil(theme_info.colors.palette, "Should have palette colors")
  
  print("✓ get_theme_info tests passed")
end

-- Run all tests
local function run_all_tests()
  print("Running ghostty_config unit tests...")
  print("=" .. string.rep("=", 50))
  
  local success, error_msg = pcall(function()
    test_execute_show_config()
    test_parse_config_output()
    test_extract_theme_info()
    test_get_theme_info()
  end)
  
  if success then
    print("=" .. string.rep("=", 50))
    print("✓ All ghostty_config tests passed!")
    return true
  else
    print("=" .. string.rep("=", 50))
    print("✗ Test failed: " .. error_msg)
    return false
  end
end

-- Export test runner for external use
return {
  run_tests = run_all_tests,
  test_execute_show_config = test_execute_show_config,
  test_parse_config_output = test_parse_config_output,
  test_extract_theme_info = test_extract_theme_info,
  test_get_theme_info = test_get_theme_info
}