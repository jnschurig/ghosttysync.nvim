#!/bin/bash

# Test runner script for GhosttySync plugin
# Runs unit tests for the configuration reader module

echo "Running GhosttySync unit tests..."
echo

# Check if lua is available
if ! command -v lua &> /dev/null; then
    echo "Error: lua command not found. Please install Lua to run tests."
    exit 1
fi

# Run the ghostty_config tests
echo "Testing ghostty_config module..."
lua tests/run_tests.lua

exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo
    echo "All tests completed successfully!"
else
    echo
    echo "Some tests failed. Please check the output above."
fi

exit $exit_code