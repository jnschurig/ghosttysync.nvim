# Colors module

This module is used to define the main colors used by the theme,
as well as the style specific colors and the colors that depend on the user config

files:
 ## **init.lua**:

 Used for defining main colors and style-specific colors.
 The module defines and returns a single colors table that contains all of the colors
 that the theme uses for highlighting.

 The colors table is further devided into subtables:
 ### main:
 This table contains main colors used mostly for syntax highlighting.
 Colors like blue, green, cyan, darkred, white etc. are defined here.
 ### editor:
 This table contains colors used for highlighting different parts of the editor.
 Colors like the main background, cursor, window-borders, visual mode background etc.
 are in this table.
 ### syntax:
 This table contains colors that will be used for syntax highlighting.
 The table contains these colors:
 + variable
 + keyword
 + value
 + operator
 + fn (function)
 + string
 + type
 ### backgrounds:
 This table contains background colors for different parts of the editor.
 These colors are going to be changed to a darker shade depending on the
 constrast table in the user setup function.

 ## **conditionals.lua**:
 Used for applying colors that depend on the user config.
 Also, this is the module that goes trough the contrast table
 and applies the darker backgrounds.

 ## ghosttyconfig.lua
 Used for fetching terminal colors as reported by the Ghostty api command
 `ghostty +show-config`. This command runs in other terminal emulators as well,
 so long as Ghostty is installed, configured, and is in the active Path.

 ## oklch.lua
 OKLCH color-space conversions and hue-preserving lightness helpers.
 All readability adjustments preserve hue (within ~5°) so the chosen
 Ghostty palette's color family is retained.

 ## contrast.lua
 Contrast and perceptual-distance primitives:
 - `wcag_ratio(fg, bg)` — standard WCAG ratio.
 - `ensure_contrast(fg, bg, threshold)` — lightens or darkens `fg` along OKLCH L
   until the WCAG ratio meets `threshold`. Hue is preserved; chroma may be
   reduced only by sRGB gamut clamping.
 - `nudge_apart(a, b, bg, min_distance, contrast_threshold)` — separates two
   nearly-identical role colors while keeping `b`'s contrast against `bg` valid.
 - `oklch_distance(a, b)` — perceptual ΔE.

 ### Thresholds
 Defaults (override via `setup({ contrast_thresholds = {...} })`):

 | Constant            | Default | Used for                                     |
 |---------------------|---------|----------------------------------------------|
 | `TEXT_MIN`          | 4.5     | Body text: Normal, lualine sections, popups  |
 | `UI_MIN`            | 3.0     | Syntax tokens, diagnostics, decorative text  |
 | `COMMENT_MIN`       | 2.5     | Comments and recessive groups                |
 | `MIN_FLOOR`         | 2.5     | Hard floor (audit fails below this)          |
 | `MIN_ROLE_DISTANCE` | 0.10    | Adjacent-role perceptual distance (OKLab)    |

 Loose-to-start; tighten as needed. The goal is "stay true to the chosen theme"
 while ensuring each highlight is readable. If a palette is too constrained for
 a target threshold, `ensure_contrast` returns the closest achievable color and
 the audit harness flags the case rather than silently producing a muddy color.

 ## Auditing readability
 - Headless run against all fixture palettes:
   `nvim --headless -l scripts/audit.lua`
 - Single fixture: `nvim --headless -l scripts/audit.lua "Aardvark Blue"`
 - Live audit of the currently loaded palette: `:GhosttysyncAudit`
 - Add a new fixture by dropping a file in `tests/fixtures/palettes/`
   (return a `term_colors`-shaped table) and registering it in
   `tests/fixtures/palettes/init.lua`.
