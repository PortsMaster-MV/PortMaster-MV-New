local M = {}
M.EXCLUDED_FLAGS = {link = 0x0002, firstBattle = 0x0010, safari = 0x0080,
  battleTower = 0x0100, wallyTutorial = 0x0200, ereaderTrainer = 0x0800}

local function integer(v, key, lo, hi)
  assert(type(v) == "number" and v == math.floor(v) and v >= lo and v <= hi,
    "RS BattleResults missing/invalid " .. key)
  return v
end
local function u8(v, key) return integer(v, key, 0, 255) end
local function u16(v, key) return integer(v, key, 0, 65535) end
local function boolean(v, key)
  assert(v == true or v == false or v == 0 or v == 1, "RS BattleResults missing/invalid " .. key)
  return v == true or v == 1
end
local function side(v) return integer(v, "side", 0, 1) end
local function result(r)
  assert(type(r) == "table" and r._rsInitialized == true, "RS BattleResults not initialized")
  return r
end
local function inc(r, key)
  r[key] = math.min(u8(r[key], key) + 1, 255)
end
local function zero10(a)
  a = a or {}
  for i = 1, 10 do a[i] = 0 end
  return a
end
local function nickname(a)
  assert(type(a) == "table", "RS BattleResults requires native nickname bytes")
  local out = {}
  for i = 1, 11 do
    out[i] = u8(a[i], "nickname byte" .. i)
    if out[i] == 255 then return out end
  end
  error("RS BattleResults nickname exceeds native ten glyph/EOS buffer boundary")
end
local function copyName(r, key, a)
  local dst = r[key]
  for i = 1, #a do dst[i] = a[i] end
end

-- battle_main.c:3487
function M.new(previous)
  assert(previous == nil or type(previous) == "table", "RS BattleResults reset target must be a table")
  local r = previous or {}
  for _, key in ipairs({"battleTurnCounter", "playerFaintCounter", "opponentFaintCounter",
    "totalMonSwitchCounter", "numHealingItemsUsed", "reviveCount", "lastOpponentSpecies",
    "lastUsedMovePlayer", "lastUsedMoveOpponent", "playerMon1Species", "opponentSpecies", "caughtMonSpecies"}) do
    r[key] = 0
  end
  r.playerMonWasDamaged, r.usedMasterBall = false, false
  r.catchAttempts = r.catchAttempts or {}
  for i = 1, 11 do r.catchAttempts[i] = 0 end
  r.playerMon1NameBytes = zero10(r.playerMon1NameBytes)
  r.opponentNameBytes = zero10(r.opponentNameBytes)
  r.caughtMonNickBytes = zero10(r.caughtMonNickBytes)
  r.playerMon1Name, r.opponentName, r.caughtMonNick = nil, nil, nil
  r._rsInitialized, r._rsFinishSnapshot = true, false
  return r
end

-- battle_main.c:5170
function M.moveDispatch(r, c)
  result(r)
  if boolean(c.called, "called") or boolean(c.pursuitSwitch, "pursuitSwitch")
      or boolean(c.initiallyAbsent, "initiallyAbsent") then return false end
  local which, move = side(c.side), u16(c.move, "selected move")
  r[which == 0 and "lastUsedMovePlayer" or "lastUsedMoveOpponent"] = move
  return true
end

-- battle_script_commands.c:1905
function M.healthbar(r, c)
  result(r)
  if boolean(c.controllerBusy, "controllerBusy") or boolean(c.noEffect, "noEffect") then return false end
  local sub = boolean(c.hasSubstitute, "hasSubstitute")
  if sub and u16(c.substituteHP, "substituteHP") ~= 0
      and not boolean(c.ignoreSubstitute, "ignoreSubstitute") then return false end
  local which = side(c.side)
  local damage = integer(c.damage, "gBattleMoveDamage", -2147483648, 2147483647)
  if which ~= 0 or damage <= 0 then return false end
  r.playerMonWasDamaged = true
  return true
end

-- battle_script_commands.c:3041
function M.tryFaint(r, c)
  result(r)
  if boolean(c.checkOnly, "tryfaint checkOnly") then return false end
  local selector = u8(c.selector, "tryfaint selector")
  local selected
  if selector == 1 then selected = c.attacker else selected = c.target end
  local id = integer(selected, "tryfaint selected slot", 0, 3)
  local b = assert(c.battlers and c.battlers[id], "RS BattleResults missing selected faint slot")
  if boolean(b.absent, "faint absent") or u16(b.hp, "faint HP") ~= 0 then return false end
  if side(b.side) == 0 then inc(r, "playerFaintCounter")
  else
    local species = u16(b.species, "fainted working species")
    inc(r, "opponentFaintCounter"); r.lastOpponentSpecies = species
  end
  return true, id
end

-- pokemon_item_effect.c:270
function M.hpItem(r, c)
  result(r)
  if not boolean(c.hpEffect, "HEAL_HP effect") or boolean(c.revive, "REVIVE effect")
      or not boolean(c.inBattle, "inBattle") or u8(c.effectMode, "item effect mode") ~= 0
      or not boolean(c.committed, "direct HP assignment committed") then return false end
  local hp, max = u16(c.hpBefore, "item prior HP"), u16(c.maxHP, "item max HP")
  if hp == 0 or hp == max then return false end
  local target = integer(c.battleId, "item target battleId", 0, 4)
  if target == 4 or side(c.usingSide) ~= 0 then return false end
  inc(r, "numHealingItemsUsed")
  return true
end

-- battle_script_commands.c:9509
function M.giveCaughtMon(r, c)
  result(r)
  local species, bytes = u16(c.species, "caught working species"), nickname(c.nicknameBytes)
  r.caughtMonSpecies = species; copyName(r, "caughtMonNickBytes", bytes)
  r.caughtMonNick = c.nicknameText
  return true
end

-- include/constants/battle.h:48
function M.publicationAllowed(flags)
  flags = integer(flags, "native battleTypeFlags", 0, 4294967295)
  for _, mask in pairs(M.EXCLUDED_FLAGS) do
    if math.floor(flags / mask) % 2 ~= 0 then return false end
  end
  return true
end

-- battle_main.c:5030
function M.finishSnapshot(r, c)
  result(r)
  if r._rsFinishSnapshot then return false, false end
  local action = u8(c.actionId, "finish actionId")
  if action ~= 11 and action ~= 12 then return false, false end
  local allowed = M.publicationAllowed(c.battleTypeFlags)
  if not allowed then r._rsFinishSnapshot = true; return true, false end
  local count = integer(c.battlersCount, "finish battlersCount", 2, 4)
  assert(count == 2 or count == 4, "RS BattleResults native battler count must be2 or4")
  local rows = {}
  for id = 0, count - 1 do
    local b = assert(c.battlers and c.battlers[id], "RS BattleResults missing physical finish slot" .. id)
    if side(b.side) == 0 then
      rows[#rows + 1] = {species = u16(b.species, "finish working species"),
        bytes = nickname(b.nicknameBytes), text = b.nicknameText}
    end
  end
  for _, row in ipairs(rows) do
    if r.playerMon1Species == 0 then
      r.playerMon1Species = row.species; copyName(r, "playerMon1NameBytes", row.bytes)
      r.playerMon1Name = row.text
    else
      r.opponentSpecies = row.species; copyName(r, "opponentNameBytes", row.bytes)
      r.opponentName = row.text
    end
  end
  r._rsFinishSnapshot = true
  return true, true
end

-- battle_tower.c:1385
function M.towerSnapshot(c)
  local player = assert(c.battlers and c.battlers[0], "RS Tower missing physical player slot0")
  local enemy = assert(c.battlers and c.battlers[1], "RS Tower missing physical enemy slot1")
  local bytes = {}
  assert(type(player.nicknameBytes) == "table", "RS Tower requires native nickname bytes")
  for i = 1, 10 do bytes[i] = u8(player.nicknameBytes[i], "Tower nickname byte" .. i) end
  return {trainerName = c.trainerName, playerSpecies = u16(player.species, "Tower working slot0 species"),
    opponentSpecies = u16(enemy.species, "Tower working slot1 species"),
    playerNickname = player.nicknameText, playerNicknameBytes = bytes}
end

function M.flagsForState(st)
  if st.nativeBattleTypeFlags ~= nil then return st.nativeBattleTypeFlags end
  local k, flags = st.kinds or {}, 0
  local present = {
    link = st.link or k.link, firstBattle = st.firstBattle or k.firstBattle,
    safari = st.safari or k.safari, battleTower = st.battleTower or k.battleTower,
    wallyTutorial = k.tutorial == "wally", ereaderTrainer = st.eReader,
  }
  for key, mask in pairs(M.EXCLUDED_FLAGS) do if present[key] then flags = flags + mask end end
  return flags
end

function M.captureFinishState(st, outcome)
  local r = result(st.battleResults)
  if r._rsFinishSnapshot then return false end
  local flags = M.flagsForState(st)
  local rows, count = {}, st.battlersCount or (st.double and 4 or 2)
  if M.publicationAllowed(flags) then
    local State = require("src.core.game3.battle.state")
    local Pokemon = require("src.core.game3.pokemon")
    local Q = require("src.core.game3.rs.tv_queries")
    for id = 0, count - 1 do
      local b, which = State.battler(st, id), State.sideOf(id)
      local row = {side = which == "player" and 0 or 1}
      if which == "player" then
        if not b or not b.mon then st.rsResultsMissingSlot = id; return false end
        row.species = Pokemon.speciesOf(b.mon)
        row.nicknameBytes = Q.nicknameBytes(st.session, b.mon)
        row.nicknameText = Pokemon.displayMonName(b.mon)
      end
      rows[id] = row
    end
  end
  local committed = M.finishSnapshot(r, {actionId = outcome == "win" and 11 or 12,
    battleTypeFlags = flags, battlersCount = count, battlers = rows})
  return committed
end

return M
