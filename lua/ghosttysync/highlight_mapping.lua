-- Color Mapper Module
-- Maps Ghostty terminal colors to Neovim highlight groups

local M = {}

function M.set_lualine_highlight(colors)
	local m = colors.main
	local e = colors.editor

	local lualine_simple = {

		normal = {
			a = { fg = e.bg, bg = e.accent, gui = "bold" },
			b = { fg = e.title, bg = e.bg_alt },
			c = { fg = e.fg, bg = e.selection },
		},

		insert = {
			a = { fg = e.bg, bg = m.green, gui = "bold" },
			b = { fg = e.title, bg = e.bg_alt },
		},

		visual = {
			a = { fg = e.bg, bg = m.purple, gui = "bold" },
			b = { fg = e.title, bg = e.bg_alt },
		},

		replace = {
			a = { fg = e.bg, bg = m.red, gui = "bold" },
			b = { fg = e.title, bg = e.bg_alt },
		},

		command = {
			a = { fg = e.bg, bg = m.yellow, gui = "bold" },
			b = { fg = e.title, bg = e.bg_alt },
		},

		inactive = {
			a = { fg = e.disabled, bg = e.bg },
			b = { fg = e.disabled, bg = e.bg },
			c = { fg = e.disabled, bg = e.bg },
		},
	}

	local lualine = {}

	for action, action_table in pairs(lualine_simple) do
		for letter, settings in pairs(action_table) do
			local new_key = "lualine_" .. letter .. "_" .. action
			lualine[new_key] = settings
		end
	end

	-- lualine_transparent xxx gui=nocombine guifg=#e7ebed guibg=#1d262a
	-- lualine_a_insert xxx gui=bold,nocombine guifg=#1d262a guibg=#5cf19e
	-- lualine_b_insert xxx gui=nocombine guifg=#eeffff guibg=#435b67
	-- lualine_a_replace xxx gui=bold,nocombine guifg=#1d262a guibg=#fc3841
	-- lualine_b_replace xxx gui=nocombine guifg=#eeffff guibg=#435b67
	-- lualine_a_normal xxx gui=bold,nocombine guifg=#1d262a guibg=#fdcc09
	-- lualine_c_normal xxx gui=nocombine guifg=#e7ebed guibg=#4e6a78
	-- lualine_b_normal xxx gui=nocombine guifg=#eeffff guibg=#435b67
	-- lualine_a_inactive xxx gui=nocombine guifg=#464b5d guibg=#1d262a
	-- lualine_c_inactive xxx gui=nocombine guifg=#464b5d guibg=#1d262a
	-- lualine_b_inactive xxx gui=nocombine guifg=#464b5d guibg=#1d262a
	-- lualine_a_command xxx gui=bold,nocombine guifg=#1d262a guibg=#fee16c
	-- lualine_b_command xxx gui=nocombine guifg=#eeffff guibg=#435b67
	-- lualine_a_visual xxx gui=bold,nocombine guifg=#1d262a guibg=#fc226e
	-- lualine_b_visual xxx gui=nocombine guifg=#eeffff guibg=#435b67
	-- lualine_c_12_normal xxx gui=nocombine guifg=#59ffd1 guibg=#4e6a78
	-- lualine_c_12_insert xxx gui=nocombine guifg=#59ffd1 guibg=#4e6a78
	-- lualine_c_12_visual xxx gui=nocombine guifg=#59ffd1 guibg=#4e6a78
	-- lualine_c_12_replace xxx gui=nocombine guifg=#59ffd1 guibg=#4e6a78
	-- lualine_c_12_command xxx gui=nocombine guifg=#59ffd1 guibg=#4e6a78
	-- lualine_c_12_terminal xxx gui=nocombine guifg=#59ffd1 guibg=#4e6a78
	-- lualine_c_12_inactive xxx gui=nocombine guifg=#59ffd1 guibg=#1d262a
	-- lualine_c_diagnostics_error_normal xxx gui=nocombine guifg=#ff5370 guibg=#4e6a78
	-- lualine_c_diagnostics_error_insert xxx gui=nocombine guifg=#ff5370 guibg=#4e6a78
	-- lualine_c_diagnostics_error_visual xxx gui=nocombine guifg=#ff5370 guibg=#4e6a78
	-- lualine_c_diagnostics_error_replace xxx gui=nocombine guifg=#ff5370 guibg=#4e6a78
	-- lualine_c_diagnostics_error_command xxx gui=nocombine guifg=#ff5370 guibg=#4e6a78
	-- lualine_c_diagnostics_error_terminal xxx gui=nocombine guifg=#ff5370 guibg=#4e6a78
	-- lualine_c_diagnostics_error_inactive xxx gui=nocombine guifg=#ff5370 guibg=#1d262a
	-- lualine_c_diagnostics_warn_normal xxx gui=nocombine guifg=#fee16c guibg=#4e6a78
	-- lualine_c_diagnostics_warn_insert xxx gui=nocombine guifg=#fee16c guibg=#4e6a78
	-- lualine_c_diagnostics_warn_visual xxx gui=nocombine guifg=#fee16c guibg=#4e6a78
	-- lualine_c_diagnostics_warn_replace xxx gui=nocombine guifg=#fee16c guibg=#4e6a78
	-- lualine_c_diagnostics_warn_command xxx gui=nocombine guifg=#fee16c guibg=#4e6a78
	-- lualine_c_diagnostics_warn_terminal xxx gui=nocombine guifg=#fee16c guibg=#4e6a78
	-- lualine_c_diagnostics_warn_inactive xxx gui=nocombine guifg=#fee16c guibg=#1d262a
	-- lualine_c_diagnostics_info_normal xxx gui=nocombine guifg=#8cf8f7 guibg=#4e6a78
	-- lualine_c_diagnostics_info_insert xxx gui=nocombine guifg=#8cf8f7 guibg=#4e6a78
	-- lualine_c_diagnostics_info_visual xxx gui=nocombine guifg=#8cf8f7 guibg=#4e6a78
	-- lualine_c_diagnostics_info_replace xxx gui=nocombine guifg=#8cf8f7 guibg=#4e6a78
	-- lualine_c_diagnostics_info_command xxx gui=nocombine guifg=#8cf8f7 guibg=#4e6a78
	-- lualine_c_diagnostics_info_terminal xxx gui=nocombine guifg=#8cf8f7 guibg=#4e6a78
	-- lualine_c_diagnostics_info_inactive xxx gui=nocombine guifg=#8cf8f7 guibg=#1d262a
	-- lualine_c_diagnostics_hint_normal xxx gui=nocombine guifg=#fc226e guibg=#4e6a78
	-- lualine_c_diagnostics_hint_insert xxx gui=nocombine guifg=#fc226e guibg=#4e6a78
	-- lualine_c_diagnostics_hint_visual xxx gui=nocombine guifg=#fc226e guibg=#4e6a78
	-- lualine_c_diagnostics_hint_replace xxx gui=nocombine guifg=#fc226e guibg=#4e6a78
	-- lualine_c_diagnostics_hint_command xxx gui=nocombine guifg=#fc226e guibg=#4e6a78
	-- lualine_c_diagnostics_hint_terminal xxx gui=nocombine guifg=#fc226e guibg=#4e6a78
	-- lualine_c_diagnostics_hint_inactive xxx gui=nocombine guifg=#fc226e guibg=#1d262a
	-- lualine_x_6    xxx links to DiagnosticError
	-- lualine_x_7_normal xxx gui=nocombine guifg=#59ffd1 guibg=#4e6a78
	-- lualine_x_7_insert xxx gui=nocombine guifg=#59ffd1 guibg=#4e6a78
	-- lualine_x_7_visual xxx gui=nocombine guifg=#59ffd1 guibg=#4e6a78
	-- lualine_x_7_replace xxx gui=nocombine guifg=#59ffd1 guibg=#4e6a78
	-- lualine_x_7_command xxx gui=nocombine guifg=#59ffd1 guibg=#4e6a78
	-- lualine_x_7_terminal xxx gui=nocombine guifg=#59ffd1 guibg=#4e6a78
	-- lualine_x_7_inactive xxx gui=nocombine guifg=#59ffd1 guibg=#1d262a
	-- lualine_x_8_normal xxx gui=nocombine guifg=#fee16c guibg=#4e6a78
	-- lualine_x_8_insert xxx gui=nocombine guifg=#fee16c guibg=#4e6a78
	-- lualine_x_8_visual xxx gui=nocombine guifg=#fee16c guibg=#4e6a78
	-- lualine_x_8_replace xxx gui=nocombine guifg=#fee16c guibg=#4e6a78
	-- lualine_x_8_command xxx gui=nocombine guifg=#fee16c guibg=#4e6a78
	-- lualine_x_8_terminal xxx gui=nocombine guifg=#fee16c guibg=#4e6a78
	-- lualine_x_8_inactive xxx gui=nocombine guifg=#fee16c guibg=#1d262a
	-- lualine_x_9_normal xxx gui=nocombine guifg=#fc3841 guibg=#4e6a78
	-- lualine_x_9_insert xxx gui=nocombine guifg=#fc3841 guibg=#4e6a78
	-- lualine_x_9_visual xxx gui=nocombine guifg=#fc3841 guibg=#4e6a78
	-- lualine_x_9_replace xxx gui=nocombine guifg=#fc3841 guibg=#4e6a78
	-- lualine_x_9_command xxx gui=nocombine guifg=#fc3841 guibg=#4e6a78
	-- lualine_x_9_terminal xxx gui=nocombine guifg=#fc3841 guibg=#4e6a78
	-- lualine_x_9_inactive xxx gui=nocombine guifg=#fc3841 guibg=#1d262a
	-- lualine_x_10_normal xxx gui=nocombine guifg=#59ffd1 guibg=#4e6a78
	-- lualine_x_10_insert xxx gui=nocombine guifg=#59ffd1 guibg=#4e6a78
	-- lualine_x_10_visual xxx gui=nocombine guifg=#59ffd1 guibg=#4e6a78
	-- lualine_x_10_replace xxx gui=nocombine guifg=#59ffd1 guibg=#4e6a78
	-- lualine_x_10_command xxx gui=nocombine guifg=#59ffd1 guibg=#4e6a78
	-- lualine_x_10_terminal xxx gui=nocombine guifg=#59ffd1 guibg=#4e6a78
	-- lualine_x_10_inactive xxx gui=nocombine guifg=#59ffd1 guibg=#1d262a
	-- lualine_x_diff_added_normal xxx gui=nocombine guifg=#5cf19e guibg=#4e6a78
	-- lualine_x_diff_added_insert xxx gui=nocombine guifg=#5cf19e guibg=#4e6a78
	-- lualine_x_diff_added_visual xxx gui=nocombine guifg=#5cf19e guibg=#4e6a78
	-- lualine_x_diff_added_replace xxx gui=nocombine guifg=#5cf19e guibg=#4e6a78
	-- lualine_x_diff_added_command xxx gui=nocombine guifg=#5cf19e guibg=#4e6a78
	-- lualine_x_diff_added_terminal xxx gui=nocombine guifg=#5cf19e guibg=#4e6a78
	-- lualine_x_diff_added_inactive xxx gui=nocombine guifg=#5cf19e guibg=#1d262a
	-- lualine_x_diff_modified_normal xxx gui=nocombine guifg=#37b6ff guibg=#4e6a78
	-- lualine_x_diff_modified_insert xxx gui=nocombine guifg=#37b6ff guibg=#4e6a78
	-- lualine_x_diff_modified_visual xxx gui=nocombine guifg=#37b6ff guibg=#4e6a78
	-- lualine_x_diff_modified_replace xxx gui=nocombine guifg=#37b6ff guibg=#4e6a78
	-- lualine_x_diff_modified_command xxx gui=nocombine guifg=#37b6ff guibg=#4e6a78
	-- lualine_x_diff_modified_terminal xxx gui=nocombine guifg=#37b6ff guibg=#4e6a78
	-- lualine_x_diff_modified_inactive xxx gui=nocombine guifg=#37b6ff guibg=#1d262a
	-- lualine_x_diff_removed_normal xxx gui=nocombine guifg=#fc3841 guibg=#4e6a78
	-- lualine_x_diff_removed_insert xxx gui=nocombine guifg=#fc3841 guibg=#4e6a78
	-- lualine_x_diff_removed_visual xxx gui=nocombine guifg=#fc3841 guibg=#4e6a78
	-- lualine_x_diff_removed_replace xxx gui=nocombine guifg=#fc3841 guibg=#4e6a78
	-- lualine_x_diff_removed_command xxx gui=nocombine guifg=#fc3841 guibg=#4e6a78
	-- lualine_x_diff_removed_terminal xxx gui=nocombine guifg=#fc3841 guibg=#4e6a78
	-- lualine_x_diff_removed_inactive xxx gui=nocombine guifg=#fc3841 guibg=#1d262a
	return lualine, nil
end
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

		-- BufferLineTabSelected = { bg = e.bg_alt, fg = e.fg_alt, bold = true },
		-- TabLineSel = { bg = e.bg_alt, fg = e.fg_alt, bold = true },
		-- TabLineFill = { bg = e.bg_alt, fg = e.fg_alt, bold = true },
		-- lualine_c_normal = { bg = e.bg_alt },
		-- lualine_a_command = { bg = e.bg_alt },
		-- lualine_c_inactive = { bg = e.bg_alt },
		-- lualine_transparent = { fg = e.bg },

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

	-- local lualine_map = set_lualine_highlight(colors)
	--
	-- highlight_map = vim.tbl_deep_extend("keep", highlight_map, lualine_map)
	-- highlight_map.lualine = lualine_map

	return highlight_map, nil
end

return M
