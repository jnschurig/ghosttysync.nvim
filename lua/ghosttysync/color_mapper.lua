-- Color Mapper Module
-- Maps Ghostty terminal colors to Neovim highlight groups

local M = {}

-- Example highlight group mapping structure
-- This serves as documentation for the expected highlight map format
M.HighlightMap = {
	-- Core highlight groups
	Normal = { fg = "#ffffff", bg = "#000000" },
	Comment = { fg = "#808080", italic = true },

	-- Syntax highlighting groups
	Keyword = { fg = "#ff6b6b", bold = true },
	Conditional = { fg = "#ff6b6b" },
	String = { fg = "#4ecdc4" },
	Function = { fg = "#45b7d1" },
	Variable = { fg = "#ffffff" },
	Type = { fg = "#96ceb4" },
	Number = { fg = "#feca57" },
	Identifier = { fg = "#ffffff" },
	Constant = { fg = "#ff00ff" },
	Special = { fg = "#80ffff" },
	Statement = { fg = "#ff8080" },
	PreProc = { fg = "#ff80ff" },
	Operator = { fg = "#ffffff" },

	-- Diagnostic highlight groups (modern)
	DiagnosticError = { fg = "#ff8080" },
	DiagnosticWarn = { fg = "#ffff80" },
	DiagnosticHint = { fg = "#80ffff" },
	DiagnosticInfo = { fg = "#8080ff" },

	-- Legacy diagnostic highlight groups
	Error = { fg = "#ff6b6b", bg = "#2d1b1b" },
	Warning = { fg = "#feca57", bg = "#2d2a1b" },
	Hint = { fg = "#4ecdc4", bg = "#1b2d2a" },
	Note = { fg = "#45b7d1", bg = "#1b252d" },

	-- UI elements
	Cursor = { fg = "#000000", bg = "#ffffff" },
	CursorLine = { bg = "#000000" },
	Visual = { bg = "#808080" },
	Search = { fg = "#000000", bg = "#ffff00" },
}

-- Create highlight group mappings from Ghostty colors
function M.create_highlight_map(colors, mode)
	if not colors or type(colors) ~= "table" then
		return nil, "Invalid colors provided"
	end

	-- Default mode to dark if not provided
	mode = mode or "dark"

	-- Use EXACT colors from theme without any modifications
	-- local exact_colors = validated_colors

	-- Extract essential colors with fallbacks
	local bg = colors.background or "#000000"
	local fg = colors.foreground or "#FFFFFF"
	local selection_bg = colors.selection_background or "#404040"
	local selection_fg = colors.selection_foreground or fg
	local palette = colors.palette or {}
	local cursor_color = colors.cursor_color
	local cursor_text = colors.cursor_text

	-- Core Neovim highlight groups

	-- Create base highlight map
	-- Syntax highlighting groups
	local highlight_map = {
		Normal = { fg = fg, bg = bg },
		Comment = { fg = palette[8] or "#808080", italic = true }, -- Use bright black for comments
		Keyword = { fg = palette[1], bold = true }, -- or "#FF0000", -- Red for keywords
		Conditional = { fg = palette[5] }, -- or "#FF0000", -- Red for conditionals (if, else, etc.)
		String = { fg = palette[2] }, -- or "#00FF00", -- Green for strings
		Function = { fg = palette[6] }, -- or "#0000FF", -- Blue for functions
		Variable = { fg = fg }, -- Use foreground color for variables
		Type = { fg = palette[4] }, -- or "#00FFFF", -- Cyan for types
		Number = { fg = palette[3] }, -- or "#FFFF00", -- Yellow for numbers
		Identifier = { fg = fg }, -- Use foreground for identifiers
		Constant = { fg = palette[4] }, -- or "#FF00FF", -- Magenta for constants
		Special = { fg = palette[7] }, -- or "#80FFFF", -- Bright cyan for special characters
		SpecialChar = { fg = palette[7] }, -- or "#80FFFF", -- Bright cyan for special characters
		Statement = { fg = palette[9] }, -- or "#FF8080", -- Bright red for statements
		PreProc = { fg = palette[5] }, -- or "#FF80FF", -- Bright magenta for preprocessor
		Operator = { fg = palette[6] }, -- or "#FFFFFF", -- White for operators

		DiagnosticError = { fg = palette[9] }, -- bg = selection_bg,  -- or "#FF8080", -- Bright red for errors
		DiagnosticWarn = { fg = palette[11] }, -- bg = selection_bg,  -- or "#FFFF80", -- Bright yellow for warnings
		DiagnosticHint = { fg = palette[14] }, -- bg = selection_bg,  -- or "#80FFFF", -- Bright cyan for hints
		DiagnosticInfo = { fg = palette[12] }, -- bg = selection_bg,

		-- Legacy diagnostic names for compatibility (no background colors)
		Error = { fg = palette[9] }, -- bg = selection_bg,  -- or "#FF8080", -- Bright red for errors
		Warning = { fg = palette[11] }, -- bg = selection_bg,  -- or "#FFFF80", -- Bright yellow for warnings
		Hint = { fg = palette[14] }, -- bg = selection_bg,  -- or "#80FFFF", -- Bright cyan for hints
		Note = { fg = palette[12] }, -- bg = selection_bg,

		-- UI elements
		Cursor = { fg = cursor_text, bg = cursor_color }, -- Use foreground color for cursor
		CursorLine = { bg = palette[0] }, -- bg = selection_bg or "#000000", -- Slightly different background for cursor line
		Visual = { bg = selection_bg }, -- fg = selection_fg Use selection colors for visual mode },
		-- Visual = { bg = palette[8] }, -- fg = selection_fg, -- Use selection colors for visual mode },
		Search = { fg = bg, bg = palette[7] }, -- or "#FFFF00", -- Yellow background for search
		IncSearch = { fg = bg, bg = palette[7] }, -- or "#FFFF00", -- Yellow background for search
		CurSearch = { fg = bg, bg = palette[3] }, -- or "#FFFF00", -- Yellow background for search
	}
	-- No color adjustments - use exact theme colors

	return highlight_map, nil
end

return M
