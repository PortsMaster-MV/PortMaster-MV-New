local Rse = require("src.core.game3.rse.init")
local P = require("src.core.game3.profiles.rs.battle_tower")
local Rng = require("src.core.game3.rng")
local bit = rawget(_G, "bit") or require("bit")
local T = {}
local scratch = setmetatable({}, {__mode = "k"})
local keys = {"hp", "atk", "def", "spe", "spa", "spd"}
local arrays = {"var_4AE", "curChallengeBattleNum", "curStreakChallengesNum", "recordWinStreaks", "currentWinStreaks"}
local source, pack
local function n(v) return math.floor(tonumber(v) or 0) end
local function itemId(mon)
  return require("src.core.game3.items_data").toNumericId(mon and (mon.heldItem or mon.item)) or 0
end
local function copy(v)
  if type(v) ~= "table" then return v end
  local t = {}; for k, x in pairs(v) do t[k] = copy(x) end; return t
end
T.copy = copy
function T.reset()
  scratch = setmetatable({}, {__mode = "k"}); source, pack = nil, nil
end
function T.pack()
  local body = assert(require("src.core.game3.dataset").cache():read(P.manifest), "native RS Tower pack missing")
  if source ~= body then
    local chunk = assert((loadstring or load)(body, "@" .. P.manifest))
    if setfenv then setfenv(chunk, {}) end
    pack = chunk(); assert(pack.assetLayout == "rs", "RS Tower pack has wrong layout"); source = body
  end
  return pack
end
function T.state(s)
  assert(s, "native RS Tower requires a session")
  s.battleTower = s.battleTower or {}
  local b = s.battleTower
  b.battleTowerLevelType = n(b.battleTowerLevelType) % 2
  for _, key in ipairs(arrays) do
    b[key] = b[key] or {}; for i = 1, 2 do b[key][i] = n(b[key][i]) % 65536 end
  end
  b.selectedPartyMons, b.battledTrainerIds, b.records = b.selectedPartyMons or {0, 0, 0}, b.battledTrainerIds or {}, b.records or {}
  scratch[s] = scratch[s] or {selectedOrder = {0, 0, 0}, previousStatus = 0}
  return b, b.battleTowerLevelType + 1, scratch[s]
end
function T.streak(s, level)
  local b, i = T.state(s); if level ~= nil then i = n(level) % 2 + 1 end
  return math.min(9999, ((b.curStreakChallengesNum[i] - 1) * 7 - 1 + b.curChallengeBattleNum[i]) % 65536)
end
function T.resetStreak(s, level)
  local b = T.state(s); local i = n(level) % 2 + 1
  b.var_4AE[i], b.curChallengeBattleNum[i], b.curStreakChallengesNum[i] = 0, 1, 1
end
local function stat(s, id, value) s.gameStats = s.gameStats or {}; s.gameStats[id] = math.min(0xFFFFFF, n(value)) end
function T.saveCurrent(s)
  local b, i = T.state(s)
  b.recordWinStreaks[i] = math.max(b.recordWinStreaks[i], T.streak(s))
  local best = math.max(b.recordWinStreaks[1], b.recordWinStreaks[2])
  b.bestBattleTowerWinStreak = math.min(9999, best); stat(s, 32, best)
end
-- battle_tower.c:1110
function T.property(s, op, value, set)
  local b, i, work = T.state(s); op, value = n(op), n(value)
  if set then
    if op == 0 then work.previousStatus = b.var_4AE[i]; b.var_4AE[i] = value % 256
    elseif op == 1 then b.battleTowerLevelType = value % 2
    elseif op == 2 then b.curChallengeBattleNum[i] = value % 65536
    elseif op == 3 then b.curStreakChallengesNum[i] = value % 65536
    elseif op == 4 then b.battleTowerTrainerId = value % 256
    elseif op == 5 then b.selectedPartyMons = copy(work.selectedOrder)
    elseif op == 6 then
      if b.battleTowerTrainerId == 200 then b.ereaderTrainer = {nativeCleared = true} end
      if n(b.totalBattleTowerWins) < 9999 then b.totalBattleTowerWins = n(b.totalBattleTowerWins) + 1 end
      b.curChallengeBattleNum[i] = (b.curChallengeBattleNum[i] + 1) % 65536
      T.saveCurrent(s); return b.curChallengeBattleNum[i]
    elseif op == 7 then
      if b.curStreakChallengesNum[i] < 1430 then b.curStreakChallengesNum[i] = b.curStreakChallengesNum[i] + 1 end
      T.saveCurrent(s); return b.curStreakChallengesNum[i]
    elseif op == 8 then b.unk_554 = value % 2 end
  else
    local k = ({[0] = "var_4AE", [2] = "curChallengeBattleNum", [3] = "curStreakChallengesNum"})[op]
    if k then return b[k][i]
    elseif op == 1 then return b.battleTowerLevelType
    elseif op == 4 then return n(b.battleTowerTrainerId)
    elseif op == 8 then return n(b.unk_554) % 2
    elseif op == 9 then return T.streak(s) end
  end
  if op == 10 then stat(s, 32, b.bestBattleTowerWinStreak)
  elseif op == 11 and (not set or b.var_4AE[i] ~= 3) then T.resetStreak(s, i - 1)
  elseif op == 12 then b.var_4AE[i] = work.previousStatus
  elseif op == 13 then b.currentWinStreaks[i] = T.streak(s)
  elseif op == 14 then b.lastStreakLevelType = i - 1 end
end
function T.init(s)
  local b = T.state(s); local temp, handled = 5, 0
  for i = 1, 2 do
    local status = b.var_4AE[i]
    if status == 1 then T.resetStreak(s, i - 1); temp, handled = 1, handled + 1
    elseif status == 4 then temp, handled = 2, handled + 1
    elseif status == 5 then temp, handled = 3, handled + 1
    elseif status == 2 then temp, handled = 4, handled + 1
    elseif status ~= 3 and status ~= 6 then T.resetStreak(s, i - 1) end
  end
  if handled == 0 then temp = 5 end
  if b.playerRecord and b.playerRecord.checksumValid == false then b.playerRecord = {nativeCleared = true} end
  for i = 1, 5 do if b.records[i] and b.records[i].checksumValid == false then b.records[i] = {nativeCleared = true} end end
  Rse.setVar("VAR_TEMP_0", temp, s)
end
function T.eligible(mon, level)
  local Pokemon = require("src.core.game3.pokemon")
  if not mon or Pokemon.isEgg(mon) then return false end
  local species = Pokemon.speciesOf(mon)
  if not species or species == 0 or (n(level) == 0 and n(mon.level) > 50) then return false end
  for _, banned in ipairs(T.pack().bannedSpecies) do if species == banned then return false end end
  return true
end
function T.validateParty(s, order, level)
  if type(order) ~= "table" or #order ~= 3 then return 17 end
  local species, items, slots = {}, {}, {}
  local Pokemon = require("src.core.game3.pokemon")
  for _, slot in ipairs(order) do
    local mon = (s.party or {})[slot]
    if slots[slot] or not T.eligible(mon, level) then return 17 end
    slots[slot] = true
    local sp, item = Pokemon.speciesOf(mon), itemId(mon)
    if species[sp] then return 18 end
    if item ~= 0 and items[item] then return 19 end
    species[sp], items[item] = true, true
  end
end
function T.entryCount(s, level)
  local species, items, count = {}, {}, 0
  local Pokemon = require("src.core.game3.pokemon")
  for _, mon in ipairs(s.party or {}) do
    local sp, item = Pokemon.speciesOf(mon), itemId(mon)
    if T.eligible(mon, level) and not species[sp] and (item == 0 or not items[item]) then
      species[sp], items[item], count = true, true, count + 1
    end
  end
  return count
end
function T.reduceParty(s, order)
  local _, _, work = T.state(s)
  T.selectOrder(s, order or work.selectedOrder)
  local party = {}; for i = 1, 3 do if s.party[work.selectedOrder[i]] then party[#party + 1] = copy(s.party[work.selectedOrder[i]]) end end
  s.party = party
end
function T.selectOrder(s, order)
  local _, _, work = T.state(s); work.selectedOrder = {}
  for i = 1, 3 do work.selectedOrder[i] = n(order and order[i]) end
end
function T.setParty(s)
  local b, _, work = T.state(s)
  local Runtime = package.loaded["src.core.game3.runtime"]
  if Runtime and Runtime._game and Runtime._game.save ~= work.saveObject then
    work.saveObject = Runtime._game.save; work.saveBase = copy(work.saveObject)
  end
  T.reduceParty(s, b.selectedPartyMons)
end
function T.determinePrize(s)
  local b, i = T.state(s); local data = T.pack()
  local prizes = b.curStreakChallengesNum[i] - 1 > 5 and data.longPrizes or data.shortPrizes
  b.prizeItem = prizes[Rng.Random() % #prizes + 1]; return b.prizeItem
end
function T.givePrize(s)
  local b, i = T.state(s)
  local Bag = require("src.core.game3.bag")
  if Bag.add(s.bag, n(b.prizeItem), 1) then return true end
  b.var_4AE[i] = 6; return false
end
function T.ribbons(s)
  local b, i = T.state(s); local result = 0
  if T.streak(s) > 55 then
    local Ribbons = require("src.core.game3.rse.ribbons")
    local field = i == 1 and "winning" or "victory"
    for j = 1, 3 do
      local mon = (s.party or {})[b.selectedPartyMons[j]]
      if mon and Ribbons.get(mon, field) == 0 then Ribbons.set(mon, field, 1); result = 1 end
    end
    if result == 1 then stat(s, 42, n((s.gameStats or {})[42]) + 1) end
  end
  return result
end
function T.eReader(s)
  local b = T.state(s); local r = b.ereaderTrainer
  if not r or r.nonzero ~= true then return nil end
  if r.checksumValid == false then b.ereaderTrainer = {nativeCleared = true}; return nil end
  if r.checksumValid ~= true then return nil end
  return r
end
function T.trainer(s, override)
  local b = T.state(s); local id = n(override or b.battleTowerTrainerId)
  if id == 200 then return T.eReader(s) end
  if id >= 100 then return b.records[id - 100 + 1] end
  return T.pack().trainers[id]
end
function T.chooseTrainer(s)
  local b, i = T.state(s); local streak = T.streak(s); local selected
  local e = T.eReader(s)
  if e and n(e.winStreak) == streak then
    local level, order = i == 1 and 50 or 100, {1, 2, 3}
    local temp = {party = e.party or {}}
    if not T.validateParty(temp, order, i - 1) then
      selected = 200; for j = 1, 3 do if n(temp.party[j].level) ~= level then selected = nil end end
    end
  end
  if not selected then
    local candidates = {}
    for j = 1, 5 do
      local r = b.records[j]
      if r and r.nonzero == true and r.checksumValid == true and n(r.winStreak) == streak and n(r.battleTowerLevelType) == i - 1 then candidates[#candidates + 1] = 99 + j end
    end
    if #candidates > 0 then selected = candidates[Rng.Random() % #candidates + 1] end
  end
  local battle, challenge = b.curChallengeBattleNum[i], b.curStreakChallengesNum[i]
  assert(battle >= 1 and battle <= 7 and challenge >= 1, "RS Tower challenge is not initialized")
  if not selected then
    repeat
      local byte = Rng.Random() % 256
      if challenge > 7 then selected = math.floor(byte * 30 / 256) + 70
      elseif battle == 7 then selected = math.floor(byte * 5 / 128) + (challenge - 1) * 10 + 20
      else selected = math.floor(byte * 5 / 64) + (challenge - 1) * 10 end
      for j = 1, battle - 1 do if b.battledTrainerIds[j] == selected then selected = nil; break end end
    until selected ~= nil
  end
  b.battleTowerTrainerId = selected
  if selected >= 100 and battle == 7 then
    -- global.h:812
    b.totalBattleTowerWins = math.floor(n(b.totalBattleTowerWins) / 256) * 256 + selected
  elseif selected >= 100 or battle < 7 then b.battledTrainerIds[battle] = selected end
  local trainer = assert(T.trainer(s), "native RS Tower trainer missing")
  local info = T.pack().classInfo[trainer.trainerClass]
  local C = require("src.core.game3.constants").active(s)
  Rse.setVar("VAR_OBJ_GFX_ID_0", info and info.objGfx or C:require("event_objects", "OBJ_EVENT_GFX_BOY_1"), s)
  return selected
end
function T.fillParty(s, override)
  local b, i = T.state(s); local id = n(override or b.battleTowerTrainerId)
  local D = require("src.core.game3.rse.frontier.trainers")
  local Pokemon = require("src.core.game3.pokemon")
  local trainer = assert(T.trainer(s, id), "RS Tower trainer unavailable")
  local party = {}
  if id >= 100 then
    for j = 1, 3 do
      local row = assert((trainer.party or {})[j], "RS saved Tower Pokemon missing")
      local mon = D.createMon(row.species, row.level, 0, row.personality, row.otId, {moves = row.moves})
      local word = n(row.ivWord)
      for k, key in ipairs(keys) do mon.ivs[key] = math.floor(word / 2 ^ ((k - 1) * 5)) % 32 end
      mon.abilityNum = math.floor(word / 2 ^ 31) % 2
      mon.ability = (Pokemon.abilities(row.species) or {})[mon.abilityNum + 1] or 0; mon.abilityId = mon.ability
      local ev = {}; for k, key in ipairs({"hpEV", "attackEV", "defenseEV", "speedEV", "spAttackEV", "spDefenseEV"}) do ev[k] = n(row[key]) end
      D.setEvs(mon, ev); D.setHeldItem(mon, n(row.heldItem))
      mon.nickname, mon.friendship, mon.happiness, mon.ppBonusesPacked = row.nickname or "", n(row.friendship), n(row.friendship), n(row.ppBonuses)
      for k, move in ipairs(mon.moves) do mon.maxPp[k] = math.floor(Pokemon.movePp(move) * (5 + math.floor(mon.ppBonusesPacked / 4 ^ (k - 1)) % 4) / 5) end
      party[j] = mon
    end
    return party
  end
  local offsets, ivs = {0, 30, 60, 90, 120, 150, 180, 200}, {6, 9, 12, 15, 18, 21, 31, 31}
  local tier = id < 20 and 1 or math.min(8, math.floor(id / 10))
  local data, pool = T.pack(), id >= 80 and 100 or 60
  local mons, used, friendship = i == 1 and data.mons50 or data.mons100, {}, 255
  while #party < 3 do
    local index = math.floor((Rng.Random() % 256) * pool / 256) + offsets[tier]
    local row = assert(mons[index], "native RS Tower pool row missing")
    local item, accept = data.heldItems[row.heldItem + 1], not used[index]
    if bit.band(row.teamFlags, trainer.teamFlags) ~= trainer.teamFlags then accept = false end
    for _, mon in ipairs(party) do if mon.species == row.species or (item ~= 0 and mon.heldItem == item) then accept = false end end
    if accept then
      local mon = D.createMon(row.species, i == 1 and 50 or 100, ivs[tier], Rng.Random32(), require("src.core.game3.link.rs").trainerId(s), {otName = s.name or s.playerName, otGender = s.gender})
      local count = 0; for k = 0, 5 do if bit.band(row.evSpread, 2 ^ k) ~= 0 then count = count + 1 end end
      local ev = {}; for k = 0, 5 do ev[k + 1] = count > 0 and bit.band(row.evSpread, 2 ^ k) ~= 0 and math.floor(510 / count) % 256 or 0 end
      D.setEvs(mon, ev); D.setMoves(mon, row.moves); D.setHeldItem(mon, item)
      for _, move in ipairs(row.moves) do if move == 218 then friendship = 0 end end
      mon.friendship, mon.happiness = friendship, friendship
      used[index], party[#party + 1] = true, mon
    end
  end
  return party
end
function T.recordMon(mon)
  local Pokemon = require("src.core.game3.pokemon")
  local row = {species = Pokemon.speciesOf(mon), heldItem = itemId(mon), moves = {},
    level = n(mon.level), ppBonuses = n(mon.ppBonusesPacked or mon.ppBonuses),
    otId = mon.otSecretId ~= nil and n(mon.otId) % 65536 + n(mon.otSecretId) % 65536 * 65536 or n(mon.otId) % 4294967296, personality = n(mon.personality),
    nickname = mon.nickname and mon.nickname ~= "" and mon.nickname or Pokemon.name(Pokemon.speciesOf(mon)), friendship = n(mon.friendship or mon.happiness)}
  for i = 1, 4 do row.moves[i] = n(Pokemon.moveIdAt(mon, i)) end
  local C = require("src.core.game3.constants").active()
  if row.heldItem == C:require("items", "ITEM_ENIGMA_BERRY") then row.heldItem = 0 end
  if type(mon.ppBonuses) == "table" then
    row.ppBonuses = 0; for i = 1, 4 do row.ppBonuses = row.ppBonuses + n(mon.ppBonuses[i]) % 4 * 4 ^ (i - 1) end
  end
  local word = 0
  for k, key in ipairs(keys) do word = word + n((mon.ivs or {})[key]) % 32 * 2 ^ ((k - 1) * 5) end
  row.ivWord = word + n(mon.abilityNum) % 2 * 2 ^ 31
  for k, key in ipairs({"hpEV", "attackEV", "defenseEV", "speedEV", "spAttackEV", "spDefenseEV"}) do row[key] = n((mon.evs or {})[keys[k]]) % 256 end
  return row
end
function T.saveRecord(s)
  local b, i = T.state(s); local data = T.pack(); local id = require("src.core.game3.link.rs").trainerId(s)
  local bytes, sum = {}, 0; for j = 0, 3 do bytes[j + 1] = math.floor(id / 256 ^ j) % 256; sum = sum + bytes[j + 1] end
  local classes = (s.gender == "female" or s.gender == 1) and data.femaleClasses or data.maleClasses
  local record = {battleTowerLevelType = i - 1, trainerClass = classes[sum % #classes + 1], trainerId = bytes,
    name = s.name or s.playerName or "", winStreak = T.streak(s), greeting = copy(s.easyChatBattleStart or {}), party = {}}
  for j = 1, 3 do record.party[j] = T.recordMon(assert(s.party[b.selectedPartyMons[j]], "RS Tower selected record slot missing")) end
  record.nonzero, record.checksumValid = true, true
  b.playerRecord = record; T.saveCurrent(s)
end
function T.prepareSave(s, status, outcome)
  local b, i, work = T.state(s)
  if (status == 0 or status == 3) and (b.curStreakChallengesNum[i] > 1 or b.curChallengeBattleNum[i] > 1) then T.saveRecord(s) end
  local last = work.lastBattle
  if last then
    b.defeatedByTrainerName, b.defeatedBySpecies = last.trainerName, last.opponentSpecies
    b.firstMonSpecies, b.firstMonNickname = last.playerSpecies, last.playerNickname
  end
  b.battleOutcome = n(outcome) % 256
  if status ~= 3 then b.var_4AE[i] = n(status) % 256 end
  b.unk_554 = 1; Rse.setVar("VAR_TEMP_0", 0, s)
end
function T.setLastBattle(s, data)
  local _, _, work = T.state(s); work.lastBattle = data
end
-- easy_chat_2.c:2696
function T.message(words)
  local EC = require("src.core.game3.easy_chat_text")
  local out = {}
  for row = 0, 2 do
    local first, second = words[row * 2 + 1] or 65535, words[row * 2 + 2] or 65535
    out[#out + 1] = EC.word(first)
    if first ~= 65535 then out[#out + 1] = " " end
    out[#out + 1] = EC.word(second)
    if row < 2 then out[#out + 1] = row == 0 and "\n" or "\\l" end
  end
  return table.concat(out)
end
-- save.c:728
function T.persist(s, write)
  local Runtime = package.loaded["src.core.game3.runtime"]
  local game = Runtime and Runtime._game
  local _, _, work = T.state(s)
  if game and game.save ~= work.saveObject then work.saveObject = game.save; work.saveBase = copy(game.save) end
  local base = work.saveBase or (game and game.save)
  if type(base) ~= "table" then return false, "The Battle Tower entrance save is unavailable." end
  local candidate = copy(base)
  local live = require("src.core.game3.save_schema_firered").toSaveTable(s)
  for _, key in ipairs({"name", "gender", "trainerId", "secretId", "playTime", "options", "regionMapZoom", "dex", "pokedex",
      "specialSaveWarpFlags", "localTimeOffset", "lastBerryTreeUpdate", "battleTower"}) do candidate[key] = copy(live[key]) end
  local ModRuntime = require("src.mods.Runtime")
  if ModRuntime.wantsHook("save.write") and ModRuntime.call("save.write", function() return true end, game) == false then
    return false, "The Battle Tower challenge could not be saved."
  end
  write = write or require("src.core.SaveData").save
  if type(write) ~= "function" then return false, "The Battle Tower challenge could not be saved." end
  local ok, result = pcall(write, candidate)
  if not ok or result == false then return false, "The Battle Tower challenge could not be saved." end
  work.saveBase, work.saveObject = copy(candidate), candidate
  if game then game.save = candidate end
  require("src.core.game3.scripting.natives_frontier_story").savePlayerParty(s)
  return true
end
return T
