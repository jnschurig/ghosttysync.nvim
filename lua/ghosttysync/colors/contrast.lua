-- Contrast and perceptual-distance primitives.
-- All adjustments preserve hue (OKLCH-based) so the chosen palette's
-- color family is retained while readability is enforced.

local oklch = require("ghosttysync.colors.oklch")
local config = require("ghosttysync.util.config")

local M = {}

-- Default thresholds. Overridable via config.settings.contrast_thresholds.
M.defaults = {
	TEXT_MIN          = 4.5, -- WCAG AA body text
	UI_MIN            = 3.0, -- syntax tokens, decorative elements
	COMMENT_MIN       = 2.5, -- comments are intentionally recessive
	MIN_FLOOR         = 2.5, -- hard floor; below this the harness errors
	MIN_ROLE_DISTANCE = 0.10, -- OKLab Euclidean distance between adjacent roles
}

---Resolve thresholds with user overrides applied.
---@return table
function M.thresholds()
	local user = (config.settings or {}).contrast_thresholds or {}
	local out = {}
	for k, v in pairs(M.defaults) do
		out[k] = user[k] or v
	end
	return out
end

local function srgb_to_linear(c)
	if c <= 0.04045 then return c / 12.92 end
	return ((c + 0.055) / 1.055) ^ 2.4
end

local function hex_to_lin(hex)
	hex = hex:gsub("#", "")
	return srgb_to_linear(tonumber(hex:sub(1, 2), 16) / 255),
		srgb_to_linear(tonumber(hex:sub(3, 4), 16) / 255),
		srgb_to_linear(tonumber(hex:sub(5, 6), 16) / 255)
end

local function relative_luminance(hex)
	local r, g, b = hex_to_lin(hex)
	return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

---WCAG contrast ratio between two hex colors.
---@param fg string
---@param bg string
---@return number
function M.wcag_ratio(fg, bg)
	local lf = relative_luminance(fg)
	local lb = relative_luminance(bg)
	local lo, hi = math.min(lf, lb), math.max(lf, lb)
	return (hi + 0.05) / (lo + 0.05)
end

---Perceptual distance between two colors in OKLab (Euclidean).
---@param a string
---@param b string
---@return number
function M.oklch_distance(a, b)
	local A, B = oklch.hex_to_oklch(a), oklch.hex_to_oklch(b)
	-- Convert chroma+hue to OKLab a/b for Euclidean distance.
	local ah = A.h * math.pi / 180
	local bh = B.h * math.pi / 180
	local dL = A.L - B.L
	local da = A.c * math.cos(ah) - B.c * math.cos(bh)
	local db = A.c * math.sin(ah) - B.c * math.sin(bh)
	return math.sqrt(dL * dL + da * da + db * db)
end

---Adjust `fg`'s OKLCH lightness so contrast against `bg` meets `threshold`.
---Direction: away from bg's luminance (lighter on dark bg, darker on light bg).
---Hue is preserved; chroma may be reduced by gamut clamping.
---@param fg string
---@param bg string
---@param threshold number
---@return string new_fg
---@return boolean meets
function M.ensure_contrast(fg, bg, threshold)
	if M.wcag_ratio(fg, bg) >= threshold then
		return fg, true
	end

	local bg_lum = relative_luminance(bg)
	local lighten = bg_lum < 0.18 -- "dark" bg → push fg lighter
	local lch = oklch.hex_to_oklch(fg)
	local L = lch.L
	local step = 0.02
	local best = fg

	for _ = 1, 60 do
		L = lighten and (L + step) or (L - step)
		if L < 0 or L > 1 then break end
		lch.L = L
		local cand = oklch.oklch_to_hex(lch)
		best = cand
		if M.wcag_ratio(cand, bg) >= threshold then
			return cand, true
		end
	end

	-- Hit gamut boundary without meeting threshold.
	return best, false
end

---If `fg_a` and `fg_b` are perceptually too close, shift `fg_b`'s OKLCH L
---until the distance is met, while keeping `fg_b`'s contrast against `bg`
---above `contrast_threshold`. `fg_b` is the mutable side.
---@param fg_a string anchor (unchanged)
---@param fg_b string mutable
---@param bg string
---@param min_distance number
---@param contrast_threshold number
---@return string new_fg_b
---@return boolean meets
function M.nudge_apart(fg_a, fg_b, bg, min_distance, contrast_threshold)
	if M.oklch_distance(fg_a, fg_b) >= min_distance then
		return fg_b, true
	end

	local b_lch = oklch.hex_to_oklch(fg_b)
	local start_L = b_lch.L
	local step = 0.02
	local best = fg_b
	local best_meets = false

	-- Try both directions and pick whichever first achieves min_distance with
	-- contrast >= threshold. Falls back to the closest contrast-meeting candidate.
	for _, direction in ipairs({ 1, -1 }) do
		local L = start_L
		for _ = 1, 60 do
			L = L + direction * step
			if L < 0 or L > 1 then break end
			b_lch.L = L
			local cand = oklch.oklch_to_hex(b_lch)
			if M.wcag_ratio(cand, bg) >= contrast_threshold then
				best = cand
				if M.oklch_distance(fg_a, cand) >= min_distance then
					best_meets = true
					return cand, true
				end
			end
		end
	end

	return best, best_meets
end

return M
