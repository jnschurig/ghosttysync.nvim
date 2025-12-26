-- Tests for theme_parser module
-- Tests the color extraction functions implemented in task 3.1

-- Add the lua directory to package path for testing
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local theme_parser = require("ghosttysync.theme_parser")

-- Test helper functions
local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error(
      string.format(
        "Assertion failed: %s\nExpected: %s\nActual: %s",
        message or "values should be equal",
        tostring(expected),
        tostring(actual)
      )
    )
  end
end

local function assert_not_nil(value, message)
  if value == nil then
    error(message or "Value should not be nil")
  end
end

local function assert_nil(value, message)
  if value ~= nil then
    error(message or "Value should be nil")
  end
end

-- Test parse_cli_output function
local function test_parse_cli_output()
  print("Testing parse_cli_output...")

  -- Test with valid CLI output
  local sample_output = [[
# Ghostty Configuration
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
]]

  local config, err = theme_parser.parse_cli_output(sample_output)
  assert_not_nil(config, "Should parse valid CLI output")
  assert_nil(err, "Should not return error for valid output")
  assert_equal(config.theme, "dracula", "Should extract theme name")
  assert_equal(config.background, "#282a36", "Should extract background color")
  assert_equal(config.foreground, "#f8f8f2", "Should extract foreground color")
  assert_equal(config["cursor-color"], "#f8f8f2", "Should extract cursor color")
  assert_not_nil(config.palette_entries, "Should extract palette entries")
  assert_equal(#config.palette_entries, 16, "Should have 16 palette entries")

  -- Test with empty output
  local empty_config, empty_err = theme_parser.parse_cli_output("")
  assert_nil(empty_config, "Should return nil for empty output")
  assert_not_nil(empty_err, "Should return error for empty output")

  -- Test with nil output
  local nil_config, nil_err = theme_parser.parse_cli_output(nil)
  assert_nil(nil_config, "Should return nil for nil output")
  assert_not_nil(nil_err, "Should return error for nil output")

  print("✓ parse_cli_output tests passed")
end

-- Test extract_colors function
local function test_extract_colors()
  print("Testing extract_colors...")

  -- Test with valid configuration data
  local config_data = {
    theme = "dracula",
    background = "#282a36",
    foreground = "#f8f8f2",
    ["cursor-color"] = "#f8f8f2",
    palette_entries = {
      "0=#21222c",
      "1=#ff5555",
      "2=#50fa7b",
      "3=#f1fa8c",
      "4=#bd93f9",
      "5=#ff79c6",
      "6=#8be9fd",
      "7=#f8f8f2",
      "8=#6272a4",
      "9=#ff6e6e",
      "10=#69ff94",
      "11=#ffffa5",
      "12=#d6acff",
      "13=#ff92df",
      "14=#a4ffff",
      "15=#ffffff",
    },
  }

  local colors, err = theme_parser.extract_colors(config_data)
  assert_not_nil(colors, "Should extract colors from valid config")
  assert_nil(err, "Should not return error for valid config")
  assert_equal(colors.background, "#282A36", "Should normalize background color to uppercase hex")
  assert_equal(colors.foreground, "#F8F8F2", "Should normalize foreground color to uppercase hex")
  assert_equal(colors.cursor, "#F8F8F2", "Should extract cursor color")
  assert_not_nil(colors.palette, "Should have palette")
  assert_equal(colors.palette[0], "#21222C", "Should extract palette color 0")
  assert_equal(colors.palette[15], "#FFFFFF", "Should extract palette color 15")

  -- Test with minimal configuration (only background)
  local minimal_config = {
    background = "#000000",
  }

  local minimal_colors, minimal_err = theme_parser.extract_colors(minimal_config)
  assert_not_nil(minimal_colors, "Should handle minimal config")
  assert_nil(minimal_err, "Should not error on minimal config")
  assert_equal(minimal_colors.background, "#000000", "Should extract background")
  assert_equal(minimal_colors.foreground, "#FFFFFF", "Should default foreground")
  assert_equal(minimal_colors.cursor, "#FFFFFF", "Should default cursor to foreground")

  -- Test color normalization with different formats
  local rgb_config = {
    background = "rgb(40, 42, 54)",
    foreground = "#f8f", -- 3-digit hex
    ["cursor-color"] = "rgba(248, 248, 242, 0.9)", -- rgba format
  }

  local rgb_colors, rgb_err = theme_parser.extract_colors(rgb_config)
  assert_not_nil(rgb_colors, "Should handle different color formats")
  assert_equal(rgb_colors.background, "#282A36", "Should convert rgb() to hex")
  assert_equal(rgb_colors.foreground, "#FF88FF", "Should convert 3-digit hex to 6-digit")
  assert_equal(rgb_colors.cursor, "#F8F8F2", "Should convert rgba() to hex")

  -- Test with invalid configuration
  local invalid_colors, invalid_err = theme_parser.extract_colors(nil)
  assert_nil(invalid_colors, "Should return nil for invalid config")
  assert_not_nil(invalid_err, "Should return error for invalid config")

  -- Test with empty configuration
  local empty_colors, empty_err = theme_parser.extract_colors({})
  assert_not_nil(empty_colors, "Should handle empty config with defaults")
  assert_equal(empty_colors.background, "#000000", "Should use default background")
  assert_equal(empty_colors.foreground, "#FFFFFF", "Should use default foreground")

  print("✓ extract_colors tests passed")
end

-- Test detect_mode function (placeholder)
local function test_detect_mode()
  print("Testing detect_mode (placeholder)...")

  -- Test with dark background
  local dark_colors = {
    background = "#282a36",
    foreground = "#f8f8f2",
  }

  local dark_mode = theme_parser.detect_mode(dark_colors)
  assert_equal(dark_mode, "dark", "Should return dark mode (placeholder)")

  -- Test with light background (should still return dark in placeholder)
  local light_colors = {
    background = "#ffffff",
    foreground = "#000000",
  }

  local light_mode = theme_parser.detect_mode(light_colors)
  assert_equal(light_mode, "dark", "Should return dark mode (placeholder implementation)")

  -- Test with nil colors
  local nil_mode = theme_parser.detect_mode(nil)
  assert_equal(nil_mode, "dark", "Should return dark mode for nil input")

  print("✓ detect_mode tests passed (placeholder implementation)")
end

-- Run all tests
local function run_all_tests()
  print("Running theme_parser unit tests...")
  print("===================================================")

  test_parse_cli_output()
  test_extract_colors()
  test_detect_mode()

  print("===================================================")
  print("✓ All theme_parser tests passed!")
end

-- Execute tests if this file is run directly
if arg and arg[0] and arg[0]:match("theme_parser_spec%.lua$") then
  run_all_tests()
end

-- Export test functions for use by other test runners
return {
  run_all_tests = run_all_tests,
  test_parse_cli_output = test_parse_cli_output,
  test_extract_colors = test_extract_colors,
  test_detect_mode = test_detect_mode,
}

