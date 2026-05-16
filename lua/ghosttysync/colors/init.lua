local termcolor = require("ghosttysync.colors.ghosttyconfig")
local functions = require("ghosttysync.functions")
local contrast  = require("ghosttysync.colors.contrast")
local oklch     = require("ghosttysync.colors.oklch")
local T         = contrast.thresholds()

local pure_white = "#ffffff"
local pure_black = "#000000"
local pure_gray  = "#808080"

local default_term_colors = {
	name = "pure_dark",
	colors = {
		palette = {
			pure_black,         -- 0 black
			"#ff0000",          -- 1 red
			"#00ff00",          -- 2 green
			"#ffff00",          -- 3 yellow
			"#0000ff",          -- 4 blue
			"#8000ff",          -- 5 purple
			"#00ffff",          -- 6 cyan
			pure_white,         -- 7 white
			pure_gray,          -- 8 bright_black
			"#ff4040",          -- 9 bright_red
			"#40ff40",          -- 10 bright_green
			"#ffff80",          -- 11 bright_yellow
			"#4080ff",          -- 12 bright_blue
			"#a040ff",          -- 13 bright_purple
			"#40ffff",          -- 14 bright_cyan
			pure_white,         -- 15 bright_white
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

-- Bg dark/light detection via OKLCH lightness.
local _bg_lch = oklch.hex_to_oklch(term_colors.colors.background)
local color_mod_direction = (_bg_lch and _bg_lch.L < 0.5) and -1 or 1
vim.opt.background = (color_mod_direction == 1) and "light" or "dark"

local value_adjustment_scale = 0.25
local standard_adjustment = 1 + (value_adjustment_scale * color_mod_direction)
local standard_invert_adjustment = 1 + (value_adjustment_scale * color_mod_direction * -1)

---colors table — direct ANSI 16-color index mapping (palette[1..16] = ANSI 0..15).
---Honors the philosophy "colors should move straight across from the terminal theme".
local colors = {
	main = {
		black         = palette[1],
		red           = palette[2],
		green         = palette[3],
		yellow        = palette[4],
		blue          = palette[5],
		purple        = palette[6],
		cyan          = palette[7],
		white         = palette[8],
		bright_black  = palette[9],
		bright_red    = palette[10],
		bright_green  = palette[11],
		bright_yellow = palette[12],
		bright_blue   = palette[13],
		bright_purple = palette[14],
		bright_cyan   = palette[15],
		bright_white  = palette[16],
	},
}
colors.main.gray = colors.main.bright_black  -- semantic alias

-- Ensure each main color has minimum contrast against the editor background.
-- Hue is preserved (OKLCH); only lightness is adjusted.
local _editor_bg = term_colors.colors.background
for color_name, color in pairs(colors.main) do
	colors.main[color_name] = contrast.ensure_contrast(color, _editor_bg, T.UI_MIN)
end

-- Stash special colors at indices 17..22 (after the ANSI 16). Indices 0..15
-- are reserved for the terminal palette; the audit's palette_coverage check
-- iterates the whole table.
palette[17] = term_colors.colors.foreground
palette[18] = term_colors.colors.background
palette[19] = term_colors.colors.cursor_color
palette[20] = term_colors.colors.cursor_text
palette[21] = term_colors.colors.selection_bg
palette[22] = term_colors.colors.selection_fg

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
	info    = colors.main.bright_blue,
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
-- "active" = recessive variant of selection. Midpoint OKLCH lightness
-- between selection and bg (the downstream ensure_contrast pass enforces
-- UI_MIN if this lands too close to bg).
do
	local s_lch = oklch.hex_to_oklch(colors.editor.selection)
	local b_lch = oklch.hex_to_oklch(colors.editor.bg)
	if s_lch and b_lch then
		colors.editor.active = oklch.set_lightness(colors.editor.selection, (s_lch.L + b_lch.L) * 0.5)
	else
		colors.editor.active = colors.editor.selection
	end
end
colors.editor.border       = functions.adjust_color_value(colors.editor.selection, 0.75)
colors.editor.line_numbers = colors.editor.border
colors.editor.highlight    = colors.editor.selection
colors.editor.disabled     = functions.adjust_color_value(colors.editor.highlight, standard_invert_adjustment)
colors.editor.accent       = colors.main.purple
colors.editor.contrast     = functions.adjust_color_value(colors.editor.accent, standard_adjustment)
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
colors.syntax.value     = colors.main.yellow
colors.syntax.operator  = colors.main.cyan
colors.syntax.fn        = colors.main.blue
colors.syntax.parameter = colors.main.bright_blue
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
-- Diff semantics (added=green, removed=red) are universal — independent of
-- the theme's ANSI slot assignments. Scan the full palette for the entry
-- closest to true-red / true-green / true-yellow by OKLCH hue.
local function closest_by_hue(target_h)
	local best, best_d = nil, math.huge
	for _, hex in ipairs(palette) do
		local lch = hex and oklch.hex_to_oklch(hex)
		if lch and lch.h then
			local d = math.abs(lch.h - target_h) % 360
			if d > 180 then d = 360 - d end
			if d < best_d then best, best_d = hex, d end
		end
	end
	return best
end
colors.git.added    = contrast.ensure_contrast(closest_by_hue(140), colors.editor.bg, T.UI_MIN)
colors.git.removed  = contrast.ensure_contrast(closest_by_hue(25),  colors.editor.bg, T.UI_MIN)
colors.git.modified = contrast.ensure_contrast(closest_by_hue(95),  colors.editor.bg, T.UI_MIN)

---contrasted backgrounds
colors.backgrounds.sidebars            = colors.editor.bg
colors.backgrounds.floating_windows    = colors.editor.bg
colors.backgrounds.non_current_windows = colors.editor.bg
colors.backgrounds.bg_blend            = colors.editor.bg
colors.backgrounds.cursor_line         = functions.adjust_color_value(colors.editor.bg, standard_adjustment)

-- Lualine mode-bg selection (F4). One mode = one ANSI hue. If the primary
-- choice collides with an already-picked mode (perceptually identical, ΔE <
-- MIN_ROLE_DISTANCE) or fails TEXT_MIN against the section's text fg, escalate
-- to its bright_* variant. If that also fails, fall back to the unused entry
-- from the fallback pool with greatest ΔE from already-picked bgs.
do
	local m = colors.main
	local text_fg = colors.editor.bg -- mode `a` sections use bg-tinted text
	local primary = {
		normal   = { m.blue,   m.bright_blue   },
		insert   = { m.green,  m.bright_green  },
		visual   = { m.purple, m.bright_purple },
		replace  = { m.red,    m.bright_red    },
		command  = { m.yellow, m.bright_yellow },
		terminal = { m.cyan,   m.bright_cyan   },
	}
	local order = { "normal", "insert", "visual", "replace", "command", "terminal" }
	local fallback_pool = {
		m.blue, m.green, m.purple, m.red, m.yellow, m.cyan,
		m.bright_blue, m.bright_green, m.bright_purple,
		m.bright_red, m.bright_yellow, m.bright_cyan,
	}

	local taken = {}
	local function collides(c)
		if not c then return true end
		if contrast.wcag_ratio(text_fg, c) < T.TEXT_MIN then return true end
		for prev, _ in pairs(taken) do
			if contrast.oklch_distance(c, prev) < T.MIN_ROLE_DISTANCE then
				return true
			end
		end
		return false
	end
	local function farthest_unused()
		local best, best_d = nil, -1
		for _, c in ipairs(fallback_pool) do
			if c and not taken[c] then
				local min_d = math.huge
				for prev, _ in pairs(taken) do
					local d = contrast.oklch_distance(c, prev)
					if d < min_d then min_d = d end
				end
				if min_d > best_d then best, best_d = c, min_d end
			end
		end
		return best
	end

	local picked = {}
	for _, mode in ipairs(order) do
		local chosen
		for _, cand in ipairs(primary[mode]) do
			if not collides(cand) then chosen = cand; break end
		end
		chosen = chosen or farthest_unused() or primary[mode][1]
		picked[mode] = chosen
		taken[chosen] = true
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
