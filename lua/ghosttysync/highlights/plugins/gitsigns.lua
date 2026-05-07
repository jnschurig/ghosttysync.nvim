local colors = require "ghosttysync.colors"
local contrast = require "ghosttysync.colors.contrast"
local T = contrast.thresholds()

local e = colors.editor
local g = colors.git

local M = {}

M.load = function()
    -- Staged tier: live color routed through ensure_contrast at COMMENT_MIN
    -- against the sign-column bg. Stays perceptually dimmer than the live
    -- counterpart but legible (gitsigns' default staged colors fall well
    -- below the floor on most palettes).
    local staged_add      = contrast.ensure_contrast(g.added,    e.bg, T.COMMENT_MIN)
    local staged_change   = contrast.ensure_contrast(g.modified, e.bg, T.COMMENT_MIN)
    local staged_delete   = contrast.ensure_contrast(g.removed,  e.bg, T.COMMENT_MIN)

    local plugin_hls = {
        GitSignsAdd      = { fg = g.added },
        GitSignsChange   = { fg = g.modified },
        GitSignsDelete   = { fg = g.removed },
        GitSignsAddNr    = { fg = g.added },
        GitSignsAddLn    = { fg = g.added },
        GitSignsChangeNr = { fg = g.modified, bg = e.bg_num },
        GitSignsChangeLn = { fg = g.modified },
        GitSignsDeleteNr = { fg = g.removed, bg = e.bg_num },
        GitSignsDeleteLn = { fg = g.removed },

        GitSignsStagedAdd          = { fg = staged_add },
        GitSignsStagedAddCul       = { fg = staged_add },
        GitSignsStagedAddNr        = { fg = staged_add },
        GitSignsStagedChange       = { fg = staged_change },
        GitSignsStagedChangeCul    = { fg = staged_change },
        GitSignsStagedChangeNr     = { fg = staged_change },
        GitSignsStagedChangedelete = { fg = staged_change },
        GitSignsStagedChangedeleteCul = { fg = staged_change },
        GitSignsStagedChangedeleteNr  = { fg = staged_change },
        GitSignsStagedDelete       = { fg = staged_delete },
        GitSignsStagedDeleteCul    = { fg = staged_delete },
        GitSignsStagedDeleteNr     = { fg = staged_delete },
        GitSignsStagedTopdelete    = { fg = staged_delete },
        GitSignsStagedTopdeleteCul = { fg = staged_delete },
        GitSignsStagedTopdeleteNr  = { fg = staged_delete },
        GitSignsStagedUntracked    = { fg = staged_add },
        GitSignsStagedUntrackedCul = { fg = staged_add },
        GitSignsStagedUntrackedNr  = { fg = staged_add },
    }

    return plugin_hls
end

M.async = false

return M
