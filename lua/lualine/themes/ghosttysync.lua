local colors   = require("ghosttysync.colors")
local style    = require("ghosttysync.util.config").settings.lualine_style
local contrast = require("ghosttysync.colors.contrast")
local T        = contrast.thresholds()

local m = colors.main
local e = colors.editor
local s = colors.syntax

-- Ensure each section's `fg` meets TEXT_MIN against its `bg`.
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

if style == "stealth" then
	M.normal = {
		a = { fg = e.accent, bg = e.highlight },
		b = { fg = e.title, bg = e.bg_alt },
		c = { fg = s.comments, bg = e.bg },
	}

	M.insert = {
		a = { fg = m.green, bg = e.highlight },
		b = { fg = e.title, bg = e.bg_alt },
	}

	M.visual = {
		a = { fg = m.magenta, bg = e.highlight },
		b = { fg = e.title, bg = e.bg_alt },
	}

	M.replace = {
		a = { fg = m.red, bg = e.highlight },
		b = { fg = e.title, bg = e.bg_alt },
	}

	M.command = {
		a = { fg = m.yellow, bg = e.highlight },
		b = { fg = e.title, bg = e.bg_alt },
	}

	M.inactive = {
		a = { fg = e.disabled, bg = e.bg },
		b = { fg = e.disabled, bg = e.bg },
		c = { fg = e.disabled, bg = e.bg },
	}
else
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
end

return fit_sections(M)
