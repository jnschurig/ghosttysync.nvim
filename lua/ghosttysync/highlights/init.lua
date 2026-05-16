local colors    = require "ghosttysync.colors"
local settings  = require "ghosttysync.util.config".settings
local plugins   = require "ghosttysync.highlights.plugins"
local functions = require "ghosttysync.functions"
local contrast  = require "ghosttysync.colors.contrast"
local T         = contrast.thresholds()
local styles    = settings.styles

-- Shorthand for ensure_contrast: returns the fg adjusted for readability against `bg`.
local function fit(fg, bg, threshold)
	return contrast.ensure_contrast(fg, bg, threshold)
end

-- apply conditional colors
colors = require "ghosttysync.colors.conditionals"

local m = colors.main
local e = colors.editor
local g = colors.git
local l = colors.lsp
local s = colors.syntax
local b = colors.backgrounds

local M = {}

---main highlight functions
M.main_highlights = {}

---async highlight functions
M.async_highlights = {}

---regular Vim syntax highlights
M.main_highlights.syntax = function()
  local syntax_hls = {
    Identifier     = { fg = s.variable },
    Comment        = { fg = s.comments },
    Keyword        = { fg = s.keyword },
    Conditional    = { fg = s.keyword },
    Function       = { fg = s.fn },
    Repeat         = { fg = s.keyword },
    String         = { fg = s.string },
    Type           = { fg = s.type },
    StorageClass   = { fg = m.cyan }, -- static, register, volatile, etc.
    Structure      = { fg = s.type },
    SpecialComment = { link = "Comment" }, -- special things inside a comment
    Constant       = { fg = m.yellow },
    Number         = { fg = s.value },
    Character      = { link = "Number" },
    Boolean        = { fg = m.green },
    Float          = { link = "Number" },
    Statement      = { fg = m.cyan },
    Label          = { fg = s.keyword }, -- case, default, etc.
    Operator       = { fg = s.operator },
    Exception      = { fg = m.red },
    Macro          = { fg = m.cyan },
    Include        = { link = "Macro" },
    -- Define         = { link = "Macro" },
    PreProc        = { link = "Macro" },
    -- PreCondit   = { link = "Macro" },
    Typedef        = { fg = m.red },
    Special        = { fg = m.cyan },
    SpecialChar    = { fg = m.red },
    Tag            = { fg = m.red },
    Delimiter      = { fg = s.operator }, -- ;
    Debug          = { fg = m.red },
    htmlLink       = { fg = e.link, underline = true },
    -- htmlH1         = { fg = m.cyan, bold = true },
    -- htmlH2         = { fg = m.red, bold = true },
    -- htmlH3         = { fg = m.green, bold = true },
  }

  -- apply the user-set styles for these groups
  syntax_hls.Comment      = vim.tbl_extend("keep", syntax_hls.Comment, styles.comments)
  syntax_hls.Conditional  = vim.tbl_extend("keep", syntax_hls.Conditional, styles.keywords)
  syntax_hls.Function     = vim.tbl_extend("keep", syntax_hls.Function, styles.functions)
  syntax_hls.Identifier   = vim.tbl_extend("keep", syntax_hls.Identifier, styles.variables)
  syntax_hls.Keyword      = vim.tbl_extend("keep", syntax_hls.Keyword, styles.keywords)
  syntax_hls.Repeat       = vim.tbl_extend("keep", syntax_hls.Repeat, styles.keywords)
  syntax_hls.String       = vim.tbl_extend("keep", syntax_hls.String, styles.strings)
  syntax_hls.Type         = vim.tbl_extend("keep", syntax_hls.Type, styles.types)
  syntax_hls.Structure    = vim.tbl_extend("keep", syntax_hls.Structure, styles.types)
  syntax_hls.StorageClass = vim.tbl_extend("keep", syntax_hls.StorageClass, styles.keywords)
  syntax_hls.Include      = vim.tbl_extend("keep", syntax_hls.Include, styles.keywords)

  return syntax_hls
end

---treesitter highlights
M.main_highlights.treesitter = function()

  if vim.fn.has("nvim-0.8.0") == 1 then
    local treesitter_hls = {
      ["@error"]            = { link = "Error" },

      ["@comment"]          = { link = "Comment" },
      ["@comment.todo"]     = { link = "Comment" },
      ["@comment.error"]    = { fg = e.bg, bg = l.error },
      ["@comment.warning"]  = { fg = e.bg, bg = l.warning },
      ["@comment.hint"]     = { fg = e.bg, bg = l.hint },
      ["@comment.note"]     = { fg = e.bg, bg = l.info },

      ["@type"]             = { fg = s.type },
      ["@type.builtin"]     = { fg = s.type },
      ["@type.definition"]  = { fg = m.type },
      ["@type.qualifier"]   = { fg = m.cyan },

      ["@variable"]           = { link = "Identifier" },
      ["@variable.builtin"]   = { link = "@keyword" },
      -- ["@field"]              = { fg = e.fg_dark },
      ["@property"]           = { fg = e.fg_dark },
      ["@variable.parameter"] = { link = "Identifier" },
      ["@variable.member"]    = { fg = e.fg_dark }, -- Fields
      ["@string.special.symbol"] = { fg = m.yellow },

      ["@function"]         = { link = "Function" },
      ["@function.call"]    = { link = "Function" },
      ["@function.builtin"] = { link = "Function" },
      ["@function.macro"]   = { link = "Function" },

      ["@function.method"]      = { link = "Function" },
      ["@function.method.call"] = { link = "Function" },

      ["@constructor"]      = { fg = m.blue },

      ["@keyword"]           = { fg = m.cyan },
      ["@keyword.coroutine"] = { fg = m.cyan, italic = true },
      ["@keyword.operator"]  = { link = "@keyword" },
      ["@keyword.return"]    = { link = "@keyword" },
      ["@keyword.function"]  = { link = "@keyword" },
      ["@keyword.export"]    = { link = "@keyword" },

      ["@keyword.conditional"]       = { link = "Conditional" },
      ["@keyword.repeat"]            = { link = "Repeat" },
      ["@keyword.import"]            = { link = "Include" },
      ["@keyword.exception"]         = { link = "Exception" },

      ["@constant"]         = { fg = m.yellow },
      ["@constant.builtin"] = { fg = m.green },
      ["@constant.macro"]   = { fg = m.cyan },

      ["@keyword.directive"] = { fg = m.cyan },
      ["@macro"]     = { fg = m.cyan },
      ["@module"] = { fg = m.yellow },

      ["@string"]         = { link = "String" },
      ["@string.escape"]  = { fg = m.bright_green },
      ["@string.regexp"]   = { fg = m.yellow },
      ["@string.special"] = { fg = m.bright_green },

      ["@character"] = { link = "Character" },
      ["@character.special"] = { link = "SpecialChar" },

      ["@diff.plus"]        = { link = "DiffAdd" },
      ["@diff.minus"]       = { link = "DiffDelete" },
      ["@diff.delta"]       = { link = "DiffChange" },
      ["@attribute"]        = { link = "DiffChange" },

      -- ["@structure"]             = { fg = s.type },
      ["@keyword.storage"]          = { fg = m.cyan },

      ["@label"]                  = { fg = m.yellow },
      ["@punctuation"]            = { fg = m.cyan },
      ["@punctuation.delimiter"]  = { fg = m.cyan },
      ["@punctuation.bracket"]    = { fg = m.cyan },
      ["@punctuation.special"]    = { fg = m.cyan },
      ["@markup.underline"]         = { underline = true },
      ["@markup.emphasis"]          = { italic = true },
      ["@markup.strong"]            = { bold = true },
      -- ["@markup.strikethrough"]     = { style = { "strikethrough" } },
      ["@markup.title"]             = { fg = m.cyan, bold = true },
      ["@markup.heading"]           = { fg = m.cyan, bold = true },
      ["@markup.literal"]           = { fg = m.green },
      ["@markup.link"]              = { link = "Tag" }, -- text references, footnotes, citations, etc.
      ["@markup.link.url"]          = { fg = e.link }, -- urls, links and emails
      ["@markup.math"]              = { fg = m.blue }, -- e.g. LaTeX math
      ["@markup.raw"]               = { fg = m.purple }, -- e.g. inline `code` in Markdown
      ["@markup.list"]              = { link = "Special" },
      ["@markup.list.checked"]      = { fg = m.green }, -- checkboxes
      ["@markup.list.unchecked"]    = { fg = s.text },
      ["@markup.environment"]       = { fg = m.red },
      ["@markup.environment.name"]  = { fg = m.red },
      ["@markup.warning"]           = { fg = l.warning },
      ["@markup.danger"]            = { fg = l.error },
      ["@tag"]                       = { fg = m.red },
      ["@tag.delimiter"]             = { fg = m.cyan },
      ["@tag.attribute"]             = { fg = m.purple },
      ["@keyword.directive.define"] = { link = "@keyword.directive" },
      ["@operator"]                  = { link = "Operator" },
      TreesitterContext              = { bg = e.contrast },
      TreesitterContextLineNumber    = { fg = fit(e.line_numbers, e.contrast, T.UI_MIN), bg = e.contrast },

      ["@boolean"]                = { link = "Boolean" },
      ["@number"]                 = { link = "Number" },
      ["@number.float"]           = { link = "Float" },
    }

    -- Legacy highlights, for backward compatibility
    treesitter_hls["@parameter"] = treesitter_hls["@variable.parameter"]
    treesitter_hls["@field"] = treesitter_hls["@variable.member"]
    treesitter_hls["@namespace"] = treesitter_hls["@module"]
    treesitter_hls["@float"] = treesitter_hls["number.float"]
    treesitter_hls["@symbol"] = treesitter_hls["@string.special.symbol"]
    treesitter_hls["@string.regex"] = treesitter_hls["@string.regexp"]

    treesitter_hls["@text"] = treesitter_hls["@markup"]
    treesitter_hls["@text.strong"] = treesitter_hls["@markup.strong"]
    treesitter_hls["@text.emphasis"] = treesitter_hls["@markup.italic"]
    treesitter_hls["@text.underline"] = treesitter_hls["@markup.underline"]
    treesitter_hls["@text.strike"] = treesitter_hls["@markup.strikethrough"]
    treesitter_hls["@text.uri"] = treesitter_hls["@markup.link.url"]
    treesitter_hls["@text.math"] = treesitter_hls["@markup.math"]
    treesitter_hls["@text.environment"] = treesitter_hls["@markup.environment"]
    treesitter_hls["@text.environment.name"] = treesitter_hls["@markup.environment.name"]

    treesitter_hls["@text.title"] = treesitter_hls["@markup.heading"]
    treesitter_hls["@text.literal"] = treesitter_hls["@markup.raw"]
    treesitter_hls["@text.reference"] = treesitter_hls["@markup.link"]

    treesitter_hls["@text.todo.checked"] = treesitter_hls["@markup.list.checked"]
    treesitter_hls["@text.todo.unchecked"] = treesitter_hls["@markup.list.unchecked"]

    -- @text.todo is now for todo comments, not todo notes like in markdown
    treesitter_hls["@text.todo"] = treesitter_hls["comment.warning"]
    treesitter_hls["@text.warning"] = treesitter_hls["comment.warning"]
    treesitter_hls["@text.note"] = treesitter_hls["comment.note"]
    treesitter_hls["@text.danger"] = treesitter_hls["comment.error"]

    treesitter_hls["@method"] = treesitter_hls["@function.method"]
    treesitter_hls["@method.call"] = treesitter_hls["@function.method.call"]

    treesitter_hls["@text.diff.add"] = treesitter_hls["@diff.plus"]
    treesitter_hls["@text.diff.delete"] = treesitter_hls["@diff.minus"]

    treesitter_hls["@define"] = treesitter_hls["@keyword.directive.define"]
    treesitter_hls["@preproc"] = treesitter_hls["@keyword.directive"]
    treesitter_hls["@storageclass"] = treesitter_hls["@keyword.storage"]
    treesitter_hls["@conditional"] = treesitter_hls["@keyword.conditional"]
    treesitter_hls["exception"] = treesitter_hls["@keyword.exception"]
    treesitter_hls["@include"] = treesitter_hls["@keyword.import"]
    treesitter_hls["@repeat"] = treesitter_hls["@keyword.repeat"]

    treesitter_hls["@keyword"]           = vim.tbl_extend("keep", treesitter_hls["@keyword"], styles.keywords)
    treesitter_hls["@keyword.directive"] = vim.tbl_extend("keep", treesitter_hls["@keyword.directive"], styles.keywords)

    return treesitter_hls
  else
    local treesitter_hls = {
      TSType        = { fg = s.type },
      TSTypeBuiltin = { fg = s.type },

      TSVariableBuiltin = { link = "Identifier" },
      TSField           = { fg = e.fg_dark },
      TSSymbol          = { fg = m.yellow },

      TSFuncBuiltin = { fg = s.fn },
      TSFuncMacro   = { link = "Function" },
      TSConstructor = { link = "Function" },

      TSKeyword = { fg = m.cyan },

      TSConstant        = { fg = m.yellow },
      TSConstantBuiltin = { fg = m.yellow },
      TSConstantMacro   = { fg = m.cyan },

      TSMacro     = { fg = m.cyan },
      TSNamespace = { fg = m.yellow },

      TSStringEscape  = { fg = e.fg_dark },
      TSStringRegex   = { fg = m.yellow },
      TSStringSpecial = { fg = e.fg_dark },

      TSPunct          = { fg = m.cyan },
      TSPunctDelimiter = { fg = m.cyan },
      TSPunctBracket   = { fg = e.title },
      TSURI            = { fg = e.link },
      TSTag            = { fg = m.red },
      TSTagDelimiter   = { fg = m.cyan },
      TSTagAttribute   = { fg = m.purple },
      TSTodo           = { fg = colors.yellow },
    }

    return treesitter_hls
  end
end

---parts of the editor that get loaded right away
M.main_highlights.editor = function()
  local editor_hls = {
    Normal           = { fg = e.fg, bg = e.bg },
    NormalFloat      = { fg = e.fg, bg = e.panel_bg },
    NormalContrast   = { fg = e.fg, bg = e.bg_alt }, -- a help group for contrast fileypes
    ColorColumn      = { fg = m.none, bg = e.active },
    Conceal          = { fg = e.disabled },
    Cursor           = { fg = e.cursor_fg, bg = e.cursor },
    TermCursor       = { link = "Cursor" }, -- cursor for the terminal
    CursorIM         = { link = "Cursor" }, -- like Cursor, but used when in IME mode
    ErrorMsg         = { fg = l.error },
    Folded           = { fg = fit(e.fg_dark, e.bg_alt, T.TEXT_MIN), bg = e.bg_alt, italic = true },
    FoldColumn       = { fg = m.blue },
    -- Active line number is the visible-priority anchor; inactive nudged
    -- away from it so they're perceptually distinct.
    CursorLineNr     = { fg = fit(e.accent, e.bg, T.UI_MIN) },
    LineNr           = {
        fg = contrast.nudge_apart(
            fit(e.accent, e.bg, T.UI_MIN),
            fit(e.line_numbers, e.bg, T.COMMENT_MIN),
            e.bg,
            T.MIN_ROLE_DISTANCE,
            T.COMMENT_MIN
        ),
    },
    DiffAdd          = { bg = functions.darken(g.added, 0.2, b.bg_blend) },
    DiffChange       = { bg = functions.darken(g.modified, 0.2, b.bg_blend) },
    DiffDelete       = { bg = functions.darken(g.removed, 0.2, b.bg_blend )},
    DiffText         = { fg = g.modified, reverse = true },
    ModeMsg          = { fg = e.accent }, -- 'showmode' message (e.g., "-- INSERT -- ")
    NonText          = { fg = e.disabled },
    SignColumn       = { fg = e.fg },
    SpecialKey       = { fg = m.purple },
    StatusLine       = { fg = fit(e.fg, e.active, T.TEXT_MIN), bg = e.active },
    StatusLineNC     = { fg = fit(e.fg_dark, e.bg, T.TEXT_MIN), bg = e.bg },
    StatusLineTerm   = { fg = fit(e.fg, e.active, T.TEXT_MIN), bg = e.active },
    StatusLineTermNC = { fg = fit(e.fg_dark, e.bg, T.UI_MIN), bg = e.bg },
    TabLineFill      = { fg = e.fg },
    TabLineSel       = { fg = fit(e.bg, e.accent, T.TEXT_MIN), bg = e.accent },
    TabLine          = { fg = e.fg },
    Title            = { fg = fit(m.cyan, e.bg, T.TEXT_MIN), bold = true },
    FloatTitle       = { fg = fit(m.cyan, e.bg, T.TEXT_MIN), bg = e.bg, bold = true },
    FloatFooter      = { fg = fit(m.cyan, e.bg, T.TEXT_MIN), bg = e.bg },
    WarningMsg       = { fg = m.yellow },
    Whitespace       = { fg = e.disabled },
    CursorLine       = { bg = b.cursor_line },
    -- CursorLine       = { bg = functions.adjust_color_value(e.bg, 0.75) },
    CursorColumn     = { link = "CursorLine" },
    Todo             = { fg = m.yellow, bold = true },
    Ignore           = { fg = e.disabled },
    Underlined       = { fg = e.links, underline = true },
    Error            = { fg = l.error, bold = true },
    -- Added            = { link = "DiffAdd" },
    -- Changed          = { link = "DiffChange" },
    -- Removed          = { link = "DiffDelete" },
    Added            = { fg = g.added, bold = true },
    Changed          = { fg = g.modified, bold = true },
    Removed          = { fg = g.removed, bold = true },

    -- color highlights
    Black  = { fg = m.black },
    Red    = { fg = m.red },
    Green  = { fg = m.green },
    Yellow = { fg = m.yellow },
    Blue   = { fg = m.blue },
    Cyan   = { fg = m.cyan },
    Purple = { fg = m.purple },
    Orange = { fg = m.yellow },
  }

  return editor_hls
end

---parts of the editor that get loaded asynchronously
M.async_highlights.editor = function()
  local editor_hls = {
    NormalNC      = { bg = b.non_current_windows },
    FloatBorder   = { fg = e.border_strong, bg = e.panel_bg },
    SpellBad      = { fg = m.red, italic = true, undercurl = true },
    SpellCap      = { fg = m.blue, italic = true, undercurl = true },
    SpellLocal    = { fg = m.cyan, italic = true, undercurl = true },
    SpellRare     = { fg = m.purple, italic = true, undercurl = true },
    Warnings      = { fg = m.yellow },
    healthError   = { fg = l.error },
    healthSuccess = { fg = m.green },
    healthWarning = { fg = m.yellow },
    -- Visual        = { fg = m.none, bg = e.selection },
    Visual        = { fg = fit(e.selection_fg, e.selection, T.TEXT_MIN), bg = e.selection },
    VisualNOS     = { link = "Visual" }, -- Visual mode selection when vim is "Not Owning the Selection".
    Directory     = { fg = m.blue },
    MatchParen    = { fg = m.yellow, bold = true },
    Question      = { fg = m.yellow }, -- |hit-enter| prompt and yes/no questions
    QuickFixLine  = { fg = fit(e.fg, e.selection, T.TEXT_MIN), bg = e.selection },
    -- Search        = { fg = e.title, bg = e.selection, bold = true },
    -- IncSearch     = { fg = e.title, bg = e.selection, underline = true },
    Search        = { fg = fit(e.bg, e.title, T.TEXT_MIN), bg = e.title },
    IncSearch     = { fg = fit(e.bg, e.title, T.TEXT_MIN), bg = e.title, bold = true },
    CurSearch     = { fg = fit(e.bg, m.yellow, T.TEXT_MIN), bg = m.yellow, bold = true },
    MoreMsg       = { fg = e.accent },
    Pmenu         = { fg = fit(e.selection_fg, e.selection, T.TEXT_MIN), bg = e.selection }, -- popup menu
    PmenuSel      = { fg = fit(e.bg, e.accent, T.TEXT_MIN), bg = e.accent }, -- Popup menu: selected item.
    PmenuSbar     = { bg = e.active },
    PmenuThumb    = { fg = e.fg },
    WildMenu      = { fg = m.yellow, bold = true }, -- current match in 'wildmenu' completion
    VertSplit     = { fg = fit(e.vsplit, e.bg, T.UI_MIN) },
    WinSeparator  = { fg = fit(e.vsplit, e.bg, T.UI_MIN) },
    diffAdded     = { fg = g.added },
    diffRemoved   = { fg = g.removed },
    -- ToolbarLine   = { fg = e.fg, bg = e.bg_alt },
    -- ToolbarButton = { fg = e.fg, bold = true },
    -- NormalMode       = { fg = e.disabled }, -- Normal mode message in the cmdline
    -- InsertMode       = { link = "NormalMode" },
    -- ReplacelMode     = { link = "NormalMode" },
    -- VisualMode       = { link = "NormalMode" },
    -- CommandMode      = { link = "NormalMode" },
  }

  editor_hls.EndOfBuffer = { fg = e.bg }

  return editor_hls
end

-- these should be loaded right away because
-- some plugins like lualine.nvim inherit the colors
M.main_highlights.load_lsp = function()
  local lsp_hls = {
    DiagnosticError       = { fg = l.error },
    DiagnosticWarn        = { fg = l.warning },
    DiagnosticInfo        = { fg = l.info },
    DiagnosticHint        = { fg = l.hint },
    DiagnosticOk          = { fg = m.green },
    DiagnosticDeprecated  = { link = "DiagnosticError" },
    DiagnosticInformation = { link = "DiagnosticInfo" },
  }

  return lsp_hls
end

M.async_highlights.load_lsp = function()
  local lsp_hls = {
    -- Nvim 0.6. and up

    DiagnosticFloatingError    = { link = "DiagnosticError" },
    DiagnosticSignError        = { link = "DiagnosticError" },
    DiagnosticUnderlineError   = { undercurl = true, sp = l.error },
    DiagnosticFloatingWarn     = { link = "DiagnosticWarn" },
    DiagnosticSignWarn         = { link = "DiagnosticWarn" },
    DiagnosticUnderlineWarn    = { undercurl = true, sp = l.warning },
    DiagnosticFloatingInfo     = { link = "DiagnosticInfo" },
    DiagnosticSignInfo         = { link = "DiagnosticInfo" },
    DiagnosticUnderlineInfo    = { undercurl = true, sp = l.info },
    DiagnosticFloatingHint     = { link = "DiagnosticHint" },
    DiagnosticSignHint         = { link = "DiagnosticHint" },
    DiagnosticUnderlineHint    = { undercurl = true, sp = l.hint },
    DiagnosticUnderlineOk      = { undercurl = true, sp = m.green },
    LspReferenceText           = { bg = e.selection }, -- used for highlighting "text" references
    LspReferenceRead           = { link = "LspReferenceText" }, -- used for highlighting "read" references
    LspReferenceWrite          = { link = "LspReferenceText" }, -- used for highlighting "write" references
    LspCodeLens                = { italic = true, fg = l.hint, sp = l.hint },
    LspInlayHint               = { italic = true, fg = s.comments },
    LspInfoBorder              = { fg = e.border },

    ["@lsp.type.builtinType"]                  = { link = "@type.builtin" },
    ["@lsp.type.comment"]                      = { link = "@comment" },
    ["@lsp.type.boolean"]                      = { link = "@boolean" },
    ["@lsp.type.enum"]                         = { link = "@type" },
    ["@lsp.type.enumMember"]                   = { link = "@constant" },
    ["@lsp.type.escapeSequence"]               = { link = "@string.escape" },
    ["@lsp.type.formatSpecifier"]              = { link = "@punctuation" },
    ["@lsp.type.interface"]                    = { link = "Identifier" },
    ["@lsp.type.keyword"]                      = { link = "@keyword" },
    ['@lsp.type.class']                        = { link = "@type" },
    ["@lsp.type.namespace"]                    = { link = "@module" },
    ["@lsp.type.number"]                       = { link = "@number" },
    ["@lsp.type.operator"]                     = { link = "@operator" },
    ["@lsp.type.parameter"]                    = { link = "@variable.parameter" },
    ["@lsp.type.property"]                     = { link = "@property" },
    ["@lsp.type.selfKeyword"]                  = { link = "@variable.builtin" },
    ["@lsp.type.typeAlias"]                    = { link = "@type" },
    ["@lsp.type.unresolvedReference"]          = { link = "@error" },
    ["@lsp.typemod.class.defaultLibrary"]      = { link = "@type.builtin" },
    ["@lsp.typemod.enum.defaultLibrary"]       = { link = "@type.builtin" },
    ["@lsp.typemod.enumMember.defaultLibrary"] = { link = "@constant.builtin" },
    ["@lsp.typemod.function.defaultLibrary"]   = { link = "@function.builtin" },
    ["@lsp.typemod.keyword.async"]             = { link = "@keyword.coroutine" },
    ["@lsp.typemod.macro.defaultLibrary"]      = { link = "@function.builtin" },
    ["@lsp.typemod.method.defaultLibrary"]     = { link = "@function.builtin" },
    ["@lsp.typemod.operator.injected"]         = { link = "@operator" },
    ["@lsp.typemod.string.injected"]           = { link = "@string" },
    ["@lsp.typemod.type.defaultLibrary"]       = { link = "@type.builtin" },
    ["@lsp.typemod.variable.defaultLibrary"]   = { link = "@variable.builtin" },
    ["@lsp.typemod.variable.injected"]         = { link = "@variable" },

  }

  lsp_hls.DiagnosticVirtualTextError = { link = "DiagnosticError" }
  lsp_hls.DiagnosticVirtualTextWarn  = { link = "DiagnosticWarn" }
  lsp_hls.DiagnosticVirtualTextInfo  = { link = "DiagnosticInfo" }
  lsp_hls.DiagnosticVirtualTextHint  = { link = "DiagnosticHint" }

  return lsp_hls
end

---Map :term colors directly to the ANSI palette indices.
M.load_terminal = function()
  vim.g.terminal_color_0  = m.black
  vim.g.terminal_color_1  = m.red
  vim.g.terminal_color_2  = m.green
  vim.g.terminal_color_3  = m.yellow
  vim.g.terminal_color_4  = m.blue
  vim.g.terminal_color_5  = m.purple
  vim.g.terminal_color_6  = m.cyan
  vim.g.terminal_color_7  = m.white
  vim.g.terminal_color_8  = m.bright_black
  vim.g.terminal_color_9  = m.bright_red
  vim.g.terminal_color_10 = m.bright_green
  vim.g.terminal_color_11 = m.bright_yellow
  vim.g.terminal_color_12 = m.bright_blue
  vim.g.terminal_color_13 = m.bright_purple
  vim.g.terminal_color_14 = m.bright_cyan
  vim.g.terminal_color_15 = m.bright_white
end

-- apply plugin highlights
M.main_highlights = vim.tbl_extend("keep", M.main_highlights, plugins.main_highlights)
M.async_highlights = vim.tbl_extend("keep", M.async_highlights, plugins.async_highlights)

return M
