local Rse = require("src.core.game3.rse.init")
local D = require("src.core.game3.rse.frontier.trainers")
local Util = require("src.core.game3.rse.frontier.util")

local bit = rawget(_G, "bit") or require("bit")

local Pike = {}

Pike.MANIFEST = "data/generated/gba/rse/pike/manifest.lua"

-- pokeemerald/include/constants/battle_pike.h:4
Pike.NUM_PIKE_ROOMS = 14
-- pokeemerald/include/constants/battle_pike.h:6
Pike.ROOM = {
  SINGLE_BATTLE = 0, HEAL_FULL = 1, NPC = 2, STATUS = 3, HEAL_PART = 4, WILD_MONS = 5, HARD_BATTLE = 6,
  DOUBLE_BATTLE = 7, BRAIN = 8,
}
Pike.NUM_ROOM_TYPES = 9
-- pokeemerald/include/constants/battle_pike.h:17
Pike.PATH = { LEFT = 0, CENTER = 1, RIGHT = 2 }
-- pokeemerald/include/constants/battle_pike.h:21
Pike.HINT = { NOSTALGIA = 0, WHISPERING = 1, POKEMON = 2, PEOPLE = 3, BRAIN = 4 }
-- pokeemerald/include/constants/battle_pike.h:28
Pike.STATUSMON = { KIRLIA = 0, DUSCLOPS = 1 }
-- pokeemerald/include/constants/battle_pike.h:31
Pike.STATUS = { FREEZE = 0, BURN = 1, TOXIC = 2, PARALYSIS = 3, SLEEP = 4 }
-- pokeemerald/include/constants/battle_pike.h:38
Pike.FUNC = {
  SET_ROOM_TYPE = 0, GET_DATA = 1, SET_DATA = 2, IS_FINAL_ROOM = 3, SET_ROOM_OBJECTS = 4, GET_ROOM_TYPE = 5,
  SET_IN_WILD_MON_ROOM = 6, CLEAR_IN_WILD_MON_ROOM = 7, SAVE = 8, DUMMY_1 = 9, DUMMY_2 = 10, GET_ROOM_STATUS = 11,
  GET_ROOM_STATUS_MON = 12, HEAL_ONE_TWO_MONS = 13, BUFFER_NPC_MSG = 14, STATUS_SCREEN_FLASH = 15, IS_IN = 16,
  SET_HINT_ROOM = 17, GET_HINT_ROOM_ID = 18, GET_ROOM_TYPE_HINT = 19, CLEAR_TRAINER_IDS = 20, GET_TRAINER_INTRO = 21,
  GET_QUEEN_FIGHT_TYPE = 22, HEAL_MONS_BEFORE_QUEEN = 23, SET_HEAL_ROOMS_DISABLED = 24, IS_PARTY_FULL_HEALTH = 25,
  SAVE_HELD_ITEMS = 26, RESET_HELD_ITEMS = 27, INIT = 28,
}
-- pokeemerald/include/constants/battle_pike.h:68
Pike.DATA = { PRIZE = 0, WIN_STREAK = 1, RECORD_STREAK = 2, TOTAL_STREAKS = 3, WIN_STREAK_ACTIVE = 4 }

-- pokeemerald/include/constants/battle.h:115
Pike.STATUS1 = { SLEEP = "SLP", FREEZE = "FRZ", BURN = "BRN", PARALYSIS = "PAR", TOXIC_POISON = "TOX" }
-- pokeemerald/include/constants/battle.h:115
Pike.STATUS1_SLEEP_TURNS = 7
-- pokeemerald/src/wild_encounter.c:27
Pike.MAX_ENCOUNTER_RATE = 2880

-- pokeemerald/src/battle_pike.c:1326
Pike.MAPS = {
  EM_BATTLE_FRONTIER_BATTLE_PIKE_THREE_PATH_ROOM = true,
  EM_BATTLE_FRONTIER_BATTLE_PIKE_ROOM_NORMAL = true,
  EM_BATTLE_FRONTIER_BATTLE_PIKE_ROOM_WILD_MONS = true,
}
Pike.WILD_ROOM = "EM_BATTLE_FRONTIER_BATTLE_PIKE_ROOM_WILD_MONS"

local F = D.FACILITY

local cache = {}

function Pike.manifest()
  local GameVersion = require("src.core.GameVersion")
  local key = tostring(GameVersion.get())
  local hit = cache[key]
  if hit then return hit end
  local src = require("src.core.game3.dataset").cache():read(Pike.MANIFEST)
  if type(src) ~= "string" then error("pike: " .. Pike.MANIFEST .. " missing from the cache", 0) end
  local chunk = assert((loadstring or load)(src, "@" .. Pike.MANIFEST))
  if setfenv then setfenv(chunk, {}) end
  hit = chunk()
  cache[key] = hit
  return hit
end

local function rng() return D.rng() end
local function specialVar(ctx, id) return Rse.specialVar(ctx, id) end
local function C(sess) return D.constants(sess) end

-- pokeemerald/src/battle_pike.c:43
function Pike.rt(sess)
  if type(sess.pikeRt) ~= "table" then
    sess.pikeRt = { roomType = 0, statusMon = 0, inWildMonRoom = false, statusFlags = nil, npcId = 0 }
  end
  return sess.pikeRt
end

-- pokeemerald/include/global.h:431
function Pike.frontier(sess)
  local f = Util.frontier(sess)
  f.pikeHintedRoomIndex = tonumber(f.pikeHintedRoomIndex) or 0
  f.pikeHintedRoomType = tonumber(f.pikeHintedRoomType) or 0
  f.pikeHealingRoomsDisabled = tonumber(f.pikeHealingRoomsDisabled) or 0
  if type(f.pikeHeldItemsBackup) ~= "table" then f.pikeHeldItemsBackup = { 0, 0, 0 } end
  return f
end

local function lvlMode(sess) return tonumber(Util.frontier(sess).lvlMode) or 0 end
local function battleNum(sess) return tonumber(Util.frontier(sess).curChallengeBattleNum) or 0 end

local function party(sess) return sess.party or {} end

local function hasAilment(mon)
  local s = mon and mon.status
  return not (s == nil or s == 0 or s == "" or s == "OK" or s == "NONE")
end
Pike.hasAilment = hasAilment

local function hp(mon) return tonumber(mon and mon.hp) or 0 end

-- pokeemerald/src/battle_pike.c:547
function Pike.setRoomType(ctx, sess)
  Pike.rt(sess).roomType = Pike.nextRoomType(ctx, sess)
end

local function gfx(name, sess) return C(sess):require("event_objects", name) end

-- pokeemerald/src/battle_pike.c:553
function Pike.setupRoomObjects(sess)
  local R = Pike.ROOM
  local rt = Pike.rt(sess)
  Rse.setVar("VAR_OBJ_GFX_ID_0", gfx("OBJ_EVENT_GFX_LINK_RECEPTIONIST", sess), sess)
  Rse.setVar("VAR_OBJ_GFX_ID_1", gfx("OBJ_EVENT_GFX_DUSCLOPS", sess), sess)
  local set1, set2, g1, g2 = true, false, 0, 0
  local t = rt.roomType
  if t == R.SINGLE_BATTLE then
    Pike.prepareOneTrainer(sess, false)
    set1 = false
  elseif t == R.HEAL_FULL then
    g1 = gfx("OBJ_EVENT_GFX_LINK_RECEPTIONIST", sess)
  elseif t == R.NPC then
    g1 = Pike.npcRoomGraphicsId(sess) % 256
  elseif t == R.STATUS then
    g1 = gfx("OBJ_EVENT_GFX_GENTLEMAN", sess)
    g2 = gfx(rt.statusMon == Pike.STATUSMON.DUSCLOPS and "OBJ_EVENT_GFX_DUSCLOPS" or "OBJ_EVENT_GFX_KIRLIA", sess)
    set2 = true
  elseif t == R.HEAL_PART then
    g1 = gfx("OBJ_EVENT_GFX_GENTLEMAN", sess)
  elseif t == R.WILD_MONS then
    set1 = false
  elseif t == R.HARD_BATTLE then
    Pike.prepareOneTrainer(sess, true)
    g2 = gfx("OBJ_EVENT_GFX_LINK_RECEPTIONIST", sess)
    set1, set2 = false, true
  elseif t == R.DOUBLE_BATTLE then
    Pike.prepareTwoTrainers(sess)
    set1 = false
  elseif t == R.BRAIN then
    Rse.setVar("VAR_OBJ_GFX_ID_0", D.manifest().brainObjEventGfx[F.PIKE + 1][1], sess)
    g2 = gfx("OBJ_EVENT_GFX_LINK_RECEPTIONIST", sess)
    set1, set2 = false, true
  else
    return
  end
  if set1 then Rse.setVar("VAR_OBJ_GFX_ID_0", g1, sess) end
  if set2 then Rse.setVar("VAR_OBJ_GFX_ID_1", g2, sess) end
end

-- pokeemerald/src/battle_pike.c:618
function Pike.getData(ctx, sess)
  local f = Pike.frontier(sess)
  local lvl = lvlMode(sess)
  local which = specialVar(ctx, Util.VAR_0x8005)
  local D_ = Pike.DATA
  if which == D_.PRIZE then
    Util.setResult(ctx, tonumber(f.pikePrize) or 0)
  elseif which == D_.WIN_STREAK then
    Util.setResult(ctx, Util.get1(f.pikeWinStreaks, lvl))
  elseif which == D_.RECORD_STREAK then
    Util.setResult(ctx, Util.get1(f.pikeRecordStreaks, lvl))
  elseif which == D_.TOTAL_STREAKS then
    Util.setResult(ctx, Util.get1(f.pikeTotalStreaks, lvl))
  elseif which == D_.WIN_STREAK_ACTIVE then
    local flag = Pike.manifest().winStreakFlags[(lvl ~= D.LVL.L50) and 2 or 1]
    Util.setResult(ctx, bit.band(tonumber(f.winStreakActiveFlags) or 0, flag))
  end
end

-- pokeemerald/src/battle_pike.c:645
function Pike.setData(ctx, sess)
  local f = Pike.frontier(sess)
  local lvl = lvlMode(sess)
  local which = specialVar(ctx, Util.VAR_0x8005)
  local v = specialVar(ctx, Util.VAR_0x8006)
  local D_ = Pike.DATA
  if which == D_.PRIZE then
    f.pikePrize = v
  elseif which == D_.WIN_STREAK then
    if v <= D.MAX_STREAK then Util.set1(f.pikeWinStreaks, lvl, v) end
  elseif which == D_.RECORD_STREAK then
    if v <= D.MAX_STREAK and Util.get1(f.pikeRecordStreaks, lvl) < v then Util.set1(f.pikeRecordStreaks, lvl, v) end
  elseif which == D_.TOTAL_STREAKS then
    if v <= D.MAX_STREAK then Util.set1(f.pikeTotalStreaks, lvl, v) end
  elseif which == D_.WIN_STREAK_ACTIVE then
    local flag = Pike.manifest().winStreakFlags[(lvl ~= D.LVL.L50) and 2 or 1]
    local flags = tonumber(f.winStreakActiveFlags) or 0
    if v ~= 0 then flags = bit.bor(flags, flag) else flags = bit.band(flags, bit.bnot(flag)) end
    if flags < 0 then flags = flags + 4294967296 end
    f.winStreakActiveFlags = flags
  end
end

-- pokeemerald/src/battle_pike.c:685
function Pike.isNextRoomFinal(sess)
  return battleNum(sess) > Pike.NUM_PIKE_ROOMS
end

-- pokeemerald/src/battle_pike.c:708
function Pike.save(ctx, sess)
  local f = Util.frontier(sess)
  return Util.saveChallengeInPlace(sess, "VAR_TEMP_CHALLENGE_STATUS", function()
    f.challengeStatus = specialVar(ctx, Util.VAR_0x8005)
    Rse.setVar("VAR_TEMP_CHALLENGE_STATUS", 0, sess)
    f.challengePaused = 1
  end)
end

-- pokeemerald/src/battle_pike.c:727
function Pike.roomInflictedStatus(sess)
  local s = Pike.rt(sess).statusFlags
  local S1, S = Pike.STATUS1, Pike.STATUS
  if s == S1.FREEZE then return S.FREEZE end
  if s == S1.BURN then return S.BURN end
  if s == S1.TOXIC_POISON then return S.TOXIC end
  if s == S1.PARALYSIS then return S.PARALYSIS end
  if s == S1.SLEEP then return S.SLEEP end
  return nil
end

-- pokeemerald/src/battle_pike.c:780
function Pike.healMon(mon)
  if type(mon) ~= "table" then return end
  require("src.core.game3.party").healAll({ mon })
end

local function typesOf(species)
  return require("src.core.game3.pokemon").types(species)
end

local function abilityOf(mon)
  local ab = tonumber(mon.ability or mon.abilityId)
  if ab then return ab end
  return require("src.core.game3.pokemon").abilityId(mon.species, mon.personality)
end

-- pokeemerald/src/battle_pike.c:810
function Pike.abilityPreventsStatus(mon, status, sess)
  local ab = abilityOf(mon)
  local function is(name) return ab == C(sess):require("abilities", name) end
  local S1 = Pike.STATUS1
  if status == S1.FREEZE then return is("ABILITY_MAGMA_ARMOR") end
  if status == S1.BURN then return is("ABILITY_WATER_VEIL") end
  if status == S1.PARALYSIS then return is("ABILITY_LIMBER") end
  if status == S1.SLEEP then return is("ABILITY_INSOMNIA") or is("ABILITY_VITAL_SPIRIT") end
  if status == S1.TOXIC_POISON then return is("ABILITY_IMMUNITY") end
  return false
end

-- pokeemerald/src/battle_pike.c:841
function Pike.typePreventsStatus(species, status)
  local T = require("src.core.game3.battle.types").ID
  local t = typesOf(species)
  local function has(id) return t[1] == id or t[2] == id end
  local S1 = Pike.STATUS1
  if status == S1.TOXIC_POISON then return has(T.STEEL) or has(T.POISON) end
  if status == S1.FREEZE then return has(T.ICE) end
  if status == S1.PARALYSIS then return has(T.GROUND) or has(T.ELECTRIC) end
  if status == S1.BURN then return has(T.FIRE) end
  return false
end

local function statusCount(sess)
  local n = battleNum(sess)
  if n <= 4 then return 1 end
  if n <= 9 then return 2 end
  return 3
end

local function shuffledIndices()
  local Rng = rng()
  local idx = { 1, 2, 3 }
  for _ = 1, 10 do
    local i = (Rng.Random() % D.PARTY_SIZE) + 1
    local j = (Rng.Random() % D.PARTY_SIZE) + 1
    idx[i], idx[j] = idx[j], idx[i]
  end
  return idx
end

-- pokeemerald/src/battle_pike.c:871
function Pike.tryInflictRandomStatus(sess)
  local rt = Pike.rt(sess)
  local p = party(sess)
  local idx = shuffledIndices()
  local count = statusCount(sess)
  local S1 = Pike.STATUS1
  local Rng = rng()
  local status = nil
  local chosen = false
  repeat
    chosen = false
    local r = Rng.Random() % 100
    if r < 35 then rt.statusFlags = S1.TOXIC_POISON
    elseif r < 60 then rt.statusFlags = S1.FREEZE
    elseif r < 80 then rt.statusFlags = S1.PARALYSIS
    elseif r < 90 then rt.statusFlags = S1.SLEEP
    else rt.statusFlags = S1.BURN end
    if status ~= rt.statusFlags then
      status = rt.statusFlags
      local j = 0
      for i = 1, D.PARTY_SIZE do
        local mon = p[idx[i]]
        if mon and not hasAilment(mon) and hp(mon) ~= 0 then
          j = j + 1
          if not Pike.typePreventsStatus(mon.species, rt.statusFlags) then
            chosen = true
            break
          end
        end
        if j == count then break end
      end
      if j == 0 then return false end
    end
  until chosen
  if rt.statusFlags == S1.FREEZE then
    rt.statusMon = Pike.STATUSMON.DUSCLOPS
  elseif rt.statusFlags == S1.BURN then
    rt.statusMon = (Rng.Random() % 2 ~= 0) and Pike.STATUSMON.DUSCLOPS or Pike.STATUSMON.KIRLIA
  else
    rt.statusMon = Pike.STATUSMON.KIRLIA
  end
  local j = 0
  for i = 1, D.PARTY_SIZE do
    local mon = p[idx[i]]
    if mon and not hasAilment(mon) and hp(mon) ~= 0 then
      j = j + 1
      if not Pike.abilityPreventsStatus(mon, rt.statusFlags, sess)
          and not Pike.typePreventsStatus(mon.species, rt.statusFlags) then
        mon.status = rt.statusFlags
        mon.sleep = (rt.statusFlags == S1.SLEEP) and Pike.STATUS1_SLEEP_TURNS or nil
      end
    end
    if j == count then break end
  end
  return true
end

-- pokeemerald/src/battle_pike.c:982
function Pike.atLeastOneHealthyMon(sess)
  local p = party(sess)
  local count = statusCount(sess)
  local healthy = 0
  for i = 1, D.PARTY_SIZE do
    local mon = p[i]
    if mon and not hasAilment(mon) and hp(mon) ~= 0 then healthy = healthy + 1 end
    if healthy == count then break end
  end
  return healthy ~= 0
end

-- pokeemerald/src/battle_pike.c:1482
function Pike.atLeastTwoAliveMons(sess)
  local p = party(sess)
  local dead = 0
  for i = 1, D.PARTY_SIZE do
    if hp(p[i]) == 0 then dead = dead + 1 end
  end
  return dead < 2
end

-- pokeemerald/src/battle_pike.c:1014
function Pike.nextRoomType(ctx, sess)
  local f = Pike.frontier(sess)
  local R = Pike.ROOM
  if f.pikeHintedRoomType == R.BRAIN then return f.pikeHintedRoomType end
  if specialVar(ctx, 0x8007) == f.pikeHintedRoomIndex then
    if f.pikeHintedRoomType == R.STATUS then Pike.tryInflictRandomStatus(sess) end
    return f.pikeHintedRoomType
  end
  local hints = Pike.manifest().roomTypeHints
  local disabled = {}
  local n = Pike.NUM_ROOM_TYPES - 1
  for i = 0, n - 1 do disabled[i] = false end
  local hint = hints[f.pikeHintedRoomType + 1]
  local count = n
  for i = 0, n - 1 do
    if hints[i + 1] == hint then
      disabled[i] = true
      count = count - 1
    end
  end
  if disabled[R.DOUBLE_BATTLE] ~= true and not Pike.atLeastTwoAliveMons(sess) then
    disabled[R.DOUBLE_BATTLE] = true
    count = count - 1
  end
  if disabled[R.STATUS] ~= true and not Pike.atLeastOneHealthyMon(sess) then
    disabled[R.STATUS] = true
    count = count - 1
  end
  if f.pikeHealingRoomsDisabled ~= 0 then
    if disabled[R.HEAL_FULL] ~= true then
      disabled[R.HEAL_FULL] = true
      count = count - 1
    end
    if disabled[R.HEAL_PART] ~= true then
      disabled[R.HEAL_PART] = true
      count = count - 1
    end
  end
  local candidates = {}
  for i = 0, n - 1 do
    if not disabled[i] then candidates[#candidates + 1] = i end
  end
  local nextType = candidates[(rng().Random() % count) + 1]
  if nextType == R.STATUS then Pike.tryInflictRandomStatus(sess) end
  return nextType
end

-- pokeemerald/src/battle_pike.c:1094
function Pike.npcRoomGraphicsId(sess)
  local tbl = Pike.manifest().npcTable
  local rt = Pike.rt(sess)
  rt.npcId = rng().Random() % #tbl
  return tbl[rt.npcId + 1].graphicsId
end

-- pokeemerald/src/battle_pike.c:1154
function Pike.wildMonHeaderId(sess)
  local f = Util.frontier(sess)
  local ws = Util.get1(f.pikeWinStreaks, lvlMode(sess))
  if ws <= 20 * Pike.NUM_PIKE_ROOMS then return 0 end
  if ws <= 40 * Pike.NUM_PIKE_ROOMS then return 1 end
  if ws <= 60 * Pike.NUM_PIKE_ROOMS then return 2 end
  return 3
end

-- pokeemerald/src/battle_pike.c:1644
function Pike.speciesToPikeMonId(species, sess)
  local c = C(sess)
  if species == c:require("species", "SPECIES_SEVIPER") then return 0 end
  if species == c:require("species", "SPECIES_MILOTIC") then return 1 end
  return 2
end

-- pokeemerald/src/battle_pike.c:1628
function Pike.canEncounterWildMon(sess, enemyLevel)
  local lead = party(sess)[1]
  if lead and not (lead.isEgg or lead.egg) then
    local ab = abilityOf(lead)
    local c = C(sess)
    if ab == c:require("abilities", "ABILITY_KEEN_EYE") or ab == c:require("abilities", "ABILITY_INTIMIDATE") then
      local lv = tonumber(lead.level) or 0
      if lv > 5 and enemyLevel <= lv - 5 and rng().Random() % 2 == 0 then return false end
    end
  end
  return true
end

-- pokeemerald/src/battle_pike.c:1105
function Pike.tryGenerateWildMon(sess, enc, checkKeenEye)
  local headerId = Pike.wildMonHeaderId(sess)
  local lvl = lvlMode(sess)
  local lists = Pike.manifest().wildMons[(lvl ~= D.LVL.L50 and 2 or 1)]
  local row = lists[headerId + 1][Pike.speciesToPikeMonId(tonumber(enc.species), sess) + 1]
  local level
  if lvl ~= D.LVL.L50 then
    level = D.highestPartyLevel(party(sess))
    if level < D.FRONTIER_MIN_LEVEL_OPEN then
      level = D.FRONTIER_MIN_LEVEL_OPEN
    else
      level = level - row.levelDelta
      if level < D.FRONTIER_MIN_LEVEL_OPEN then level = D.FRONTIER_MIN_LEVEL_OPEN end
    end
  else
    level = D.FRONTIER_MAX_LEVEL_50 - row.levelDelta
  end
  if checkKeenEye and not Pike.canEncounterWildMon(sess, level) then return nil end
  local Pokemon = require("src.core.game3.pokemon")
  local abilities = Pokemon.abilities(row.species)
  local abilityNum = ((abilities[2] or 0) ~= 0) and (rng().Random() % 2) or 0
  enc.level = level
  enc.abilityNum = abilityNum
  enc.ability = abilities[abilityNum + 1]
  enc.moves = { row.moves[1], row.moves[2], row.moves[3], row.moves[4] }
  return enc
end

local function encounterRules()
  return require("src.core.game3.encounters").rules()
end

-- pokeemerald/src/wild_encounter.c:563
function Pike.standardWildEncounter(sess, cur, prev)
  local R = encounterRules()
  local Rng = rng()
  local header = Pike.manifest().wildHeaders[Pike.wildMonHeaderId(sess) + 1]
  local land = header and header.land
  if not land then return nil end
  -- pokeemerald/src/wild_encounter.c:533
  if prev ~= cur and not (Rng.Random() % 100 < 60) then return nil end
  -- pokeemerald/src/wild_encounter.c:493
  if not (Rng.Random() % Pike.MAX_ENCOUNTER_RATE < R.encounterRate(land.rate, {})) then return nil end
  local enc = R.tryGenerate(land, "land", false, true)
  if not enc then return nil end
  return Pike.tryGenerateWildMon(sess, enc, true)
end

-- pokeemerald/src/wild_encounter.c:706
function Pike.sweetScentWildEncounter(sess)
  local R = encounterRules()
  local header = Pike.manifest().wildHeaders[Pike.wildMonHeaderId(sess) + 1]
  local land = header and header.land
  if not land then return false end
  local enc = R.tryGenerate(land, "land", false, false)
  if not enc then return false end
  enc = Pike.tryGenerateWildMon(sess, enc, false)
  if not enc then return false end
  return Pike.startWildBattle(sess, enc) ~= false
end

-- pokeemerald/src/battle_setup.c:445
function Pike.startWildBattle(sess, enc)
  local Runtime = package.loaded["src.core.game3.runtime"]
  local BattleBridge = require("src.core.game3.battle_bridge")
  sess.battleOutcome = 0
  return BattleBridge.startWild(Runtime and Runtime._mod, Runtime and Runtime._game, enc, {
    pike = true,
    frontier = true,
    scriptedLoss = true,
  })
end

function Pike.inWildRoom(sess)
  return sess ~= nil and sess.map == Pike.WILD_ROOM
end

-- pokeemerald/src/battle_pike.c:1259
function Pike.tryHealMons(sess, healCount)
  if healCount == 0 then return end
  local p = party(sess)
  local idx = shuffledIndices()
  for i = 1, D.PARTY_SIZE do
    local mon = p[idx[i]]
    if mon and not Pike.isFullyHealed(mon) then
      Pike.healMon(mon)
      healCount = healCount - 1
      if healCount == 0 then break end
    end
  end
end

-- pokeemerald/src/battle_pike.c:1551
function Pike.isFullyHealed(mon)
  if hp(mon) < (tonumber(mon.maxHp) or 0) or hasAilment(mon) then return false end
  for j = 1, 4 do
    local m = mon.moves and mon.moves[j]
    if m and m ~= 0 then
      local max = mon.maxPp and mon.maxPp[j] or require("src.core.game3.pokemon").movePp(m)
      if (tonumber(mon.pp and mon.pp[j]) or 0) < (tonumber(max) or 0) then return false end
    end
  end
  return true
end

function Pike.isPartyFullHealed(sess)
  local p = party(sess)
  for i = 1, D.PARTY_SIZE do
    if p[i] and not Pike.isFullyHealed(p[i]) then return false end
  end
  return true
end

-- pokeemerald/src/battle_pike.c:754
function Pike.healOneOrTwo(sess)
  local n = (rng().Random() % 2) + 1
  Pike.tryHealMons(sess, n)
  return n
end

-- pokeemerald/src/battle_pike.c:761
function Pike.npcMessage(ctx, adapters, sess)
  local man = Pike.manifest()
  local npc = man.npcTable[Pike.rt(sess).npcId + 1]
  local n = battleNum(sess)
  local speechId
  if n <= 4 then speechId = npc.speech[1]
  elseif n <= 10 then speechId = npc.speech[2]
  else speechId = npc.speech[3] end
  Util.setStringVar(ctx, adapters, 4, D.speechToString(man.npcSpeeches[speechId + 1]))
end

-- pokeemerald/src/battle_pike.c:1334
function Pike.setHintedRoom(sess)
  local f = Pike.frontier(sess)
  local R = Pike.ROOM
  local Rng = rng()
  if Pike.queenFightType(sess, 1) ~= Util.BRAIN.NOT_READY then
    f.pikeHintedRoomIndex = Rng.Random() % 6
    f.pikeHintedRoomType = R.BRAIN
    return true
  end
  f.pikeHintedRoomIndex = Rng.Random() % 3
  local count, candidates = 0, {}
  if f.pikeHealingRoomsDisabled ~= 0 then
    count = Pike.NUM_ROOM_TYPES - 3
    for i = 0, count - 1 do
      if i ~= R.HEAL_FULL and i ~= R.HEAL_PART then candidates[#candidates + 1] = i end
    end
    while #candidates < count do candidates[#candidates + 1] = 0 end
  else
    count = Pike.NUM_ROOM_TYPES - 1
    for i = 0, count - 1 do candidates[i + 1] = i end
  end
  f.pikeHintedRoomType = candidates[(Rng.Random() % count) + 1]
  if f.pikeHintedRoomType == R.STATUS and not Pike.atLeastOneHealthyMon(sess) then f.pikeHintedRoomType = R.NPC end
  if f.pikeHintedRoomType == R.DOUBLE_BATTLE and not Pike.atLeastTwoAliveMons(sess) then f.pikeHintedRoomType = R.NPC end
  return false
end

-- pokeemerald/src/battle_pike.c:1382
function Pike.roomTypeHint(sess)
  return Pike.manifest().roomTypeHints[Pike.frontier(sess).pikeHintedRoomType + 1]
end

local function trainerUsed(f, tid, upto)
  for i = 1, upto do
    if tonumber(f.trainerIds[i]) == tid then return true end
  end
  return false
end

-- pokeemerald/src/battle_pike.c:1387
function Pike.prepareOneTrainer(sess, difficult)
  local f = Util.frontier(sess)
  local Tower = require("src.core.game3.rse.frontier.tower")
  local num = difficult and (D.STAGES_PER_CHALLENGE - 1) or 1
  local challengeNum = math.floor(Util.get1(f.pikeWinStreaks, lvlMode(sess)) / Pike.NUM_PIKE_ROOMS)
  local n = battleNum(sess)
  local tid
  repeat
    tid = Tower.randomScaledTrainerId(challengeNum, num)
  until not trainerUsed(f, tid, n - 1)
  sess.frontierOpponentA = tid
  D.setGfxVar(sess, tid, 0, F.PIKE)
  if n < Pike.NUM_PIKE_ROOMS then f.trainerIds[n] = tid end
end

-- pokeemerald/src/battle_pike.c:1419
function Pike.prepareTwoTrainers(sess)
  local f = Util.frontier(sess)
  local Tower = require("src.core.game3.rse.frontier.tower")
  local challengeNum = math.floor(Util.get1(f.pikeWinStreaks, lvlMode(sess)) / Pike.NUM_PIKE_ROOMS)
  local n = battleNum(sess)
  local tid
  repeat
    tid = Tower.randomScaledTrainerId(challengeNum, 1)
  until not trainerUsed(f, tid, n - 1)
  sess.frontierOpponentA = tid
  D.setGfxVar(sess, tid, 0, F.PIKE)
  if n <= Pike.NUM_PIKE_ROOMS then f.trainerIds[n] = tid end
  repeat
    tid = Tower.randomScaledTrainerId(challengeNum, 1)
  until not trainerUsed(f, tid, n)
  sess.frontierOpponentB = tid
  D.setGfxVar(sess, tid, 1, F.PIKE)
  if n < Pike.NUM_PIKE_ROOMS then f.trainerIds[n - 1] = tid end
end

-- pokeemerald/src/battle_pike.c:1460
function Pike.clearTrainerIds(sess)
  local f = Util.frontier(sess)
  for i = 1, Pike.NUM_PIKE_ROOMS do f.trainerIds[i] = 0xFFFF end
end

-- pokeemerald/src/battle_pike.c:1468
function Pike.trainerIntro(ctx, adapters, sess)
  local which = specialVar(ctx, Util.VAR_0x8005)
  local tid
  if which == 0 then tid = tonumber(sess.frontierOpponentA) or 0
  elseif which == 1 then tid = tonumber(sess.frontierOpponentB) or 0
  else return end
  if tid < D.TRAINERS_COUNT then
    Util.setStringVar(ctx, adapters, 4, D.trainerSpeech(sess, tid, 0, F.PIKE))
  end
end

-- pokeemerald/src/battle_pike.c:1501
function Pike.queenFightType(sess, nextRoom)
  local f = Util.frontier(sess)
  local ap = Pike.manifest().brainStreakAppearances[F.PIKE + 1]
  local ws = Util.get1(f.pikeWinStreaks, lvlMode(sess)) + nextRoom
  local symbols = Util.symbolCount(sess, F.PIKE)
  local B = Util.BRAIN
  if symbols == 0 or symbols == 1 then
    if ws == ap[symbols + 1] - ap[4] then return symbols + 1 end
    return B.NOT_READY
  end
  if ws == ap[1] - ap[4] then return B.STREAK end
  if ws == ap[2] - ap[4] or (ws > ap[2] and (ws - ap[2] + ap[4]) % ap[3] == 0) then return B.STREAK_LONG end
  return B.NOT_READY
end

-- pokeemerald/src/battle_pike.c:1538
function Pike.healBeforeQueen(ctx, sess)
  local f = Pike.frontier(sess)
  local row = Pike.manifest().healBeforeQueen[f.pikeHintedRoomIndex + 1]
  local n = row and row[specialVar(ctx, 0x8007) + 1] or 0
  Pike.tryHealMons(sess, n)
  return n
end

-- pokeemerald/src/battle_pike.c:1590
function Pike.saveHeldItems(sess)
  local f = Pike.frontier(sess)
  local src = sess.party or {}
  for i = 1, D.PARTY_SIZE do
    local slot = tonumber(f.selectedPartyMons[i]) or 0
    local mon = src[slot]
    f.pikeHeldItemsBackup[i] = mon and (tonumber(mon.heldItem or mon.item) or 0) or 0
  end
end

-- pokeemerald/src/battle_pike.c:1602
function Pike.restoreHeldItems(sess)
  local f = Pike.frontier(sess)
  local p = sess.party or {}
  for i = 1, D.PARTY_SIZE do
    local slot = tonumber(f.selectedPartyMons[i]) or 0
    local mon = p[slot]
    if mon then D.setHeldItem(mon, tonumber(f.pikeHeldItemsBackup[i]) or 0) end
  end
end

-- pokeemerald/src/battle_pike.c:1614
function Pike.init(sess)
  local f = Pike.frontier(sess)
  local lvl = lvlMode(sess)
  f.challengeStatus = 0
  f.curChallengeBattleNum = 0
  f.challengePaused = 0
  if bit.band(tonumber(f.winStreakActiveFlags) or 0, Pike.manifest().winStreakFlags[lvl + 1]) == 0 then
    Util.set1(f.pikeWinStreaks, lvl, 0)
  end
  sess.frontierOpponentA = 0
  sess.battleOutcome = 0
end

-- pokeemerald/src/battle_pike.c:1326
function Pike.inBattlePike(sess)
  return sess ~= nil and Pike.MAPS[tostring(sess.map)] == true
end

-- pokeemerald/src/field_specials.c:3827
Pike.CURTAIN_HEIGHT, Pike.CURTAIN_WIDTH = 4, 3
-- pokeemerald/include/global.fieldmap.h:60
Pike.METATILE_ROW_WIDTH = 8

-- pokeemerald/src/field_specials.c:3841
function Pike.curtainFrameMetatiles(frame, sess)
  local start = C(sess):require("metatile_labels", "METATILE_BattlePike_CurtainFrames_Start")
  local out = {}
  for y = 0, Pike.CURTAIN_HEIGHT - 1 do
    for x = 0, Pike.CURTAIN_WIDTH - 1 do
      out[#out + 1] = { x = x - 1, y = y - 3,
        metatile = (x + start) + (y * Pike.METATILE_ROW_WIDTH) + (frame * Pike.CURTAIN_HEIGHT * Pike.METATILE_ROW_WIDTH) }
    end
  end
  return out
end

-- pokeemerald/src/field_specials.c:3832
function Pike.closeCurtain(sess, px, py, onDone)
  local Task = require("src.core.game3.task")
  local Field = require("src.core.game3.field")
  local timers = { 4, 4, 4 }
  local frame = 0
  Task.spawn(function()
    timers[frame + 1] = timers[frame + 1] - 1
    if timers[frame + 1] == 0 then
      for _, t in ipairs(Pike.curtainFrameMetatiles(frame, sess)) do
        Field.setMetatile(px + t.x, py + t.y, t.metatile, false)
      end
      local FieldView = package.loaded["src.core.game3.field_view"]
      if FieldView then FieldView._nativeDirty = true end
      frame = frame + 1
      if frame == 3 then
        if onDone then onDone() end
        return true
      end
    end
    return false
  end)
end

-- pokeemerald/src/battle_pike.c:1242
function Pike.statusFlash(onDone)
  local Stack = require("src.ui.game3.stack")
  local layer = { id = "rse_pike_status_flash", state = 0, coeff = 0, fades = 3, delay = 0 }
  -- pokeemerald/src/battle_pike.c:1250
  local fadeOutDelay, fadeInDelay, outSpeed, inSpeed = 0, 0, 2, 2
  function layer.update()
    local done = false
    if layer.state == 0 then
      if layer.delay == 0 or layer.delay - 1 == 0 then
        layer.delay = fadeOutDelay
        layer.coeff = math.min(16, layer.coeff + outSpeed)
      else
        layer.delay = layer.delay - 1
      end
      if layer.coeff >= 16 then
        layer.state = 1
        layer.delay = fadeInDelay
      end
    else
      if layer.delay == 0 or layer.delay - 1 == 0 then
        layer.delay = fadeInDelay
        layer.coeff = math.max(0, layer.coeff - inSpeed)
      else
        layer.delay = layer.delay - 1
      end
      if layer.coeff == 0 then
        layer.fades = layer.fades - 1
        if layer.fades == 0 then
          done = true
        else
          layer.delay = fadeOutDelay
          layer.state = 0
        end
      end
    end
    if done then
      Stack.pop(layer.id)
      if onDone then onDone() end
    end
  end
  function layer.handleInput() end
  function layer.draw()
    local okR, Renderer = pcall(require, "src.render.Renderer")
    local a = layer.coeff / 16
    -- pokeemerald/src/battle_pike.c:1186
    local g = 11 / 31
    if okR and Renderer and Renderer.canvas then
      Renderer.screenVeil = { g, g, g, a }
    else
      love.graphics.setColor(g, g, g, a)
      love.graphics.rectangle("fill", 0, 0, 240, 160)
      love.graphics.setColor(1, 1, 1, 1)
    end
  end
  Pike._flash = layer
  Stack.push(layer.id, layer, { hideBelow = false })
  return layer
end

-- pokeemerald/src/battle_tower.c:2101
function Pike.doSpecialBattle(ctx, adapters, sess, which)
  local Tower = require("src.core.game3.rse.frontier.tower")
  local SB = Tower.SPECIAL_BATTLE
  local party = {}
  local tid = tonumber(sess.frontierOpponentA) or 0
  local double = which == SB.PIKE_DOUBLE
  local extra = {}
  if double then
    -- pokeemerald/src/battle_tower.c:1620
    local tmp = {}
    D.fillTrainerParty(sess, tid, 0, 1, tmp, { facility = F.PIKE })
    D.fillTrainerParty(sess, tonumber(sess.frontierOpponentB) or 0, 3, 1, tmp, { facility = F.PIKE })
    party = { tmp[1], tmp[4] }
    extra = { frontierOpponentB = tonumber(sess.frontierOpponentB) or 0 }
  else
    D.fillTrainerParty(sess, tid, 0, D.PARTY_SIZE, party, { facility = F.PIKE })
  end
  return Tower.startBattle(ctx, adapters, sess, "pike", {
    party = party,
    double = double,
    extra = extra,
    transitionId = D.specialTransition(sess, "B_PIKE", party),
  })
end

Rse.register("pike", Pike)

return Pike
