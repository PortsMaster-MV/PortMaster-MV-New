local K = require("src.import.gba.rse.boot_gfx")
local TextIR = require("src.core.game3.scripting.text_ir")

local M = {}

M.SUB = "rse/menus"

M.FILES = {}

M.REQUIRED = K.required(M.SUB, M.FILES)

local function window(c, off)
  return {
    bg = c:u8(off), left = c:u8(off + 1), top = c:u8(off + 2), width = c:u8(off + 3),
    height = c:u8(off + 4), paletteNum = c:u8(off + 5), baseBlock = c:u16(off + 6),
  }
end

local function windows(c, name)
  local out, off = {}, c:off(name)
  for i = 0, c.S.size(name) / 8 - 1 do
    local w = window(c, off + i * 8)
    if w.bg == 0xFF then break end
    out[#out + 1] = w
  end
  return out
end

local function readString(c, off)
  local bytes = {}
  for i = 0, 255 do
    local b = c:u8(off + i)
    bytes[#bytes + 1] = b
    if b == 0xFF then break end
  end
  return TextIR.toPlain(TextIR.decode(bytes, { dialect = "rse" }), {})
end

-- pokeemerald/src/data/party_menu.h:658
local function cursorOptions(c)
  local out, off = {}, c:off("sCursorOptions")
  for i = 0, c.S.size("sCursorOptions") / 8 - 1 do
    local p = c:ptr(off + i * 8)
    out[i + 1] = p and readString(c, p) or ""
  end
  return out
end

-- pokeemerald/src/data/party_menu.h:745
local function fieldMoves(c)
  local out, off = {}, c:off("sFieldMoves")
  for i = 0, c.S.size("sFieldMoves") / 2 - 2 do out[i + 1] = c:u16(off + i * 2) end
  return out
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  -- pokeemerald/src/option_menu.c:75
  local optText = c:pal("sOptionMenuText_Pal", 16)
  -- pokeemerald/src/option_menu.c:135
  local optBg = c:pal("sOptionMenuBg_Pal", 1)
  return true, c:finish({
    screen = "menus",
    option = {
      textPalette = K.palList(optText, 0, 16),
      bgColor = optBg[0],
      windows = windows(c, "sOptionMenuWinTemplates"),
    },
    party = {
      cursorOptions = cursorOptions(c),
      fieldMoves = fieldMoves(c),
    },
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
