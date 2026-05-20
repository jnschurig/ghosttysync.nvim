local colors = require "ghosttysync.colors"

local m = colors.main
local e = colors.editor

local M = {}

M.load = function()
    local plugin_hls = {
        NeogitBranch               = { fg = m.bright_blue },
        NeogitRemote               = { fg = m.magenta },

        NeogitHunkHeader           = { fg = e.fg, bg = e.highlight },
        NeogitHunkHeaderHighlight  = { fg = m.blue, bg = e.contrast },

        NeogitDiffAdd              = { fg = m.green },
        NeogitDiffDelete           = { fg = m.red },

        NeogitDiffContextHighlight = { fg = e.fg_dark, bg = e.contrast },
        NeogitDiffDeleteHighlight  = { fg = m.red },
        NeogitDiffAddHighlight     = { fg = m.yellow },

        NeogitNotificationInfo     = { fg = m.bright_blue },
        NeogitNotificationWarning  = { fg = m.yellow },
        NeogitNotificationError    = { fg = m.red },
    }

    return plugin_hls
end

M.async = true

return M
