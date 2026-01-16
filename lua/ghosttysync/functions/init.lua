local settings = require("ghosttysync.util.config").settings

local M = {}

---checks if the user uses lualine and then sets the lualine theme
local set_lualine = function()
	local has_lualine, lualine = pcall(require, "lualine")
	if has_lualine then
		lualine.setup({
			options = {
				theme = "auto",
			},
		})
	end
end

---switch to a given style
---@param style string name of the style to switch to
M.change_style = function(style)
	set_lualine()
	vim.g.ghosttysync_style = style
	-- print("ghosttysync style: ", style)
	vim.cmd("colorscheme ghosttysync")
end

---toggle the end-of-buffer lines (~)
M.toggle_eob = function()
	local colors = require("ghosttysync.colors").editor

	settings.disable.eob_lines = not settings.disable.eob_lines

	if settings.disable.eob_lines then
		vim.api.nvim_set_hl(0, "EndOfBuffer", { fg = colors.bg })
	else
		vim.api.nvim_set_hl(0, "EndOfBuffer", { fg = colors.disabled })
	end
end

---use telescope to change the style
M.find_style = function()
	require("ghosttysync.functions.telescope_styles").find()
end

local rgb_to_hex = function(r, g, b)
	r = math.min(r, 255)
	g = math.min(g, 255)
	b = math.min(b, 255)
	return string.format("#%02x%02x%02x", r, g, b)
end

local function hex_to_rgb(hex)
	if not hex then
		return { 0, 0, 0 }
	end
	hex = hex:gsub("#", "")
	return {
		tonumber(hex:sub(1, 2), 16),
		tonumber(hex:sub(3, 4), 16),
		tonumber(hex:sub(5, 6), 16),
	}
end

local function hex_color_diff(color1, color2)
	local rgb1 = hex_to_rgb(color1)
	local color1_r = rgb1[1]
	local color1_g = rgb1[2]
	local color1_b = rgb1[3]

	local rgb2 = hex_to_rgb(color2)
	local color2_r = rgb2[1]
	local color2_g = rgb2[2]
	local color2_b = rgb2[3]

	local r_diff = color1_r - color2_r
	local g_diff = color1_g - color2_g
	local b_diff = color1_b - color2_b

	local diff_score = math.floor((math.abs(r_diff) + math.abs(g_diff) + math.abs(b_diff)) / 3)

	return diff_score
end

local function linearize_rgb(floating_point_value)
	-- Standard liniarization formula.
	-- See: https://www.w3.org/WAI/GL/wiki/Relative_luminance
	if floating_point_value <= 0.04045 then
		return floating_point_value * 12.92
	end
	return ((floating_point_value + 0.055) / 1.055) ^ 2.4
end

local function delinearize_rgb(linear_value)
	-- The undo of the linearize_rgb function
	if linear_value <= 0.0031308 then
		return linear_value * 12.92
	end
	return 1.055 * (linear_value ^ (1 / 2.4)) - 0.055
end

local function invert_hue(rgb_number)
	return (1 - (rgb_number / 255)) * 255
end

local function rgb_luminance(color)
	-- Standard luminance calculation.
	-- See: https://www.w3.org/WAI/GL/wiki/Relative_luminance
	local rgb_max = 255
	local rgb = hex_to_rgb(color)
	local r = linearize_rgb(rgb[1] / rgb_max) * 0.2126
	local g = linearize_rgb(rgb[2] / rgb_max) * 0.7152
	local b = linearize_rgb(rgb[3] / rgb_max) * 0.0722
	return { r, g, b }
end

M.invert_color = function(color)
	local rgb = hex_to_rgb(color)
	local r = invert_hue(rgb[1])
	local g = invert_hue(rgb[2])
	local b = invert_hue(rgb[3])

	return rgb_to_hex(r, g, b)
end

M.color_diff = function(color1, color2)
	return hex_color_diff(color1, color2)
end

M.closest_color_match = function(spec_color, colors_table)
	local diff_score = 300 -- biggest difference can only be 255
	local closest_color = nil

	for _, color in ipairs(colors_table) do
		local new_diff = nil
		if not color then
			new_diff = 400
		end
		new_diff = hex_color_diff(spec_color, color)
		if new_diff < diff_score then
			diff_score = new_diff
			closest_color = color
		end
	end
	return closest_color
end

M.relative_luminance = function(color)
	local rgb = rgb_luminance(color)
	local r = rgb[1]
	local g = rgb[2]
	local b = rgb[3]

	return r + g + b
end

M.adjust_luminance = function(color, adjustment_factor)
	local rgb = rgb_luminance(color)
	local r_lum = rgb[1] * adjustment_factor
	local g_lum = rgb[2] * adjustment_factor
	local b_lum = rgb[3] * adjustment_factor

	local rgb_max = 255
	local r = delinearize_rgb(r_lum / 0.2126) * rgb_max
	local g = delinearize_rgb(g_lum / 0.7152) * rgb_max
	local b = delinearize_rgb(b_lum / 0.0722) * rgb_max

	return rgb_to_hex(r, g, b)
end

M.contrast_ratio = function(color1, color2)
	local c1_luminance = M.relative_luminance(color1)
	local c2_luminance = M.relative_luminance(color2)

	return (math.max(c1_luminance, c2_luminance) + 0.05) / (math.min(c1_luminance, c2_luminance) + 0.05)
end

M.adjust_color_value = function(starting_color, adjustment_factor)
	if adjustment_factor < 0 then
		return starting_color
	end
	local rgb = hex_to_rgb(starting_color)
	local r = math.min(math.floor(rgb[1] * adjustment_factor), 255)
	local g = math.min(math.floor(rgb[2] * adjustment_factor), 255)
	local b = math.min(math.floor(rgb[3] * adjustment_factor), 255)
	return rgb_to_hex(r, g, b)
end

M.lower_contrast = function(color, reference_color, contrast_threshold)
	if contrast_threshold == nil then
		contrast_threshold = 4
	end

	local contrast_ratio = M.contrast_ratio(color, reference_color)
	local reference_is_dark = true
	if M.closest_color_match(reference_color, { "#000000", "#ffffff" }) == "#ffffff" then
		reference_is_dark = false
	end

	local adjustment_factor = nil
	if contrast_ratio > contrast_threshold then
		if reference_is_dark then
			adjustment_factor = 1 / contrast_ratio
		else
			adjustment_factor = contrast_ratio
		end

		return M.adjust_luminance(color, adjustment_factor)
	end

	return color
end

M.raise_contrast = function(color, reference_color, contrast_threshold)
	if contrast_threshold == nil then
		contrast_threshold = 4
	end

	local contrast_ratio = M.contrast_ratio(color, reference_color)
	if contrast_ratio == 0 then
		contrast_ratio = 0.0001
	end
	local reference_is_dark = true
	if M.closest_color_match(reference_color, { "#000000", "#ffffff" }) == "#ffffff" then
		reference_is_dark = false
	end

	local adjustment_factor = nil
	if contrast_ratio < contrast_threshold then
		if reference_is_dark then
			adjustment_factor = contrast_ratio
		else
			adjustment_factor = 1 / contrast_ratio
		end

		return M.adjust_luminance(color, adjustment_factor)
	end

	return color
end

-- M.adjust_luminance_for_contrast = function(color, reference_color, contrast_threshold)
-- 	if contrast_threshold == nil then
-- 		contrast_threshold = 4
-- 	end
--
-- 	local contrast_ratio = M.contrast_ratio(color, reference_color)
-- 	local reference_is_dark = true
-- 	if M.closest_color_match(reference_color, { "#404040", "#ffffff" }) == "#ffffff" then
-- 		reference_is_dark = false
-- 	end
--
-- 	local adjustment_factor = nil
-- 	if contrast_ratio > contrast_threshold then
-- 		if reference_is_dark then
-- 			adjustment_factor = 1 / contrast_ratio
-- 		else
-- 			adjustment_factor = contrast_ratio
-- 		end
--
-- 		return M.adjust_luminance(color, adjustment_factor)
-- 	end
--
-- 	return color
-- end

M.round = function(val)
	return math.floor(val + 0.5)
end

M.clamp = function(val, min, max)
	return math.min(math.max(val, min), max)
end

M.blend = function(foreground, background, alpha)
	local bg = hex_to_rgb(background)
	local fg = hex_to_rgb(foreground)

	local blend_channel = function(i)
		return M.round(M.clamp(alpha * fg[i] + ((1 - alpha) * bg[i]), 0, 255))
	end

	local r = blend_channel(1)
	local g = blend_channel(2)
	local b = blend_channel(3)

	return rgb_to_hex(r, g, b)
end

M.darken = function(color, amount, bg)
	return M.blend(color, bg or "#000000", amount)
end

M.check_colors = function(color_table)
	if color_table.background == nil and color_table.foreground ~= nil then
		color_table.background = M.invert_color(color_table.foreground)
	end
	if color_table.background ~= nil and color_table.foreground == nil then
		color_table.foreground = M.invert_color(color_table.background)
	end
	if color_table.selection_background == nil and color_table.selection_foreground ~= nil then
		color_table.selection_background = M.invert_color(color_table.selection_foreground)
	end
	if color_table.selection_background ~= nil and color_table.selection_foreground == nil then
		color_table.selection_foreground = M.invert_color(color_table.selection_background)
	end
	if color_table.cursor_color == nil and color_table.cursor_text ~= nil then
		color_table.cursor_color = M.invert_color(color_table.cursor_text)
	end
	if color_table.cursor_color ~= nil and color_table.cursor_text == nil then
		color_table.cursor_text = M.invert_color(color_table.cursor_color)
	end
	return color_table
end

M.print_colors = function(color_table)
	for key, value in pairs(color_table) do
		if type(value) ~= "table" then
			print(key .. ": " .. value .. " | lum: " .. M.relative_luminance(value))
		else
			for idx, member in ipairs(value) do
				print(key .. ": " .. idx .. ": " .. member .. " | lum: " .. M.relative_luminance(member))
			end
		end
	end
	print("")
end

return M
