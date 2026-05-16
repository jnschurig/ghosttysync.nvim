local colors = require "ghosttysync.colors"

local m = colors.main
local e = colors.editor

local M = {}

M.load = function()
    local plugin_hls = {
        NoiceCmdlineIcon              = { fg = m.bright_blue },
        NoiceCmdlineIconLua           = { fg = m.blue },
        NoiceCmdlineIconSearch        = { fg = m.bright_blue },
        NoiceCmdlinePopupTitle        = { fg = m.bright_blue },
        NoiceCmdlinePopupBorder       = { fg = e.border_strong },
        NoiceCmdlinePopupBorderSearch = { fg = e.border_strong },
        NoiceConfirmBorder            = { fg = e.border_strong },
    }

    return plugin_hls
end

M.async = true

return M
