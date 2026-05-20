local colors = require("ghosttysync.colors")
local contrast = require("ghosttysync.colors.contrast")
local T = contrast.thresholds()

local e = colors.editor
local fg = contrast.ensure_contrast(e.selection_fg, e.highlight, T.TEXT_MIN)

local M = {}

M.load = function()
  local plugin_hls = {
    IlluminatedWordText = { fg = fg, bg = e.highlight },
    IlluminatedWordRead = { fg = fg, bg = e.highlight },
    IlluminatedWordWrite = { fg = fg, bg = e.highlight, standout = true },
  }

  return plugin_hls
end

M.async = false

return M
