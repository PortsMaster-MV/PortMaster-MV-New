local Base = require("src.ui.game3.rse.contest_painting")
local IR = require("src.core.game3.scripting.text_ir")
local Kit = require("src.ui.game3.rse.scene_kit")
local Font = require("src.ui.game3.frlg_font")
local Painting = {ID = Base.ID, SUB = Base.SUB}

local function manifest()
  local man = Base.manifest()
  assert(man.assetLayout == "rs" and man.paintingVersion == 1 and man.captionPolicy == "rs_parts",
    "native RS painting schema required")
  return man
end

local function render(bytes)
  local out = {}
  for _, seg in ipairs(IR.decode(bytes, {dialect = "rs"})) do
    if seg.t == "ext" then
      out[#out + 1] = string.char(252, seg.cmd)
      for _, arg in ipairs(seg.args or {}) do out[#out + 1] = string.char(arg) end
    elseif seg.t ~= "eos" then out[#out + 1] = IR.toPlain({seg}, {}) end
  end
  return table.concat(out)
end
local function text(man, key) return render(assert(man.textBytes[key], "native painting caption missing: " .. key)) end
local function name(value, limit)
  if type(value) == "table" then
    local bytes = {}
    for i = 1, math.min(#value, limit or #value) do
      if value[i] == 255 then break end
      bytes[#bytes + 1] = value[i]
    end
    bytes[#bytes + 1] = 255
    return render(bytes)
  end
  if type(value) ~= "string" then return "" end
  if not limit then return value end
  local out = {}
  for glyph in value:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    if #out >= limit then break end
    out[#out + 1] = glyph
  end
  return table.concat(out)
end

function Painting.caption(saveIdx, winner, artist, man)
  if artist then return nil end
  man = man or manifest()
  local nickname = name(winner.monName or winner.nickname, man.captionLayout.nicknameBytes)
  local category = tonumber(winner.contestCategory) or 0
  if saveIdx < man.captionLayout.museumStart then
    return text(man, assert(man.rankNames[category], "native painting category")) .. text(man, man.hallCaption)
      .. name(winner.trainerName) .. string.char(unpack(man.captionLayout.hallLatinControl))
      .. text(man, man.hallPossessive) .. nickname
  end
  local pair = assert(man.captionParts[category], "native museum caption pair")
  return text(man, pair.prefix) .. nickname .. text(man, pair.suffix)
end
function Painting.drawCaption(st, man)
  man = man or manifest()
  local w, pal = man.window, man.textPalette
  local xy = st.saveIdx < man.captionLayout.museumStart and man.captionLayout.hall or man.captionLayout.museum
  Font.draw(st.caption, xy.x, xy.y, {font = "native_" .. w.fontNum, textMode = w.textMode,
    letterSpacing = w.spacing, linePitch = 16, maxWidth = 240 - xy.x,
    colors = {fg = Kit.color555(pal[w.foregroundColor + 1]), shadow = Kit.color555(pal[w.shadowColor + 1]),
      bg = {0, 0, 0, 0}}})
end
function Painting.build(opts)
  manifest(); opts = opts or {}; opts.nativePolicy = Painting
  return Base.build(opts)
end
function Painting.open(opts)
  manifest(); opts = opts or {}; opts.nativePolicy = Painting
  return Base.open(opts)
end
Painting.isOpen, Painting.close, Painting.resetCache = Base.isOpen, Base.close, Base.resetCache
Painting.update, Painting.handleInput, Painting.draw, Painting._st = Base.update, Base.handleInput, Base.draw, Base._st
function Painting.reset() Base.reset(); Base.resetCache() end
return Painting
