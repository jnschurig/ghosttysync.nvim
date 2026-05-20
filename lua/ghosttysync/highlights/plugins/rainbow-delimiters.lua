local colors = require "ghosttysync.colors"

local m = colors.main

local M = {}

M.load = function()
    local plugin_hls = {
        RainbowDelimiterRed = { fg = m.red },
        RainbowDelimiterYellow = { fg = m.yellow },
        RainbowDelimiterBlue = { fg = m.blue },
        RainbowDelimiterOrange = { fg = m.yellow },
        RainbowDelimiterGreen = { fg = m.green },
        RainbowDelimiterViolet = { fg = m.magenta },
        RainbowDelimiterCyan = { fg = m.cyan },
    }

    return plugin_hls
end

M.async = true

return M
