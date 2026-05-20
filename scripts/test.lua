-- Plain test runner. Run via:  nvim --headless -l scripts/test.lua
-- Adds the repo's `lua/` to package.path so requires resolve when run directly.

local script_path = debug.getinfo(1, "S").source:sub(2) -- strip leading "@"
local script_dir = script_path:match("(.*/)") or "./"
local repo_root = script_dir:gsub("scripts/$", "")
if repo_root == "" then
  repo_root = "./"
end
package.path = repo_root .. "lua/?.lua;" .. repo_root .. "lua/?/init.lua;" .. package.path

local failures = 0
local passes = 0

local function check(name, ok, msg)
  if ok then
    passes = passes + 1
    print(string.format("  ok  %s", name))
  else
    failures = failures + 1
    print(string.format("  FAIL %s: %s", name, msg or "(no message)"))
  end
end

local function approx(a, b, tol)
  return math.abs(a - b) <= (tol or 1e-6)
end

local function hex_to_rgb(hex)
  hex = hex:gsub("#", "")
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

-- ---------- oklch ----------
print("oklch:")
local oklch = require("ghosttysync.colors.oklch")

do
  for _, hex in ipairs({ "#000000", "#ffffff", "#808080" }) do
    local back = oklch.oklch_to_hex(oklch.hex_to_oklch(hex))
    local r1, g1, b1 = hex_to_rgb(hex)
    local r2, g2, b2 = hex_to_rgb(back)
    local close = math.abs(r1 - r2) <= 1 and math.abs(g1 - g2) <= 1 and math.abs(b1 - b2) <= 1
    check("round-trip " .. hex, close, "got " .. back)
  end
end

do
  -- pure red/green/blue should round-trip with hue preserved within 1 degree
  for _, hex in ipairs({ "#ff0000", "#00ff00", "#0000ff" }) do
    local lch1 = oklch.hex_to_oklch(hex)
    local back = oklch.oklch_to_hex(lch1)
    local lch2 = oklch.hex_to_oklch(back)
    local dh = math.abs(lch1.h - lch2.h)
    if dh > 180 then
      dh = 360 - dh
    end
    check("hue preserved " .. hex, dh < 1, "delta_h=" .. dh)
  end
end

do
  -- gamut clamp: an OKLCH with high chroma should still produce a valid 7-char hex
  local out = oklch.oklch_to_hex({ L = 0.7, c = 0.5, h = 30 })
  check(
    "gamut clamp produces valid hex",
    type(out) == "string" and #out == 7 and out:match("^#%x%x%x%x%x%x$") ~= nil,
    "got " .. tostring(out)
  )
end

do
  -- set_lightness preserves hue
  local lch1 = oklch.hex_to_oklch("#ff0000")
  local lighter = oklch.set_lightness("#ff0000", 0.8)
  local lch2 = oklch.hex_to_oklch(lighter)
  local dh = math.abs(lch1.h - lch2.h)
  if dh > 180 then
    dh = 360 - dh
  end
  check("set_lightness preserves hue", dh < 2, "delta_h=" .. dh)
  check("set_lightness changes L", approx(lch2.L, 0.8, 0.05), "got L=" .. lch2.L)
end

-- ---------- contrast ----------
print("\ncontrast:")
local contrast = require("ghosttysync.colors.contrast")

do
  -- known WCAG ratios
  check(
    "wcag white on black ~= 21",
    approx(contrast.wcag_ratio("#ffffff", "#000000"), 21, 0.1),
    "got " .. contrast.wcag_ratio("#ffffff", "#000000")
  )
  check(
    "wcag identical = 1",
    approx(contrast.wcag_ratio("#808080", "#808080"), 1, 1e-9),
    "got " .. contrast.wcag_ratio("#808080", "#808080")
  )
end

do
  -- ensure_contrast lifts a low-contrast fg
  local low_fg = "#444444"
  local bg = "#222222"
  local ratio_before = contrast.wcag_ratio(low_fg, bg)
  local fixed, meets = contrast.ensure_contrast(low_fg, bg, 4.5)
  local ratio_after = contrast.wcag_ratio(fixed, bg)
  check(
    "ensure_contrast meets threshold on dark bg",
    meets,
    string.format("before=%.2f after=%.2f", ratio_before, ratio_after)
  )
  check("ensure_contrast no-op when already met", contrast.ensure_contrast("#ffffff", "#000000", 4.5) == "#ffffff")
end

do
  -- ensure_contrast preserves hue family
  local lch_before = oklch.hex_to_oklch("#aa3333")
  local fixed = contrast.ensure_contrast("#aa3333", "#222222", 7.0)
  local lch_after = oklch.hex_to_oklch(fixed)
  local dh = math.abs(lch_before.h - lch_after.h)
  if dh > 180 then
    dh = 360 - dh
  end
  check("ensure_contrast preserves hue", dh < 5, "delta_h=" .. dh)
end

do
  -- nudge_apart separates near-identical colors
  local a = "#3060a0"
  local b = "#3565a5"
  local dist_before = contrast.oklch_distance(a, b)
  local nudged, meets = contrast.nudge_apart(a, b, "#1a1a1a", 0.10, 3.0)
  local dist_after = contrast.oklch_distance(a, nudged)
  check("nudge_apart increases distance", meets, string.format("before=%.3f after=%.3f", dist_before, dist_after))
end

-- ---------- summary ----------
print(string.format("\n%d passed, %d failed", passes, failures))
if failures > 0 then
  os.exit(1)
end
