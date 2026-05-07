local settings = require("ghosttysync.util.config").settings
local oklch = require("ghosttysync.colors.oklch")

local M = {}

---Apply the configured lualine theme if lualine is loaded.
---Honors `settings.lualine_theme`: a string applies that theme; `false` skips.
---Deferred to `VimEnter` (or `schedule`) so other plugins referenced by the
---user's lualine config are loaded before lualine.setup re-evaluates them.
M.apply_lualine_theme = function()
	local theme = settings.lualine_theme
	if not theme or theme == false then return end
	local apply = function()
		local has_lualine, lualine = pcall(require, "lualine")
		if not has_lualine then return end
		local ok, current = pcall(lualine.get_config)
		local opts = (ok and current) or {}
		opts.options = opts.options or {}
		if opts.options.theme == theme then return end
		opts.options.theme = theme
		pcall(lualine.setup, opts)
	end
	if vim.v.vim_did_enter == 1 then
		vim.schedule(apply)
	else
		vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = apply })
	end
end

local set_lualine = M.apply_lualine_theme

---switch to a given style @param style string name of the style to switch to
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
	-- Hue-prioritized match for saturated specs (pure_red, pure_purple, ...).
	-- Naïve OKLab Euclidean lets a near-gray with matching lightness beat a
	-- clear in-hue palette color, because gray sits near zero in (a,b) and
	-- the high-chroma spec sits far out — the lightness term dominates.
	-- Instead: take min angular hue distance, then break ties by chroma
	-- (prefer more-saturated palette entries) and lightness proximity.
	local ok, oklch = pcall(require, "ghosttysync.colors.oklch")
	if not ok then
		local closest, best = nil, math.huge
		for _, color in ipairs(colors_table) do
			if color then
				local d = hex_color_diff(spec_color, color)
				if d < best then best, closest = d, color end
			end
		end
		return closest
	end

	local spec = oklch.hex_to_oklch(spec_color)
	if not spec then return colors_table[1] end
	local spec_is_saturated = (spec.c or 0) > 0.05

	local function hue_diff(a, b)
		local d = math.abs((a or 0) - (b or 0)) % 360
		if d > 180 then d = 360 - d end
		return d
	end

	local closest, best_score = nil, math.huge
	for _, color in ipairs(colors_table) do
		if color then
			local lch = oklch.hex_to_oklch(color)
			if lch then
				local score
				if spec_is_saturated then
					-- Hue distance dominates; chroma proximity is secondary;
					-- lightness is a small tie-breaker. Penalise low-chroma
					-- palette entries when the spec is saturated.
					score = hue_diff(spec.h, lch.h)
						+ math.abs((spec.c or 0) - (lch.c or 0)) * 50
						+ math.abs((spec.L or 0) - (lch.L or 0)) * 30
				else
					-- Spec is near-gray — match by lightness primarily.
					score = math.abs((spec.L or 0) - (lch.L or 0)) * 100
						+ (lch.c or 0) * 10
				end
				if score < best_score then
					best_score = score
					closest = color
				end
			end
		end
	end
	return closest or colors_table[1]
end

-- WCAG relative luminance (scalar).
M.relative_luminance = function(color)
	local rgb = rgb_luminance(color)
	return rgb[1] + rgb[2] + rgb[3]
end

M.contrast_ratio = function(color1, color2)
	local l1 = M.relative_luminance(color1)
	local l2 = M.relative_luminance(color2)
	return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05)
end

-- Scale OKLCH lightness by `factor` (preserves hue and chroma).
-- Negative factor returns the input unchanged (legacy guard).
M.adjust_luminance = function(color, factor)
	if factor < 0 then return color end
	local lch = oklch.hex_to_oklch(color)
	if not lch then return color end
	lch.L = math.min(math.max(lch.L * factor, 0), 1)
	return oklch.oklch_to_hex(lch)
end

-- Hue-preserving lighten/darken. Alias of adjust_luminance — kept for call-site clarity.
M.adjust_color_value = M.adjust_luminance

-- DEPRECATED: prefer ghosttysync.colors.contrast.ensure_contrast (Step 3+).
M.lower_contrast = function(color, reference_color, contrast_threshold)
	if contrast_threshold == nil then
		contrast_threshold = 4
	end

	local contrast_ratio = M.contrast_ratio(color, reference_color)
	if contrast_ratio == 1 then
		contrast_ratio = 1.0001
	end
	local reference_is_dark = true
	if M.closest_color_match(reference_color, { "#404040", "#ffffff" }) == "#ffffff" then
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

-- DEPRECATED: prefer ghosttysync.colors.contrast.ensure_contrast (Step 3+).
M.raise_contrast = function(color, reference_color, contrast_threshold)
	if contrast_threshold == nil then
		contrast_threshold = 4
	end

	local contrast_ratio = M.contrast_ratio(color, reference_color)
	if contrast_ratio == 1 then
		contrast_ratio = 1.0001
	end
	local reference_is_dark = true
	if M.closest_color_match(reference_color, { "#404040", "#ffffff" }) == "#ffffff" then
		reference_is_dark = false
	end

	local adjustment_factor = nil
	if contrast_ratio < contrast_threshold then
		if reference_is_dark then
			adjustment_factor = contrast_ratio
		else
			adjustment_factor = 1 / contrast_ratio
		end
		-- this is recursive now...
		local new_color = M.adjust_luminance(color, adjustment_factor)
		if M.contrast_ratio(color, new_color) < contrast_threshold then
			new_color = M.raise_contrast(new_color, reference_color, contrast_threshold)
		end
		-- return M.adjust_luminance(color, adjustment_factor)
		return new_color
	end

	return color
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
