local Pokemon = require("src.core.game3.pokemon")
local State = require("src.core.game3.battle.state")
local H = require("src.core.game3.battle.effects._helpers")

local Policy = {}
local SOUNDPROOF = 43

local function species2(mon)
  if type(mon) ~= "table" then return 0 end
  local species = Pokemon.speciesOf(mon) or 0
  if species ~= 0 and (mon.isEgg or mon.egg or mon.isBadEgg or mon.badEgg) then
    return Pokemon.SPECIES_EGG
  end
  return species
end

-- pokeruby/src/pokemon_2.c:1056
function Policy.benchAbility(mon, species)
  species = species or species2(mon)
  local pair = Pokemon.abilities(species)
  local flag = mon.abilityNum
  if flag == nil then flag = mon.altAbility end
  if flag == nil then
    -- pokemon_1.c:1465
    flag = (pair[2] or 0) ~= 0 and (tonumber(mon.personality) or 0) % 2 or 0
  end
  local alternate = flag == true or (tonumber(flag) or 0) ~= 0
  return pair[alternate and 2 or 1] or 0
end

-- pokeruby/src/battle_script_commands.c:8073
function Policy.plan(ad, user, isBell)
  local st = ad._st
  local partner = st.double and ad:partnerOf(user) or nil
  local blocked = isBell and ad:abilityOf(user) == "SOUNDPROOF" or false
  local partnerBlocked = partner and isBell and ad:abilityOf(partner) == "SOUNDPROOF" or false
  local result = { mask = isBell and 0 or 0x3F, chooser = isBell and 0 or 4,
    partner = partner, blocked = blocked, partnerBlocked = partnerBlocked,
    abilityRecords = {} }
  if blocked then
    result.chooser = result.chooser + 1
    result.abilityRecords[#result.abilityRecords + 1] = State.idOf(user)
  end
  if partnerBlocked then
    result.chooser = result.chooser + 2
    result.abilityRecords[#result.abilityRecords + 1] = State.idOf(partner)
  end
  if isBell then
    local party = ad:partyMons(user)
    for i = 1, 6 do
      local mon = party[i]
      local species = species2(mon)
      if species ~= 0 and species ~= Pokemon.SPECIES_EGG then
        local ability
        if i == user.partyIndex then
          ability = ad:abilityOf(user) == "SOUNDPROOF" and SOUNDPROOF or 0
        elseif partner and i == partner.partyIndex then
          ability = ad:abilityOf(partner) == "SOUNDPROOF" and SOUNDPROOF or 0
        else
          ability = Policy.benchAbility(mon, species)
        end
        if ability ~= SOUNDPROOF then result.mask = result.mask + 2 ^ (i - 1) end
      end
    end
  end
  return result
end

local function clearBattleStatus1(b)
  b.status = 0
  b.sleepTurns = nil
  b.toxicCounter = nil
end

local function retainBattleStatus(ad, b)
  if b.status == nil then b.status = ad:status(b) or 0 end
  if b.status == "SLP" and b.sleepTurns == nil then
    b.sleepTurns = b.mon and b.mon.sleep
  end
end

function Policy.healBell(ctx, isBell)
  local ad, user = ctx.adapter, ctx.user
  local result = Policy.plan(ad, user, isBell)
  if result.blocked then retainBattleStatus(ad, user) else clearBattleStatus1(user) end
  if result.partner then
    if result.partnerBlocked then retainBattleStatus(ad, result.partner)
    else clearBattleStatus1(result.partner) end
  end

  for _, id in ipairs(result.abilityRecords) do
    ad:pushEvent({ kind = "ability_record", battler = id, ability = SOUNDPROOF })
  end
  -- battle_controllers.c:615
  local request = { kind = "controller_set_mon_data", battler = State.idOf(user),
    side = user.side, bufferId = 0, command = 2, requestId = 40,
    request = "REQUEST_STATUS_BATTLE", mask = result.mask, numBytes = 4,
    data = { 0, 0, 0, 0 }, markedForExec = true }
  result.request = request
  ad._st._rsPartyStatusHeal = result
  ad:pushEvent(request)
  local party = ad:partyMons(user)
  for i = 1, 6 do
    local selected = result.mask == 0 and i == user.partyIndex
      or result.mask ~= 0 and math.floor(result.mask / 2 ^ (i - 1)) % 2 == 1
    local mon = party[i]
    if selected and mon then
      mon.status = nil
      mon.sleep = nil
    end
  end

  H.attackAnim(ctx)
  if isBell then
    ad:sayText("STRINGID_BELLCHIMED")
    if result.blocked then
      ad:sayText("STRINGID_PKMNSXBLOCKSY", { def = user, defAbility = SOUNDPROOF, currentMove = 215 })
    end
    if result.partnerBlocked then
      ad:sayText("STRINGID_PKMNSXBLOCKSY2", { scrActive = result.partner,
        scrActiveAbility = SOUNDPROOF, currentMove = 215 })
    end
  else
    ad:sayText("STRINGID_SOOTHINGAROMA")
  end
  return result
end

return Policy
