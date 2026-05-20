local colors = require("ghosttysync.colors")
local settings = require("ghosttysync.util.config").settings
local disabled = settings.disable

colors.editor.vsplit = colors.editor.border

-- disable the background
if disabled.background then
  colors.editor.bg = "NONE"
  colors.editor.bg_alt = "NONE"

  -- bg_blend is a blend *reference* (used by functions.darken to compute diff
  -- row tints), not a bg that should be transparent. Leave it alone.
  -- cursor_line is also kept: even on a transparent background the user still
  -- wants the active line to be visibly highlighted (and it differs from the
  -- Visual selection highlight).
  for _, k in ipairs({ "sidebars", "floating_windows", "non_current_windows" }) do
    colors.backgrounds[k] = "NONE"
  end
end

-- apply user defined colors
if type(settings.custom_colors) == "function" then
  settings.custom_colors(colors)
end

return colors
