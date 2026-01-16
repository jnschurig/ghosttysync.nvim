local colors = require("ghosttysync.colors")
local settings = require("ghosttysync.util.config").settings
local disabled = settings.disable

-- disable borders
if disabled.borders then
	colors.editor.vsplit = colors.editor.bg
else
	colors.editor.vsplit = colors.editor.border
end

-- disable the background
if disabled.background then
	colors.editor.bg = "NONE"
	colors.editor.bg_alt = "NONE"

	for k, _ in pairs(settings.contrast) do
		colors.backgrounds[k] = "NONE"
	end
end

-- apply user defined colors
if type(settings.custom_colors) == "function" then
	settings.custom_colors(colors)
end

return colors
