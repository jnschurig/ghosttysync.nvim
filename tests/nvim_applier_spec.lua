-- Test file for nvim_applier.lua
-- Tests the highlight group application functions

-- Load the nvim_applier module
local nvim_applier = require('chosttysync.nvim_applier')

-- Test apply_highlights with invalid input
local function test_apply_highlights_invalid_input()
  print("Testing apply_highlights with invalid input...")
  
  -- Test with nil
  local success, message = nvim_applier.apply_highlights(nil)
  if not success and message:match("Invalid highlight map") then
    print("✓ Nil input test passed")
  else
    print("✗ Nil input test failed")
    return false
  end
  
  -- Test with non-table
  success, message = nvim_applier.apply_highlights("invalid")
  if not success and message:match("Invalid highlight map") then
    print("✓ Non-table input test passed")
  else
    print("✗ Non-table input test failed")
    return false
  end
  
  -- Test with empty table
  success, message = nvim_applier.apply_highlights({})
  if not success and message:match("Failed to apply any highlight groups") then
    print("✓ Empty table test passed")
  else
    print("✗ Empty table test failed")
    return false
  end
  
  return true
end

-- Test apply_highlights with valid input
local function test_apply_highlights_valid_input()
  print("Testing apply_highlights with valid input...")
  
  local highlight_map = {
    Normal = { fg = "#FFFFFF", bg = "#000000" },
    Comment = { fg = "#808080", italic = true }
  }
  
  local success, message = nvim_applier.apply_highlights(highlight_map)
  if success and message:match("Applied 2 highlight groups") then
    print("✓ Valid highlight map test passed")
    return true
  else
    print("✗ Valid highlight map test failed: " .. (message or "unknown error"))
    return false
  end
end

-- Test apply_highlights with mixed valid/invalid input (error handling)
local function test_apply_highlights_error_handling()
  print("Testing apply_highlights error handling...")
  
  local highlight_map = {
    Normal = { fg = "#FFFFFF", bg = "#000000" },  -- Valid
    Comment = { fg = "invalid_color", italic = true },  -- Invalid color
    [""] = { fg = "#FF0000" },  -- Invalid group name (empty)
    [123] = { fg = "#00FF00" },  -- Invalid group name (number)
    BadGroup = { fg = "#0000FF", invalid_attr = "not_boolean" },  -- Invalid attribute
    GoodGroup = { fg = "#FFFF00" }  -- Valid
  }
  
  local success, message, errors = nvim_applier.apply_highlights(highlight_map)
  
  -- Should succeed because some groups are valid, but should have errors
  if success and message:match("Applied") and errors and #errors > 0 then
    print("✓ Error handling test passed - applied valid groups and reported errors")
    return true
  else
    print("✗ Error handling test failed: " .. (message or "unknown error"))
    if errors then
      print("  Errors reported: " .. #errors)
    end
    return false
  end
end

-- Test set_colorscheme_name with invalid input
local function test_set_colorscheme_name_invalid_input()
  print("Testing set_colorscheme_name with invalid input...")
  
  -- Test with nil
  local success, message = nvim_applier.set_colorscheme_name(nil)
  if not success and message:match("Invalid colorscheme name") then
    print("✓ Nil name test passed")
  else
    print("✗ Nil name test failed")
    return false
  end
  
  -- Test with empty string
  success, message = nvim_applier.set_colorscheme_name("")
  if not success and message:match("Invalid colorscheme name") then
    print("✓ Empty name test passed")
  else
    print("✗ Empty name test failed")
    return false
  end
  
  -- Test with non-string
  success, message = nvim_applier.set_colorscheme_name(123)
  if not success and message:match("Invalid colorscheme name") then
    print("✓ Non-string name test passed")
  else
    print("✗ Non-string name test failed")
    return false
  end
  
  return true
end

-- Test set_colorscheme_name with valid input
local function test_set_colorscheme_name_valid_input()
  print("Testing set_colorscheme_name with valid input...")
  
  local success, message = nvim_applier.set_colorscheme_name("chosttysync")
  if success and message:match("Colorscheme name set to 'chosttysync'") then
    print("✓ Valid colorscheme name test passed")
    return true
  else
    print("✗ Valid colorscheme name test failed: " .. (message or "unknown error"))
    return false
  end
end

-- Test clear_existing_highlights
local function test_clear_existing_highlights()
  print("Testing clear_existing_highlights...")
  
  local success, message = nvim_applier.clear_existing_highlights()
  if success and message:match("Cleared highlights") then
    print("✓ Clear highlights test passed")
    return true
  else
    print("✗ Clear highlights test failed: " .. (message or "unknown error"))
    return false
  end
end

-- Run all tests
local function run_tests()
  print("Running nvim_applier tests...")
  print("=" .. string.rep("=", 40))
  
  local tests = {
    test_apply_highlights_invalid_input,
    test_apply_highlights_valid_input,
    test_apply_highlights_error_handling,
    test_set_colorscheme_name_invalid_input,
    test_set_colorscheme_name_valid_input,
    test_clear_existing_highlights
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
    print("✓ All nvim_applier tests passed!")
    return true
  else
    print("✗ Some nvim_applier tests failed!")
    return false
  end
end

-- Export test runner
return {
  run_tests = run_tests
}