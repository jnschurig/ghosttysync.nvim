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
local cls = require("ghosttysync.audit_classify")

local THRESH = contrast.thresholds()

local function classify(name) return cls.classify(name, THRESH) end

local function int_to_hex(n)
	if not n then return nil end
	return string.format("#%06x", n)
end

-- Apply a fixture by monkey-patching ghosttyconfig and reloading.
local function apply_fixture(fixture)
	-- Reset package state so colors / highlights re-evaluate.
	for k in pairs(package.loaded) do
		if k:match("^ghosttysync") or k:match("^lualine%.themes%.ghosttysync") then
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

	-- mode_bg_distinguishability: pairwise OKLCH distance over lualine mode-`a` bgs.
	-- Read from the theme table directly — lualine's runtime highlights aren't
	-- registered in headless mode.
	local mode_bg_failures = {}
	do
		local modes = { "normal", "insert", "visual", "replace", "command", "terminal" }
		local ok, theme = pcall(require, "lualine.themes.ghosttysync")
		if ok and type(theme) == "table" then
			local mode_bgs = {}
			for _, m in ipairs(modes) do
				if theme[m] and theme[m].a and theme[m].a.bg then
					mode_bgs[m] = theme[m].a.bg
				end
			end
			for i, a in ipairs(modes) do
				for j = i + 1, #modes do
					local b = modes[j]
					if mode_bgs[a] and mode_bgs[b] then
						local d = contrast.oklch_distance(mode_bgs[a], mode_bgs[b])
						if d < THRESH.MIN_ROLE_DISTANCE then
							table.insert(mode_bg_failures, {
								a = a, a_color = mode_bgs[a], b = b, b_color = mode_bgs[b], distance = d,
							})
						end
					end
				end
			end
		end
	end

	-- floating_border_visibility: any group whose name ends in "Border" must
	-- meet UI_MIN against Normal bg.
	local border_failures = {}
	for _, name in ipairs(names) do
		if name:match("Border$") then
			local fg, bg = resolve_hl(name, normal_bg)
			if fg and bg and fg ~= bg then
				local ratio = contrast.wcag_ratio(fg, bg)
				if ratio < THRESH.UI_MIN then
					table.insert(border_failures, {
						name = name, fg = fg, bg = bg, ratio = ratio,
					})
				end
			end
		end
	end

	-- floating_panel_bg_distinct: any group whose name matches the panel-bg
	-- heuristic must have ΔE >= PANEL_BG_OFFSET from Normal bg.
	local panel_bg_failures = {}
	local panel_re = "Float.*Bg$|Popup.*Bg$|Cmdline.*Bg|^NormalFloat$|^NoiceCmdlinePopup$|^TelescopePromptNormal$|^SnacksPicker.*Normal$"
	for _, name in ipairs(names) do
		-- Lua patterns lack alternation; check each subpattern.
		local matched = name:match("Float.*Bg$") or name:match("Popup.*Bg$")
			or name:match("Cmdline.*Bg") or name == "NormalFloat"
			or name == "NoiceCmdlinePopup" or name == "TelescopePromptNormal"
			or name:match("^SnacksPicker.*Normal$")
		if matched then
			local _, bg = resolve_hl(name, normal_bg)
			if bg and normal_bg and bg ~= normal_bg then
				local d = contrast.oklch_distance(bg, normal_bg)
				if d < THRESH.PANEL_BG_OFFSET then
					table.insert(panel_bg_failures, {
						name = name, bg = bg, normal_bg = normal_bg, distance = d,
					})
				end
			elseif bg == normal_bg then
				table.insert(panel_bg_failures, {
					name = name, bg = bg, normal_bg = normal_bg, distance = 0,
				})
			end
		end
	end
	-- Silence the unused-local warning while keeping the regex documented above.
	local _ = panel_re

	-- palette_coverage: every palette index 1..14 must be referenced by at
	-- least one applied highlight's fg or bg. Indices 0 and 15 are required
	-- only when distinctive (ΔE >= PALETTE_BGFG_DIVERGENCE from resolved bg/fg).
	local coverage_failures = {}
	do
		-- Build the set of distinct colors actually applied to highlights.
		-- We match palette indices to applied colors *perceptually* (ΔE) rather
		-- than by exact hex, because `ensure_contrast` shifts colors during
		-- role assignment — the literal palette hex rarely appears verbatim.
		local applied_list = {}
		local applied_set = {}
		for _, name in ipairs(names) do
			local fg, bg = resolve_hl(name, normal_bg)
			for _, c in ipairs({ fg, bg }) do
				if c and not applied_set[c:lower()] then
					applied_set[c:lower()] = true
					table.insert(applied_list, c)
				end
			end
		end
		-- Match threshold: a palette index counts as "covered" if any applied
		-- color is within this OKLab ΔE. ensure_contrast can shift saturated
		-- palette colors substantially when the bg luminance is extreme;
		-- bright (8..15) variants also tend to differ from their normal
		-- counterparts by more than a small ΔE. 0.12 ≈ "same hue family,
		-- different shade" which is what coverage really cares about.
		local function applied_near(palette_color)
			for _, c in ipairs(applied_list) do
				if contrast.oklch_distance(palette_color, c) < 0.12 then
					return true
				end
			end
			return false
		end
		local palette = fixture.colors.palette or {}
		local _, n_bg = resolve_hl("Normal", nil)
		local n_fg = (function() local f, _ = resolve_hl("Normal", normal_bg); return f end)()
		-- Dedupe by hex: many palettes have bright (8..15) duplicating normal (0..7).
		-- Report the lowest-index occurrence; downstream only needs one
		-- referencing highlight for that hue.
		local seen = {}
		for idx = 1, #palette do
			local color = palette[idx]
			if color then
				local lc = color:lower()
				local zero_idx = (idx - 1)
				if not seen[lc] then
					seen[lc] = true
					local required = true
					if zero_idx == 0 and n_bg then
						required = contrast.oklch_distance(color, n_bg) >= THRESH.PALETTE_BGFG_DIVERGENCE
					elseif zero_idx == 15 and n_fg then
						required = contrast.oklch_distance(color, n_fg) >= THRESH.PALETTE_BGFG_DIVERGENCE
					end
					if required and not applied_near(color) then
						table.insert(coverage_failures, { index = zero_idx, color = color })
					end
				end
			end
		end
	end

	return {
		fixture = fixture,
		failures = results,
		pair_failures = pair_failures,
		mode_bg_failures = mode_bg_failures,
		border_failures = border_failures,
		panel_bg_failures = panel_bg_failures,
		coverage_failures = coverage_failures,
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

	if #rep.mode_bg_failures == 0 then
		print("  mode_bg_distinguishability: all-pass")
	else
		print(string.format("  mode_bg_distinguishability: %d collision(s) (min=%.2f)",
			#rep.mode_bg_failures, THRESH.MIN_ROLE_DISTANCE))
		for _, p in ipairs(rep.mode_bg_failures) do
			print(string.format("    %s (%s) <-> %s (%s) dist=%.3f",
				p.a, p.a_color, p.b, p.b_color, p.distance))
		end
	end

	if #rep.border_failures == 0 then
		print("  floating_border_visibility: all-pass")
	else
		print(string.format("  floating_border_visibility: %d failure(s) (min ratio=%.2f)",
			#rep.border_failures, THRESH.UI_MIN))
		for _, b in ipairs(rep.border_failures) do
			print(string.format("    %-32s fg=%s bg=%s %.2f", b.name:sub(1, 32), b.fg, b.bg, b.ratio))
		end
	end

	if #rep.panel_bg_failures == 0 then
		print("  floating_panel_bg_distinct: all-pass")
	else
		print(string.format("  floating_panel_bg_distinct: %d failure(s) (min ΔE=%.2f)",
			#rep.panel_bg_failures, THRESH.PANEL_BG_OFFSET))
		for _, p in ipairs(rep.panel_bg_failures) do
			print(string.format("    %-32s bg=%s normal=%s ΔE=%.3f",
				p.name:sub(1, 32), p.bg, p.normal_bg, p.distance))
		end
	end

	if #rep.coverage_failures == 0 then
		print("  palette_coverage: all-pass")
	else
		print(string.format("  palette_coverage: %d unused index/indices",
			#rep.coverage_failures))
		for _, c in ipairs(rep.coverage_failures) do
			print(string.format("    palette[%d] = %s  (no applied highlight references it)",
				c.index, c.color))
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
