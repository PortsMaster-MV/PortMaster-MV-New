local A = require("src.import.gba.rs.assets")
local M = {SUB = "rse/battle_tower", FILES = {}, REQUIRED = {"rse/battle_tower/manifest.lua"}}

function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local function array(symbol, width)
    local out, off = {}, c:off(symbol)
    for i = 0, c.S.count(symbol, width) - 1 do
      out[i + 1] = width == 2 and c:u16(off + i * width) or c:u8(off + i)
    end
    return out
  end
  local man = {trainers = {}, mons50 = {}, mons100 = {}, classInfo = {},
    heldItems = array("battle_tower.o:sBattleTowerHeldItems", 2),
    bannedSpecies = array("gBattleTowerBannedSpecies", 2),
    shortPrizes = array("battle_tower.o:sShortStreakPrizes", 2),
    longPrizes = array("battle_tower.o:sLongStreakPrizes", 2),
    maleClasses = array("battle_tower.o:sMaleTrainerClasses", 1),
    femaleClasses = array("battle_tower.o:sFemaleTrainerClasses", 1),
    strings = {}, aiFlags = c:u32(c:off("gTrainers") + 28),
    layouts = {trainer = 24, pokemon = 16, record = 164, recordMon = 44, eReader = 188}}
  local pic, names, classNames = c:off("gTrainerClassToPicIndex"), c:off("gTrainerClassToNameIndex"), c:off("gTrainerClassNames")
  for i = 0, c.S.size("gTrainerClassToPicIndex") - 1 do
    local nameId = c:u8(names + i)
    man.classInfo[i] = {pic = c:u8(pic + i), nameId = nameId, name = A.text(c, classNames + nameId * 13)}
  end
  for _, sex in ipairs({"Male", "Female"}) do
    local classes = man[sex:lower() .. "Classes"]
    local gfx = array("battle_tower.o:s" .. sex .. "TrainerGfxIds", 1)
    for i, cls in ipairs(classes) do man.classInfo[cls].objGfx = gfx[i] end
  end
  local trainers = c:off("gBattleTowerTrainers")
  assert(c.S.count("gBattleTowerTrainers", 24) == 100, "RS Tower trainer count differs")
  for i = 0, 99 do
    local o, words = trainers + i * 24, {}
    for j = 0, 5 do words[j + 1] = c:u16(o + 12 + j * 2) end
    man.trainers[i] = {trainerClass = c:u8(o), name = A.text(c, o + 1), teamFlags = c:u8(o + 9), greeting = words}
  end
  for _, row in ipairs({{"mons50", "gBattleTowerLevel50Mons"}, {"mons100", "gBattleTowerLevel100Mons"}}) do
    local off = c:off(row[2])
    assert(c.S.count(row[2], 16) == 300, "RS Tower Pokemon count differs")
    for i = 0, 299 do
      local o, moves = off + i * 16, {}
      for j = 0, 3 do moves[j + 1] = c:u16(o + 4 + j * 2) end
      man[row[1]][i] = {species = c:u16(o), heldItem = c:u8(o + 2), teamFlags = c:u8(o + 3),
        moves = moves, evSpread = c:u8(o + 12), nature = c:u8(o + 13)}
    end
  end
  for i = 3, 9 do man.strings["format" .. i] = A.text(c, c:off("BattleText_Format" .. i)) end
  local messages = c:off("party_menu.o:PartyMenuPromptTexts")
  for i = 17, 19 do man.strings["entry" .. i] = A.text(c, assert(c:ptr(messages + i * 4))) end
  man.strings.full = A.text(c, c:off("gOtherText_NoMoreThreePoke"))
  return A.finish(c, man)
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
