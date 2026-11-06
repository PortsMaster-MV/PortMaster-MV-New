local Rse = require("src.core.game3.rse.init")

local Braille = {}

local function constants(session)
  return require("src.core.game3.constants").active(session or Rse.session())
end

function Braille.isRs(session)
  local profile = require("src.core.game3.profile").forSession(session or Rse.session())
  return profile.id == "ruby" or profile.id == "sapphire"
end

local function onMap(name, session)
  session = session or Rse.session()
  if not session or not Braille.isRs(session) then return false end
  local target = constants(session).map_groups.byName[name]
  local group, num = Rse.mapGroupNum(session.map, session)
  return target ~= nil and group == target.group and num == target.num
end

local function playerPos(session)
  session = session or Rse.session()
  return tonumber(session and session.x) or 0, tonumber(session and session.y) or 0
end

-- pokeruby/src/braille_puzzles.c:27
function Braille.shouldDoDig(session)
  if not onMap("MAP_SEALED_CHAMBER_OUTER_ROOM", session)
      or Rse.flag("FLAG_SYS_BRAILLE_DIG", session) then return false end
  local x, y = playerPos(session)
  return y == 3 and (x == 9 or x == 10 or x == 11)
end

-- pokeruby/src/braille_puzzles.c:71
function Braille.shouldDoStrength(session)
  if not onMap("MAP_DESERT_RUINS", session)
      or Rse.flag("FLAG_SYS_BRAILLE_STRENGTH", session) then return false end
  local x, y = playerPos(session)
  return y == 23 and (x == 9 or x == 10 or x == 11)
end

-- pokeruby/src/braille_puzzles.c:101
function Braille.shouldDoFly(session)
  if not onMap("MAP_ANCIENT_TOMB", session)
      or Rse.flag("FLAG_SYS_BRAILLE_FLY", session) then return false end
  local x, y = playerPos(session)
  return x == 8 and y == 25
end

local function openEntrance(x, y, flag, session)
  local Field = require("src.core.game3.field")
  local C = constants(session)
  local tiles = {
    { 0, 0, "TopLeft", false }, { 1, 0, "TopMid", false }, { 2, 0, "TopRight", false },
    { 0, 1, "BottomLeft", true }, { 1, 1, "BottomMid", false }, { 2, 1, "BottomRight", true },
  }
  for _, tile in ipairs(tiles) do
    Field.setMetatile(x + tile[1], y + tile[2],
      C:require("metatile_labels", "METATILE_Cave_SealedChamberEntrance_" .. tile[3]), tile[4])
  end
  require("src.core.game3.field_view")._nativeDirty = true
  require("src.core.game3.audio").playSe(C:require("songs", "SE_BANG"))
  Rse.setFlag(flag, true, session)
end

-- pokeruby/src/braille_puzzles.c:44
function Braille.doDig(session)
  openEntrance(9, 1, "FLAG_SYS_BRAILLE_DIG", session)
end

-- pokeruby/src/braille_puzzles.c:86
function Braille.doStrength(session)
  openEntrance(7, 19, "FLAG_SYS_BRAILLE_STRENGTH", session)
end

-- pokeruby/src/braille_puzzles.c:112
function Braille.doFly(session)
  openEntrance(7, 19, "FLAG_SYS_BRAILLE_FLY", session)
end

return Braille
