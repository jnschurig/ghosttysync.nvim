-- Ghostty Configuration Reader Module
-- Handles execution of Ghostty CLI and parsing of configuration output

local M = {}

-- Execute `ghostty +show-config` command and return output
function M.execute_show_config()
	-- function execute_show_config()
	-- Check if we are being run from a vim environment.
	if not vim or not vim.fn or not vim.fn.executable then
		print("Not executable")
		return nil, "Not running in vim: Ghostty CLI not available"
	end

	-- Check if ghostty command is available
	local ghostty_check = vim.fn.executable("ghostty")
	if ghostty_check == 0 then
		print("Ghostty not found in PATH")
		return nil, "Ghostty executable not found in PATH"
	end

	-- Execute the ghostty +show-config command
	local cmd = { "ghostty", "+show-config" }
	local result = vim.fn.system(cmd)
	local exit_code = vim.v and vim.v.shell_error or 1

	-- Handle command execution errors
	if exit_code ~= 0 then
		local error_msg = string.format("Ghostty command failed with exit code %d: %s", exit_code, result)
		return nil, error_msg
	end

	-- Check if we got valid output
	if not result or result == "" then
		return nil, "Ghostty command returned empty output"
	end

	return result, nil
end

-- Helper function to split string (compatible with both vim and standalone lua)
local function split_string(str, delimiter)
	if vim and vim.split then
		return vim.split(str, delimiter, { plain = true })
	else
		local result = {}
		local pattern = "([^" .. delimiter .. "]*)" .. delimiter .. "?"
		for match in str:gmatch(pattern) do
			if match ~= "" then
				table.insert(result, match)
			end
		end
		return result
	end
end

-- Helper function to trim whitespace (compatible with both vim and standalone lua)
local function trim_string(str)
	if vim and vim.trim then
		return vim.trim(str)
	else
		return str:gsub("^%s*(.-)%s*$", "%1")
	end
end

-- Parse the CLI output from `ghostty +show-config`
function M.parse_config_output(output)
	if not output or output == "" then
		return nil, "Empty or nil output provided"
	end

	-- Handle case where output is not a string
	if type(output) ~= "string" then
		return nil, "Output must be a string"
	end

	local config = {}
	local palette_entries = {} -- Special handling for palette entries
	local lines = split_string(output, "\n")

	for _, line in ipairs(lines) do
		-- Skip empty lines and comments
		line = trim_string(line)
		local line_parts = split_string(line, " = ")
		local key = line_parts[1]
		local value = line_parts[2]

		if key == "palette" then
			local color_parts = split_string(value, "=")
			local color_idx = tonumber(color_parts[1])
			local color_str = color_parts[2]

			if color_str ~= nil and color_idx ~= nil then
				-- Ghostty's palette indices are 0-based (ANSI 0..15). Store at
				-- color_idx + 1 so the result is a contiguous Lua 1..16 array
				-- that ipairs traverses correctly. Without the offset, index 0
				-- is orphaned and every downstream slot is shifted by one.
				palette_entries[color_idx + 1] = color_str
			end
		else
			if key ~= nil and value ~= nil then
				config[key] = value
			end
		end

	end

	-- Add palette entries to config
	if #palette_entries > 0 then
		config.palette_entries = palette_entries
	end

	-- Check if we parsed any configuration
	if next(config) == nil then
		return nil, "No valid configuration found in output"
	end

	return config, nil
end

-- Extract theme information from parsed configuration
function M.extract_theme_info(config)
	if not config or type(config) ~= "table" then
	  return nil, "Invalid or empty configuration provided"
	end

	local theme_info = {
    name = config["theme"],
		colors = {
      background = config["background"],
      foreground = config["foreground"],

      selection_bg = config["selection-background"],
      selection_fg = config["selection-foreground"],

      cursor_color = config["cursor-color"],
      cursor_text  = config["cursor-text"],

      --TODO: Extract the background opacity.

      palette = {},
    },
	}

	-- Ghostty uses format: palette = N=#color
	-- Process palette entries from the special palette_entries array
	if config.palette_entries then
		for idx, color in ipairs(config.palette_entries) do
			if idx <= 16 and color ~= nil then
				theme_info.colors.palette[idx] = color
			end
		end
	end

	-- Validate that we have detected the theme name at least.
	if not theme_info.name then
		return nil, "No basic color information found in configuration"
	end

	return theme_info, nil
end

-- Main function to get theme information from Ghostty
-- Combines CLI execution, parsing, and theme extraction
function M.get_theme_info()
	-- Execute the CLI command
	local output, err = M.execute_show_config()
	if not output then
		return nil, "Failed to execute Ghostty CLI: " .. (err or "unknown error")
	end

	-- Parse the CLI output
	local config, parse_err = M.parse_config_output(output)
	if not config then
		return nil, "Failed to parse Ghostty configuration: " .. (parse_err or "unknown error")
	end

	-- Extract theme information
	local theme_info, extract_err = M.extract_theme_info(config)
	if not theme_info then
		return nil, "Failed to extract theme information: " .. (extract_err or "unknown error")
	end

	return theme_info, nil
end

return M
