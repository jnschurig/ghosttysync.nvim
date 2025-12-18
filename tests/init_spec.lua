-- Test suite for ChosttySync init module (main controller)

-- Add the lua directory to the package path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Mock vim API for testing
_G.vim = {
  tbl_deep_extend = function(behavior, ...)
    local result = {}
    for i = 1, select('#', ...) do
      local tbl = select(i, ...)
      if type(tbl) == 'table' then
        for k, v in pairs(tbl) do
          result[k] = v
        end
      end
    end
    return result
  end,
  tbl_count = function(tbl)
    local count = 0
    for _ in pairs(tbl) do
      count = count + 1
    end
    return count
  end,
  api = {
    nvim_create_autocmd = function() end,
    nvim_create_augroup = function() return 1 end,
    nvim_create_user_command = function() end,
  },
  notify = function() end,
  log = { levels = { DEBUG = 1, WARN = 2, ERROR = 3 } }
}

-- Load the module
local init = require('chosttysync.init')

-- Test functions
local function test_cache_functions()
  print("Testing cache functions...")
  
  -- Test initial cache state
  local cached_data = init.get_cache()
  assert(cached_data == nil, "Initial cache should be empty")
  
  -- Test setting cache
  local test_data = { theme = "test", colors = {} }
  init.set_cache(test_data)
  
  -- Test getting cache immediately (should be valid)
  cached_data = init.get_cache()
  assert(cached_data ~= nil, "Cache should contain data after setting")
  assert(cached_data.theme == "test", "Cached data should match what was set")
  
  print("✓ Cache functions test passed")
end

local function test_setup_function()
  print("Testing setup function...")
  
  -- Test setup with default config
  local success, error_msg = pcall(function()
    init.setup()
  end)
  if not success then
    print("Setup error with no options:", error_msg)
  end
  assert(success, "Setup should work with no options: " .. (error_msg or ""))
  
  -- Test setup with custom config
  success, error_msg = pcall(function()
    init.setup({
      auto_sync = false,
      debug = true,
      cache_timeout = 60
    })
  end)
  if not success then
    print("Setup error with custom options:", error_msg)
  end
  assert(success, "Setup should work with custom options: " .. (error_msg or ""))
  
  -- Test get_config function
  local config = init.get_config()
  assert(type(config) == "table", "get_config should return a table")
  assert(type(config.auto_sync) == "boolean", "config should have auto_sync boolean")
  assert(type(config.debug) == "boolean", "config should have debug boolean")
  assert(type(config.cache_timeout) == "number", "config should have cache_timeout number")
  
  print("✓ Setup function test passed")
end

local function test_configuration_options()
  print("Testing configuration options...")
  
  -- Test with different configuration options
  local test_configs = {
    { auto_sync = true, debug = false, cache_timeout = 30 },
    { auto_sync = false, debug = true, cache_timeout = 60 },
    { auto_sync = true, debug = true, cache_timeout = 10 }
  }
  
  for i, test_config in ipairs(test_configs) do
    local success, error_msg = pcall(function()
      init.setup(test_config)
    end)
    assert(success, "Setup should work with test config " .. i .. ": " .. (error_msg or ""))
    
    local current_config = init.get_config()
    assert(current_config.auto_sync == test_config.auto_sync, 
           "auto_sync should match for config " .. i)
    assert(current_config.debug == test_config.debug, 
           "debug should match for config " .. i)
    assert(current_config.cache_timeout == test_config.cache_timeout, 
           "cache_timeout should match for config " .. i)
  end
  
  print("✓ Configuration options test passed")
end

local function test_sync_theme_integration()
  print("Testing sync_theme integration...")
  
  -- Note: This test will fail in the test environment because Ghostty CLI won't be available
  -- But we can test that the function exists and handles errors gracefully
  local success, result = pcall(function()
    return init.sync_theme()
  end)
  
  if not success then
    print("sync_theme error:", result)
  end
  
  -- The function should exist and be callable
  assert(success, "sync_theme function should be callable: " .. (result or "unknown error"))
  
  -- In test environment, it should return false due to missing Ghostty CLI
  -- but it shouldn't crash
  assert(type(result) == "boolean", "sync_theme should return a boolean")
  
  print("✓ sync_theme integration test passed")
end

-- Run all tests
local function run_all_tests()
  print("Running init module tests...")
  print("=========================================")
  
  test_cache_functions()
  test_setup_function()
  test_configuration_options()
  test_sync_theme_integration()
  
  print("=========================================")
  print("✓ All init module tests passed!")
end

-- Execute tests
run_all_tests()