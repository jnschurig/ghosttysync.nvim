# GhosttySync Unit Tests

This directory contains unit tests for the GhosttySync Neovim plugin.

## Running Tests

### Prerequisites

- Lua interpreter (lua or luajit)
- The GhosttySync plugin source code

### Running All Tests

From the project root directory:

```bash
# Using the test runner script
./run_tests.sh

# Or directly with lua
lua tests/run_tests.lua
```

### Running Individual Test Suites

You can also run individual test functions by requiring the test modules in a Lua REPL:

```lua
-- Load the ghostty_config tests
local tests = require('tests.ghostty_config_spec')

-- Run all tests
tests.run_tests()

-- Or run individual test functions
tests.test_execute_show_config()
tests.test_parse_config_output()
tests.test_extract_theme_info()
tests.test_get_theme_info()
```

## Test Coverage

### ghostty_config_spec.lua

Tests for the `lua/ghosttysync/ghostty_config.lua` module:

#### CLI Command Execution Tests (`test_execute_show_config`)
- ✅ Ghostty executable not found in PATH
- ✅ Command execution failure (non-zero exit code)
- ✅ Empty command output
- ✅ Successful command execution

#### Configuration Parsing Tests (`test_parse_config_output`)
- ✅ Nil and empty input handling
- ✅ Non-string input validation
- ✅ Valid basic configuration parsing
- ✅ Configuration with comments
- ✅ Configuration with quoted values
- ✅ Malformed lines (graceful handling)
- ✅ Empty values (skipping)
- ✅ Comments-only configuration

#### Theme Information Extraction Tests (`test_extract_theme_info`)
- ✅ Invalid input handling (nil, non-table)
- ✅ Empty configuration handling
- ✅ Valid basic configuration extraction
- ✅ Selection colors extraction
- ✅ RGB color normalization
- ✅ 3-digit hex color expansion
- ✅ Invalid color handling (graceful skipping)
- ✅ Missing theme name (default fallback)

#### Integration Tests (`test_get_theme_info`)
- ✅ End-to-end error handling
- ✅ Complete successful workflow
- ✅ Error propagation through the pipeline

## Test Data

The tests use sample Ghostty configuration outputs that cover various scenarios:

- `valid_basic`: Complete configuration with theme and palette
- `valid_with_selection`: Configuration with selection colors
- `minimal_config`: Minimal valid configuration
- `with_comments`: Configuration with comment lines
- `with_quotes`: Configuration with quoted values
- `malformed_lines`: Configuration with some invalid lines
- `empty_values`: Configuration with empty values
- `rgb_colors`: Configuration using RGB color format

## Error Scenarios Tested

The tests comprehensively cover error handling for:

1. **Missing Ghostty executable**: When `ghostty` command is not found in PATH
2. **Command execution failures**: When `ghostty +show-config` fails
3. **Empty or invalid output**: When the command returns no usable data
4. **Malformed configuration**: When the output contains invalid lines
5. **Invalid color formats**: When colors cannot be parsed or normalized
6. **Missing required data**: When essential configuration is absent

## Requirements Coverage

These tests fulfill the requirements specified in task 2.3:

- ✅ **Test CLI command execution with various scenarios**: Covered by `test_execute_show_config`
- ✅ **Test output parsing with sample Ghostty configurations**: Covered by `test_parse_config_output`
- ✅ **Test error handling for missing Ghostty or invalid output**: Covered across all test functions
- ✅ **Requirements 2.1, 2.2**: Error handling and graceful fallbacks are thoroughly tested