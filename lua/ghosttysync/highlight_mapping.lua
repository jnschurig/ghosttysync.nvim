-- Color Mapper Module
-- Maps Ghostty terminal colors to Neovim highlight groups

local M = {}

-- Create highlight group mappings from Ghostty colors
function M.create_highlight_map(colors)
	if not colors or type(colors) ~= "table" then
		return nil, "Invalid colors provided"
	end

	local m = colors.main
	local e = colors.editor
	local g = colors.git
	local l = colors.lsp
	local s = colors.syntax
	local b = colors.backgrounds

	-- Core Neovim highlight groups
	local highlight_map = {
		Normal = { fg = e.fg, bg = e.bg },
		Comment = { fg = s.comments },
		SpecialComment = { link = "Comment" },
		Keyword = { fg = s.keyword },
		Label = { fg = s.keyword },
		Repeat = { fg = s.keyword },
		Conditional = { fg = s.keyword },
		String = { fg = s.string },
		Function = { fg = s.fn },
		Variable = { fg = s.variable },
		Type = { fg = s.type },
		Structure = { fg = s.type },
		Number = { fg = s.value },
		Character = { link = "Number" },
		Boolean = { link = "Number" },
		Float = { link = "Number" },
		Identifier = { fg = s.variable },
		Constant = { fg = m.yellow },
		Special = { fg = m.cyan },
		SpecialChar = { fg = m.red },
		Statement = { fg = m.cyan },
		Macro = { fg = m.cyan },
		Include = { link = "Macro" },
		StorageClass = { fg = m.cyan },
		-- Define = { link = "Macro" },
		-- PreProc = { link = "Macro" },
		-- PreCondit = { link = "Macro" },
		Operator = { fg = s.operator },
		Exception = { fg = m.red },
		Typedef = { fg = m.red },
		Tag = { fg = m.red },
		Delimiter = { fg = s.operator },
		Debug = { fg = m.red },
		htmlLink = { fg = e.link, underline = true },

		StatusLine = { fg = e.fg, bg = e.contrast },
		StatusLineNC = { fg = e.contrast, bg = e.bg },
		StatusLineTerm = { link = "StatusLine" },
		StatusLineTermNC = { link = "StatusLineNC" },

		TabLineSel = { bg = e.bg_alt, fg = e.fg_alt, bold = true },
		-- TabLineFill = { bg = e.bg_alt, fg = e.fg_alt, bold = true },
		lualine_c_normal = { bg = e.bg_alt },

		DiagnosticError = { fg = l.error },
		DiagnosticWarn = { fg = l.warning },
		DiagnosticHint = { fg = l.hint },
		DiagnosticInfo = { fg = l.info },

		-- Legacy diagnostic names for compatibility (no background colors)
		Error = { fg = l.error },
		Warning = { fg = l.warning },
		Hint = { fg = l.hint },
		Note = { fg = l.info },

		Warnings = { fg = l.warning },
		healthError = { fg = l.error },
		healthSuccess = { fg = m.green },
		healthWarning = { fg = l.warning },

		-- UI elements
		Cursor = { fg = e.cursor_text, bg = e.cursor },
		CursorLine = { bg = e.highlight },
		Visual = { bg = e.selection, fg = e.none },
		Search = { fg = e.bg, bg = e.title },
		IncSearch = { fg = e.bg, bg = e.title, bold = true },
		CurSearch = { fg = e.bg, bg = m.yellow, bold = true },

		NormalNC = { bg = b.non_current_windows },
		FloatBorder = { fg = e.border, bg = b.floating_windows },
		SpellBad = { fg = m.red, italic = true, undercurl = true },
		SpellCap = { fg = m.blue, italic = true, undercurl = true },
		SpellLocal = { fg = m.cyan, italic = true, undercurl = true },
		SpellRare = { fg = m.purple, italic = true, undercurl = true },
		VisualNOS = { link = "Visual" },
		Directory = { fg = m.blue },
		MatchParen = { fg = m.yellow, bold = true },
		Question = { fg = m.yellow }, -- |hit-enter| prompt and yes/no questions
		QuickFixLine = { fg = e.highlight, bg = e.title, reverse = true },
		MoreMsg = { fg = e.accent },
		Pmenu = { fg = e.fg, bg = e.border }, -- popup menu
		PmenuSel = { fg = e.contrast, bg = e.accent }, -- Popup menu: selected item.
		PmenuSbar = { bg = e.active },
		PmenuThumb = { fg = e.fg },
		WildMenu = { fg = m.orange, bold = true }, -- current match in 'wildmenu' completion
		VertSplit = { fg = e.border },
		WinSeparator = { fg = e.border },
		diffAdded = { fg = g.added },
		diffRemoved = { fg = g.removed },

		-- ToolbarLine   = { fg = e.fg, bg = e.bg_alt },
		-- ToolbarButton = { fg = e.fg, bold = true },
		-- NormalMode       = { fg = e.disabled }, -- Normal mode message in the cmdline
		-- InsertMode       = { link = "NormalMode" },
		-- ReplacelMode     = { link = "NormalMode" },
		-- VisualMode       = { link = "NormalMode" },
		-- CommandMode      = { link = "NormalMode" },

		DiagnosticFloatingError = { link = "DiagnosticError" },
		DiagnosticSignError = { link = "DiagnosticError" },
		DiagnosticUnderlineError = { undercurl = true, sp = l.error },
		DiagnosticFloatingWarn = { link = "DiagnosticWarn" },
		DiagnosticSignWarn = { link = "DiagnosticWarn" },
		DiagnosticUnderlineWarn = { undercurl = true, sp = l.warning },
		DiagnosticFloatingInfo = { link = "DiagnosticInfo" },
		DiagnosticSignInfo = { link = "DiagnosticInfo" },
		DiagnosticUnderlineInfo = { undercurl = true, sp = l.info },
		DiagnosticFloatingHint = { link = "DiagnosticHint" },
		DiagnosticSignHint = { link = "DiagnosticHint" },
		DiagnosticUnderlineHint = { undercurl = true, sp = l.hint },
		LspReferenceText = { bg = e.selection },
		LspReferenceRead = { link = "LspReferenceText" },
		LspReferenceWrite = { link = "LspReferenceText" },
		LspCodeLens = { italic = true, fg = l.hint, sp = l.hint },
		LspInlayHint = { italic = true, fg = s.comments },
		LspInfoBorder = { fg = e.border },
	}

	return highlight_map, nil
end

return M
