-- Test file for color_mapper.lua
-- Tests the highlight group mapping logic

-- Load the color_mapper module
local color_assignment = require("lua.ghosttysync.color_assignment")

-- Test data
local test_settings = {
	config = {
		debug = false,
		mode = "primary",
	},
	theme_colors = {
		background = "#1d262a",
		foreground = "#e7ebed",
		cursor_color = "#eaeaea",
		cursor_text = "#000000",
		selection_background = "#4e6a78",
		selection_foreground = "#e7ebed",
		palette = {
			"#435b67",
			"#fc3841",
			"#5cf19e",
			"#fed032",
			"#37b6ff",
			"#fc226e",
			"#59ffd1",
			"#ffffff",
			"#a1b0b8",
			"#fc746d",
			"#adf7be",
			"#fee16c",
			"#70cfff",
			"#fc669b",
			"#9affe6",
			"#ffffff",
		},
	},
}

local function test_color_assignment()
	print("testing...")
	local highlight_map, err = color_assignment.assign_colors_from_theme(test_settings)

	-- print(highlight_map)
	if type(highlight_map) == "table" then
		print("it's a table")
		for key, value in pairs(highlight_map) do
			if type(value) == "table" then
				print("table: " .. key)
				for i, j in pairs(value) do
					print(i .. ": " .. j)
				end
			else
				print(key .. ": " .. value)
			end
		end
	end

	if err then
		print(err)
		return false
	end
	return true
end

return test_color_assignment()

