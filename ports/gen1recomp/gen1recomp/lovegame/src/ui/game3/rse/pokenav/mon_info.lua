local Gfx = require("src.ui.game3.rse.pokenav.gfx")

local MonInfo = {}

local function Pokemon() return require("src.core.game3.pokemon") end
local function Ribbons() return require("src.core.game3.rse.ribbons") end

-- pokeemerald/include/constants/species.h:33
local SPECIES_NIDORAN_F, SPECIES_NIDORAN_M = 29, 32

function MonInfo.mon(session, item)
  if not item then return nil end
  if item.boxId == nil then return session and session.party and session.party[item.monId] or nil end
  return Ribbons().boxMon(session, item.boxId, item.monId)
end

function MonInfo.nickname(mon)
  if Pokemon().isEgg(mon) then return Gfx.plain("gText_EggNickname") end
  return Pokemon().displayName(mon)
end

function MonInfo.level(mon)
  return math.floor(tonumber(mon and mon.level) or 1)
end

function MonInfo.gender(mon)
  local P = Pokemon()
  local g = P.gender(P.speciesOf(mon), mon and mon.personality)
  return g
end

-- pokeemerald/src/pokenav_conditions.c:368
function MonInfo.conditionGender(mon)
  local P = Pokemon()
  local sp = P.speciesOf(mon)
  local g = MonInfo.gender(mon)
  if (sp == SPECIES_NIDORAN_F or sp == SPECIES_NIDORAN_M) and MonInfo.nickname(mon) == P.name(sp) then return "U" end
  return g
end

function MonInfo.boxName(session, boxId)
  local boxes = session and session.storage and session.storage.boxes
  local box = boxes and boxes[boxId]
  return box and box.name or ""
end

-- pokeemerald/src/pokenav_ribbons_list.c:123
function MonInfo.genderSymbol(g)
  if g == "M" then return "♂" end
  if g == "F" then return "♀" end
  return "{UNK_SPACER}"
end

-- pokeemerald/src/pokenav_ribbons_list.c:123
function MonInfo.listColors(pal)
  local T = Gfx.TEXT
  return {
    normal = Gfx.colors(pal, T.WHITE, T.DARK_GRAY, T.LIGHT_GRAY),
    M = Gfx.colors(pal, T.WHITE, T.LIGHT_RED, T.GREEN),
    F = Gfx.colors(pal, T.WHITE, T.LIGHT_GREEN, T.BLUE),
  }
end

-- pokeemerald/src/string_util.c:163
function MonInfo.rightAlign(n, digits)
  local s = tostring(math.floor(tonumber(n) or 0))
  local pad = digits - #s
  local out = {}
  for _ = 1, math.max(0, pad) do out[#out + 1] = "{UNK_SPACER}" end
  out[#out + 1] = s
  return table.concat(out)
end

-- pokeemerald/src/pokenav_ribbons_list.c:698
function MonInfo.listSegments(session, item, colors, withCount)
  local mon = MonInfo.mon(session, item)
  if not mon then return {} end
  local g = MonInfo.gender(mon)
  local segs = {
    { text = MonInfo.nickname(mon), x = 0, colors = colors.normal },
  }
  local gx = 60
  local sym = MonInfo.genderSymbol(g)
  segs[#segs + 1] = { text = sym, x = gx, colors = colors[g] or colors.normal }
  local lx = gx + Gfx.measure(sym)
  segs[#segs + 1] = { text = "/{LV_2}" .. MonInfo.level(mon), x = lx, colors = colors.normal }
  if withCount then
    segs[#segs + 1] = { text = MonInfo.rightAlign(item.data or 0, 2), x = gx + 54, colors = colors.normal }
  end
  return segs
end

return MonInfo
