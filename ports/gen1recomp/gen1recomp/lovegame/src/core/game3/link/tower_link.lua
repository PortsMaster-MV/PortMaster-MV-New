local Rse = require("src.core.game3.rse.init")

local TowerLink = {}

TowerLink.MSG = {
  CHALLENGE = "game3_tower_challenge",
  TRAINERS = "game3_tower_trainers",
  SETUP = "game3_tower_setup",
}
-- pokeemerald/include/constants/union_room.h:78
TowerLink.WIRES = { "battle_tower", "battle_tower_open" }
-- pokeemerald/src/battle_tower.c:2570
TowerLink.LOAD = { SEND_CHALLENGE = 0, RECV_CHALLENGE = 1, SEND_IDS = 2, RECV_IDS = 3, DONE = 6 }
-- pokeemerald/include/constants/battle.h:100
TowerLink.B_OUTCOME = { WON = 1, LOST = 2, DREW = 3 }
TowerLink.OUTCOME_OF = { win = 1, lose = 2, draw = 3 }
-- pokeemerald/src/battle_main.c:1197
TowerLink.SEAT_OF_PLAYER = { [0] = 0, [1] = 2 }
-- pokeemerald/src/battle_controller_opponent.c:1271
TowerLink.FOE_SEATS = { 3, 1 }
TowerLink.WAIT_TICKS = 3600

TowerLink.loads = setmetatable({}, { __mode = "k" })
TowerLink.battle = nil
TowerLink._link = nil

local function trainers() return require("src.core.game3.rse.frontier.trainers") end
local function Util() return require("src.core.game3.rse.frontier.util") end
local function Tower() return require("src.core.game3.rse.frontier.tower") end
local function LB() return require("src.core.game3.link.battle") end

function TowerLink.link()
  if TowerLink._link then return TowerLink._link end
  local okL, Link = pcall(require, "src.core.game3.link.init")
  local lk = okL and Link and Link.link or nil
  if lk and lk.isOpen and lk:isOpen() then return lk end
  return nil
end

local function seatOf(lk)
  if type(lk.getSeat) == "function" then return tonumber(lk:getSeat()) or 0 end
  return tonumber(lk.seat) or 0
end

local function fromOf(msg)
  return tonumber(msg and (msg.from or msg.seat))
end

-- pokeemerald/src/battle_tower.c:2605
function TowerLink.generateTrainerIds(challengeNum, randomScaled)
  local D = trainers()
  randomScaled = randomScaled or Tower().randomScaledTrainerId
  local ids = {}
  for i = 0, D.STAGES_PER_CHALLENGE * 2 - 1 do
    local id
    repeat
      id = randomScaled(challengeNum, math.floor(i / 2))
      local dup = false
      for j = 1, i do
        if ids[j] == id then dup = true break end
      end
    until not dup
    ids[i + 1] = id
  end
  return ids
end

local function challengeNumOf(sess)
  local D = trainers()
  local f = Util().frontier(sess)
  local mode = Rse.var("VAR_FRONTIER_BATTLE_MODE", sess)
  return math.floor(Util().get2(f.towerWinStreaks, mode, f.lvlMode) / D.STAGES_PER_CHALLENGE)
end

-- pokeemerald/src/battle_tower.c:2633
function TowerLink.applyTrainerIds(sess, ids)
  local D = trainers()
  local f = Util().frontier(sess)
  f.trainerIds = f.trainerIds or {}
  for i = 1, D.STAGES_PER_CHALLENGE * 2 do f.trainerIds[i] = tonumber(ids[i]) or 0 end
  local n = tonumber(f.curChallengeBattleNum) or 0
  sess.frontierOpponentA = tonumber(f.trainerIds[n * 2 + 1]) or 0
  sess.frontierOpponentB = tonumber(f.trainerIds[n * 2 + 2]) or 0
  pcall(D.setGfxVar, sess, sess.frontierOpponentA, 0)
  pcall(D.setGfxVar, sess, sess.frontierOpponentB, 1)
end

-- pokeemerald/src/battle_tower.c:2570
function TowerLink.loadLinkMultiOpponents(ctx, sess, adapters)
  local U = Util()
  local L = TowerLink.LOAD
  local state = Rse.specialVar(ctx, U.VAR_RESULT)
  local lk = TowerLink.link()
  if state == L.SEND_CHALLENGE then
    if Rse.var("VAR_FRONTIER_BATTLE_MODE", sess) ~= trainers().MODE.LINK_MULTIS then
      U.setResult(ctx, L.DONE)
      return
    end
    if not lk then
      Rse.missing("frontierLink", "LoadLinkMultiOpponentsData without a link", adapters and adapters.log)
      TowerLink.applyTrainerIds(sess, TowerLink.generateTrainerIds(challengeNumOf(sess)))
      U.setResult(ctx, L.DONE)
      return
    end
    local seat = seatOf(lk)
    local mine = challengeNumOf(sess)
    TowerLink.loads[lk] = { seat = seat, challenge = { [seat] = mine }, ticks = 0 }
    lk:send({ type = TowerLink.MSG.CHALLENGE, from = seat, challengeNum = mine })
    U.setResult(ctx, L.RECV_CHALLENGE)
    return
  end
  local st = lk and TowerLink.loads[lk]
  if not (st and lk) then
    if state ~= L.DONE then U.setResult(ctx, L.DONE) end
    return
  end
  st.ticks = st.ticks + 1
  if state == L.RECV_CHALLENGE then
    local msg = lk:take(TowerLink.MSG.CHALLENGE)
    while msg do
      local from = fromOf(msg)
      if from and from ~= st.seat then st.challenge[from] = tonumber(msg.challengeNum) or 0 end
      msg = lk:take(TowerLink.MSG.CHALLENGE)
    end
    local best, n = nil, 0
    for _, v in pairs(st.challenge) do
      n = n + 1
      if best == nil or v > best then best = v end
    end
    if n < 2 then return end
    st.challengeNum = best
    if st.seat == 0 then st.ids = TowerLink.generateTrainerIds(best) end
    U.setResult(ctx, L.SEND_IDS)
  elseif state == L.SEND_IDS then
    if st.seat == 0 then lk:send({ type = TowerLink.MSG.TRAINERS, from = st.seat, ids = st.ids }) end
    U.setResult(ctx, L.RECV_IDS)
  elseif state == L.RECV_IDS then
    if st.seat ~= 0 then
      local msg = lk:take(TowerLink.MSG.TRAINERS)
      while msg do
        if fromOf(msg) == 0 and type(msg.ids) == "table" then st.ids = msg.ids end
        msg = lk:take(TowerLink.MSG.TRAINERS)
      end
    end
    if not st.ids then return end
    TowerLink.applyTrainerIds(sess, st.ids)
    TowerLink.loads[lk] = nil
    -- pokeemerald/src/battle_tower.c:2651
    U.setResult(ctx, L.DONE)
  end
end

local function foeParties(sess)
  local D = trainers()
  local tidA = tonumber(sess.frontierOpponentA) or 0
  local tidB = tonumber(sess.frontierOpponentB) or 0
  local partyA, partyB = {}, {}
  -- pokeemerald/src/battle_tower.c:1620
  D.fillTrainerParty(sess, tidA, 0, D.MULTI_PARTY_SIZE, partyA)
  D.fillTrainerParty(sess, tidB, 0, D.MULTI_PARTY_SIZE, partyB, { setOwner = tidA })
  return tidA, partyA, tidB, partyB
end

local function foeRow(sess, tid, party)
  local D = trainers()
  local F = D.FACILITY
  return {
    name = D.trainerName(sess, tid, F.TOWER),
    trainerId = tid,
    gender = D.isFemale(sess, tid, F.TOWER) and 1 or 0,
    party = LB().packParty(party),
  }
end

-- pokeemerald/src/battle_main.c:1161
function TowerLink.buildSetup(sess, seat, battleNum, seed)
  local me = LB().localPlayer()
  local party = {}
  for i, mon in ipairs(sess.party or {}) do
    if i <= trainers().MULTI_PARTY_SIZE then party[i] = LB().copy(mon) end
  end
  local setup = {
    type = TowerLink.MSG.SETUP,
    from = seat,
    battleNum = battleNum,
    name = me.name,
    trainerId = me.trainerId,
    gender = me.gender,
    party = LB().packParty(party),
  }
  if seat == 0 then
    local tidA, partyA, tidB, partyB = foeParties(sess)
    -- pokeemerald/src/battle_main.c:1302
    setup.foes = { foeRow(sess, tidA, partyA), foeRow(sess, tidB, partyB) }
    setup.seed = seed
  end
  return setup
end

function TowerLink.setupsFor(mine, peer)
  local setups = {}
  local lead = (tonumber(mine.from) == 0) and mine or peer
  local other = lead == mine and peer or mine
  setups[TowerLink.SEAT_OF_PLAYER[0]] = lead
  setups[TowerLink.SEAT_OF_PLAYER[1]] = other
  local foes = type(lead.foes) == "table" and lead.foes or {}
  for i, seat in ipairs(TowerLink.FOE_SEATS) do setups[seat] = foes[i] end
  return setups, tonumber(lead.seed)
end

local function withAiRng(st, fn)
  local tb = TowerLink.battle
  local saved = st.rng
  if tb and tb.aiRng then st.rng = tb.aiRng end
  local ok, a, b = pcall(fn)
  st.rng = saved
  if not ok then return nil end
  return a, b
end

-- pokeemerald/src/battle_ai_switch_items.c:67
function TowerLink.aiAction(seat)
  local Battle = package.loaded["src.core.game3.battle"]
  local st = Battle and Battle.getState and Battle.getState()
  local tb = TowerLink.battle
  if not (st and tb) then return { kind = "move", slot = 1 } end
  local id = st.linkLocalOf and st.linkLocalOf[seat]
  local Ai = require("src.core.game3.battle.ai")
  local act = withAiRng(st, function() return Ai.chooseAction(st, id, { rng = tb.aiRng, aiFlags = tb.aiFlags }) end)
  if type(act) ~= "table" then return { kind = "move", slot = 1 } end
  if act.kind == "switch" then return { kind = "switch", slot = tonumber(act.slot) } end
  if act.kind ~= "move" then return { kind = "move", slot = 1 } end
  local target = tonumber(act.target)
  return { kind = "move", slot = tonumber(act.slot) or 1, target = target and st.linkSeatOf[target] or nil }
end

-- pokeemerald/src/battle_controller_opponent.c:1410
function TowerLink.aiSwitch(seat)
  local Battle = package.loaded["src.core.game3.battle"]
  local st = Battle and Battle.getState and Battle.getState()
  if not st then return nil end
  local State = require("src.core.game3.battle.state")
  local id = st.linkLocalOf and st.linkLocalOf[seat]
  if id == nil then return nil end
  local active = {}
  for b = 0, 3 do
    local bt = State.battler(st, b)
    if bt and bt.partyIndex and State.sideOf(b) == State.sideOf(id) then active[bt.partyIndex] = true end
  end
  local party = State.sideOf(id) == "player" and st.playerParty or st.foeParty
  local cands = {}
  for slot, mon in ipairs(party or {}) do
    if (tonumber(mon.hp) or 0) > 0 and not active[slot] and State.ownsSlot(st, id, slot) then
      cands[#cands + 1] = slot
    end
  end
  if #cands == 0 then return nil end
  local okE, Engine = pcall(require, "src.core.game3.battle.engine")
  if okE and Engine.mostSuitableMon then
    local pick = withAiRng(st, function() return Engine.mostSuitableMon(st, Battle._adapter, id) end)
    for _, c in ipairs(cands) do
      if c == pick then return pick end
    end
  end
  return cands[1]
end

local function speech(sess, tid, which)
  local TextIR = require("src.core.game3.scripting.text_ir")
  local ok, text = pcall(function()
    return TextIR.toPlain(trainers().trainerSpeech(sess, tid, which, trainers().FACILITY.TOWER), {})
  end)
  return ok and text or nil
end

function TowerLink.foeTrainer(sess, tid)
  local D = trainers()
  local F = D.FACILITY.TOWER
  local classId = D.opponentClass(sess, tid, F)
  return {
    class = classId,
    className = D.className(sess, classId),
    name = D.trainerName(sess, tid, F),
    -- pokeemerald/src/battle_controller_link_opponent.c:1231
    pic = D.frontSpriteId(sess, tid, F),
  }
end

function TowerLink.battleOpts(sess, setups)
  local D = trainers()
  local BP = require("src.core.game3.battle.profile")
  local foeA = setups[TowerLink.FOE_SEATS[1]] or {}
  local foeB = setups[TowerLink.FOE_SEATS[2]] or {}
  local tidA = tonumber(foeA.trainerId) or 0
  local tidB = tonumber(foeB.trainerId) or 0
  local rowA, rowB = TowerLink.foeTrainer(sess, tidA), TowerLink.foeTrainer(sess, tidB)
  return {
    frontier = true,
    battleTower = true,
    tower = true,
    towerLinkMulti = true,
    scriptedLoss = true,
    aiFlags = Tower().aiFlags(sess),
    trainerItems = { 0, 0, 0, 0 },
    song = BP.battleSong(BP.get(sess), { trainerClass = rowA.class, frontier = true }),
    transitionId = D.specialTransition(sess, "B_TOWER", {}),
    trainerName = rowA.name,
    trainerPicId = rowA.pic,
    frontierTrainer = rowA,
    frontierTrainerB = rowB,
    -- pokeemerald/src/battle_message.c:2600
    defeatText = speech(sess, tidA, 2),
    victoryText = speech(sess, tidA, 1),
    defeatTextB = speech(sess, tidB, 2),
    victoryTextB = speech(sess, tidB, 1),
  }
end

function TowerLink.finish(sess, word)
  local L = LB()
  if L.setVirtual then L.setVirtual(nil) end
  L._offField = nil
  TowerLink.battle = nil
  local code = TowerLink.OUTCOME_OF[word] or TowerLink.B_OUTCOME.DREW
  sess.battleOutcome = code
  return code
end

-- pokeemerald/src/battle_tower.c:2031
function TowerLink.startBattle(ctx, adapters, sess)
  local L = LB()
  local N = require("src.core.game3.scripting.natives")
  local lk = TowerLink.link()
  if not (lk and L.VIRTUAL_SEATS) then
    Rse.missing("frontierLink", lk and "link multi battle needs LB.VIRTUAL_SEATS" or "link multi without a link",
      adapters and adapters.log)
    return false
  end
  local seat = seatOf(lk)
  local f = Util().frontier(sess)
  local battleNum = tonumber(f.curChallengeBattleNum) or 0
  local seed = seat == 0 and (L.seedFromRelay() or L.dealSeed()) or nil
  local mine = TowerLink.buildSetup(sess, seat, battleNum, seed)
  local peer, ticks, started, finished = nil, 0, false, false
  sess.battleOutcome = 0
  if not N.yieldHost(ctx, adapters, function() end) then return false end
  lk:send(mine)
  local function done(word)
    finished = true
    local code = TowerLink.finish(sess, word)
    if ctx then ctx.lastBattleOutcome = code end
    -- pokeemerald/src/battle_main.c:5228
    Util().setResult(ctx, code)
    Util().onSpecialBattleEnd(sess, "frontier")
  end
  ctx.nativePoll = function()
    if finished then return true end
    if started then return false end
    ticks = ticks + 1
    local live = TowerLink.link()
    if not live then
      done("draw")
      return true
    end
    local msg = live:take(TowerLink.MSG.SETUP, function(m) return tonumber(m.battleNum) == battleNum end)
    if msg and fromOf(msg) ~= seat then peer = msg end
    if not peer then
      if ticks > TowerLink.WAIT_TICKS then
        done("draw")
        return true
      end
      return false
    end
    local setups, sharedSeed = TowerLink.setupsFor(mine, peer)
    TowerLink.battle = {
      aiRng = L.makeRng((tonumber(sharedSeed) or 0) + 0x5EED),
      aiFlags = Tower().aiFlags(sess),
    }
    L.freshBattle()
    L.mode = L.MODE_OF.multi
    L.unionRoom = false
    L.seed = sharedSeed
    L.seat = seat
    L._myPacked = mine.party
    L._myParty = nil
    local virtual = { seats = {}, seatMap = TowerLink.SEAT_OF_PLAYER,
      unpack = { strict = true, forceLevel = nil } }
    for _, s in ipairs(TowerLink.FOE_SEATS) do
      virtual.seats[s] = seat == 0 and {
        action = function() return TowerLink.aiAction(s) end,
        switch = function() return TowerLink.aiSwitch(s) end,
      } or {}
    end
    L.setVirtual(virtual)
    L.state = "setup"
    started = true
    local opts = TowerLink.battleOpts(sess, setups)
    local ok = L.beginMulti(setups, function(word)
      done(word)
      local Space = package.loaded["src.core.game3.scripting.space"]
      if Space and Space.vm then Space.vm:tick() end
    end, { offField = true, battle = opts })
    if ok == false and not finished then
      done("draw")
      return true
    end
    return finished
  end
  return true
end

function TowerLink.reset()
  TowerLink.loads = setmetatable({}, { __mode = "k" })
  TowerLink.battle = nil
end

-- pokeemerald/src/union_room.c:375
function TowerLink.onLinked()
  return false
end

function TowerLink.registerGroups()
  local okG, RseGroups = pcall(require, "src.core.game3.link.rse_groups")
  if not (okG and RseGroups and RseGroups.register) then return false end
  for _, wire in ipairs(TowerLink.WIRES) do
    RseGroups.register(wire, {
      linkType = "BATTLE_TOWER",
      onLinked = function(ctx, adapters, link) return TowerLink.onLinked(ctx, adapters, link) end,
    })
  end
  return true
end

TowerLink.registerGroups()

return TowerLink
