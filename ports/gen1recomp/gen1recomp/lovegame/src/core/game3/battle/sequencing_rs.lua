local State = require("src.core.game3.battle.state")
local Policy = {}

function Policy.prepareSwitch(ad, battler, kind)
  local r = ad._rsFaintRoles or {}
  ad._rsFaintRoles = r
  local id, selector = State.idOf(battler), 3
  if kind == "roar" then
    r.target, selector = id, 0
  elseif kind == "switch" or kind == "baton_pass" or kind == "shift_player" then
    r.attacker, selector = id, 1
  end
  r.stage, r.phase = "script", nil
  ad._rsSwitchSelectors = ad._rsSwitchSelectors or {}
  ad._rsSwitchSelectors[id] = selector
end

function Policy.spikesFaint(ad, battler)
  local r = ad._rsFaintRoles or {}
  local selectors = ad._rsSwitchSelectors or {}
  local selector = selectors[State.idOf(battler)]
  if selector == nil then return false end
  local id = selector == 1 and r.attacker or r.target
  local victim = id ~= nil and State.battler(ad._st, id) or nil
  if not victim or not State.isPresent(ad._st, id) or not ad:isFainted(victim)
      or victim._faintAnnounced then return false end
  local script = {attacker = r.attacker, target = r.target, selector = selector}
  victim._faintAnnounced = true
  if ad.prepareFaintAnnouncement then ad:prepareFaintAnnouncement(victim, script) end
  ad:pushEvent({kind = "faint", side = victim.side, battler = id})
  if selector == 1 then
    ad:sayText("STRINGID_ATTACKERFAINTED", {atk = victim})
  else
    ad:sayText("STRINGID_TARGETFAINTED", {def = victim})
  end
  ad:emitFaint(victim, script)
  return true
end

function Policy.residualOrder(ad, battler, phase, active)
  if phase ~= "leech_seed" or not battler then return active end
  local r = ad._rsFaintRoles or {}
  local out, seen = {}, {}
  local function add(b)
    if b and not seen[b] then out[#out + 1], seen[b] = b, true end
  end
  add(battler)
  if r.target ~= nil then add(State.battler(ad._st, r.target)) end
  for _, b in ipairs(active) do add(b) end
  return out
end

return Policy
