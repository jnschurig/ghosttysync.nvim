local colors = require "ghosttysync.colors"

local m = colors.main
local e = colors.editor
local s = colors.syntax

local M = {}

M.load = function()
    local plugin_hls = {
        CmpItemAbbr           = { fg = e.fg },
        CmpItemMenu           = { fg = e.disabled },
        CmpItemAbbrMatch      = { fg = e.accent, bold = true },
        CmpItemAbbrMatchFuzzy = { fg = e.fg, bold = true },

        CmpItemKind              = { fg = m.blue },
        CmpItemKindText          = { fg = s.comments },
        CmpItemKindMethod        = { fg = s.fn },
        CmpItemKindFunction      = { fg = s.fn },
        CmpItemKindContructor    = { fg = s.fn },
        CmpItemKindField         = { fg = m.cyan },
        CmpItemKindVariable      = { fg = m.bright_blue },
        CmpItemKindValue         = { fg = m.bright_blue },
        CmpItemKindConstant      = { fg = m.yellow },
        CmpItemKindClass         = { fg = s.type },
        CmpItemKindStruct        = { fg = s.type },
        CmpItemKindInterface     = { fg = s.type },
        CmpItemKindModule        = { fg = m.yellow },
        CmpItemKindProperty      = { fg = s.text },
        CmpItemKindKeyword       = { fg = s.keyword },
        CmpItemKindUnit          = { fg = m.green },
        CmpItemKindFile          = { fg = e.title },
        CmpItemKindFolder        = { fg = e.title },
        CmpItemKindSnippet       = { fg = m.green },
        CmpItemKindEvent         = { fg = m.blue },
        CmpItemKindTypeParameter = { fg = m.blue },
        CmpItemKindCopilot       = { fg = m.bright_cyan },
        CmpItemKindColor         = { fg = m.red },
        CmpItemKindEnum          = { fg = s.type }, -- TODO
        CmpItemEnumMember        = { fg = m.cyan }, -- TODO
        CmpItemKindOperator      = { fg = s.operator }, -- TODO
        CmpItemKindReference     = { fg = e.fg_dark }, -- TODO

    }

    return plugin_hls
end

M.async = true

return M
