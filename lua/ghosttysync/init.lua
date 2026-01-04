-- GhosttySync: Neovim plugin to sync Ghostty terminal themes
-- Main controller module that orchestrates the theme synchronization process

local M = {}

-- Import required modules
local ghostty_config = require("ghosttysync.ghostty_config")
-- local theme_parser = require("ghosttysync.theme_parser")
local color_assignment = require("ghosttysync.color_assignment")
local highlight_mapping = require("ghosttysync.highlight_mapping")
local nvim_applier = require("ghosttysync.nvim_applier")

-- Plugin configuration with defaults
local config = {
	-- Enable automatic theme sync on startup
	-- auto_sync = true,
	-- Cache timeout in seconds (30 seconds)
	-- cache_timeout = 30,
	-- Enable debug logging
	debug = false,
	palette_set = "primary",
	-- Force fresh sync (bypass cache) - useful for debugging
	-- force_fresh = false,
}

-- -- Cache for theme data to improve performance
-- local cache = {
--   data = nil,
--   timestamp = 0,
-- }

-- -- Check if cache is still valid
-- local function is_cache_valid()
--   return cache.data and (os.time() - cache.timestamp) < config.cache_timeout
-- end

-- -- Get cached theme data if valid
-- function M.get_cache()
--   if is_cache_valid() then
--     return cache.data
--   end
--   return nil
-- end

-- -- Store theme data in cache
-- function M.set_cache(data)
--   cache.data = data
--   cache.timestamp = os.time()
-- end

-- Get current plugin configuration
function M.get_config()
	return vim.deepcopy and vim.deepcopy(config) or config
end

-- Log debug messages
local function log_debug(message)
	if config.debug then
		if vim and vim.notify then
			vim.notify("[GhosttySync] " .. message, vim.log.levels.DEBUG)
		else
			print("[GhosttySync] " .. message)
		end
	end
end

-- Log error messages
local function log_error(message)
	if vim and vim.notify then
		vim.notify("[GhosttySync] ERROR: " .. message, vim.log.levels.ERROR)
	else
		print("[GhosttySync] ERROR: " .. message)
	end
end

-- Log warning messages
local function log_warning(message)
	if vim and vim.notify then
		vim.notify("[GhosttySync] WARNING: " .. message, vim.log.levels.WARN)
	else
		print("[GhosttySync] WARNING: " .. message)
	end
end

-- Main theme synchronization function
-- Orchestrates the complete theme synchronization process
-- Integrates all modules: config reader, parser, mapper, applier
-- Handles the full data flow from CLI execution to highlight application
function M.sync_theme()
	log_debug("Theme synchronization initiated")

	-- -- Check cache first for performance (Requirements 5.1, 5.2)
	-- -- Skip cache if force_fresh is enabled or cache_timeout is 0
	-- local cached_data = nil
	-- if not config.force_fresh and config.cache_timeout > 0 then
	--   cached_data = M.get_cache()
	-- end
	--
	-- if cached_data then
	--   log_debug("Using cached theme data")
	--
	--   -- Apply cached highlight map directly
	--   local success, message, errors = nvim_applier.apply_highlights(cached_data.highlight_map)
	--   if success then
	--     -- Set colorscheme name
	--     local name_success, name_message = nvim_applier.set_colorscheme_name(cached_data.colorscheme_name)
	--     if name_success then
	--       log_debug("Applied cached theme successfully")
	--       return true, "Theme synchronized from cache"
	--     else
	--       log_warning("Failed to set colorscheme name from cache: " .. name_message)
	--       -- Continue with fresh sync
	--     end
	--   else
	--     log_warning("Failed to apply cached theme, falling back to fresh sync: " .. message)
	--   end
	--   -- Clear invalid cache and continue with fresh sync
	--   cache.data = nil
	-- end

	-- Step 1: Read Ghostty configuration via CLI (Requirements 1.1, 3.1)
	log_debug("Step 1: Reading Ghostty configuration via CLI")
	local theme_info, config_error = ghostty_config.get_theme_info()
	if not theme_info then
		local error_msg = "Failed to read Ghostty configuration: " .. (config_error or "unknown error")
		log_error(error_msg)
		-- Requirement 1.3: Fall back gracefully without crashing
		return false, error_msg
	end

	log_debug("Successfully read Ghostty theme: " .. (theme_info.name or "unknown"))

	-- Debug: Show detected colors
	if config.debug and theme_info.colors then
		local detected_colors_msg = ""
			.. "Detected colors: "
			.. "\n  Background: "
			.. (theme_info.colors.background or "none")
			.. "\n  Foreground: "
			.. (theme_info.colors.foreground or "none")
			.. "\n  Selection BG: "
			.. (theme_info.colors.selection_background or "none")
			.. "\n  Selection FG: "
			.. (theme_info.colors.selection_foreground or "none")
			.. "\n  cursor_color: "
			.. (theme_info.colors.cursor_color or "none")
			.. "\n  cursor_text: "
			.. (theme_info.colors.cursor_text or "none")
			.. "\n  Palette: "
		if theme_info.colors.palette then
			local palette_count = 0
			for key, value in pairs(theme_info.colors.palette) do
				palette_count = palette_count + 1
				detected_colors_msg = detected_colors_msg .. "\n    " .. key .. ": " .. value
			end
			log_debug("  Palette colors: " .. palette_count)
		end
		log_debug(detected_colors_msg)
	end

	-- local colors = theme_info.colors
	-- config.theme_info = theme_info
	theme_info.config = config
	-- local theme_settings = {
	-- 	config = config,
	-- 	colors = theme_info.colors,
	-- }
	local colors = color_assignment.assign_colors_from_theme(theme_info)

	-- Step 4: Map colors to Neovim highlight groups (Requirements 1.2, 3.2)
	log_debug("Step 4: Mapping colors to Neovim highlight groups")
	local highlight_map, mapping_error = highlight_mapping.create_highlight_map(colors)
	if not highlight_map then
		local error_msg = "Failed to create highlight map: " .. (mapping_error or "unknown error")
		log_error(error_msg)
		return false, error_msg
	end

	local highlight_count = 0
	for _ in pairs(highlight_map) do
		highlight_count = highlight_count + 1
	end
  log_debug("dark_gray: " .. (colors.main.dark_gray or "unknown"))
  log_debug("gray: " .. (colors.main.gray or "unknown"))
	log_debug("Created highlight map with " .. highlight_count .. " groups")

	-- -- Step 5: Clear existing highlights before applying new theme
	-- log_debug("Step 5: Clearing existing highlights")
	-- local clear_success, clear_message, clear_errors = nvim_applier.clear_existing_highlights()
	-- if not clear_success then
	-- 	log_warning("Failed to clear existing highlights: " .. clear_message)
	-- -- Continue anyway, as this is not critical for functionality
	-- else
	-- 	log_debug("Successfully cleared existing highlights")
	-- end

	if config.debug then
		local highlight_group_msg = ""
		for key, value in pairs(highlight_map) do
			highlight_group_msg = highlight_group_msg .. key .. ": fg=" .. (value.fg or "none") .. " bg=" .. (value.bg or "none") .. "\n"
		end

		log_debug(highlight_group_msg)
	end

	-- Step 6: Apply highlights to Neovim (Requirements 1.2)
	log_debug("Step 6: Applying highlights to Neovim")
	local apply_success, apply_message = nvim_applier.apply_highlights(highlight_map)
	if not apply_success then
		local error_msg = "Failed to apply highlights: " .. apply_message
		log_error(error_msg)
		return false, error_msg
	end

	log_debug("Successfully applied highlights: " .. apply_message)

	-- Step 7: Set colorscheme name for identification
	local colorscheme_name = "ghosttysync_" .. (theme_info.name or "unknown"):gsub("[^%w_]", "_")
	log_debug("Step 7: Setting colorscheme name: " .. colorscheme_name)
	local name_success, name_message = nvim_applier.set_colorscheme_name(colorscheme_name)
	if not name_success then
		log_warning("Failed to set colorscheme name: " .. name_message)
	-- Continue anyway, as this is not critical for core functionality
	else
		log_debug("Successfully set colorscheme name")
	end

	-- Step 8: Cache the results for performance (Requirements 5.1, 5.2)
	-- log_debug("Step 8: Caching theme data for future use")
	-- M.set_cache({
	--   theme_info = theme_info,
	--   colors = colors,
	--   mode = mode,
	--   highlight_map = highlight_map,
	--   colorscheme_name = colorscheme_name,
	--   timestamp = os.time(),
	-- })

	-- Log success with comprehensive summary
	local success_msg = string.format(
		"Theme synchronized successfully: %s (%s mode, %d highlight groups applied)",
		theme_info.name or "unknown",
		mode,
		highlight_count
	)
	log_debug(success_msg)

	return true, success_msg
end

-- Plugin setup function with configuration options
-- Requirements 1.1, 1.2: Initialize plugin and set up automatic theme synchronization
function M.setup(opts)
	-- Merge user options with defaults
	if opts then
		config = vim.tbl_deep_extend("force", config, opts)
	end

	log_debug("Setting up GhosttySync plugin")

	-- Set up automatic synchronization on startup if enabled
	-- Requirements 1.1: Plugin SHALL read Ghostty theme configuration when Neovim starts
	if config.auto_sync then
		log_debug("Setting up automatic theme synchronization on startup")

		-- Create autocommand for VimEnter event to hook into Neovim startup
		local augroup = vim.api.nvim_create_augroup("GhosttySync", { clear = true })

		vim.api.nvim_create_autocmd("VimEnter", {
			group = augroup,
			callback = function()
				log_debug("VimEnter event triggered, starting automatic theme sync")

				-- Add a small delay to ensure terminal is fully initialized
				vim.defer_fn(function()
					local success, message = M.sync_theme()
					if success then
						log_debug("Automatic theme sync completed: " .. message)
					else
						log_warning("Automatic theme sync failed: " .. message)
						-- Try once more after a longer delay
						vim.defer_fn(function()
							log_debug("Retrying automatic theme sync...")
							local retry_success, retry_message = M.sync_theme()
							if retry_success then
								log_debug("Retry theme sync completed: " .. retry_message)
							else
								log_error("Retry theme sync also failed: " .. retry_message)
							end
						end, 1000) -- 1 second delay for retry
					end
				end, 100) -- 100ms delay for initial sync
			end,
			desc = "Sync Ghostty theme with Neovim on startup",
		})

		-- Also try to sync on ColorScheme event in case another plugin changes colors
		vim.api.nvim_create_autocmd("ColorScheme", {
			group = augroup,
			callback = function(args)
				-- Only sync if it's not our own colorscheme to avoid infinite loops
				if args.match and not args.match:match("^ghosttysync_") then
					log_debug("ColorScheme event detected (" .. args.match .. "), syncing Ghostty theme")
					vim.defer_fn(function()
						M.sync_theme()
					end, 50) -- Small delay to let the colorscheme settle
				end
			end,
			desc = "Sync Ghostty theme when colorscheme changes",
		})
	else
		log_debug("Automatic theme synchronization disabled")
	end

	-- Create user command for manual synchronization
	-- Provide manual sync command for user-triggered updates
	vim.api.nvim_create_user_command("GhosttySyncTheme", function()
		log_debug("Manual theme sync command triggered")
		local success, message = M.sync_theme()
		if success then
			if vim and vim.notify then
				vim.notify("GhosttySync: " .. message, vim.log.levels.INFO)
			else
				print("GhosttySync: " .. message)
			end
		else
			if vim and vim.notify then
				vim.notify("GhosttySync: " .. message, vim.log.levels.ERROR)
			else
				print("GhosttySync ERROR: " .. message)
			end
		end
	end, {
		desc = "Manually sync Ghostty theme with Neovim",
	})

	-- Create additional user command to toggle debug mode
	vim.api.nvim_create_user_command("GhosttySyncDebug", function()
		config.debug = not config.debug
		local status = config.debug and "enabled" or "disabled"
		local message = "GhosttySync debug mode " .. status
		if vim and vim.notify then
			vim.notify(message, vim.log.levels.INFO)
		else
			print(message)
		end
	end, {
		desc = "Toggle GhosttySync debug mode",
	})

	-- Create command to force fresh sync (bypass cache)
	-- vim.api.nvim_create_user_command("GhosttySyncForce", function()
	--   log_debug("Force sync command triggered - bypassing cache")
	--   -- Temporarily clear cache and force fresh sync
	--   cache.data = nil
	--   local success, message = M.sync_theme()
	--   if success then
	--     if vim and vim.notify then
	--       vim.notify("GhosttySync (forced): " .. message, vim.log.levels.INFO)
	--     else
	--       print("GhosttySync (forced): " .. message)
	--     end
	--   else
	--     if vim and vim.notify then
	--       vim.notify("GhosttySync (forced): " .. message, vim.log.levels.ERROR)
	--     else
	--       print("GhosttySync ERROR (forced): " .. message)
	--     end
	--   end
	-- end, {
	--   desc = "Force sync Ghostty theme (bypass cache)",
	-- })

	-- Create command to show current configuration
	vim.api.nvim_create_user_command("GhosttySyncStatus", function()
		-- local cached_data = M.get_cache()
		-- local cache_status = cached_data and "valid" or "empty"

		-- Check if autocmds exist
		-- local autocmds = vim.api.nvim_get_autocmds({ group = "GhosttySync" })
		-- local autocmd_count = #autocmds

		local status_message = string.format(
			"GhosttySync Status:\n"
				.. "  Auto sync: %s\n"
				.. "  Debug: %s\n"
				-- .. "  Cache timeout: %ds\n"
				-- .. "  Cache status: %s\n"
				.. "  Autocmds registered: %d",
			-- config.auto_sync and "enabled" or "disabled",
			-- config.cache_timeout,
			config.debug and "enabled" or "disabled",
			config.M.colors
			-- cache_status,
			-- autocmd_count
		)

		-- if cached_data then
		--   status_message = status_message
		--     .. string.format(
		--       "\n  Current theme: %s\n" .. "  Theme mode: %s",
		--       cached_data.theme_info and cached_data.theme_info.name or "unknown",
		--       cached_data.mode or "unknown"
		--     )
		-- end

		if vim and vim.notify and false then
			vim.notify(status_message, vim.log.levels.INFO)
		else
			print(status_message)
		end
	end, {
		desc = "Show GhosttySync plugin status and configuration",
	})

	-- Create command to test autocmd manually
	vim.api.nvim_create_user_command("GhosttySyncTest", function()
		log_debug("Manual autocmd test triggered")
		vim.api.nvim_exec_autocmds("VimEnter", { group = "GhosttySync" })
	end, {
		desc = "Manually trigger VimEnter autocmd for testing",
	})

	log_debug("Plugin setup completed successfully")

	-- Debug: Show autocmd status
	if config.debug then
		log_debug("Autocmd setup status:")
		log_debug("  Auto sync enabled: " .. tostring(config.auto_sync))
		if config.auto_sync then
			log_debug("  VimEnter autocmd created for automatic theme sync")
			log_debug("  ColorScheme autocmd created for theme change detection")
		end
	end

	if config.debug then
		local config_str = "GhosttySync: Plugin initialized with config: "
		if vim and vim.inspect then
			config_str = config_str .. vim.inspect(config)
		else
			-- Fallback for test environment
			config_str = config_str
				.. "auto_sync="
				.. tostring(config.auto_sync)
				.. ", debug="
				.. tostring(config.debug)
			-- .. ", cache_timeout="
			-- .. tostring(config.cache_timeout)
		end
		print(config_str)
	end
end

return M
