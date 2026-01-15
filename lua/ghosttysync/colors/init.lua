-- local high_visibility = require "ghosttysync.util.config".settings.high_visibility
-- local termcolor = require("ghosttysync.colors.termcolor3")
local termcolor = require("ghosttysync.colors.ghosttyconfig")
-- local closest_color_match = require("ghosttysync.functions.functions.closest_color_match")
-- local adjust_color_value = require("ghosttysync.functions.functions.adjust_color_value")
local functions = require("ghosttysync.functions")

local pure_red    = "#ff0000"
local pure_green  = "#00ff00"
local pure_blue   = "#0000ff"
local pure_cyan   = "#00ffff"
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

local term_colors, error_message = termcolor.get_theme_info()

print("Testing ----")
if term_colors.name ~= nil then
  print("term_colors.name: " .. term_colors.name)
end
for key, value in pairs(term_colors) do
  print("key: " .. key)
end
if term_colors.colors ~= nil then
  print("term_colors.colors")
  for key, value in pairs(term_colors.colors) do
    print("key: ", key)
  end
end
print("End Testing ----")

if error_message then
  print("Error fetching theme info: " .. error_message)
  print("Setting pure_dark theme.")
  term_colors = {
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
      background = pure_black,
      foreground = pure_white,
      cursor_color = pure_white,
      cursor_text = pure_black,
      selection_foreground = pure_black,
      selection_background = pure_white,
    },
  }
end

local background_match = functions.closest_color_match(term_colors.colors.background, {pure_black, pure_white})
local color_mod_direction = -1

if background_match == pure_white then
  color_mod_direction = 1
end

local value_adjustment_scale = 0.25
-- local selection_benchmark_value = 50 -- 30 to 40 is pretty much perfect.
local selection_benchmark_value = 170

local selection_background_diff = functions.color_diff(term_colors.colors.foreground, term_colors.colors.selection_background)

local selection_adjustment_ratio = 1 - ((selection_benchmark_value - selection_background_diff) / 255 * color_mod_direction * -1)
local selection_background_color = functions.adjust_color_value(term_colors.colors.selection_background, selection_adjustment_ratio)
-- TODO: this value here, foreground, is coming up as nil... Yet somehow we are doing math on it?
-- It's broken for the "Desert" theme in particular. Do some nil checking maybe?
print("color: fg vs selection_bg | fg: " .. term_colors.colors.foreground .. " | selection_bg: " .. selection_background_color .. " | diff: " .. selection_background_diff)
---colors table
local colors = {
	---main colors
	main = {
		red    = functions.closest_color_match(pure_red   , term_colors.colors.palette),
		green  = functions.closest_color_match(pure_green , term_colors.colors.palette),
		yellow = functions.closest_color_match(pure_yellow, term_colors.colors.palette),
		blue   = functions.closest_color_match(pure_blue  , term_colors.colors.palette),
		purple = functions.closest_color_match(pure_purple, term_colors.colors.palette),
		cyan   = functions.closest_color_match(pure_cyan  , term_colors.colors.palette),
		orange = functions.closest_color_match(pure_orange, term_colors.colors.palette),
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

-- print("old cyan: " .. colors.main.cyan)
-- -- Ajust cyan color to be a bit darker on light backgrounds
-- if color_mod_direction == 1 then
--   colors.main.cyan = functions.adjust_color_value(colors.main.cyan, 0.5)
-- end
-- print("new cyan: " .. colors.main.cyan)

colors.main.darkred     = functions.adjust_color_value(colors.main.red   , 1 + (value_adjustment_scale * color_mod_direction))
colors.main.darkgreen   = functions.adjust_color_value(colors.main.green , 1 + (value_adjustment_scale * color_mod_direction))
colors.main.darkyellow  = functions.adjust_color_value(colors.main.yellow, 1 + (value_adjustment_scale * color_mod_direction))
colors.main.darkblue    = functions.adjust_color_value(colors.main.blue  , 1 + (value_adjustment_scale * color_mod_direction))
colors.main.darkcyan    = functions.adjust_color_value(colors.main.cyan  , 1 + (value_adjustment_scale * color_mod_direction))
colors.main.darkpurple  = functions.adjust_color_value(colors.main.purple, 1 + (value_adjustment_scale * color_mod_direction))
colors.main.darkorange  = functions.adjust_color_value(colors.main.orange, 1 + (value_adjustment_scale * color_mod_direction))
colors.main.paleblue    = functions.adjust_color_value(colors.main.blue  , 1 + (value_adjustment_scale * color_mod_direction * -1))

-- print("red: " .. colors.main.red)
-- print("green: " .. colors.main.green)
-- print("yellow: " .. colors.main.yellow)
-- print("blue: " .. colors.main.blue)
-- print("purple: " .. colors.main.purple)
-- print("cyan: " .. colors.main.cyan)
-- print("orange: " .. colors.main.orange)
-- print("darkred: " .. colors.main.darkred)
-- print("darkgreen: "  .. colors.main.darkgreen)
-- print("darkyellow: " .. colors.main.darkyellow)
-- print("darkblue: "   .. colors.main.darkblue)
-- print("darkpurple: " .. colors.main.darkpurple)
-- print("darkcyan: "   .. colors.main.darkcyan)
-- print("darkorange: " .. colors.main.darkorange)
-- print("paleblue: " .. colors.main.paleblue)

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
  -- cursor = colors.main.yellow,
  -- cursor_fg = term_colors.colors.selection_foreground,
  -- TODO: adjust these to be nicer. They work now.
  cursor = term_colors.colors.cursor_color,
  cursor_fg = term_colors.colors.cursor_text,
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

---editor colors
colors.editor.bg = term_colors.colors.background
colors.editor.bg_alt = functions.adjust_color_value(colors.editor.bg, 1 + (value_adjustment_scale * color_mod_direction))
colors.editor.fg = term_colors.colors.foreground
colors.editor.fg_dark = functions.adjust_color_value(colors.editor.fg, 1 + (value_adjustment_scale * color_mod_direction))
-- colors.editor.selection = term_colors.colors.selection_background
colors.editor.selection = selection_background_color
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
colors.git.modified = colors.main.yellow

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
