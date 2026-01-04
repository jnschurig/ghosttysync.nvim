-- Test file for highlight_mapping.lua
-- Tests the highlight group mapping logic

-- Load the highlight_mapping module
local highlight_mapping = require("lua.ghosttysync.highlight_mapping")

-- Test data
local test_colors = {
	palette = {
		"#435b67",
		"#fc3841",
		"#5cf19e",
		"#fed032",
		"#37b6ff",
		"#fc226e",
		"#59ffd1",
		"#ffffff",
	},

	backgrounds = {
		floating_windows = "#1d262a",
		sidebars = "#1d262a",
		bg_blend = "#1d262a",
		non_current_windows = "#1d262a",
		cursor_line = "#212d33",
	},

	lsp = {
		warning = "#fed032",
		error = "#fc3841",
		hint = "#37b6ff",
		info = "#59ffd1",
	},

	syntax = {
		fn = "#37b6ff",
		operator = "#59ffd1",
		comments = "#435b67",
		keyword = "#37b6ff",
		parameter = "#59ffd1",
		type = "#37b6ff",
		string = "#59ffd1",
		field = "#e7ebed",
		variable = "#e7ebed",
		value = "#fed032",
	},

	main = {
		purple = "#37b6ff",
		white = "#ffffff",
		green = "#5cf19e",
		blue = "#37b6ff",
		orange = "#fed032",
		black = "#141b1e",
		yellow = "#fed032",
		gray = "#435b67",
		pink = "#fc226e",
		cyan = "#59ffd1",
		red = "#fc3841",
	},

	git = {
		removed = "#fc3841",
		added = "#5cf19e",
		modified = "#37b6ff",
	},

	editor = {
		none = "NONE",
		link = "#59ffd1",
		line_numbers = "#435b67",
		cursor = "#eaeaea",
		cursor_text = "#000000",
		accent = "#fed032",
		title = "#ffffff",
		highlight = "#435b67",
		fg_dark = "#b8bcbd",
		border = "#28363d",
		bg = "#1d262a",
		bg_alt = "#171e21",
		active = "#212d33",
		contrast = "#4e6a78",
		fg = "#e7ebed",
		selection = "#4e6a78",
		disabled = "#435b67",
	},
}

local function print_table(table_object)
	for key, value in pairs(table_object) do
		if type(value) == "table" then
			print("table: " .. key)
			print_table(value)
		else
			if type(value) == "boolean" and value then
				value = "true"
			end
			if type(value) == "boolean" and ~value then
				value = "false"
			end
			print(key .. ": " .. value)
		end
	end
end

local function test_highlight_map()
	print("Testing create_highlight_map() with standard colors")

	local highlight_map = highlight_mapping.create_highlight_map(test_colors)
	print_table(highlight_map)
	return true
end

-- Test functions
local function test_create_highlight_map_basic()
	print("Testing create_highlight_map with valid colors...")

	local highlight_map, err = highlight_mapping.create_highlight_map(test_colors)

	if err then
		print("ERROR: " .. err)
		return false
	end

	if not highlight_map then
		print("ERROR: No highlight map returned")
		return false
	end

	-- Test core highlight groups
	if not highlight_map.Normal then
		print("ERROR: Missing Normal highlight group")
		return false
	end

	-- Check that Normal highlight group exists and has valid colors
	if not highlight_map.Normal.fg or not highlight_map.Normal.bg then
		print("ERROR: Normal highlight group missing fg or bg colors")
		return false
	end

	-- Colors may be adjusted for contrast, so just verify they're valid hex colors
	if not highlight_map.Normal.fg:match("^#[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]$") then
		print("ERROR: Normal foreground is not a valid hex color: " .. highlight_map.Normal.fg)
		return false
	end

	if not highlight_map.Normal.bg:match("^#[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]$") then
		print("ERROR: Normal background is not a valid hex color: " .. highlight_map.Normal.bg)
		return false
	end

	-- Test syntax highlighting groups
	local required_groups = {
		"Comment",
		"Keyword",
		"String",
		"Function",
		"Type",
		"Number",
		"Conditional",
		"Variable",
		"Identifier",
		"Constant",
	}

	for _, group in ipairs(required_groups) do
		if not highlight_map[group] then
			print("ERROR: Missing " .. group .. " highlight group")
			return false
		end
	end

	-- Test diagnostic groups
	local diagnostic_groups = {
		"DiagnosticError",
		"DiagnosticWarn",
		"DiagnosticHint",
		"DiagnosticInfo",
		"Error",
		"Warning",
		"Hint",
		"Note",
	}

	for _, group in ipairs(diagnostic_groups) do
		if not highlight_map[group] then
			print("ERROR: Missing " .. group .. " diagnostic group")
			return false
		end
	end

	print("✓ Basic highlight map creation test passed")
	return true
end

local function test_create_highlight_map_with_minimal_colors()
	print("Testing create_highlight_map with minimal colors...")

	local minimal_colors = {
		background = "#000000",
		foreground = "#ffffff",
		-- No palette provided
	}

	local highlight_map, err = highlight_mapping.create_highlight_map(minimal_colors)

	if err then
		print("ERROR: " .. err)
		return false
	end

	if not highlight_map or not highlight_map.Normal then
		print("ERROR: Failed to create highlight map with minimal colors")
		return false
	end

	print("✓ Minimal colors test passed")
	return true
end

local function test_create_highlight_map_invalid_input()
	print("Testing create_highlight_map with invalid input...")

	local highlight_map, err = highlight_mapping.create_highlight_map(nil)

	if not err then
		print("ERROR: Should have returned error for nil colors")
		return false
	end

	if highlight_map then
		print("ERROR: Should not have returned highlight map for invalid input")
		return false
	end

	print("✓ Invalid input test passed")
	return true
end

local function test_apply_mode_adjustments()
	print("Testing apply_mode_adjustments...")

	local test_highlight_map = {
		Normal = { fg = "#ffffff", bg = "#000000" },
		Comment = { fg = "#808080", italic = true },
	}

	local adjusted_map = highlight_mapping.apply_mode_adjustments(test_highlight_map, "dark")

	if not adjusted_map then
		print("ERROR: apply_mode_adjustments returned nil")
		return false
	end

	-- For now, it should return the same map (placeholder implementation)
	if adjusted_map.Normal.fg ~= "#ffffff" or adjusted_map.Normal.bg ~= "#000000" then
		print("ERROR: Mode adjustments changed colors unexpectedly")
		return false
	end

	print("✓ Mode adjustments test passed")
	return true
end

local function test_validate_colors_valid_input()
	print("Testing validate_colors with valid input...")

	local valid, result = highlight_mapping.validate_colors(test_colors)

	if not valid then
		print("ERROR: Valid colors were rejected: " .. (result or "unknown error"))
		return false
	end

	if not result or type(result) ~= "table" then
		print("ERROR: validate_colors should return validated colors table")
		return false
	end

	-- Check that essential colors are present
	if not result.background or not result.foreground then
		print("ERROR: Missing essential colors after validation")
		return false
	end

	print("✓ Valid colors validation test passed")
	return true
end

local function test_validate_colors_invalid_input()
	print("Testing validate_colors with invalid input...")

	local valid, result = highlight_mapping.validate_colors(nil)

	if valid then
		print("ERROR: nil input should be invalid")
		return false
	end

	-- Test with invalid color formats
	local invalid_colors = {
		background = "not-a-color",
		foreground = "#gggggg", -- Invalid hex
		palette = {
			[0] = "invalid",
		},
	}

	local valid2, result2 = highlight_mapping.validate_colors(invalid_colors)

	if not valid2 then
		print("ERROR: Should handle invalid colors gracefully")
		return false
	end

	-- Should have fallback colors
	if not result2.background or not result2.foreground then
		print("ERROR: Should provide fallback colors for invalid input")
		return false
	end

	print("✓ Invalid colors validation test passed")
	return true
end

local function test_normalize_color()
	print("Testing _normalize_color function...")

	-- Test various color formats
	local test_cases = {
		{ input = "#fff", expected = "#FFFFFF" },
		{ input = "#ffffff", expected = "#FFFFFF" },
		{ input = "#FF0000", expected = "#FF0000" },
		{ input = "rgb(255, 0, 0)", expected = "#FF0000" },
		{ input = "0xff0000", expected = "#FF0000" },
		{ input = "invalid", expected = nil },
		{ input = nil, expected = nil },
	}

	for _, case in ipairs(test_cases) do
		local result = highlight_mapping._normalize_color(case.input)
		if result ~= case.expected then
			print(
				"ERROR: _normalize_color('"
					.. tostring(case.input)
					.. "') = '"
					.. tostring(result)
					.. "', expected '"
					.. tostring(case.expected)
					.. "'"
			)
			return false
		end
	end

	print("✓ Color normalization test passed")
	return true
end

local function test_adjust_contrast()
	print("Testing adjust_contrast function...")

	local test_colors_copy = {
		background = "#000000",
		foreground = "#ffffff",
		palette = {
			[0] = "#000000",
			[1] = "#ff0000",
			[8] = "#808080",
			[9] = "#ff8080",
		},
	}

	-- Test dark mode adjustments
	local dark_adjusted = highlight_mapping.adjust_contrast(test_colors_copy, "dark")

	if not dark_adjusted then
		print("ERROR: adjust_contrast returned nil for dark mode")
		return false
	end

	-- Test light mode adjustments
	local light_adjusted = highlight_mapping.adjust_contrast(test_colors_copy, "light")

	if not light_adjusted then
		print("ERROR: adjust_contrast returned nil for light mode")
		return false
	end

	-- Colors should be different between modes
	if dark_adjusted.foreground == light_adjusted.foreground then
		print("WARNING: Foreground colors are the same between light and dark modes")
	end

	print("✓ Contrast adjustment test passed")
	return true
end

local function test_luminance_and_contrast_calculation()
	print("Testing luminance and contrast calculation...")

	-- Test luminance calculation
	local white_luminance = highlight_mapping._get_luminance("#FFFFFF")
	local black_luminance = highlight_mapping._get_luminance("#000000")

	if not white_luminance or not black_luminance then
		print("ERROR: Failed to calculate luminance")
		return false
	end

	if white_luminance <= black_luminance then
		print("ERROR: White should have higher luminance than black")
		return false
	end

	-- Test contrast ratio calculation
	local contrast = highlight_mapping._calculate_contrast_ratio(white_luminance, black_luminance)

	if not contrast or contrast < 20 then -- White on black should have very high contrast
		print("ERROR: Contrast ratio calculation seems incorrect")
		return false
	end

	print("✓ Luminance and contrast calculation test passed")
	return true
end

-- Run all tests
local function run_tests()
	print("Running highlight_mapping tests...")
	print("=" .. string.rep("=", 40))

	local tests = {
		-- test_create_highlight_map_basic,
		-- test_create_highlight_map_with_minimal_colors,
		-- test_create_highlight_map_invalid_input,
		-- test_apply_mode_adjustments,
		-- test_validate_colors_valid_input,
		-- test_validate_colors_invalid_input,
		-- test_normalize_color,
		-- test_adjust_contrast,
		-- test_luminance_and_contrast_calculation,
		test_highlight_map(),
	}

	-- local passed = 0
	-- local total = #tests
	--
	-- for _, test in ipairs(tests) do
	-- 	if test() then
	-- 		passed = passed + 1
	-- 	end
	-- 	print()
	-- end
	--
	-- print("=" .. string.rep("=", 40))
	-- print(string.format("Tests completed: %d/%d passed", passed, total))
	--
	-- if passed == total then
	-- 	print("✓ All tests passed!")
	-- 	return true
	-- else
	-- 	print("✗ Some tests failed!")
	-- 	return false
	-- end
end

-- Export test runner
return {
	run_tests = run_tests(),
}
