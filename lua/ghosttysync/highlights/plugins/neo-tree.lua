local colors = require "ghosttysync.colors"
local settings = require "ghosttysync.util.config".settings
local contrast = require "ghosttysync.colors.contrast"
local T = contrast.thresholds()

local e = colors.editor
local s = colors.syntax
local g = colors.git
local b = colors.backgrounds

local M = {}

M.load = function()
    local plugin_hls = {
        NeoTreeNormal       = { bg = b.sidebars },
        NeoTreeNormalNC     = { bg = b.sidebars },
        NeoTreeCursorLine   = { bg = e.active },
        NeoTreeIndentMarker = { fg = e.border },
        NeoTreeTitleBar     = { fg = e.title, bg = b.floating_windows },

        NeoTreeGitAdded     = { fg = g.added },
        NeoTreeGitDeleted   = { fg = g.removed },
        NeoTreeGitIgnored   = { fg = e.disabled },
        NeoTreeGitModified  = { fg = g.modified },
        NeoTreeGitUnstaged  = { fg = g.added },
        NeoTreeGitUntracked = { fg = g.added },

        -- Override neo-tree's hardcoded near-black defaults so they meet
        -- COMMENT_MIN against the palette-derived bgs.
        NeoTreeTabSeparatorActive   = {
            fg = contrast.ensure_contrast(s.comments, e.bg, T.COMMENT_MIN),
            bg = e.bg,
        },
        NeoTreeTabSeparatorInactive = {
            fg = contrast.ensure_contrast(s.comments, e.bg_alt, T.COMMENT_MIN),
            bg = e.bg_alt,
        },
        NeoTreeFadeText1            = {
            fg = contrast.ensure_contrast(s.comments, e.bg, T.COMMENT_MIN),
        },
        NeoTreeFadeText2            = {
            fg = contrast.ensure_contrast(s.comments, e.bg, T.COMMENT_MIN),
        },
    }

    if settings.contrast.sidebars then
        plugin_hls.NeoTreeCursorLine = { bg = e.active }
    else
        plugin_hls.NeoTreeCursorLine = { bg = b.cursor_line }
    end

    return plugin_hls
end

M.async = true -- should the plugin highlights be loaded async [true/false]

return M
