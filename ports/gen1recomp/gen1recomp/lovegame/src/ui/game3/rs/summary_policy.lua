local Pokemon = require("src.core.game3.pokemon")
local RomText = require("src.core.game3.rom_text")
local Exp = require("src.core.game3.summary_data")
local P = {}
P.PAGE = {INFO = 0, SKILLS = 1, BATTLE = 2, CONTEST = 3}
P.MODE = {NORMAL = 0, MOVES_ONLY = 1, SELECT_MOVE = 2, MOVE_DELETER = 3,
  NO_MOVE_ORDER_EDIT = 4, PC_NORMAL = 5, PC_MOVES_ONLY = 6}
function P.mode(opts)
  opts = opts or {}
  if opts.nativeMode ~= nil then return assert(tonumber(opts.nativeMode)) end
  if opts.mode == "select_move" then return opts.forgetMove and 3 or 2 end
  if opts.enemyParty or opts.context == "inBattle" or opts.context == "trade" or opts.disableMoveOrderEditing then return 4 end
  if opts.mode == "moves_only" then return opts.context == "box" and 6 or 1 end
  return opts.context == "box" and 5 or 0
end
function P.bounds(mode) return (mode == 0 or mode == 4 or mode == 5) and 0 or 2, 3 end
local function occupied(mon) return mon and (tonumber(Pokemon.speciesOf(mon)) or 0) ~= 0 end
-- storage_system.c:212
function P.nextMon(list, cursor, direction, page, opts, manifest)
  opts = opts or {}
  local order = opts.linkDoubleBattle and assert(manifest.doubleBattleOrder)
  if order then
    local at
    for i, slot in ipairs(order) do if slot + 1 == cursor then at = i; break end end
    if not at then return cursor end
    for i = at + direction, direction > 0 and #order or 1, direction do
      local slot = order[i] + 1
      if occupied(list[slot]) and (page ~= 0 or not Pokemon.isEgg(list[slot])) then return slot end
    end
  else
    local maximum = opts.maxMonIndex and opts.maxMonIndex + 1 or #list
    local box = opts.context == "box" or opts.nativeMode and opts.nativeMode >= 5
    for i = cursor + direction, direction > 0 and maximum or 1, direction do
      if (not box or occupied(list[i])) and (page == 0 or not Pokemon.isEgg(list[i])) then return i end
    end
  end
  return cursor
end
function P.nextMove(mon, cursor, direction, maximum)
  for _ = 1, 4 do
    cursor = (cursor + direction) % (maximum + 1)
    if cursor == 4 or (Pokemon.moveIdAt(mon, cursor + 1) or 0) ~= 0 then return cursor end
  end
  return cursor
end
function P.multipleMoves(mon)
  for i = 2, 4 do if (Pokemon.moveIdAt(mon, i) or 0) ~= 0 then return true end end
  return false
end
function P.canForget(mon, cursor, mode)
  return cursor == 4 or mode == 3 or not Pokemon.isHmMove(Pokemon.moveIdAt(mon, cursor + 1))
end
function P.maxPP(mon, slot, id)
  id = id or Pokemon.moveIdAt(mon, slot)
  local bonus = mon.ppBonusesPacked
  local count = type(bonus) == "number" and math.floor(bonus / 4 ^ (slot - 1)) % 4
    or type(mon.ppBonuses) == "number" and math.floor(mon.ppBonuses / 4 ^ (slot - 1)) % 4
    or type(mon.ppBonuses) == "table" and mon.ppBonuses[slot]
    or type(mon.ppUp) == "table" and mon.ppUp[slot] or 0
  local base = Pokemon.movePp(id) or 0
  return base + math.floor(base * (tonumber(count) or 0) / 5)
end
function P.swapMoves(mon, a, b)
  local numeric = type(mon.ppBonuses) == "number" and mon.ppBonuses
  Pokemon.swapMoves(mon, a, b)
  if numeric then
    local shiftA, shiftB = 4 ^ (a - 1), 4 ^ (b - 1)
    local bonusA, bonusB = math.floor(numeric / shiftA) % 4, math.floor(numeric / shiftB) % 4
    mon.ppBonuses = numeric + (bonusB - bonusA) * shiftA + (bonusA - bonusB) * shiftB
  end
end
local function clean(s) return tostring(s or ""):gsub("{[^}]*}", "") end
function P.heldByOT(mon, owner)
  if not owner then return false end
  local id = tonumber(owner.trainerId or owner.otId or owner.id) or 0
  return id % 65536 == (tonumber(mon.otId) or 0) % 65536
    and clean(owner.playerName or owner.name) == clean(mon.otName or mon.originalTrainer)
end
function P.eggHatchKey(mon)
  local value = tonumber(mon.friendship or mon.eggCycles) or 0
  return value <= 5 and "gOtherText_EggAbout" or value <= 10 and "gOtherText_EggSoon"
    or value <= 40 and "gOtherText_EggSomeTime" or "gOtherText_EggLongTime"
end
local function fromRSE(mon) local g = tonumber(mon.metGame); return g == 1 or g == 2 or g == 3 end
function P.eggMemoKey(mon, owner)
  if not fromRSE(mon) then return "gOtherText_EggObtainedInTrade" end
  local location = tonumber(mon.metLocation) or 0
  if location == 255 then return "gOtherText_EggNicePlace" end
  if not P.heldByOT(mon, owner) then return "gOtherText_EggObtainedInTrade" end
  return location == 253 and "gOtherText_EggHotSprings" or "gOtherText_EggDayCare"
end
function P.memo(mon, owner, locationName)
  if Pokemon.isEgg(mon) then return {{text = RomText.plain(P.eggMemoKey(mon, owner)), color = 255}} end
  local nature = (tonumber(mon.personality) or 0) % 25
  local runs = {{text = RomText.at("gNatureNames", nature), color = 14}}
  local function add(text, color) runs[#runs + 1] = {text = text, color = color or 255} end
  if nature ~= 5 and nature ~= 21 then add(RomText.plain("gOtherText_Terminator4")) end
  add(RomText.plain("gOtherText_Nature"))
  local own, loc, level = P.heldByOT(mon, owner), tonumber(mon.metLocation) or 0, tonumber(mon.metLevel) or 0
  local trade = own and level ~= 0 and loc >= 88 or not own and (not fromRSE(mon) or loc >= 88 and loc ~= 255)
  if trade then add("\n" .. RomText.plain("gOtherText_ObtainedInTrade")); return runs end
  add("{LV}")
  add(tostring(level == 0 and 5 or level), 14)
  add(RomText.plain("gOtherText_Comma") .. "\n")
  if not own and loc == 255 then add(RomText.plain("gOtherText_FatefulEncounter"))
  else
    add(locationName or "", 14)
    add(RomText.plain(own and level == 0 and "gOtherText_Egg2" or own and "gOtherText_Met" or "gOtherText_Met2"))
  end
  return runs
end
function P.exp(mon)
  local row = Exp.expProgress(mon, Pokemon.growthRate(Pokemon.speciesOf(mon)))
  local ticks = row.level >= 100 and 0 or math.floor(row.expProgress * 64 / row.levelTotalExp)
  if ticks == 0 and row.expProgress ~= 0 and row.level < 100 then ticks = 1 end
  row.ticks = ticks
  return row
end
return P
