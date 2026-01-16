local M = {}

---theme settings
local defaults = {
	contrast = {
		terminal = false,
		sidebars = false,
		cursor_line = false,
		floating_windows = false,
		lsp_virtual_text = false,
		non_current_windows = false,
		filetypes = {},
	},
	-- TODO: Deprecate styles.
	styles = {
		comments = {},
		strings = {},
		keywords = {},
		functions = {},
		variables = {},
		operators = {},
		types = {},
	},
	-- TODO: remove disable settings that don't make sense or don't align with the mission
	disable = {
		colored_cursor = false,
		borders = false,
		background = false,
		term_colors = false,
		eob_lines = false,
	},
	lualine_style = "default",
	plugins = {},
	async_loading = true,
}

M.settings = defaults

---setup function
---@param user_settings table user defined settings for the theme
M.setup = function(user_settings)
	M.settings = vim.tbl_deep_extend("force", {}, defaults, user_settings or {})
end

return M
