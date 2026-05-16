-- OKLCH color-space conversions.
-- Reference: https://bottosson.github.io/posts/oklab/

local M = {}

local function srgb_to_linear(c)
	if c <= 0.04045 then
		return c / 12.92
	end
	return ((c + 0.055) / 1.055) ^ 2.4
end

local function linear_to_srgb(c)
	if c <= 0.0031308 then
		return c * 12.92
	end
	return 1.055 * (c ^ (1 / 2.4)) - 0.055
end

local function clamp01(x)
	if x < 0 then return 0 end
	if x > 1 then return 1 end
	return x
end

local function hex_to_rgb01(hex)
	hex = hex:gsub("#", "")
	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)
	if not (r and g and b) then return nil end
	return r / 255, g / 255, b / 255
end

local function is_valid_hex(s)
	return type(s) == "string" and s:match("^#?%x%x%x%x%x%x$") ~= nil
end

M.is_valid_hex = is_valid_hex

local function rgb01_to_hex(r, g, b)
	r = math.floor(clamp01(r) * 255 + 0.5)
	g = math.floor(clamp01(g) * 255 + 0.5)
	b = math.floor(clamp01(b) * 255 + 0.5)
	return string.format("#%02x%02x%02x", r, g, b)
end

-- linear sRGB -> OKLab
local function linear_rgb_to_oklab(r, g, b)
	local l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
	local m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
	local s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

	local l_ = l ^ (1 / 3)
	local m_ = m ^ (1 / 3)
	local s_ = s ^ (1 / 3)

	-- handle negative cube roots from negative linear values (out-of-gamut input)
	if l < 0 then l_ = -((-l) ^ (1 / 3)) end
	if m < 0 then m_ = -((-m) ^ (1 / 3)) end
	if s < 0 then s_ = -((-s) ^ (1 / 3)) end

	local L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
	local a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
	local b2 = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_

	return L, a, b2
end

-- OKLab -> linear sRGB
local function oklab_to_linear_rgb(L, a, b)
	local l_ = L + 0.3963377774 * a + 0.2158037573 * b
	local m_ = L - 0.1055613458 * a - 0.0638541728 * b
	local s_ = L - 0.0894841775 * a - 1.2914855480 * b

	local l = l_ * l_ * l_
	local m = m_ * m_ * m_
	local s = s_ * s_ * s_

	local r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
	local g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
	local b2 = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

	return r, g, b2
end

local function lab_to_lch(L, a, b)
	local C = math.sqrt(a * a + b * b)
	local h = math.atan2(b, a) * 180 / math.pi
	if h < 0 then h = h + 360 end
	return L, C, h
end

local function lch_to_lab(L, C, h)
	local hr = h * math.pi / 180
	return L, C * math.cos(hr), C * math.sin(hr)
end

local function in_gamut(r, g, b)
	local eps = 1e-6
	return r >= -eps and r <= 1 + eps
		and g >= -eps and g <= 1 + eps
		and b >= -eps and b <= 1 + eps
end

-- Reduce chroma until the color is in sRGB gamut, preserving L and h.
local function clamp_to_gamut(L, C, h)
	local lo, hi = 0, C
	for _ = 1, 20 do
		local mid = (lo + hi) / 2
		local La, aa, ba = lch_to_lab(L, mid, h)
		local r, g, b = oklab_to_linear_rgb(La, aa, ba)
		if in_gamut(r, g, b) then
			lo = mid
		else
			hi = mid
		end
	end
	return L, lo, h
end

---Convert a `#rrggbb` hex string to OKLCH.
---@param hex string
---@return table { L=number (0..1), c=number, h=number (0..360) }
function M.hex_to_oklch(hex)
	if not is_valid_hex(hex) then return nil end
	local r, g, b = hex_to_rgb01(hex)
	if not r then return nil end
	local lr, lg, lb = srgb_to_linear(r), srgb_to_linear(g), srgb_to_linear(b)
	local L, a, b2 = linear_rgb_to_oklab(lr, lg, lb)
	local LL, C, h = lab_to_lch(L, a, b2)
	return { L = LL, c = C, h = h }
end

---Convert OKLCH back to `#rrggbb`. Reduces chroma to fit sRGB gamut while preserving L and h.
---@param lch table { L=number, c=number, h=number }
---@return string
function M.oklch_to_hex(lch)
	local L, C, h = lch.L, lch.c, lch.h
	local La, a, b = lch_to_lab(L, C, h)
	local r, g, b2 = oklab_to_linear_rgb(La, a, b)
	if not in_gamut(r, g, b2) then
		L, C, h = clamp_to_gamut(L, C, h)
		La, a, b = lch_to_lab(L, C, h)
		r, g, b2 = oklab_to_linear_rgb(La, a, b)
	end
	r = linear_to_srgb(clamp01(r))
	g = linear_to_srgb(clamp01(g))
	b2 = linear_to_srgb(clamp01(b2))
	return rgb01_to_hex(r, g, b2)
end

---Return a new hex with OKLCH lightness set to `L` (0..1), preserving hue and chroma.
---@param hex string
---@param L number
---@return string
function M.set_lightness(hex, L)
	local lch = M.hex_to_oklch(hex)
	if not lch then return hex end
	lch.L = clamp01(L)
	return M.oklch_to_hex(lch)
end

---Return a new hex with OKLCH lightness shifted by `delta`, preserving hue and chroma.
---@param hex string
---@param delta number
---@return string
function M.shift_lightness(hex, delta)
	local lch = M.hex_to_oklch(hex)
	if not lch then return hex end
	lch.L = clamp01(lch.L + delta)
	return M.oklch_to_hex(lch)
end

return M
