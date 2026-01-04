local M = {}

local function hex_to_rgb(hex)
	-- remove leading '#', if present
	hex = hex:gsub("#", "")
	return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

local function rgb_to_hex(red, green, blue)
	if red > 255 then
		red = 255
	end
	if green > 255 then
		green = 255
	end
	if blue > 255 then
		blue = 255
	end
	return "#" .. string.format("%02x", red) .. string.format("%02x", green) .. string.format("%02x", blue)
end

local function hex_color_diff(color1, color2)
	local color1_red, color1_green, color1_blue = hex_to_rgb(color1)
	local color2_red, color2_green, color2_blue = hex_to_rgb(color2)

	local red_diff = color1_red - color2_red
	local green_diff = color1_green - color2_green
	local blue_diff = color1_blue - color2_blue

	local diff_score = math.floor((math.abs(red_diff) + math.abs(green_diff) + math.abs(blue_diff)) / 3)

	return diff_score
end

local function closest_color_match(spec_color, colors_table)
	local diff_score = 300 -- biggest difference can only be 255
	local closest_color = nil

	for _, color in ipairs(colors_table) do
		local new_diff = hex_color_diff(spec_color, color)
		if new_diff < diff_score then
			diff_score = new_diff
			closest_color = color
		end
	end
	return closest_color
end

local function adjust_color_value(starting_color, adjustment_factor)
	if adjustment_factor < 0 then
		return starting_color
	end
	local red, green, blue = hex_to_rgb(starting_color)
	red = math.floor(red * adjustment_factor)
	green = math.floor(green * adjustment_factor)
	blue = math.floor(blue * adjustment_factor)
	return rgb_to_hex(red, green, blue)
end

function M.assign_colors_from_theme(settings)
	local pure_red = "#ff0000"
	local pure_green = "#00ff00"
	local pure_blue = "#0000ff"
	local pure_cyan = "#40ffff"
	local pure_yellow = "#ffff00"
	local pure_purple = "#8000ff"
	local pure_pink = "#ff00ff"
	local pure_orange = "#ff8000" -- 255 128 0
	local pure_white = "#ffffff"
	local pure_black = "#000000"
	local pure_gray = "#808080"

	local colors = {}

	-- Step 1, select the base set of 8 colors to work with
	local palette_index = nil
	if settings.config.palette_set == "primary" then
		palette_index = 0
	end
	if settings.config.palette_set == "secondary" then
		palette_index = 8
	end
	if palette_index == nil then
		return nil, "Incompatible palette set: " .. settings.config.palette_set .. " expected 'primary' or 'secondary'"
	end

	local local_use_palette = {}
	for i = 1, 8 do
		local idx = i + palette_index
		local_use_palette[i] = settings.colors.palette[idx]
	end

	colors.palette = local_use_palette
	colors.main = {
		red = closest_color_match(pure_red, colors.palette),
		green = closest_color_match(pure_green, colors.palette),
		blue = closest_color_match(pure_blue, colors.palette),
		cyan = closest_color_match(pure_cyan, colors.palette),
		yellow = closest_color_match(pure_yellow, colors.palette),
		purple = closest_color_match(pure_purple, colors.palette),
		pink = closest_color_match(pure_pink, colors.palette),
		orange = closest_color_match(pure_orange, colors.palette),
		white = closest_color_match(pure_white, colors.palette),
		gray = closest_color_match(pure_gray, colors.palette),
		-- black = closest_color_match(pure_black, colors.palette),
	}

	colors.main.black = adjust_color_value(colors.main.gray, 0.3)

	colors.editor = {
		link = colors.main.cyan,
		cursor = settings.colors.cursor_color,
		cursor_text = settings.colors.cursor_text,
		title = colors.main.white,
		bg = settings.colors.background,
		bg_alt = adjust_color_value(settings.colors.background, 0.8),
		fg = settings.colors.foreground,
		fg_dark = adjust_color_value(settings.colors.foreground, 0.8),
		selection = settings.colors.selection_background,
		contrast = settings.colors.selection_background,
		active = adjust_color_value(colors.main.gray, 0.5),
		border = adjust_color_value(colors.main.gray, 0.6),
		highlight = colors.main.gray,
		disabled = colors.main.gray,
		accent = colors.main.orange,
		line_numbers = colors.main.gray,
		none = "NONE",
	}

	colors.lsp = {
		warning = colors.main.yellow,
		-- info = colors.main.paleblue,
		info = colors.main.cyan,
		hint = colors.main.purple,
		error = colors.main.red,
	}

	colors.syntax = {
		comments = colors.main.gray,
		variable = colors.editor.fg,
		field = colors.editor.fg,
		keyword = colors.main.purple,
		value = colors.main.orange,
		operator = colors.main.cyan,
		fn = colors.main.blue,
		-- parameter = colors.main.paleblue,
		parameter = colors.main.cyan,
		string = colors.main.green,
		type = colors.main.purple,
	}

	colors.git = {
		added = colors.main.green,
		removed = colors.main.red,
		modified = colors.main.blue,
	}

	colors.backgrounds = {
		sidebars = colors.editor.bg,
		floating_windows = colors.editor.bg,
		non_current_windows = colors.editor.bg,
		bg_blend = colors.editor.bg, -- backup used for blending backgrounds (not sure if we need this)
		cursor_line = colors.editor.active,
	}

	return colors, nil
end

return M
