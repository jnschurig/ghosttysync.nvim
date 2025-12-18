#!/usr/bin/env lua

-- Simple test runner for ghostty_config tests
-- Can be run with: lua tests/run_tests.lua

-- Add the project root to the Lua path so we can require modules
local project_root = arg[0]:match("(.*/)")
if project_root then
  package.path = project_root .. "../?.lua;" .. package.path
else
  package.path = "../?.lua;" .. package.path
end

-- Load and run the tests
local ghostty_config_tests = require('tests.ghostty_config_spec')
local theme_parser_tests = require('tests.theme_parser_spec')
local color_mapper_tests = require('tests.color_mapper_spec')
local nvim_applier_tests = require('tests.nvim_applier_spec')

-- Run the tests
local ghostty_success = ghostty_config_tests.run_tests()
local theme_parser_success = theme_parser_tests.run_all_tests()
local color_mapper_success = color_mapper_tests.run_tests()
local nvim_applier_success = nvim_applier_tests.run_tests()

-- Exit with appropriate code
local overall_success = ghostty_success and theme_parser_success and color_mapper_success and nvim_applier_success
os.exit(overall_success and 0 or 1)