local colors   = require("ghosttysync.colors")
local contrast = require("ghosttysync.colors.contrast")
local T        = contrast.thresholds()

local m = colors.main
local e = colors.editor

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

local mb = colors.lualine_mode_bgs
M.normal = {
	a = { fg = e.bg, bg = mb.normal, gui = "bold" },
	b = { fg = e.title, bg = e.bg_alt },
	c = { fg = e.fg, bg = e.active },
}

M.insert = {
	a = { fg = e.bg, bg = mb.insert, gui = "bold" },
	b = { fg = e.title, bg = e.bg_alt },
}

M.visual = {
	a = { fg = e.bg, bg = mb.visual, gui = "bold" },
	b = { fg = e.title, bg = e.bg_alt },
}

M.replace = {
	a = { fg = e.bg, bg = mb.replace, gui = "bold" },
	b = { fg = e.title, bg = e.bg_alt },
}

M.command = {
	a = { fg = e.bg, bg = mb.command, gui = "bold" },
	b = { fg = e.title, bg = e.bg_alt },
}

M.terminal = {
	a = { fg = e.bg, bg = mb.terminal, gui = "bold" },
	b = { fg = e.title, bg = e.bg_alt },
}

M.inactive = {
	a = { fg = e.disabled, bg = e.bg },
	b = { fg = e.disabled, bg = e.bg },
	c = { fg = e.disabled, bg = e.bg },
}

return fit_sections(M)
