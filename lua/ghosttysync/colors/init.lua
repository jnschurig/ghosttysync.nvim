-- local high_visibility = require "ghosttysync.util.config".settings.high_visibility
-- local termcolor = require("ghosttysync.colors.termcolor3")
local termcolor = require("ghosttysync.colors.ghosttyconfig")
-- local closest_color_match = require("ghosttysync.functions.functions.closest_color_match")
-- local adjust_color_value = require("ghosttysync.functions.functions.adjust_color_value")
local functions = require("ghosttysync.functions")

local pure_red    = "#ff0000"
local pure_green  = "#00ff00"
local pure_blue   = "#0000ff"
local pure_cyan   = "#40ffff"
local pure_yellow = "#ffff00"
local pure_purple = "#8000ff"
local pure_orange = "#ff8000" -- 255 128 0
-- local pure_pink   = "#ff00ff"
local pure_white  = "#ffffff"
local pure_black  = "#000000"
local pure_gray   = "#808080"

-- local palette_index = 1
-- if vim.g.ghosttysync_style == "secondary" then
-- 	palette_index = 9
-- end

-- TODO: create a function in functions which will take the above as input
-- and return the colors.main colors below

-- local local_use_palette = {}
-- for i = 1, 8 do
-- 	local idx = i + palette_index
-- 	local_use_palette[i] = term_colors.palette[idx]
-- end
--
-- local term_colors = termcolor.query_all()
local term_colors, _ = termcolor.get_theme_info()

local background_match = functions.closest_color_match(termcolor.colors.background, {pure_black, pure_white})
local color_mod_direction = -1

if background_match == pure_white then
  color_mod_direction = 1
end

local value_adjustment_scale = 0.25
-- print("------ termcolor test ------")
-- print("term_color type: ", type(term_colors))
--
-- local key_value_count = 0
-- local subkey_value_count = 0
-- for key, value in pairs(term_colors.colors) do
--   key_value_count = key_value_count + 1
--   print("key: " .. key)
--   if value then
--     if type(value) ~= "table" then
--       print("value: " .. value)
--     else
--       for subkey, subval in pairs(value) do
--         subkey_value_count = subkey_value_count + 1
--         print("  subkey: " .. subkey)
--         print("  subval: " .. subval)
--       end
--     end
--   else
--     print("value is nil")
--   end
-- end
-- print("key_value_count: " .. key_value_count)
-- print("subkey_value_count: " .. subkey_value_count)

-- print("-- ui table --")
-- local table_len = 0
-- for key, value in pairs(term_colors.ui) do
--   table_len = table_len + 1
--   print("key: " .. key .. " - value: " .. value)
-- end
-- print("ui table len: " .. table_len)
--
-- table_len = 0
--
-- print("-- palette table --")
-- for idx, value in ipairs(term_colors.palette) do
--   table_len = table_len + 1
--   print("idx: " .. idx .. " - value: " .. value)
-- end
-- print("palette table len: " .. table_len)
-- print("------ termcolor test end ------")

-- if term_colors == nil or term_colors.colors == nil then
--   term_colors.colors = {palette = {} }
-- end
--
-- if term_colors.colors.cursor_color == nil then term_colors.colors.cursor_color = pure_white end
-- if term_colors.colors.cursor_text == nil then term_colors.colors.cursor_text = pure_black end
-- if term_colors.colors.selection_background == nil then term_colors.colors.selection_background = pure_gray end
-- if term_colors.colors.background == nil then term_colors.colors.background = pure_black end
-- if term_colors.colors.selection_foreground == nil then term_colors.colors.selection_foreground = pure_white end
-- if term_colors.colors.foreground == nil then term_colors.colors.foreground = pure_white end
-- if term_colors.colors.palette[1] == nil then term_colors.colors.cursor_color = pure_black end
-- if term_colors.colors.palette[2] == nil then term_colors.colors.cursor_color = pure_red end
-- if term_colors.colors.palette[3] == nil then term_colors.colors.cursor_color = pure_green end
-- if term_colors.colors.palette[4] == nil then term_colors.colors.cursor_color = pure_blue end
-- if term_colors.colors.palette[5] == nil then term_colors.colors.cursor_color = pure_yellow end
-- if term_colors.colors.palette[6] == nil then term_colors.colors.cursor_color = pure_purple end
-- if term_colors.colors.palette[7] == nil then term_colors.colors.cursor_color = pure_orange end
-- if term_colors.colors.palette[8] == nil then term_colors.colors.cursor_color = pure_white end


---colors table
local colors = {
	---main colors
	main = {
		red      = functions.closest_color_match(pure_red   , term_colors.colors.palette),
		green    = functions.closest_color_match(pure_green , term_colors.colors.palette),
		yellow   = functions.closest_color_match(pure_yellow, term_colors.colors.palette),
		blue     = functions.closest_color_match(pure_blue  , term_colors.colors.palette),
		purple   = functions.closest_color_match(pure_purple, term_colors.colors.palette),
		cyan     = functions.closest_color_match(pure_cyan  , term_colors.colors.palette),
		orange   = functions.closest_color_match(pure_orange, term_colors.colors.palette),
  },
}

colors.main.darkred     = functions.adjust_color_value(colors.main.red   , 1 + (value_adjustment_scale * color_mod_direction))
colors.main.darkgreen   = functions.adjust_color_value(colors.main.green , 1 + (value_adjustment_scale * color_mod_direction))
colors.main.darkyellow  = functions.adjust_color_value(colors.main.yellow, 1 + (value_adjustment_scale * color_mod_direction))
colors.main.darkblue    = functions.adjust_color_value(colors.main.blue  , 1 + (value_adjustment_scale * color_mod_direction))
colors.main.darkcyan    = functions.adjust_color_value(colors.main.cyan  , 1 + (value_adjustment_scale * color_mod_direction))
colors.main.darkpurple  = functions.adjust_color_value(colors.main.purple, 1 + (value_adjustment_scale * color_mod_direction))
colors.main.darkorange  = functions.adjust_color_value(colors.main.orange, 1 + (value_adjustment_scale * color_mod_direction))
colors.main.paleblue    = functions.adjust_color_value(colors.main.blue  , 1 + (value_adjustment_scale * color_mod_direction * -1))

term_colors.colors.palette[17] = term_colors.colors.foreground
term_colors.colors.palette[18] = term_colors.colors.background
term_colors.colors.palette[19] = term_colors.colors.cursor_color
term_colors.colors.palette[20] = term_colors.colors.cursor_text
term_colors.colors.palette[21] = term_colors.colors.selection_background
term_colors.colors.palette[22] = term_colors.colors.selection_foreground

colors.main.gray     = functions.closest_color_match(pure_gray , term_colors.colors.palette)
colors.main.white    = functions.closest_color_match(pure_white, term_colors.colors.palette)
colors.main.black    = functions.closest_color_match(pure_black, term_colors.colors.palette)

	---colors applied to the editor
colors.editor = {
  link = colors.main.cyan,
  cursor = colors.main.yellow,
  title = term_colors.colors.foreground
}

colors.lsp = {
  error = colors.main.red,
}

colors.syntax = {}
colors.git = {}
colors.backgrounds = {}

-- {
--   ui = {
--     foreground = "#eeeeee",
--     background = "#1c1c1c",
--     cursor_color = "#eeeeee",
--     cursor_text = "#1c1c1c",
--     selection_background = "#444444",
--     selection_foreground = "#ffffff",
--   },
--   palette = {
--     "#000000", "#cd3131", "#0dbc79", "#e5e510",
--     "#2472c8", "#bc3fbc", "#11a8cd", "#e5e5e5",
--     "#666666", "#f14c4c", "#23d18b", "#f5f543",
--     "#3b8eea", "#d670d6", "#29b8db", "#ffffff",
--   }
-- }

		-- -- default Lighter theme style
		-- colors.editor.fg = "#546E7A"
		-- colors.editor.fg_dark = "#94A7B0"
		-- colors.editor.selection = "#80CBC4"
		-- colors.editor.line_numbers = "#CFD8DC"
		-- colors.editor.accent = "#00BCD4"
		-- colors.syntax.comments = "#AABFC9"
		--
		-- colors.main.red = "#E53935"
		-- colors.main.green = "#91B859"
		--
		-- colors.main.yellow = "#F6A434"
		-- colors.main.blue = "#6182B8"
		-- colors.main.paleblue = "#8796B0"
		-- colors.main.cyan = "#39ADB5"
		-- colors.main.purple = "#7C4DFF"
		-- colors.main.orange = "#F76D47"
		-- colors.main.pink = "#FF5370"
---editor colors
colors.editor.bg = term_colors.colors.background
colors.editor.bg_alt = functions.adjust_color_value(colors.editor.bg, 1 + (value_adjustment_scale * color_mod_direction))
colors.editor.fg = term_colors.colors.foreground
colors.editor.fg_dark = functions.adjust_color_value(colors.editor.fg, 1 + (value_adjustment_scale * color_mod_direction))
colors.editor.selection = term_colors.colors.selection_background
colors.editor.contrast = functions.adjust_color_value(colors.editor.selection, 1 + (value_adjustment_scale * color_mod_direction)) -- darker than selection
colors.editor.active = colors.editor.selection -- similar to selection
colors.editor.border = colors.editor.selection -- slightly darker than active
colors.editor.line_numbers = colors.editor.border -- about the same as border
colors.editor.highlight = colors.editor.selection
colors.editor.disabled = functions.adjust_color_value(colors.editor.highlight, 1 + (value_adjustment_scale * color_mod_direction * -1)) -- lighter than highlight
colors.editor.accent = colors.main.purple
colors.editor.none = "NONE"
colors.syntax.comments = colors.main.gray -- use main.gray

---syntax colors
colors.syntax.variable = colors.editor.fg
colors.syntax.field = colors.editor.fg
colors.syntax.keyword = colors.main.purple
colors.syntax.value = colors.main.orange
colors.syntax.operator = colors.main.cyan
colors.syntax.fn = colors.main.blue
colors.syntax.parameter = colors.main.paleblue
colors.syntax.string = colors.main.green
colors.syntax.type = colors.main.purple

---git colors
colors.git.added = colors.main.green
colors.git.removed = colors.main.red
colors.git.modified = colors.main.blue

---lsp colors
colors.lsp.warning = colors.main.yellow
colors.lsp.info = colors.main.paleblue
colors.lsp.hint = colors.main.purple

---contrasted backgrounds
colors.backgrounds.sidebars = colors.editor.bg
colors.backgrounds.floating_windows = colors.editor.bg
colors.backgrounds.non_current_windows = colors.editor.bg
colors.backgrounds.bg_blend = colors.editor.bg
colors.backgrounds.cursor_line = colors.editor.active

return colors
