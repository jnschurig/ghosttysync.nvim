local colors   = require("ghosttysync.colors")
local contrast = require("ghosttysync.colors.contrast")
local T        = contrast.thresholds()

local m = colors.main
local e = colors.editor
local s = colors.syntax

local function fit_sections(theme)
	for _, mode in pairs(theme) do
		for _, section in pairs(mode) do
			if section.fg and section.bg and section.bg ~= "NONE" then
				section.fg = contrast.ensure_contrast(section.fg, section.bg, T.TEXT_MIN)
			end
		end
	end
	return theme
end

local M = {}

-- Stealth keeps a single neutral mode bg; modes are distinguished via fg.
-- Reuse the same distinct-color picker so fg's don't collide.
local mb = colors.lualine_mode_bgs

M.normal = {
	a = { fg = mb.normal, bg = e.highlight },
	b = { fg = e.title, bg = e.bg_alt },
	c = { fg = s.comments, bg = e.bg },
}

M.insert = {
	a = { fg = mb.insert, bg = e.highlight },
	b = { fg = e.title, bg = e.bg_alt },
}

M.visual = {
	a = { fg = mb.visual, bg = e.highlight },
	b = { fg = e.title, bg = e.bg_alt },
}

M.replace = {
	a = { fg = mb.replace, bg = e.highlight },
	b = { fg = e.title, bg = e.bg_alt },
}

M.command = {
	a = { fg = mb.command, bg = e.highlight },
	b = { fg = e.title, bg = e.bg_alt },
}

M.terminal = {
	a = { fg = mb.terminal, bg = e.highlight },
	b = { fg = e.title, bg = e.bg_alt },
}

M.inactive = {
	a = { fg = e.disabled, bg = e.bg },
	b = { fg = e.disabled, bg = e.bg },
	c = { fg = e.disabled, bg = e.bg },
}

return fit_sections(M)
