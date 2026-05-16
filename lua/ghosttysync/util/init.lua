local highlights = require("ghosttysync.highlights")
local colors = require("ghosttysync.colors")
local settings = require("ghosttysync.util.config").settings
local functions = require("ghosttysync.functions")
require("ghosttysync.audit") -- registers :GhosttysyncAudit

local M = {}

---apply highlights for a given table
---@param extra_highlights table highlight group names and their values
local apply_highlights = function(extra_highlights)
	for name, values in pairs(extra_highlights) do
		local hl_val = {}
		if type(values) == "table" then
			hl_val = values
		elseif type(values) == "function" then
			local ret = values(colors, highlights)
			if type(ret) == "table" then
				hl_val = ret
			else
				vim.notify_once(
					"highlight function for highlight-group '"
						.. name
						.. "' returned '"
						.. type(ret)
						.. "', expected table",
					vim.log.levels.ERROR,
					{ title = "ghosttysync.nvim" }
				)
			end
		else
			vim.notify_once(
				"cannot create custom highlight '" .. name .. "' from value of type '" .. type(values) .. "'",
				vim.log.levels.ERROR,
				{ title = "ghosttysync.nvim" }
			)
		end
		vim.api.nvim_set_hl(0, name, hl_val)
	end
end

---prepare environment
local prepare_environment = function()
	if vim.g.colors_name then
		vim.cmd("hi clear")
	end

	vim.g.colors_name = "ghosttysync"
	vim.opt.termguicolors = true

	if vim.fn.exists("syntax_on") then
		vim.cmd("syntax reset")
	end

	vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,a:Cursor/Cursor"
	local exit_group = vim.api.nvim_create_augroup("MaterialExit", { clear = true })
	vim.api.nvim_create_autocmd({ "ExitPre", "ColorSchemePre" }, {
		command = "autocmd ExitPre * set guicursor=n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20",
		group = exit_group,
	})
end

---async clojure
local async

---loads highlights asynchronously
local load_async = function()
	for _, fn in pairs(highlights.async_highlights) do
		-- fn() returns a table of highlights to be applied
		apply_highlights(fn())
	end

	-- load terminal colors
	highlights.load_terminal()

	-- load user defined higlights
	if type(settings.custom_highlights) == "table" then
		apply_highlights(settings.custom_highlights)
	elseif type(settings.custom_highlights) == "function" then
		apply_highlights(settings.custom_highlights(colors))
	end

	-- if this function gets called asyncronously, this closure is needed
	if async then
		async:close()
	end
end

---Reapply every highlight group ghosttysync owns. Used by the post-VeryLazy
---reapplication so plugins that set their own highlights via ColorScheme
---autocmds don't get the last word over our overrides.
local function apply_all_highlights()
	for _, fn in pairs(highlights.main_highlights) do
		apply_highlights(fn())
	end
	for _, fn in pairs(highlights.async_highlights) do
		apply_highlights(fn())
	end
end

---loads the theme and applies the highlights
M.load = function()
	prepare_environment()

	-- schedule the async function if async is enabled
	if settings.async_loading then
		async = vim.loop.new_async(vim.schedule_wrap(load_async))
	end

	-- apply highlights one by one
	for _, fn in pairs(highlights.main_highlights) do
		-- fn() returns a table of highlights to be applied
		apply_highlights(fn())
	end

	-- if async is enabled, send the function
	if settings.async_loading then
		async:send()
	else
		load_async()
	end

	-- Apply configured lualine theme so our contrast-fitted theme is used by default.
	functions.apply_lualine_theme()

	-- After Lazy reports VeryLazy, plugins have registered their ColorScheme
	-- autocmds and applied their own highlights. Reapply ours so our overrides
	-- in highlights/plugins/*.lua take precedence.
	if vim.v.vim_did_enter == 1 then
		vim.schedule(apply_all_highlights)
	else
		vim.api.nvim_create_autocmd("User", {
			pattern = "VeryLazy",
			once = true,
			callback = apply_all_highlights,
		})
	end
end

return M
