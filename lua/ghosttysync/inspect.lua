local M = {}

local GROUPS = { "main", "editor", "syntax", "backgrounds" }

local function fg_for(hex)
  local r = tonumber(hex:sub(2, 3), 16) or 0
  local g = tonumber(hex:sub(4, 5), 16) or 0
  local b = tonumber(hex:sub(6, 7), 16) or 0
  return ((r * 299 + g * 587 + b * 114) / 1000 > 140) and "#000000" or "#ffffff"
end

local function ensure_swatch_hl(hex)
  local name = "GhosttysyncSwatch_" .. hex:sub(2)
  vim.api.nvim_set_hl(0, name, { bg = hex, fg = fg_for(hex) })
  return name
end

function M.show(opts)
  opts = opts or {}
  local colors = require("ghosttysync.colors")
  local buf = vim.api.nvim_create_buf(false, true)

  local lines, highlights = {}, {}
  local function push(line, hl_ranges)
    lines[#lines + 1] = line
    if hl_ranges then
      for _, r in ipairs(hl_ranges) do
        highlights[#highlights + 1] = { #lines - 1, r[1], r[2], r[3] }
      end
    end
  end

  local wanted = opts.group and { opts.group } or GROUPS
  for _, group in ipairs(wanted) do
    local tbl = colors[group]
    if type(tbl) ~= "table" then
      push("(" .. group .. " not found)")
    else
      push(group .. ":")
      local keys = {}
      for k in pairs(tbl) do
        keys[#keys + 1] = k
      end
      table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
      end)
      for _, k in ipairs(keys) do
        local v = tbl[k]
        if type(v) == "string" and v:match("^#%x%x%x%x%x%x$") then
          local label = string.format("  %-16s ", tostring(k))
          local swatch = "  " .. v .. "  "
          local line = label .. swatch
          local s_start = #label
          local s_end = s_start + #swatch
          push(line, { { ensure_swatch_hl(v), s_start, s_end } })
        else
          push(string.format("  %-16s %s", tostring(k), tostring(v)))
        end
      end
      push("")
    end
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  for _, h in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(buf, 0, h[2], h[1], h[3], h[4])
  end
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_set_name(buf, "ghosttysync-colors")
  vim.cmd("vnew")
  vim.api.nvim_win_set_buf(0, buf)
end

vim.api.nvim_create_user_command("GhosttysyncColors", function(a)
  M.show({ group = (a.args ~= "" and a.args) or nil })
end, {
  nargs = "?",
  complete = function()
    return GROUPS
  end,
})

return M
