local colors = require("ghosttysync.colors")
local contrast = require("ghosttysync.colors.contrast")
local T = contrast.thresholds()

local e = colors.editor
local s = colors.syntax

local M = {}

M.load = function()
  -- bufferline uses three tab-bg variants: selected (Normal), visible
  -- (slightly off-bg), and the inactive fill (further off-bg). Override
  -- separator and diagnostic-tier groups so they meet COMMENT_MIN against
  -- whichever bg variant they render in.
  local sep = contrast.ensure_contrast(s.comments, e.bg, T.COMMENT_MIN)

  return {
    BufferLineSeparator = { fg = sep, bg = e.bg_alt },
    BufferLineSeparatorSelected = { fg = sep, bg = e.bg },
    BufferLineSeparatorVisible = { fg = sep, bg = e.bg },
    BufferLineTabSeparator = { fg = sep, bg = e.bg_alt },
    BufferLineTabSeparatorSelected = { fg = sep, bg = e.bg },
    BufferLineOffsetSeparator = { fg = sep, bg = e.bg_alt },
    BufferLineGroupSeparator = { fg = sep, bg = e.bg_alt },

    -- Inactive-tab diagnostic dots: dim but legible.
    BufferLineDiagnostic = { fg = sep, bg = e.bg_alt },
    BufferLineDiagnosticVisible = { fg = sep, bg = e.bg },
    BufferLineErrorDiagnostic = { fg = sep, bg = e.bg_alt },
    BufferLineErrorDiagnosticVisible = { fg = sep, bg = e.bg },
    BufferLineHintDiagnostic = { fg = sep, bg = e.bg_alt },
    BufferLineHintDiagnosticVisible = { fg = sep, bg = e.bg },
    BufferLineInfoDiagnostic = { fg = sep, bg = e.bg_alt },
    BufferLineInfoDiagnosticVisible = { fg = sep, bg = e.bg },
    BufferLineWarningDiagnostic = { fg = sep, bg = e.bg_alt },
    BufferLineWarningDiagnosticVisible = { fg = sep, bg = e.bg },
  }
end

M.async = false

return M
