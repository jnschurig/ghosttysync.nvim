-- :GhosttysyncAudit — runs the contrast audit against the *currently loaded*
-- palette and prints the report into a scratch buffer. For headless / CI
-- runs against fixtures, see scripts/audit.lua.

local M = {}

local SKIP = {
	Black = true, Red = true, Green = true, Yellow = true, Blue = true,
	Cyan = true, Purple = true, Orange = true, White = true,
	Cursor = true, CursorIM = true, TermCursor = true, lCursor = true,
}

local function classify(name, T)
	if SKIP[name] then return nil end
	local lname = name:lower()
	-- Recessive groups (intentionally low-contrast by design).
	if lname == "comment" or lname:match("^@comment") or lname == "lspinlayhint"
		or name == "SpecialComment" or name == "DiagnosticUnnecessary"
		or name == "DiagnosticDeprecated" or name == "Conceal"
		or name == "EndOfBuffer" or name == "NonText" or name == "Whitespace"
		or name == "Ignore" or name == "@lsp.type.comment"
		-- Plugin-recessive groups: dim file indicators, inactive separators, etc.
		or name:match("^NeoTree.*Dim") or name:match("^NeoTree.*Fade")
		or name:match("^NeoTree.*Ignored") or name:match("^NeoTree.*Hidden")
		or name == "NeoTreeDotfile" or name == "NeoTreeExpander"
		or name == "NeoTreeIndentMarker" or name == "NeoTreeMessage"
		or name:match("^NeoTreeTabSeparator")
		or name:match("^BufferLine.*Diagnostic") or name:match("^BufferLine.*Separator")
		or name:match("^BufferLineDuplicate")
		or name:match("^GitSignsStaged") then
		return { kind = "comment", threshold = T.COMMENT_MIN }
	end
	if name == "Normal" or name == "NormalFloat" or name == "NormalNC"
		or name == "NormalContrast" or name == "Pmenu" or name == "PmenuSel"
		or name == "StatusLine" or name == "StatusLineNC"
		or name == "TabLine" or name == "TabLineSel"
		or name == "Folded" or name == "Visual" or name == "Search"
		or name == "IncSearch" or name == "CurSearch"
		or name:match("^lualine_") then
		return { kind = "text", threshold = T.TEXT_MIN }
	end
	return { kind = "ui", threshold = T.UI_MIN }
end

local function int_to_hex(n)
	if not n then return nil end
	return string.format("#%06x", n)
end

local function resolve_hl(name, normal_bg)
	local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
	if not ok or not hl then return nil end
	return int_to_hex(hl.fg), int_to_hex(hl.bg) or normal_bg
end

---Run the audit and return a list of report lines.
function M.run()
	local contrast = require("ghosttysync.colors.contrast")
	local T = contrast.thresholds()

	local _, normal_bg = resolve_hl("Normal", nil)
	local groups = vim.api.nvim_get_hl(0, {})
	local names = {}
	for n, _ in pairs(groups) do table.insert(names, n) end
	table.sort(names)

	local lines = {
		"GhosttysyncAudit — current palette",
		"Normal bg: " .. tostring(normal_bg),
		string.format("Thresholds: TEXT=%.1f UI=%.1f COMMENT=%.1f FLOOR=%.1f",
			T.TEXT_MIN, T.UI_MIN, T.COMMENT_MIN, T.MIN_FLOOR),
		"",
	}
	local fails = 0
	for _, name in ipairs(names) do
		local fg, bg = resolve_hl(name, normal_bg)
		if fg and bg and fg ~= bg then
			local ratio = contrast.wcag_ratio(fg, bg)
			local cls = classify(name, T)
			if ratio < cls.threshold then
				fails = fails + 1
				table.insert(lines, string.format("%-36s %-8s fg=%s bg=%s %.2f < %.2f",
					name:sub(1, 36), cls.kind, fg, bg, ratio, cls.threshold))
			end
		end
	end
	if fails == 0 then
		table.insert(lines, "All highlights meet their thresholds.")
	else
		table.insert(lines, 1, string.format("%d failure(s)", fails))
	end
	return lines
end

---Open a scratch buffer with the report.
function M.show()
	local lines = M.run()
	vim.cmd("vnew")
	local buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false
	vim.api.nvim_buf_set_name(buf, "ghosttysync-audit")
end

vim.api.nvim_create_user_command("GhosttysyncAudit", function() M.show() end, {})

return M
