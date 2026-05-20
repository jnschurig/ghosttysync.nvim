package.loaded["ghosttysync"] = nil
package.loaded["ghosttysync.util"] = nil
package.loaded["ghosttysync.colors"] = nil
package.loaded["ghosttysync.colors.conditionals"] = nil
package.loaded["ghosttysync.functions"] = nil
package.loaded["ghosttysync.highlights"] = nil
package.loaded["ghosttysync.highlights.plugins"] = nil
-- Lualine caches required theme modules; clear so re-sourcing this colorscheme
-- (e.g. after a Ghostty theme switch) picks up the freshly-derived palette
-- instead of the previous load's stale fg/bg values.
for k in pairs(package.loaded) do
  if k:match("^lualine%.themes%.ghosttysync") then
    package.loaded[k] = nil
  end
end

require("ghosttysync.util").load()
