-- mod-version:3

--[[
  Lite-XL plugin to sort CSS properties alphabetically or using
  the concentric model by https://rhodesmill.org/brandon/2011/concentric-css/

  This plugin is based on vscode plugin: https://github.com/roubaobaozi/vscode-sort-selection-concentrically

  Usage:
  1. Select CSS code (must have one property per line).
  2. Press control+alt+a to sort alphabetically or control+alt+c to sort concentrically.
     Alternatively you can also right-click and select the appropriate option.
--]]

local core = require "core"
local config = require "core.config"
local common = require "core.common"
local command = require "core.command"
local keymap = require "core.keymap"
local contextmenu = require "plugins.contextmenu"

local css_syntaxes = {
  "CSS",
  "HTML",
  "JSX",
  "TypeScript with JSX",
}

local concentric_order = {
  -- browser default styles
  "all",
  "appearance",

  -- box model
  "box-sizing",

  -- position
  "display",
  "position",
  "top",
  "right",
  "bottom",
  "left",

  "float",
  "clear",

  -- flex
  "flex",
  "flex-basis",
  "flex-direction",
  "flex-flow",
  "flex-grow",
  "flex-shrink",
  "flex-wrap",

  -- grid
  "grid",
  "grid-area",
  "grid-template",
  "grid-template-areas",
  "grid-template-rows",
  "grid-template-columns",
  "grid-row",
  "grid-row-start",
  "grid-row-end",
  "grid-column",
  "grid-column-start",
  "grid-column-end",
  "grid-auto-rows",
  "grid-auto-columns",
  "grid-auto-flow",
  "grid-gap",
  "grid-row-gap",
  "grid-column-gap",

  -- flex align
  "align-content",
  "align-items",
  "align-self",

  -- flex justify
  "justify-content",
  "justify-items",
  "justify-self",

  -- order
  "order",

  -- columns
  "columns",
  "column-gap",
  "column-fill",
  "column-rule",
  "column-rule-width",
  "column-rule-style",
  "column-rule-color",
  "column-span",
  "column-count",
  "column-width",

  -- transform
  "backface-visibility",
  "perspective",
  "perspective-origin",
  "transform",
  "transform-origin",
  "transform-style",

  -- transitions
  "transition",
  "transition-delay",
  "transition-duration",
  "transition-property",
  "transition-timing-function",

  -- visibility
  "visibility",
  "opacity",
  "mix-blend-mode",
  "isolation",
  "z-index",

  -- margin
  "margin",
  "margin-top",
  "margin-right",
  "margin-bottom",
  "margin-left",

  -- outline
  "outline",
  "outline-offset",
  "outline-width",
  "outline-style",
  "outline-color",

  -- border
  "border",
  "border-top",
  "border-right",
  "border-bottom",
  "border-left",
  "border-width",
  "border-top-width",
  "border-right-width",
  "border-bottom-width",
  "border-left-width",

  -- border-style
  "border-style",
  "border-top-style",
  "border-right-style",
  "border-bottom-style",
  "border-left-style",

  -- border-radius
  "border-radius",
  "border-top-left-radius",
  "border-top-right-radius",
  "border-bottom-left-radius",
  "border-bottom-right-radius",

  -- border-color
  "border-color",
  "border-top-color",
  "border-right-color",
  "border-bottom-color",
  "border-left-color",

  -- border-image
  "border-image",
  "border-image-source",
  "border-image-width",
  "border-image-outset",
  "border-image-repeat",
  "border-image-slice",

  -- box-shadow
  "box-shadow",

  -- background
  "background",
  "background-attachment",
  "background-clip",
  "background-color",
  "background-image",
  "background-origin",
  "background-position",
  "background-repeat",
  "background-size",
  "background-blend-mode",

  -- cursor
  "cursor",

  -- padding
  "padding",
  "padding-top",
  "padding-right",
  "padding-bottom",
  "padding-left",

  -- width
  "width",
  "min-width",
  "max-width",

  -- height
  "height",
  "min-height",
  "max-height",

  -- overflow
  "overflow",
  "overflow-x",
  "overflow-y",
  "resize",

  -- list-style
  "list-style",
  "list-style-type",
  "list-style-position",
  "list-style-image",
  "caption-side",

  -- tables
  "table-layout",
  "border-collapse",
  "border-spacing",
  "empty-cells",

  -- animation
  "animation",
  "animation-name",
  "animation-duration",
  "animation-timing-function",
  "animation-delay",
  "animation-iteration-count",
  "animation-direction",
  "animation-fill-mode",
  "animation-play-state",

  -- vertical-alignment
  "vertical-align",

  -- text-alignment & decoration
  "direction",
  "tab-size",
  "text-align",
  "text-align-last",
  "text-justify",
  "text-indent",
  "text-transform",
  "text-decoration",
  "text-decoration-color",
  "text-decoration-line",
  "text-decoration-style",
  "text-rendering",
  "text-shadow",
  "text-overflow",

  -- text-spacing
  "line-height",
  "word-spacing",
  "letter-spacing",
  "white-space",
  "word-break",
  "word-wrap",
  "color",

  -- font
  "font",
  "font-family",
  "font-kerning",
  "font-size",
  "font-size-adjust",
  "font-stretch",
  "font-weight",
  "font-smoothing",
  "osx-font-smoothing",
  "font-variant",
  "font-style",

  -- content
  "content",
  "quotes",

  -- counters
  "counter-reset",
  "counter-increment",

  -- breaks
  "page-break-before",
  "page-break-after",
  "page-break-inside",

  -- mouse
  "pointer-events",

  -- intent
  "will-change"
}

config.plugins.sortcss = common.merge({
  css_syntaxes = css_syntaxes,
  concentric_order = concentric_order,
  -- The config specification used by the settings gui
  config_spec = {
    name = "Sort CSS",
    {
      label = "CSS file syntaxes",
      description = "List of CSS-compatible syntax names.",
      path = "css_syntaxes",
      type = "list_strings",
      default = css_syntaxes
    },
  }
}, config.plugins.sortcss)

local function compare_alphabetical(line1, line2)
  local prop1 = line1:match("^%s*([^:]+)")
  local prop2 = line2:match("^%s*([^:]+)")

  return string.lower(prop1) < string.lower(prop2)
end

local function compare_concentrical(line1, line2)
  local prop1 = line1:match("^%s*([^:]+)")
  local prop2 = line2:match("^%s*([^:]+)")

  local index1 = 0
  local index2 = 0

  for i, prop in ipairs(config.plugins.sortcss.concentric_order) do
    if prop == prop1 then
      index1 = i
    end
    if prop == prop2 then
      index2 = i
    end
  end

  if index1 == 0 then
    index1 = #concentric_order + 1
  end

  if index2 == 0 then
    index2 = #concentric_order + 1
  end

  return index1 < index2
end

local function sort_css(str, order)
  local lines = {}
  for line in str:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end

  if order == "alphabetical" then
    table.sort(lines, compare_alphabetical)
  end

  if order == "concentrical" then
    table.sort(lines, compare_concentrical)
  end

  return table.concat(lines, "\n")
end

command.add("core.docview", {
  ["sortcss:alphabetical"] = function(dv)
    local doc = dv.doc
    if not doc:has_selection() then
      core.error("No text selected")
      return
    end

    local text = doc:get_text(doc:get_selection())
    doc:text_input(sort_css(text, "alphabetical"))
  end,
  ["sortcss:concentrical"] = function(dv)
    local doc = dv.doc
    if not doc:has_selection() then
      core.error("No text selected")
      return
    end

    local text = doc:get_text(doc:get_selection())
    doc:text_input(sort_css(text, "concentrical"))
  end,
})

contextmenu:register(function()
  local doc = core.active_view.doc
  if doc and doc:has_selection() then
    for _, v in pairs(config.plugins.sortcss.css_syntaxes) do
      if v == doc.syntax.name then
        return true, core.active_view
      end
    end
  end

  return false
end, {
  contextmenu.DIVIDER,
  { text = "Sort CSS Selection Alphabetically", command = "sortcss:alphabetical" },
  { text = "Sort CSS Selection Concentrically", command = "sortcss:concentrical" },
})

keymap.add { ["ctrl+alt+a"] = "sortcss:alphabetical" }
keymap.add { ["ctrl+alt+c"] = "sortcss:concentrical" }
