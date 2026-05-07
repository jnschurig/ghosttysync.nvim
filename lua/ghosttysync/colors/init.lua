local termcolor = require("ghosttysync.colors.ghosttyconfig")
local functions = require("ghosttysync.functions")
local contrast  = require("ghosttysync.colors.contrast")
local T         = contrast.thresholds()

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

-- Ensure each main color has minimum contrast against the editor background.
-- Hue is preserved (OKLCH); only lightness is adjusted.
local _editor_bg = term_colors.colors.background
for color_name, color in pairs(colors.main) do
	colors.main[color_name] = contrast.ensure_contrast(color, _editor_bg, T.UI_MIN)
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
colors.editor.active       = functions.lower_contrast(colors.editor.selection, colors.editor.bg, 5) -- similar to selection
colors.editor.border       = functions.adjust_color_value(colors.editor.selection, 0.75)
colors.editor.line_numbers = colors.editor.border -- about the same as border
colors.editor.highlight    = colors.editor.selection
colors.editor.disabled     = functions.adjust_color_value(colors.editor.highlight, standard_invert_adjustment) -- lighter than highlight
colors.editor.accent       = colors.main.purple
colors.editor.contrast     = functions.raise_contrast(functions.adjust_color_value(colors.editor.accent, standard_adjustment), colors.main.accent, 10)
colors.editor.none         = "NONE"

-- Panel bg role: shifted from editor.bg by 1.5x PANEL_BG_OFFSET in the
-- direction that increases ΔE from Normal bg (lighter on dark bg, darker on
-- light bg). 1.5x gives slack above the audit threshold for hue drift.
do
    local oklch = require("ghosttysync.colors.oklch")
    local lch = oklch.hex_to_oklch(colors.editor.bg)
    if lch then
        local dir = (color_mod_direction == 1) and -1 or 1
        lch.L = math.max(0, math.min(1, lch.L + dir * T.PANEL_BG_OFFSET * 1.5))
        colors.editor.panel_bg = oklch.oklch_to_hex(lch)
    else
        colors.editor.panel_bg = colors.editor.bg_alt
    end
end

-- Stronger border role: ensure floating-panel borders are always visible
-- against the panel bg they're rendered on (panel_bg, not editor.bg).
colors.editor.border_strong = contrast.ensure_contrast(
    colors.editor.border, colors.editor.panel_bg, T.UI_MIN)

-- Ensure text/UI roles in editor.* meet readability thresholds.
colors.editor.fg           = contrast.ensure_contrast(colors.editor.fg,           colors.editor.bg, T.TEXT_MIN)
colors.editor.fg_dark      = contrast.ensure_contrast(colors.editor.fg_dark,      colors.editor.bg, T.TEXT_MIN)
colors.editor.line_numbers = contrast.ensure_contrast(colors.editor.line_numbers, colors.editor.bg, T.UI_MIN)
colors.editor.border       = contrast.ensure_contrast(colors.editor.border,       colors.editor.bg, T.UI_MIN)
colors.editor.disabled     = contrast.ensure_contrast(colors.editor.disabled,     colors.editor.bg, T.UI_MIN)
colors.editor.contrast     = contrast.ensure_contrast(colors.editor.contrast,     colors.editor.bg, T.UI_MIN)
colors.editor.title        = colors.editor.fg

---syntax colors
colors.syntax.comments  = contrast.ensure_contrast(colors.main.gray, colors.editor.bg, T.COMMENT_MIN)
colors.syntax.variable  = colors.editor.fg
colors.syntax.field     = colors.editor.fg_dark
colors.syntax.keyword   = colors.main.purple
colors.syntax.value     = colors.main.orange
colors.syntax.operator  = colors.main.cyan
colors.syntax.fn        = colors.main.blue
colors.syntax.parameter = colors.main.paleblue
colors.syntax.string    = colors.main.green
colors.syntax.type      = colors.main.purple

-- Adjacent-role distinguishability: nudge the second member of each pair.
do
	local pairs_to_check = {
		{ "keyword",   "type" },
		{ "fn",        "parameter" },
		{ "string",    "value" },
		{ "operator",  "fn" },
		{ "variable",  "field" },
	}
	for _, p in ipairs(pairs_to_check) do
		local a, b = colors.syntax[p[1]], colors.syntax[p[2]]
		if a and b then
			colors.syntax[p[2]] = contrast.nudge_apart(a, b, colors.editor.bg,
				T.MIN_ROLE_DISTANCE, T.UI_MIN)
		end
	end
end

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

-- Lualine mode-bg distinct selection (F4).
-- Each mode prefers a short list of semantic palette colors. We walk modes in
-- priority order, picking the first preference that (a) is not yet taken and
-- (b) yields TEXT_MIN against the mode's text fg. Falls back to the unused
-- semantic with greatest perceptual distance from already-picked bgs.
do
	local m = colors.main
	local text_fg = colors.editor.bg -- mode `a` sections use bg-tinted text
	local prefs = {
		normal   = { m.blue,   m.cyan   },
		insert   = { m.green,  m.cyan   },
		visual   = { m.purple, m.yellow },
		replace  = { m.red,    m.purple },
		command  = { m.yellow, m.green  },
		terminal = { m.cyan,   m.blue   },
	}
	local order = { "normal", "insert", "visual", "replace", "command", "terminal" }
	local all_semantics = { m.red, m.green, m.yellow, m.blue, m.purple, m.cyan, m.orange }

	local picked = {}
	local taken = {}
	for _, mode in ipairs(order) do
		local chosen
		for _, cand in ipairs(prefs[mode] or {}) do
			if cand and not taken[cand]
				and contrast.wcag_ratio(text_fg, cand) >= T.TEXT_MIN then
				chosen = cand
				break
			end
		end
		if not chosen then
			-- Fallback: pick the candidate (from semantics) with greatest
			-- distance from already-picked bgs. Prefer unused; if all are
			-- already taken (e.g. palette has fewer distinct hue families
			-- than modes), accept reuse but pick the farthest. Text fg may
			-- need ensure_contrast downstream.
			local best, best_dist = nil, -1
			local function score(cand)
				local min_d = math.huge
				for c, _ in pairs(taken) do
					local d = contrast.oklch_distance(cand, c)
					if d < min_d then min_d = d end
				end
				return min_d
			end
			for _, cand in ipairs(all_semantics) do
				if cand and not taken[cand] then
					local d = score(cand)
					if d > best_dist then best, best_dist = cand, d end
				end
			end
			if not best then
				best_dist = -1
				for _, cand in ipairs(all_semantics) do
					if cand then
						local d = score(cand)
						if d > best_dist then best, best_dist = cand, d end
					end
				end
			end
			chosen = best or prefs[mode][1]
		end
		picked[mode] = chosen
		if chosen then taken[chosen] = true end
	end
	colors.lualine_mode_bgs = picked
end

term_colors.colors.palette = palette

-- useful for debugging
-- print("--- term_colors.colors ---")
-- functions.print_colors(term_colors.colors)
-- print("--- colors.main ---")
-- functions.print_colors(colors.main)
-- print("--- default_term_colors.colors ---")
-- functions.print_colors(default_term_colors.colors)

return colors
