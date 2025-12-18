-- Neovim Applier Module
-- Applies color mappings to Neovim highlight groups

local M = {}

-- Check if we're in a test environment and provide mock vim API if needed
local function get_vim_api()
  if vim and vim.api and vim.api.nvim_set_hl then
    return vim
  else
    -- Mock vim API for testing
    return {
      g = {},
      api = {
        nvim_set_hl = function(ns, name, opts)
          return true
        end
      },
      cmd = function(cmd)
        return true
      end,
      fn = {
        exists = function(name)
          return 1
        end
      }
    }
  end
end

-- Log error messages (simple logging for now)
local function log_error(message)
  -- In a real Neovim environment, this could use vim.notify or vim.api.nvim_err_writeln
  -- For now, we'll use print for compatibility with tests
  local vim_api = get_vim_api()
  if vim_api and vim_api.notify then
    vim_api.notify("[ChosttySync] " .. message, vim_api.log.levels.ERROR)
  elseif vim and vim.notify then
    vim.notify("[ChosttySync] " .. message, vim.log.levels.ERROR)
  else
    -- Fallback for test environment - don't print to avoid cluttering test output
    -- Tests can check the error messages in return values
  end
end

-- Log warning messages
local function log_warning(message)
  local vim_api = get_vim_api()
  if vim_api and vim_api.notify then
    vim_api.notify("[ChosttySync] " .. message, vim_api.log.levels.WARN)
  elseif vim and vim.notify then
    vim.notify("[ChosttySync] " .. message, vim.log.levels.WARN)
  else
    -- Fallback for test environment - don't print to avoid cluttering test output
    -- Tests can check the warning messages in return values
  end
end

-- Validate color format
local function validate_color(color)
  if type(color) ~= "string" then
    return false, "Color must be a string"
  end
  
  -- Check for valid hex color format (#RRGGBB or #RGB)
  if color:match("^#%x%x%x%x%x%x$") or color:match("^#%x%x%x$") then
    return true
  end
  
  -- Check for valid color names (basic validation)
  local valid_names = {
    "black", "red", "green", "yellow", "blue", "magenta", "cyan", "white",
    "darkred", "darkgreen", "darkyellow", "darkblue", "darkmagenta", "darkcyan",
    "lightred", "lightgreen", "lightyellow", "lightblue", "lightmagenta", "lightcyan"
  }
  
  for _, name in ipairs(valid_names) do
    if color:lower() == name then
      return true
    end
  end
  
  return false, "Invalid color format: " .. color
end

-- Validate highlight group configuration
local function validate_highlight_config(config)
  if type(config) ~= "table" then
    return false, "Highlight config must be a table"
  end
  
  local valid_config = {}
  local errors = {}
  
  -- Validate foreground color
  if config.fg then
    local valid, err = validate_color(config.fg)
    if valid then
      valid_config.fg = config.fg
    else
      table.insert(errors, "fg: " .. err)
    end
  end
  
  -- Validate background color
  if config.bg then
    local valid, err = validate_color(config.bg)
    if valid then
      valid_config.bg = config.bg
    else
      table.insert(errors, "bg: " .. err)
    end
  end
  
  -- Validate style attributes (boolean values)
  local style_attrs = {"bold", "italic", "underline", "strikethrough", "reverse", "standout"}
  for _, attr in ipairs(style_attrs) do
    if config[attr] ~= nil then
      if type(config[attr]) == "boolean" then
        valid_config[attr] = config[attr]
      else
        table.insert(errors, attr .. ": must be boolean")
      end
    end
  end
  
  -- Check if we have at least one valid attribute
  local has_valid_attrs = false
  for _ in pairs(valid_config) do
    has_valid_attrs = true
    break
  end
  
  if not has_valid_attrs then
    return false, "No valid attributes found", {}
  end
  
  return true, valid_config, errors
end

-- Apply highlight group mappings to Neovim
function M.apply_highlights(highlight_map)
  if not highlight_map or type(highlight_map) ~= "table" then
    local error_msg = "Invalid highlight map provided"
    log_error(error_msg)
    return false, error_msg
  end
  
  local vim_api = get_vim_api()
  local success_count = 0
  local error_count = 0
  local all_errors = {}
  
  -- Apply each highlight group
  for group_name, group_config in pairs(highlight_map) do
    if type(group_name) ~= "string" then
      error_count = error_count + 1
      local error_msg = string.format("Invalid highlight group name (not a string): %s", tostring(group_name))
      table.insert(all_errors, error_msg)
      log_warning(error_msg)
      goto continue
    end
    
    if group_name == "" then
      error_count = error_count + 1
      local error_msg = "Empty highlight group name"
      table.insert(all_errors, error_msg)
      log_warning(error_msg)
      goto continue
    end
    
    -- Validate and sanitize the highlight configuration
    local config_valid, validated_config, validation_errors = validate_highlight_config(group_config)
    
    if not config_valid then
      error_count = error_count + 1
      local error_msg = string.format("Invalid config for highlight group '%s': %s", group_name, validated_config)
      table.insert(all_errors, error_msg)
      log_warning(error_msg)
      goto continue
    end
    
    -- Log validation warnings but continue with valid parts
    if validation_errors and #validation_errors > 0 then
      for _, val_error in ipairs(validation_errors) do
        local warning_msg = string.format("Skipped invalid attribute in '%s': %s", group_name, val_error)
        log_warning(warning_msg)
        table.insert(all_errors, warning_msg)
      end
    end
    
    -- Try to apply the highlight group with error handling
    local apply_success, apply_error = M.handle_api_errors(
      function()
        vim_api.api.nvim_set_hl(0, group_name, validated_config)
      end,
      string.format("setting highlight group '%s'", group_name)
    )
    
    if apply_success then
      success_count = success_count + 1
    else
      error_count = error_count + 1
      table.insert(all_errors, apply_error)
    end
    
    ::continue::
  end
  
  -- Log summary
  if success_count > 0 then
    local success_msg = string.format("Applied %d highlight groups", success_count)
    if error_count > 0 then
      success_msg = success_msg .. string.format(" (%d errors/warnings)", error_count)
      log_warning(success_msg)
    end
    return true, success_msg, all_errors
  else
    local error_msg = string.format("Failed to apply any highlight groups (%d errors)", error_count)
    log_error(error_msg)
    return false, error_msg, all_errors
  end
end

-- Set colorscheme name for identification
function M.set_colorscheme_name(name)
  if not name or type(name) ~= "string" or name == "" then
    local error_msg = "Invalid colorscheme name provided"
    log_error(error_msg)
    return false, error_msg
  end
  
  local vim_api = get_vim_api()
  local success, result = M.handle_api_errors(
    function()
      vim_api.g.colors_name = name
    end,
    "setting colorscheme name"
  )
  
  if success then
    local success_msg = string.format("Colorscheme name set to '%s'", name)
    return true, success_msg
  else
    return false, result
  end
end

-- Clear existing highlights before applying new theme
function M.clear_existing_highlights()
  local vim_api = get_vim_api()
  local errors = {}
  local operations_completed = 0
  
  -- Clear the current colorscheme name
  local success1, result1 = M.handle_api_errors(
    function()
      vim_api.g.colors_name = nil
    end,
    "clearing colorscheme name"
  )
  
  if success1 then
    operations_completed = operations_completed + 1
  else
    table.insert(errors, result1)
  end
  
  -- Reset all highlight groups to default
  local success2, result2 = M.handle_api_errors(
    function()
      vim_api.cmd("highlight clear")
    end,
    "clearing highlight groups"
  )
  
  if success2 then
    operations_completed = operations_completed + 1
  else
    table.insert(errors, result2)
  end
  
  -- Reload syntax highlighting to ensure clean state
  local success3, result3 = M.handle_api_errors(
    function()
      if vim_api.fn.exists("syntax_on") == 1 then
        vim_api.cmd("syntax reset")
      end
    end,
    "resetting syntax highlighting"
  )
  
  if success3 then
    operations_completed = operations_completed + 1
  else
    table.insert(errors, result3)
  end
  
  -- Return success if at least some operations completed
  if operations_completed > 0 then
    local success_msg = string.format("Cleared highlights (%d/3 operations successful)", operations_completed)
    if #errors > 0 then
      success_msg = success_msg .. string.format(" with %d errors", #errors)
      log_warning(success_msg)
    end
    return true, success_msg, errors
  else
    local error_msg = "Failed to clear any highlights"
    log_error(error_msg)
    return false, error_msg, errors
  end
end



-- Handle Neovim API errors gracefully
function M.handle_api_errors(func, error_context, ...)
  local success, result = pcall(func, ...)
  
  if success then
    return true, result
  else
    local error_msg = string.format("API error in %s: %s", error_context or "unknown operation", result)
    log_error(error_msg)
    return false, error_msg
  end
end

return M