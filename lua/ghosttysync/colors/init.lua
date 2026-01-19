local termcolor = require("ghosttysync.colors.ghosttyconfig")
local functions = require("ghosttysync.functions")

local pure_red    = "#ff0000"
local pure_green  = "#00ff00"
local pure_blue   = "#0000ff"
local pure_cyan   = "#00ffff"
local pure_yellow = "#ffff00"
local pure_purple = "#8000ff"
local pure_orange = "#ff8000"
-- local pure_pink   = "#ff00ff"
local pure_white  = "#ffffff"
local pure_black  = "#000000"
local pure_gray   = "#808080"

local default_term_colors = {
	name = "pure_dark",
	colors = {
		palette = {
			pure_black,
			pure_red,
			pure_green,
			pure_yellow,
			pure_blue,
			pure_purple,
			pure_cyan,
			pure_white,
		},
		background   = pure_black,
		foreground   = pure_white,
		cursor_color = pure_white,
		cursor_text  = pure_black,
		selection_fg = pure_black,
		selection_bg = pure_gray,
	},
}

local term_colors, term_color_error = termcolor.get_theme_info()

if term_color_error then
	print("Error: " .. term_color_error)
	term_colors = default_term_colors
end

if term_colors and term_colors.colors then
	term_colors.colors = functions.check_colors(term_colors.colors)
end

term_colors = vim.tbl_deep_extend("keep", term_colors or {}, default_term_colors)
local palette = term_colors.colors.palette

local background_match = functions.closest_color_match(term_colors.colors.background, { pure_black, pure_white })
local color_mod_direction = -1

if background_match == pure_white then
	color_mod_direction = 1
	vim.opt.background = "light"
else
	vim.opt.background = "dark"
end

local value_adjustment_scale = 0.25
local standard_adjustment = 1 + (value_adjustment_scale * color_mod_direction)
local standard_invert_adjustment = 1 + (value_adjustment_scale * color_mod_direction * -1)

---colors table
local colors = {
	---main colors
	main = {
		red    = functions.closest_color_match(pure_red   , palette),
		green  = functions.closest_color_match(pure_green , palette),
		yellow = functions.closest_color_match(pure_yellow, palette),
		blue   = functions.closest_color_match(pure_blue  , palette),
		purple = functions.closest_color_match(pure_purple, palette),
		cyan   = functions.closest_color_match(pure_cyan  , palette),
		orange = functions.closest_color_match(pure_orange, palette),
	},
}

-- Ajdust color if it is the same as the background/foreground
for color_name, color in pairs(colors.main) do
	if color == term_colors.colors.background or color == term_colors.colors.foreground then
		for new_name, _ in pairs(colors.main) do
			if color_name ~= new_name then
				colors.main[color_name] = colors.main[new_name]
				break
			end
		end
	end
end

-- darker colors
colors.main.darkred    = functions.adjust_color_value(colors.main.red   , standard_adjustment)
colors.main.darkgreen  = functions.adjust_color_value(colors.main.green , standard_adjustment)
colors.main.darkyellow = functions.adjust_color_value(colors.main.yellow, standard_adjustment)
colors.main.darkblue   = functions.adjust_color_value(colors.main.blue  , standard_adjustment)
colors.main.darkcyan   = functions.adjust_color_value(colors.main.cyan  , standard_adjustment)
colors.main.darkpurple = functions.adjust_color_value(colors.main.purple, standard_adjustment)
colors.main.darkorange = functions.adjust_color_value(colors.main.orange, standard_adjustment)

-- lighter colors
colors.main.paleblue   = functions.adjust_color_value(colors.main.blue  , standard_invert_adjustment)

palette[16] = term_colors.colors.foreground
palette[17] = term_colors.colors.background
palette[18] = term_colors.colors.cursor_color
palette[19] = term_colors.colors.cursor_text
palette[20] = term_colors.colors.selection_bg
palette[21] = term_colors.colors.selection_fg

colors.main.gray  = functions.closest_color_match(pure_gray , palette)
colors.main.white = functions.closest_color_match(pure_white, palette)
colors.main.black = functions.closest_color_match(pure_black, palette)

---colors applied to the editor
colors.editor = {
	link      = colors.main.cyan,
	cursor    = term_colors.colors.cursor_color,
	cursor_fg = term_colors.colors.cursor_text,
	title     = term_colors.colors.foreground,
}

---lsp colors
colors.lsp = {
	error   = colors.main.red,
	warning = colors.main.yellow,
	info    = colors.main.paleblue,
	hint    = colors.main.purple,
}

colors.syntax      = {}
colors.git         = {}
colors.backgrounds = {}

---editor colors
colors.editor.bg           = term_colors.colors.background
colors.editor.bg_alt       = functions.adjust_color_value(colors.editor.bg, standard_adjustment)
colors.editor.fg           = term_colors.colors.foreground
colors.editor.fg_dark      = functions.adjust_color_value(colors.editor.fg, standard_adjustment)
colors.editor.selection    = term_colors.colors.selection_bg
colors.editor.selection_fg = term_colors.colors.selection_fg
-- colors.editor.active       = functions.lower_contrast(colors.editor.selection, colors.editor.bg, 5) -- similar to selection
colors.editor.active       = functions.adjust_color_value(colors.editor.selection, standard_adjustment * 2) -- similar to selection
colors.editor.border       = functions.adjust_color_value(colors.editor.selection, 0.75)
-- colors.editor.line_numbers = functions.raise_contrast(colors.editor.border, colors.editor.bg, 20)
colors.editor.line_numbers = functions.adjust_color_value(colors.editor.border, standard_adjustment)
colors.editor.highlight    = colors.editor.selection
colors.editor.disabled     = functions.adjust_color_value(colors.editor.highlight, standard_invert_adjustment) -- lighter than highlight
colors.editor.accent       = colors.main.purple
colors.editor.contrast     = functions.adjust_color_value(colors.editor.accent, standard_adjustment * 2)
colors.editor.none         = "NONE"

---syntax colors
colors.syntax.comments  = colors.main.gray
colors.syntax.variable  = colors.editor.fg
colors.syntax.field     = colors.editor.fg
colors.syntax.keyword   = colors.main.purple
colors.syntax.value     = colors.main.orange
colors.syntax.operator  = colors.main.cyan
colors.syntax.fn        = colors.main.blue
colors.syntax.parameter = colors.main.paleblue
colors.syntax.string    = colors.main.green
colors.syntax.type      = colors.main.purple

---git colors
colors.git.added    = colors.main.green
colors.git.removed  = colors.main.red
colors.git.modified = colors.main.yellow

---contrasted backgrounds
colors.backgrounds.sidebars            = colors.editor.bg
colors.backgrounds.floating_windows    = colors.editor.bg
colors.backgrounds.non_current_windows = colors.editor.bg
colors.backgrounds.bg_blend            = colors.editor.bg
colors.backgrounds.cursor_line         = functions.adjust_color_value(colors.editor.bg, standard_adjustment)

term_colors.colors.palette = palette

-- useful for debugging
-- print("--- term_colors.colors ---")
-- functions.print_colors(term_colors.colors)
-- print("--- colors.main ---")
-- functions.print_colors(colors.main)
-- print("--- default_term_colors.colors ---")
-- functions.print_colors(default_term_colors.colors)

return colors
