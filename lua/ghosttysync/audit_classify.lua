-- Shared classification logic for the contrast audit. Used by both
-- :GhosttysyncAudit (live, in `ghosttysync.audit`) and the headless fixture
-- runner (`scripts/audit.lua`). Owns the canonical SKIP set, the
-- recessive/comment-class pattern list, and the per-name kind → threshold
-- classifier.

local M = {}

-- Decorative groups that exist as palette swatches or block-cursor pairs;
-- contrast against Normal bg is not a meaningful constraint.
M.SKIP = {
	Black = true, Red = true, Green = true, Yellow = true, Blue = true,
	Cyan = true, Magenta = true, Orange = true, White = true,
	Cursor = true, CursorIM = true, TermCursor = true, lCursor = true,
}

-- Heuristic substrings/suffixes (lowercased) marking a name as a
-- recessive/comment-class group. A heuristic ages better than an explicit
-- per-plugin allowlist.
M.COMMENT_PATTERNS = {
	"comment$", "blockquote$", "dim$", "dimtext$", "fade$", "fadetext%d*$",
	"indent$", "indentmarker$", "expander$", "message$", "duplicate",
	"hidden$", "ignored$", "dotfile$", "tabseparator", "separator$",
	"staged",
}

function M.is_comment_class(name)
	local lname = name:lower()
	if lname == "comment" or lname:match("^@comment") or lname == "lspinlayhint"
		or name == "SpecialComment" or name == "DiagnosticUnnecessary"
		or name == "DiagnosticDeprecated" or name == "Conceal"
		or name == "EndOfBuffer" or name == "NonText" or name == "Whitespace"
		or name == "Ignore" or name == "@lsp.type.comment" then
		return true
	end
	for _, p in ipairs(M.COMMENT_PATTERNS) do
		if lname:match(p) then return true end
	end
	return false
end

-- Classify a highlight name → { kind, threshold } using the given thresholds
-- table. Returns nil for groups that should be skipped.
function M.classify(name, T)
	if M.SKIP[name] then return nil end
	if M.is_comment_class(name) then
		return { kind = "comment", threshold = T.COMMENT_MIN }
	end
	-- Lualine decorative groups (transitional separators, diff/diagnostic
	-- icons rendered in section bgs) are UI tier, not body text.
	if name:match("^lualine_transitional_")
		or name:match("^lualine_.*_diff_")
		or name:match("^lualine_.*_diagnostics_")
		or name:match("^lualine_.*_filetype_MiniIcons") then
		return { kind = "ui", threshold = T.UI_MIN }
	end
	-- Text-like groups: editor body, lualine sections, popup body, statuslines.
	if name == "Normal" or name == "NormalFloat" or name == "NormalNC"
		or name == "NormalContrast" or name == "Pmenu" or name == "PmenuSel"
		or name == "StatusLine" or name == "StatusLineNC"
		or name == "TabLine" or name == "TabLineSel"
		or name == "Folded" or name == "FloatTitle" or name == "FloatFooter"
		or name == "Visual" or name == "VisualNOS" or name == "Search"
		or name == "IncSearch" or name == "CurSearch"
		or name == "WinBar" or name == "WinBarNC"
		or name:match("^lualine_") or name:match("^Telescope.*Title") then
		return { kind = "text", threshold = T.TEXT_MIN }
	end
	return { kind = "ui", threshold = T.UI_MIN }
end

return M
