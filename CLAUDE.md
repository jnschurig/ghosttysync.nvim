# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Neovim colorscheme plugin that derives its palette at runtime from the active Ghostty terminal theme (shelling out to `ghostty +show-config`). Adapted from `material.nvim`. Design philosophy: pass terminal colors through with minimal customization, derive missing colors from the existing palette, and adjust readability along OKLCH lightness while preserving hue.

## Commands

- Unit tests (pure Lua, no Neovim env required for assertions but invoked via headless nvim):
  `nvim --headless -l scripts/test.lua`
- Full contrast audit against all fixture palettes in `tests/fixtures/palettes/`:
  `nvim --headless -l scripts/audit.lua`
- Audit a single fixture by name (matched case/space-insensitive):
  `nvim --headless -l scripts/audit.lua "rose-pine-moon"`
- Live audit against the currently loaded palette inside a running Neovim:
  `:GhosttysyncAudit`

`scripts/audit.lua` exits non-zero if any contrast `MIN_FLOOR` violations exist — treat it as the regression gate when changing color logic.

## Architecture

Entry point is `colors/ghosttysync.lua` (Neovim's `:colorscheme ghosttysync`), which clears cached modules and calls `ghosttysync.util.load()`. `lua/ghosttysync/init.lua` only exposes `setup()` from `util/config.lua`; setup just deep-merges user options into defaults — it does NOT load the theme.

Load order (`ghosttysync.util.load`):
1. `colors.ghosttyconfig` — runs `ghostty +show-config` and parses the palette/background/foreground/cursor/selection colors. `audit.lua` and tests monkey-patch `get_theme_info` to inject fixture palettes.
2. `colors.init` — defines `main` / `editor` / `syntax` / `backgrounds` tables seeded from the Ghostty palette.
3. `colors.conditionals` — applies the user's `contrast` table (darkens backgrounds for sidebars/floats/etc.) and exposes the final `colors.syntax.*` role assignments. This is where role colors are bound to palette indices and where `ensure_contrast` may shift them.
4. `highlights.init` + `highlights.plugins.*` — apply `nvim_set_hl`.
5. `lualine.themes.ghosttysync*` — three lualine theme variants derived from the same palette.

Readability pipeline lives in `colors/oklch.lua` (sRGB↔OKLCH, gamut-clamped) and `colors/contrast.lua`. Key invariants:
- `ensure_contrast` only moves along OKLCH L; hue is preserved within ~5°. Chroma is only reduced by sRGB gamut clamping.
- `nudge_apart` separates near-identical role colors while keeping the bg contrast valid.
- Thresholds (`TEXT_MIN=4.5`, `UI_MIN=3.0`, `COMMENT_MIN=2.5`, `MIN_FLOOR=2.5`, `MIN_ROLE_DISTANCE=0.10`, `PANEL_BG_OFFSET=0.03`, `PALETTE_BGFG_DIVERGENCE=0.08`) are overridable via `setup({ contrast_thresholds = {...} })`. See `lua/ghosttysync/colors/README.md`.

The audit harness checks six properties per fixture: per-group contrast against resolved bg, pairwise role distinguishability (`ROLE_PAIRS`), lualine mode-bg distinguishability, `*Border$` visibility, floating-panel bg ΔE from `Normal`, and palette index coverage (perceptual ΔE match, not exact hex — `ensure_contrast` shifts palette colors during role binding). Group classification (text/ui/comment) uses heuristic name patterns (`SKIP`, `COMMENT_PATTERNS`, the lualine/Telescope-title text-tier list) owned by `lua/ghosttysync/audit_classify.lua` and consumed by both `scripts/audit.lua` and `lua/ghosttysync/audit.lua`.

## Known limitations

- `disable.*` and `styles.*` options in `util/config.lua` are partly deprecated; the project is moving toward minimal configuration.
