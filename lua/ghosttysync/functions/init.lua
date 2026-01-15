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
	-- Standard luminance calculation.
	-- See: https://www.w3.org/WAI/GL/wiki/Relative_luminance
	local rgb_max = 255
	local rgb = hex_to_rgb(color)
	local r = linearize_rgb(rgb[1] / rgb_max) * 0.2126
	local g = linearize_rgb(rgb[2] / rgb_max) * 0.7152
	local b = linearize_rgb(rgb[3] / rgb_max) * 0.0722

	return r + g + b
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

return M
