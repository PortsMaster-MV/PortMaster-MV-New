local State = require("src.core.game3.battle.state")
local Moves = require("src.core.game3.battle.moves")
local Data = require("src.core.game3.rse.frontier.f2_data")

local bit = rawget(_G, "bit") or require("bit")

local Fac = {}
Fac.__index = Fac

-- pokeemerald/include/constants/battle_palace.h:20
Fac.GROUP = { ATTACK = 0, DEFENSE = 1, SUPPORT = 2 }
-- pokeemerald/include/constants/battle_palace.h:25
Fac.TARGET = { STRONGER = 0, WEAKER = 1, RANDOM = 2 }
-- pokeemerald/include/constants/battle_string_ids.h:563
Fac.B_MSG_INCAPABLE_OF_POWER = 4

-- pokeemerald/include/constants/pokemon.h:170
local T = { SELECTED = 0, DEPENDS = 1, USER_OR_SELECTED = 2, RANDOM = 4, BOTH = 8, USER = 0x10,
  FOES_AND_ALLY = 0x20, OPPONENTS_FIELD = 0x40 }

local MOVE_CURSE = 174
local MOVE_STRUGGLE = 165

local function num(mv)
  local n = tonumber(mv)
  if n then return n end
  if mv == nil or mv == "" then return 0 end
  return Moves.numForName and Moves.numForName(mv) or 0
end

local function rng(st)
  return function(lo, hi)
    local f = st and st.rng
    if type(f) == "function" then
      local ok, v = pcall(f, lo, hi)
      if ok and type(v) == "number" then return v end
    end
    local Rng = require("src.core.game3.rng")
    return Rng.compat(lo, hi)
  end
end

local function nature(b)
  local mon = b and b.mon or {}
  local p = tonumber(mon.personality) or 0
  if p < 0 then p = p + 4294967296 end
  return p % 25
end

function Fac.new()
  return setmetatable({ kind = "palace", flags = {}, seen = {}, unable = {}, selScript = {} }, Fac)
end

function Fac:start(st)
  self.flags, self.seen, self.unable, self.selScript = {}, {}, {}, {}
end

-- pokeemerald/src/battle_gfx_sfx_util.c:296
function Fac.moveGroup(mv)
  local m = Moves.get(mv)
  local target = tonumber(m and m.target) or 0
  local power = tonumber(m and m.power) or 0
  if target == T.SELECTED or target == T.USER_OR_SELECTED or target == T.RANDOM or target == T.BOTH
      or target == T.FOES_AND_ALLY then
    return power == 0 and Fac.GROUP.SUPPORT or Fac.GROUP.ATTACK
  elseif target == T.DEPENDS or target == T.OPPONENTS_FIELD then
    return Fac.GROUP.SUPPORT
  elseif target == T.USER then
    return Fac.GROUP.DEFENSE
  end
  return Fac.GROUP.ATTACK
end

local function lowHp(b)
  local mon = b and b.mon or {}
  local hp, maxHp = tonumber(mon.hp) or 0, tonumber(mon.maxHp) or 0
  local asleep = (b and (b.status or mon.status)) == "SLP"
  return math.floor(maxHp / 2) >= hp and hp ~= 0 and not asleep
end

local function ids(st)
  return st.double and { 0, 1, 2, 3 } or { 0, 1 }
end

-- pokeemerald/src/battle_main.c:3240
function Fac:syncSwitchIns(st)
  for _, id in ipairs(ids(st)) do
    local b = State.battler(st, id)
    local mon = b and b.mon
    if self.seen[id] ~= mon then
      local switched = self.seen[id] ~= nil
      self.seen[id] = mon
      self.flags[id] = nil
      -- pokeemerald/src/battle_script_commands.c:4659
      if switched and mon and lowHp(b) then self.flags[id] = true end
    end
  end
end

-- pokeemerald/src/battle_main.c:4015
function Fac:turnStart(st, ad, headless)
  self:syncSwitchIns(st)
  if (tonumber(st.turn) or 0) == 0 then return false end
  local texts = {}
  local P = Data.palace()
  local BattleText = require("src.core.game3.battle.battle_text")
  local Adapter = require("src.core.game3.battle.adapter")
  for _, id in ipairs(ids(st)) do
    local b = State.battler(st, id)
    -- pokeemerald/src/battle_script_commands.c:6389
    if b and b.mon and not State.isAbsent(st, id) and not self.flags[id] and lowHp(b) then
      self.flags[id] = true
      local which = P.flavorTextId[nature(b) + 1]
      local sid = P.flavorTextTable[which + 1]
      texts[#texts + 1] = BattleText.get(sid, Adapter.fill(st, { scrActive = b, active = b, atk = b }))
    end
  end
  if #texts == 0 then return false end
  local Ui = require("src.core.game3.battle.ui")
  for _, t in ipairs(texts) do Ui.push(t) end
  if headless then return false end
  self.waiting = true
  return true
end

function Fac:update(st)
  local Ui = require("src.core.game3.battle.ui")
  if not Ui.pump() then return false end
  if Ui.dialogPending and Ui.dialogPending() then return false end
  self.waiting = nil
  return true
end

-- pokeemerald/src/battle_gfx_sfx_util.c:325
function Fac:target(st, id)
  if st.double then
    local o1, o2
    if id % 2 == 0 then o1, o2 = 1, 3 else o1, o2 = 0, 2 end
    local b1, b2 = State.battler(st, o1), State.battler(st, o2)
    local h1 = tonumber(b1 and b1.mon and b1.mon.hp) or 0
    local h2 = tonumber(b2 and b2.mon and b2.mon.hp) or 0
    local r = rng(st)
    if h1 == h2 then return State.OPPOSITE(id % 2) + bit.band(r(0, 0xFFFF), 2) end
    local pref = Data.palace().moveTarget[nature(State.battler(st, id)) + 1]
    if pref == Fac.TARGET.STRONGER then return h1 > h2 and o1 or o2 end
    if pref == Fac.TARGET.WEAKER then return h1 < h2 and o1 or o2 end
    return State.OPPOSITE(id % 2) + bit.band(r(0, 0xFFFF), 2)
  end
  return State.OPPOSITE(id)
end

local function aiPick(st, id, mask)
  local Engine = require("src.core.game3.battle.engine")
  local Ai = require("src.core.game3.battle.ai")
  local orig = Engine.moveLimitations
  -- pokeemerald/src/battle_ai_script_commands.c:323
  Engine.moveLimitations = function(b, ad)
    local bad = orig(b, ad)
    if b == State.battler(st, id) then
      for i = 1, 4 do
        if bit.band(mask, bit.lshift(1, i - 1)) == 0 then bad[i] = true end
      end
    end
    return bad
  end
  local ok, act = pcall(Ai.chooseMove, st, { battler = id })
  Engine.moveLimitations = orig
  if not ok then error(act, 0) end
  if act and act.kind == "move" and act.slot and bit.band(mask, bit.lshift(1, act.slot - 1)) ~= 0 then
    return act.slot
  end
  local slots = {}
  local b = State.battler(st, id)
  for i = 1, 4 do
    if num(b.mon.moves and b.mon.moves[i]) ~= 0 then slots[#slots + 1] = i end
  end
  if act and act.kind == "move" and act.slot then return act.slot end
  return slots[rng(st)(1, #slots)]
end

-- pokeemerald/src/battle_gfx_sfx_util.c:109
function Fac:choose(st, id, ad)
  local Engine = require("src.core.game3.battle.engine")
  local b = State.battler(st, id)
  local mon = b and b.mon or {}
  local moves = mon.moves or {}
  local limits = Engine.moveLimitations(b, ad) or {}
  local r = rng(st)
  local percent = r(0, 99)
  local lik = Data.palace().moveGroupLikelihood[nature(b) + 1]
  local i = self.flags[id] and 2 or 0
  local minGroup, maxGroup = i, i + 2
  while i < maxGroup do
    if lik[i + 1] > percent then break end
    i = i + 1
  end
  local group = i - minGroup
  if i == maxGroup then group = Fac.GROUP.SUPPORT end
  local mask = 0
  for slot = 1, 4 do
    local mv = num(moves[slot])
    if mv == 0 then break end
    if Fac.moveGroup(mv) == group and (tonumber(mon.pp and mon.pp[slot]) or 0) ~= 0 then
      mask = bit.bor(mask, bit.lshift(1, slot - 1))
    end
  end
  local chosen
  if mask ~= 0 then chosen = aiPick(st, id, mask) end
  if not chosen then
    local all = true
    for slot = 1, 4 do if not limits[slot] then all = false end end
    if all then
      self.unable[id] = true
      return 1
    end
    local per = { 0, 0, 0 }
    for slot = 1, 4 do
      local mv = num(moves[slot])
      if not limits[slot] then
        local g = Fac.moveGroup(mv)
        per[g + 1] = per[g + 1] + 1
      end
    end
    local multi = 0
    if per[1] >= 2 then multi = multi + 1 end
    if per[2] >= 2 then multi = multi + 1 end
    -- pokeemerald/src/battle_gfx_sfx_util.c:195
    if per[2] * 16 >= 2 * 256 then multi = multi + 1 end
    if multi > 1 or multi == 0 then
      repeat
        local s = r(0, 0xFFFF) % 4 + 1
        if not limits[s] then chosen = s end
      until chosen
    else
      local want
      if per[1] >= 2 then want = Fac.GROUP.ATTACK end
      if per[2] >= 2 then want = Fac.GROUP.DEFENSE end
      if per[2] * 16 >= 2 * 256 then want = Fac.GROUP.SUPPORT end
      repeat
        local s = r(0, 0xFFFF) % 4 + 1
        if not limits[s] and want == Fac.moveGroup(num(moves[s])) then chosen = s end
      until chosen
    end
    if r(0, 0xFFFF) % 100 >= 50 then
      self.unable[id] = true
      return 1
    end
  end
  return chosen
end

-- pokeemerald/src/battle_gfx_sfx_util.c:275
function Fac:targetFor(st, id, slot)
  local b = State.battler(st, id)
  local mv = num(b.mon.moves[slot])
  local target
  if mv == MOVE_CURSE then
    local Types = require("src.core.game3.battle.types")
    local ghost = b.type1 == Types.ID.GHOST or b.type2 == Types.ID.GHOST
    target = ghost and T.SELECTED or T.USER
  else
    local m = Moves.get(mv)
    target = tonumber(m and m.target) or 0
  end
  if bit.band(target, T.USER) ~= 0 then return id end
  if target == T.SELECTED then return self:target(st, id) end
  return (id % 2 == 0) and 1 or 0
end

-- pokeemerald/src/battle_util.c:975
function Fac:selectionCheck(st, id, slot, ad)
  local Engine = require("src.core.game3.battle.engine")
  local b = State.battler(st, id)
  local mv = num(b.mon.moves[slot])
  local script
  if b.expDisabledMove and num(b.expDisabledMove) == mv and mv ~= 0 then
    script = "STRINGID_PKMNMOVEISDISABLED"
    self.unable[id] = true
  end
  if mv == num(b.lastMoveId or b.lastMove) and mv ~= MOVE_STRUGGLE and (b.expTormented or b.torment) then
    script = "STRINGID_PKMNCANTUSEMOVETORMENT"
    self.unable[id] = true
  end
  local m = Moves.get(mv)
  if (tonumber(b.expTauntedTurns) or 0) > 0 and (tonumber(m and m.power) or 0) == 0 then
    script = "STRINGID_PKMNCANTUSEMOVETAUNT"
    self.unable[id] = true
  end
  if Engine.isImprisoned(ad, b, mv) then
    script = "STRINGID_PKMNCANTUSEMOVESEALED"
    self.unable[id] = true
  end
  local HeldItems = require("src.core.game3.battle.held_items")
  local cm = num(b.choicedMove)
  if HeldItems.of(b) == HeldItems.HOLD.CHOICE_BAND and cm ~= 0 and cm ~= 0xFFFF and cm ~= mv then
    self.unable[id] = true
  end
  if (tonumber(b.mon.pp and b.mon.pp[slot]) or 0) == 0 then self.unable[id] = true end
  self.selScript[id] = script
end

function Fac:actionFor(st, id, ad)
  self.choices = (self.choices or 0) + 1
  local slot = self:choose(st, id, ad)
  local b = State.battler(st, id)
  local tid = self:targetFor(st, id, slot)
  if not self.unable[id] then self:selectionCheck(st, id, slot, ad) end
  local act = { kind = "move", move = b.mon.moves[slot], slot = slot, user = (id % 2 == 0) and "player" or "enemy" }
  if st.double then
    act.battler, act.target = id, tid
  end
  return act
end

local function isFight(act)
  return type(act) == "table" and act.kind == "move" and act.move ~= "STRUGGLE" and act.move ~= MOVE_STRUGGLE
end

local function locked(st, id)
  local b = State.battler(st, id)
  return b and (b.expLockedMove or b.expMustRecharge or (b.expEncoreMove and (tonumber(b.expEncoreTurns) or 0) > 0))
end

-- pokeemerald/src/battle_main.c:4185
function Fac:actions(st, playerAct, enemyAct)
  local ad = require("src.core.game3.battle")._adapter
  self.unable, self.selScript = {}, {}
  if isFight(playerAct) and not locked(st, 0) then playerAct = self:actionFor(st, 0, ad) end
  if isFight(enemyAct) and not locked(st, 1) then enemyAct = self:actionFor(st, 1, ad) end
  return playerAct, enemyAct
end

function Fac:doubleActions(st, chosen)
  local ad = require("src.core.game3.battle")._adapter
  self.unable, self.selScript = {}, {}
  for id = 0, 3 do
    local act = chosen[id]
    if isFight(act) and not locked(st, id) and not State.isAbsent(st, id) then
      chosen[id] = self:actionFor(st, id, ad)
      chosen[id].battler = id
    end
  end
end

-- pokeemerald/src/battle_util2.c:126
local function tryEscapeStatus(st, ad, user, say)
  local status = ad:status(user)
  if status == "SLP" then
    local up = ad:uproarActive()
    if up and ad:abilityOf(user) ~= "SOUNDPROOF" then
      ad:clearStatus(user)
      user.expNightmare = nil
      say("STRINGID_PKMNWOKEUPINUPROAR", { atk = user })
      return false
    end
    local toSub = (ad:abilityOf(user) == "EARLY_BIRD") and 2 or 1
    local turns = tonumber(user.sleepTurns) or tonumber(user.mon and (user.mon.sleepTurns or user.mon.sleep))
    if not turns or turns <= 0 then turns = ad:rollSleepTurns() end
    if turns < toSub then turns = 0 else turns = turns - toSub end
    user.sleepTurns = turns
    if turns > 0 then
      say("STRINGID_PKMNFASTASLEEP", { atk = user })
      ad:statusAnim(user, "SLP")
      return true
    end
    ad:clearStatus(user)
    user.expNightmare = nil
    say("STRINGID_PKMNWOKEUP", { atk = user })
    return false
  end
  if status == "FRZ" then
    if rng(st)(0, 0xFFFF) % 5 ~= 0 then
      say("STRINGID_PKMNISFROZEN", { atk = user })
      ad:statusAnim(user, "FRZ")
      return true
    end
    ad:clearStatus(user)
    say("STRINGID_PKMNWASDEFROSTED2", { atk = user })
  end
  return false
end

-- pokeemerald/src/battle_util.c:263
function Fac:resolveMove(st, ad, act, out, userRef, targetRef)
  local Engine = require("src.core.game3.battle.engine")
  local id = tonumber(act.battler) or ((act.user == "enemy" or (type(act.user) == "table" and act.user.side == "enemy")) and 1 or 0)
  if not self.unable[id] then
    return Engine.resolveMove(userRef, targetRef, act.move, act.slot, ad, st, out)
  end
  self.unable[id] = nil
  local user = State.battler(st, id)
  local mark = ad:eventMark()
  local prevSay = ad._say
  ad._say = function(text) out[#out + 1] = text end
  local function say(key, fill) ad:sayText(key, fill) end
  if user and user.mon and (tonumber(user.mon.hp) or 0) > 0 then
    local script = self.selScript[id]
    self.selScript[id] = nil
    if script then
      say(script, { active = user, atk = user, currentMove = act.move })
    elseif not tryEscapeStatus(st, ad, user, say) then
      local sid = Data.palace().inobedientStringIds[Fac.B_MSG_INCAPABLE_OF_POWER + 1]
      say(sid, { atk = user })
    end
  end
  local anim = { moveId = act.move, user = user, target = user, hits = {}, heals = {}, faints = {},
    missed = false, statusOnly = true }
  return Engine.finishResolve(ad, st, out, anim, mark, prevSay, true)
end

-- pokeemerald/src/battle_controller_player.c:2631
function Fac:fightShortcut(st, id)
  local b = State.battler(st, id or 0)
  if not (b and b.mon) then return nil end
  local act = { kind = "move", move = b.mon.moves and b.mon.moves[1], slot = 1, user = "player" }
  if id ~= nil then
    act.battler = id
    act.target = (id % 2 == 0) and 1 or 0
  end
  return act
end

local installed = false
function Fac.install()
  if installed then return end
  installed = true
  local Commands = require("src.core.game3.battle.commands")
  local orig = Commands.fightShortcut
  Commands.fightShortcut = function(st, battlerId, ...)
    local act, msg = orig(st, battlerId, ...)
    if act then return act, msg end
    local fac = st and st.facility
    if fac and fac.fightShortcut then return fac:fightShortcut(st, battlerId) end
    return nil
  end
end
Fac.install()

return Fac
