-- Test script to check if GhosttySync plugin is loadable
-- Run this in Neovim with :luafile test-plugin-load.lua

print("=== GhosttySync Plugin Load Test ===")

-- Test 1: Can we require the module?
local success, ghosttysync = pcall(require, 'ghosttysync')
if success then
  print("✓ Module 'ghosttysync' loaded successfully")
  
  -- Test 2: Does it have a setup function?
  if type(ghosttysync.setup) == 'function' then
    print("✓ setup() function found")
    
    -- Test 3: Try calling setup
    local setup_success, setup_error = pcall(ghosttysync.setup, { debug = true })
    if setup_success then
      print("✓ setup() called successfully")
      print("✓ Plugin should now be active with debug enabled")
      
      -- Test 4: Check if commands are registered
      local commands = vim.api.nvim_get_commands({})
      local ghostty_commands = {}
      for name, _ in pairs(commands) do
        if name:match("^GhosttySync") then
          table.insert(ghostty_commands, name)
        end
      end
      
      if #ghostty_commands > 0 then
        print("✓ Commands registered: " .. table.concat(ghostty_commands, ", "))
      else
        print("✗ No GhosttySync commands found")
        print("  Available commands starting with 'C':")
        for name, _ in pairs(commands) do
          if name:match("^C") then
            print("    " .. name)
          end
        end
      end
    else
      print("✗ setup() failed: " .. tostring(setup_error))
    end
  else
    print("✗ setup() function not found")
  end
else
  print("✗ Failed to load module 'ghosttysync': " .. tostring(ghosttysync))
  
  -- Try alternative module names
  local alt_success, alt_module = pcall(require, 'ghosttysync')
  if alt_success then
    print("✓ Found alternative module 'ghosttysync'")
  else
    print("✗ Alternative module 'ghosttysync' also failed: " .. tostring(alt_module))
  end
end

print("=== Test Complete ===")