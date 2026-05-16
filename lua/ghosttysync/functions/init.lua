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

local function invert_hue(rgb_number)
	return (1 - (rgb_number / 255)) * 255
end

M.invert_color = function(color)
	local rgb = hex_to_rgb(color)
	local r = invert_hue(rgb[1])
	local g = invert_hue(rgb[2])
	local b = invert_hue(rgb[3])

	return rgb_to_hex(r, g, b)
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
			print(key .. ": " .. value)
		else
			for idx, member in ipairs(value) do
				print(key .. ": " .. idx .. ": " .. member)
			end
		end
	end
	print("")
end

return M
