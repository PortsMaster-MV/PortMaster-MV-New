local State = require("src.core.game3.battle.state")

local Policy = {}

local function roles(ad)
  ad._rsFaintRoles = ad._rsFaintRoles or {}
  return ad._rsFaintRoles
end

function Policy.setScriptBattlers(ad, attacker, target)
  local r = roles(ad)
  r.attacker, r.target = State.idOf(attacker), State.idOf(target)
  r.stage, r.phase = "script", nil
end

local function firstPresent(st)
  for id = 0, (st.double and 3 or 1) do
    if State.isPresent(st, id) then return id end
  end
end

-- pokeruby/src/battle_main.c:4072
function Policy.prepareStep(ad, battler, phase)
  local r, st = roles(ad), ad._st
  if battler then
    r.target = firstPresent(st)
    r.stage, r.attacker = "battler", State.idOf(battler)
    if phase == "leech_seed" and battler.expSeeded then
      local src = battler.expSeedSource
      if src and st.double then
        src = State.isPresent(st, src.id) and State.battler(st, src.id) or nil
      elseif src and src.side then
        src = st[src.side]
      end
      if src and not ad:isFainted(src) and not ad:isFainted(battler) then
        r.target = State.idOf(src)
      end
    end
  elseif phase == "fainted_actions" then
    r.stage, r.target = "post", st.double and 3 or 1
  elseif phase == "perish_song" then
    r.stage, r.target = "post", st.double and 3 or 1
  elseif phase == "future_sight" then
    r.stage = "post"
  else
    local first = firstPresent(st)
    r.stage, r.attacker, r.target = "field", first, first
  end
  r.phase = phase
end

local function snapshot(ad, battler, script)
  local r = script or roles(ad)
  local attacker, target = State.idOf(r.attacker), State.idOf(r.target)
  local id = State.idOf(battler)
  local other
  if r.selector ~= nil then
    local active = r.selector == 1 and attacker or target
    if active ~= id then return nil end
    other = r.selector == 1 and target or attacker
  elseif id == attacker then
    other = target
  elseif id == target then
    other = attacker
  else
    return nil
  end
  local b = State.battler(ad._st, other)
  if not b or not b.mon or not battler.mon then return nil end
  return { other = other, faintedLevel = tonumber(battler.mon.level) or 0,
    otherLevel = tonumber(b.mon.level) or 0 }
end

function Policy.capture(ad, battler)
  local r = roles(ad)
  if r.phase == "weather_continue" or r.phase == "perish_song" then
    r.attacker = State.idOf(battler)
  end
  ad._rsFaintPending = ad._rsFaintPending or {}
  ad._rsFaintPending[battler] = snapshot(ad, battler)
end

-- pokeruby/src/battle_script_commands.c:3063
function Policy.apply(ad, battler, script)
  local pending = ad._rsFaintPending
  local c
  if script then
    c = snapshot(ad, battler, script)
  else
    c = pending and pending[battler] or snapshot(ad, battler)
  end
  if pending then pending[battler] = nil end
  if not State.isPresent(ad._st, State.idOf(battler)) then return false end
  if not c then
    battler._rsFaintContextMissing = true
    return false
  end
  battler._rsFaintContext = c
  if c.otherLevel <= c.faintedLevel then return false end
  local Pokemon = require("src.core.game3.pokemon")
  local event = c.otherLevel - c.faintedLevel > 29
    and Pokemon.FRIENDSHIP_EVENT_FAINT_LARGE or Pokemon.FRIENDSHIP_EVENT_FAINT_SMALL
  return Pokemon.adjustFriendship(battler.mon, event,
    { mapSec = Pokemon.currentMapSec(ad._st.session) })
end

return Policy
