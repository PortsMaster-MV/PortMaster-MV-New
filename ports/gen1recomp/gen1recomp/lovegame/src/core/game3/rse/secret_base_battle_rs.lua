local Rse = require("src.core.game3.rse.init")
local M = {MANIFEST = "data/generated/gba/rse/secret_base_battle/manifest.lua"}
local work = setmetatable({}, {__mode = "k"})
local cached, cachedSource
local function copy(v)
  if type(v) ~= "table" then return v end
  local out = {}; for k, x in pairs(v) do out[k] = copy(x) end; return out
end
function M.reset() work = setmetatable({}, {__mode = "k"}); cached, cachedSource = nil, nil end
function M.pack()
  local source = assert(require("src.core.game3.dataset").cache():read(M.MANIFEST), "native RS secret-base battle pack missing")
  if source ~= cachedSource then
    local fn = assert((loadstring or load)(source, "@" .. M.MANIFEST))
    if setfenv then setfenv(fn, {}) end
    cached, cachedSource = fn(), source
  end
  return cached
end
local function base(s)
  return assert(require("src.core.game3.rse.secret_base").base(s, Rse.var("VAR_CURRENT_SECRET_BASE", s)), "RS current secret-base index outside0..19")
end
function M.ownerType(b)
  return (tonumber((b.trainerId or {})[1]) or 0) % 5 + (tonumber(b.gender) or 0) * 5
end
function M.ownerAndState(s)
  local SB = require("src.core.game3.rse.secret_base")
  if not Rse.flag("FLAG_DAILY_UNKNOWN_8C2", s) then
    for _, b in ipairs(SB.bases(s)) do b.battledOwnerToday = 0 end
    Rse.setFlag("FLAG_DAILY_UNKNOWN_8C2", true, s)
  end
  local b = base(s); return M.ownerType(b), tonumber(b.battledOwnerToday) or 0
end
function M.setBattledOwner(s, value)
  base(s).battledOwnerToday = math.floor(tonumber(value) or 0) % 2
end

function M.prepare(s)
  require("src.core.game3.rse.fan_club_rs").activity(s, 1)
  local b, party, slots = copy(base(s)), {}, {}
  local D = require("src.core.game3.rse.frontier.trainers")
  local Pokemon = require("src.core.game3.pokemon")
  local Rng = require("src.core.game3.rng")
  for i = 1, 6 do
    local species = tonumber((b.party.species or {})[i]) or 0
    if species ~= 0 then
      local pid = tonumber((b.party.personality or {})[i]) or 0
      local otId; repeat otId = Rng.Random32() until not D.isShiny(otId, pid)
      local mon = D.createMon(species, b.party.levels[i], 15, pid, otId,
        {otName = s.name, otGender = (s.gender == 1 or s.gender == "female" or s.gender == "F") and 1 or 0})
      D.setHeldItem(mon, tonumber((b.party.heldItems or {})[i]) or 0)
      local ev = tonumber((b.party.EVs or {})[i]) or 0
      mon.evs = {hp = ev, atk = ev, def = ev, spe = ev, spa = ev, spd = ev}
      mon.moves, mon.pp, mon.maxPp = {}, {}, {}
      for j = 1, 4 do
        local move = tonumber((b.party.moves or {})[(i - 1) * 4 + j]) or 0
        mon.moves[j] = move
        mon.pp[j] = move == 0 and 0 or Pokemon.movePp(move)
        mon.maxPp[j] = mon.pp[j]
      end
      slots[i], party[#party + 1] = mon, mon
    end
  end
  work[s] = {base = b, party = party, nativeSlots = slots}
  s.trainerBattleOpponentA, s.battleTypeFlags = 0x400, 8
  return work[s]
end
function M.prepared(s) return work[s] end
function M.snapshotHeldItems(s)
  local held = {}
  for i = 1, 6 do
    local mon = (s.party or {})[i]
    held[i] = mon and (tonumber(mon.item or mon.heldItem) or 0) or 0
    local saved = s.savedPlayerParty and s.savedPlayerParty[i]
    if saved then saved.item, saved.heldItem = held[i], held[i] end
  end
  return held
end
function M.restoreHeldItems(s, held)
  for i = 1, 6 do
    local mon = (s.party or {})[i]
    if mon then
      local item = held[i] ~= 0 and held[i] or nil
      mon.item, mon.heldItem = item, item
    end
  end
end
function M.start(ctx, adapters, s)
  local N = require("src.core.game3.scripting.natives")
  local prepared = work[s]
  if not prepared or not prepared.party[1] then
    return require("src.core.game3.rse.frontier.util").saveFromNative(ctx, adapters, s,
      function() return false, "The secret-base opponent has not been prepared." end)
  end
  local pack, Pokemon = M.pack(), require("src.core.game3.pokemon")
  local owner = M.ownerType(prepared.base)
  local info, lead = assert(pack.classes[owner]), prepared.party[1]
  local foe = {party = prepared.party, trainerId = 0x400, trainerName = prepared.base.trainerName,
    trainerClass = info.nameId, trainerClassName = info.name, trainerPicId = info.pic,
    defeatText = pack.loseText[owner], species = lead.species, level = lead.level, moves = lead.moves, pp = lead.pp}
  local held, playerLevel = M.snapshotHeldItems(s), 0
  for _, mon in ipairs(s.party or {}) do
    if Pokemon.speciesOf(mon) and not Pokemon.isEgg(mon) and (tonumber(mon.hp) or 0) ~= 0 then playerLevel = tonumber(mon.level) or 0; break end
  end
  local BP = require("src.core.game3.battle.profile")
  local opts = {wild = false, secretBase = true, specialBattleKind = 1, scriptedLoss = true,
    aiFlags = pack.aiFlags, trainerItems = {0, 0, 0, 0}, song = BP.battleSong(BP.get(s), {trainerClass = info.nameId}),
    transitionId = require("src.core.game3.battle_transition_ids_rse").pickSpecial("battle_tower", {enemyLevel = lead.level, playerLevel = playerLevel})}
  s.battleOutcome = 0
  return N.yieldHost(ctx, adapters, function(done)
    opts.done = function(outcome)
      M.restoreHeldItems(s, held)
      local code = N.outcome_to_code(outcome)
      ctx.lastBattleOutcome, s.battleOutcome = code, code
      done()
    end
    local Runtime = require("src.core.game3.runtime")
    local ok, err = require("src.core.game3.battle_bridge").start(Runtime._mod, Runtime._game, foe, opts)
    if not ok then
      M.restoreHeldItems(s, held); ctx.pc, ctx.stack = nil, {}
      if adapters and adapters.log then adapters.log("[game3/rs-secret-base] battle start failed: " .. tostring(err)) end
      done()
    end
  end)
end
return M
