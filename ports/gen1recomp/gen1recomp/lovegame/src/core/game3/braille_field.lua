local BrailleField = {}

local function Rse()
  return require("src.core.game3.rse.init")
end

local function session()
  return Rse().session()
end

-- pokeemerald/src/braille_puzzles.c:17
BrailleField.REGICE_PATH = {
  { 4, 21 }, { 5, 21 }, { 6, 21 }, { 7, 21 }, { 8, 21 }, { 9, 21 }, { 10, 21 }, { 11, 21 }, { 12, 21 },
  { 12, 22 }, { 12, 23 }, { 13, 23 }, { 13, 24 }, { 13, 25 }, { 13, 26 }, { 13, 27 }, { 12, 27 }, { 12, 28 },
  { 4, 29 }, { 5, 29 }, { 6, 29 }, { 7, 29 }, { 8, 29 }, { 9, 29 }, { 10, 29 }, { 11, 29 }, { 12, 29 },
  { 4, 28 }, { 4, 27 }, { 3, 27 }, { 3, 26 }, { 3, 25 }, { 3, 24 }, { 3, 23 }, { 4, 23 }, { 4, 22 },
}

local function playerPos(s)
  local P = package.loaded["src.core.game3.player"]
  if P and P.cellX then return P.cellX, P.cellY end
  s = s or session()
  return s and s.x or 0, s and s.y or 0
end

local function onMap(name, s)
  s = s or session()
  return s ~= nil and s.map == name
end

local function setMetatile(x, y, label, impassable)
  local Field = package.loaded["src.core.game3.field"] or require("src.core.game3.field")
  local Constants = require("src.core.game3.constants")
  local C = Constants.of(Constants.versionOf(session()))
  Field.setMetatile(x, y, C:require("metatile_labels", label), impassable == true)
end

local function playSe(name)
  local SE = require("src.core.game3.se_ids")
  local ok, Audio = pcall(require, "src.core.game3.audio")
  if ok and Audio and Audio.playSe and SE[name] then Audio.playSe(SE[name]) end
end

-- pokeemerald/src/braille_puzzles.c:78
local function openEntrance(x0, y0)
  setMetatile(x0, y0, "METATILE_Cave_SealedChamberEntrance_TopLeft")
  setMetatile(x0 + 1, y0, "METATILE_Cave_SealedChamberEntrance_TopMid")
  setMetatile(x0 + 2, y0, "METATILE_Cave_SealedChamberEntrance_TopRight")
  setMetatile(x0, y0 + 1, "METATILE_Cave_SealedChamberEntrance_BottomLeft", true)
  setMetatile(x0 + 1, y0 + 1, "METATILE_Cave_SealedChamberEntrance_BottomMid")
  setMetatile(x0 + 2, y0 + 1, "METATILE_Cave_SealedChamberEntrance_BottomRight", true)
  playSe("SE_BANG")
end

-- pokeemerald/src/braille_puzzles.c:61
function BrailleField.shouldDoDig(s)
  if Rse().flag("FLAG_SYS_BRAILLE_DIG", s) or not onMap("EM_SEALED_CHAMBER_OUTER_ROOM", s) then return false end
  local x, y = playerPos(s)
  return y == 3 and (x == 9 or x == 10 or x == 11)
end

-- pokeemerald/src/braille_puzzles.c:78
function BrailleField.doDig(s)
  openEntrance(9, 1)
  Rse().setFlag("FLAG_SYS_BRAILLE_DIG", true, s)
end

-- pokeemerald/src/braille_puzzles.c:92
function BrailleField.checkRelicanthWailord(s)
  s = s or session()
  local party = s and s.party or {}
  local Constants = require("src.core.game3.constants")
  local C = Constants.of(Constants.versionOf(s))
  local function speciesOf(mon)
    if not mon then return 0 end
    if mon.isEgg then return C:require("species", "SPECIES_EGG") end
    return tonumber(mon.species) or 0
  end
  local n = 0
  for i = 1, 6 do if party[i] then n = i end end
  if n == 0 then return false end
  return speciesOf(party[1]) == C:require("species", "SPECIES_WAILORD")
    and speciesOf(party[n]) == C:require("species", "SPECIES_RELICANTH")
end

-- pokeemerald/src/braille_puzzles.c:141
function BrailleField.shake(long, done)
  local FieldView = require("src.core.game3.field_view")
  local delayCounter, shakes = 0, 0
  local pan = long and 2 or 3
  local delay, total = 5, long and 50 or 2
  require("src.core.game3.task").spawn(function()
    delayCounter = delayCounter + 1
    if delayCounter % delay == 0 then
      delayCounter = 0
      shakes = shakes + 1
      pan = -pan
      FieldView.setCameraPanning(0, pan)
      if shakes == total then
        FieldView.setCameraPanning(0, 0)
        if done then done() end
        return true
      end
    end
    return false
  end)
end

-- pokeemerald/src/braille_puzzles.c:167
function BrailleField.shouldDoRegirock(s)
  if Rse().flag("FLAG_SYS_REGIROCK_PUZZLE_COMPLETED", s) or not onMap("EM_DESERT_RUINS", s) then return false end
  local x, y = playerPos(s)
  if y == 23 and (x == 5 or x == 6 or x == 7) then
    BrailleField.isRegisteel = false
    return true
  end
  return false
end

-- pokeemerald/src/braille_puzzles.c:219
function BrailleField.shouldDoRegisteel(s)
  if Rse().flag("FLAG_SYS_REGISTEEL_PUZZLE_COMPLETED", s) or not onMap("EM_ANCIENT_TOMB", s) then return false end
  local x, y = playerPos(s)
  if x == 8 and y == 25 then
    BrailleField.isRegisteel = true
    return true
  end
  return false
end

-- pokeemerald/src/braille_puzzles.c:205
function BrailleField.doRegiEffect(s)
  openEntrance(7, 19)
  Rse().setFlag(BrailleField.isRegisteel and "FLAG_SYS_REGISTEEL_PUZZLE_COMPLETED"
    or "FLAG_SYS_REGIROCK_PUZZLE_COMPLETED", true, s)
end

-- pokeemerald/src/braille_puzzles.c:283
function BrailleField.shouldDoRegicePuzzle(s)
  s = s or session()
  if not onMap("EM_ISLAND_CAVE", s) then return false end
  local R = Rse()
  if R.flag("FLAG_SYS_BRAILLE_REGICE_COMPLETED", s) then return false end
  if not R.flag("FLAG_TEMP_REGICE_PUZZLE_STARTED", s) then return false end
  if R.flag("FLAG_TEMP_REGICE_PUZZLE_FAILED", s) then return false end
  local x, y = playerPos(s)
  for i, c in ipairs(BrailleField.REGICE_PATH) do
    if c[1] == x and c[2] == y then
      local k = i - 1
      local var, bit
      if k < 16 then var, bit = "VAR_REGICE_STEPS_1", k
      elseif k < 32 then var, bit = "VAR_REGICE_STEPS_2", k - 16
      else var, bit = "VAR_REGICE_STEPS_3", k - 32 end
      local v = R.var(var, s)
      if math.floor(v / 2 ^ bit) % 2 == 0 then v = v + 2 ^ bit end
      R.setVar(var, v, s)
      if R.var("VAR_REGICE_STEPS_1", s) ~= 0xFFFF or R.var("VAR_REGICE_STEPS_2", s) ~= 0xFFFF
          or R.var("VAR_REGICE_STEPS_3", s) ~= 0xF then
        return false
      end
      return x == 8 and y == 21
    end
  end
  R.setFlag("FLAG_TEMP_REGICE_PUZZLE_FAILED", true, s)
  R.setFlag("FLAG_TEMP_REGICE_PUZZLE_STARTED", false, s)
  return false
end

local function shakeSpecial(long)
  return function(ctx)
    local finished = false
    BrailleField.shake(long, function() finished = true end)
    ctx.stateWait = function() return finished end
    return false
  end
end

BrailleField.BY_NAME = {
  -- pokeemerald/src/braille_puzzles.c:92
  CheckRelicanthWailord = function(ctx)
    local v = BrailleField.checkRelicanthWailord() and 1 or 0
    Rse().setSpecialVar(ctx, 0x800D, v)
    return false, v
  end,
  -- pokeemerald/src/braille_puzzles.c:107
  ShouldDoBrailleRegirockEffectOld = function() return false end,
  -- pokeemerald/src/braille_puzzles.c:117
  DoSealedChamberShakingEffect_Long = shakeSpecial(true),
  -- pokeemerald/src/braille_puzzles.c:129
  DoSealedChamberShakingEffect_Short = shakeSpecial(false),
  ShouldDoBrailleRegicePuzzle = function(ctx)
    local v = BrailleField.shouldDoRegicePuzzle() and 1 or 0
    Rse().setSpecialVar(ctx, 0x800D, v)
    return false, v
  end,
}

return BrailleField
