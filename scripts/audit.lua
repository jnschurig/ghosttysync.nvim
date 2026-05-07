-- Contrast audit harness for ghosttysync.nvim.
-- Run via:  nvim --headless -l scripts/audit.lua [fixture_name]

local script_path = debug.getinfo(1, "S").source:sub(2)
local script_dir = script_path:match("(.*/)") or "./"
local repo_root = script_dir:gsub("scripts/$", "")
if repo_root == "" then repo_root = "./" end
package.path = repo_root .. "lua/?.lua;" .. repo_root .. "lua/?/init.lua;"
	.. repo_root .. "?.lua;" .. repo_root .. "?/init.lua;"
	.. package.path

vim.opt.runtimepath:prepend(repo_root)
vim.opt.termguicolors = true

local contrast = require("ghosttysync.colors.contrast")
local fixtures = require("tests.fixtures.palettes")

local THRESH = contrast.thresholds()

-- Decorative groups that exist as palette swatches or block-cursor pairs;
-- contrast against Normal bg is not a meaningful constraint.
local SKIP = {
	Black = true, Red = true, Green = true, Yellow = true, Blue = true,
	Cyan = true, Purple = true, Orange = true, White = true,
	Cursor = true, CursorIM = true, TermCursor = true, lCursor = true,
	-- Sign columns are intentionally dim; checked indirectly via DiagnosticSign* fg.
}

-- Classify a highlight name to its applicable threshold.
local function classify(name)
	if SKIP[name] then return nil end
	local lname = name:lower()
	-- Recessive groups: comments, conceal/whitespace/non-text, plugin dim indicators.
	if lname == "comment" or lname:match("^@comment") or lname == "lspinlayhint"
		or name == "SpecialComment" or name == "DiagnosticUnnecessary"
		or name == "DiagnosticDeprecated" or name == "Conceal"
		or name == "EndOfBuffer" or name == "NonText" or name == "Whitespace"
		or name == "Ignore" or name == "@lsp.type.comment"
		or name:match("^NeoTree.*Dim") or name:match("^NeoTree.*Fade")
		or name:match("^NeoTree.*Ignored") or name:match("^NeoTree.*Hidden")
		or name == "NeoTreeDotfile" or name == "NeoTreeExpander"
		or name == "NeoTreeIndentMarker" or name == "NeoTreeMessage"
		or name:match("^NeoTreeTabSeparator")
		or name:match("^BufferLine.*Diagnostic") or name:match("^BufferLine.*Separator")
		or name:match("^BufferLineDuplicate")
		or name:match("^GitSignsStaged") then
		return { kind = "comment", threshold = THRESH.COMMENT_MIN }
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
		return { kind = "text", threshold = THRESH.TEXT_MIN }
	end
	return { kind = "ui", threshold = THRESH.UI_MIN }
end

local function int_to_hex(n)
	if not n then return nil end
	return string.format("#%06x", n)
end

-- Apply a fixture by monkey-patching ghosttyconfig and reloading.
local function apply_fixture(fixture)
	-- Reset package state so colors / highlights re-evaluate.
	for k in pairs(package.loaded) do
		if k:match("^ghosttysync") then
			package.loaded[k] = nil
		end
	end

	-- Patch ghosttyconfig BEFORE colors loads.
	local cfg = require("ghosttysync.colors.ghosttyconfig")
	cfg.get_theme_info = function() return fixture, nil end

	-- Disable async so highlights apply immediately.
	require("ghosttysync.util.config").setup({ async_loading = false })

	vim.cmd("hi clear")
	vim.cmd("colorscheme ghosttysync")
end

-- Resolve a group's fg/bg, following links and inheriting bg from Normal.
local function resolve_hl(name, normal_bg)
	local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
	if not ok or not hl then return nil end
	local fg = int_to_hex(hl.fg)
	local bg = int_to_hex(hl.bg) or normal_bg
	return fg, bg, hl
end

-- The ghosttysync syntax-role names exposed by colors.syntax — used for
-- pairwise distinguishability checks. We re-derive them from the live `colors`
-- module rather than the highlight table because highlight bindings may shift.
local function get_role_colors()
	local colors = require("ghosttysync.colors.conditionals")
	return {
		keyword   = colors.syntax.keyword,
		type      = colors.syntax.type,
		fn        = colors.syntax.fn,
		parameter = colors.syntax.parameter,
		string    = colors.syntax.string,
		value     = colors.syntax.value,
		operator  = colors.syntax.operator,
		variable  = colors.syntax.variable,
		field     = colors.syntax.field,
	}
end

local ROLE_PAIRS = {
	{ "keyword", "type" },
	{ "fn", "parameter" },
	{ "string", "value" },
	{ "operator", "fn" },
	{ "variable", "field" },
}

local function audit_palette(fixture)
	apply_fixture(fixture)

	local _, normal_bg = resolve_hl("Normal", nil)
	if not normal_bg then normal_bg = fixture.colors.background end

	local groups = vim.api.nvim_get_hl(0, {})
	local results = {}
	local floor_violations = 0

	-- Sorted iteration for stable output.
	local names = {}
	for n, _ in pairs(groups) do table.insert(names, n) end
	table.sort(names)

	for _, name in ipairs(names) do
		local fg, bg = resolve_hl(name, normal_bg)
		local cls = fg and bg and classify(name)
		if cls and fg ~= bg then
			local ratio = contrast.wcag_ratio(fg, bg)
			local pass = ratio >= cls.threshold
			if not pass then
				if ratio < THRESH.MIN_FLOOR then
					floor_violations = floor_violations + 1
				end
				table.insert(results, {
					name = name, fg = fg, bg = bg,
					ratio = ratio, threshold = cls.threshold,
					kind = cls.kind,
				})
			end
		end
	end

	-- Pairwise distinguishability.
	local roles = get_role_colors()
	local pair_failures = {}
	for _, p in ipairs(ROLE_PAIRS) do
		local a, b = roles[p[1]], roles[p[2]]
		if a and b and a ~= b then
			local d = contrast.oklch_distance(a, b)
			if d < THRESH.MIN_ROLE_DISTANCE then
				table.insert(pair_failures, {
					a = p[1], a_color = a, b = p[2], b_color = b, distance = d,
				})
			end
		end
	end

	return {
		fixture = fixture,
		failures = results,
		pair_failures = pair_failures,
		floor_violations = floor_violations,
		normal_bg = normal_bg,
	}
end

local function print_report(rep)
	print(string.format("\n=== %s (bg=%s) ===", rep.fixture.name, rep.normal_bg))
	if #rep.failures == 0 then
		print("  contrast: all-pass")
	else
		print(string.format("  contrast: %d failure(s)", #rep.failures))
		print("  highlight                        kind     fg       bg       ratio  thr")
		print("  --------------------------------------------------------------------")
		for _, r in ipairs(rep.failures) do
			print(string.format("  %-32s %-8s %-8s %-8s %-6.2f %.2f",
				r.name:sub(1, 32), r.kind, r.fg, r.bg, r.ratio, r.threshold))
		end
	end

	if #rep.pair_failures == 0 then
		print("  distinguishability: all-pass")
	else
		print(string.format("  distinguishability: %d collision(s) (min=%.2f)",
			#rep.pair_failures, THRESH.MIN_ROLE_DISTANCE))
		for _, p in ipairs(rep.pair_failures) do
			print(string.format("    %s (%s) <-> %s (%s) dist=%.3f",
				p.a, p.a_color, p.b, p.b_color, p.distance))
		end
	end
end

-- Entry point.
local arg_name = (arg or {})[1]
local target_fixtures = fixtures
if arg_name then
	target_fixtures = {}
	for _, f in ipairs(fixtures) do
		if f.name:lower():gsub("%s", "") == arg_name:lower():gsub("%s", "") then
			table.insert(target_fixtures, f)
		end
	end
	if #target_fixtures == 0 then
		print("No fixture matches: " .. arg_name)
		os.exit(2)
	end
end

local total_floor = 0
for _, f in ipairs(target_fixtures) do
	local rep = audit_palette(f)
	print_report(rep)
	total_floor = total_floor + rep.floor_violations
end

print(string.format("\nDone. Floor violations across all fixtures: %d", total_floor))
if total_floor > 0 then os.exit(1) end
