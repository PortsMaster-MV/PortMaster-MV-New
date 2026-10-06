local E = require("src.core.game3.battle.effect_ids")
local Secondary = require("src.core.game3.battle.effects.secondary")
local Policy = {}

local hit = {}
for _, id in ipairs({0,2,4,5,6,12,14,15,17,21,22,27,31,34,36,38,39,40,41,42,43,45,48,
  55,56,61,63,64,68,69,70,71,72,73,74,75,76,78,80,81,87,88,89,92,96,99,101,103,105,
  110,117,119,121,122,123,125,128,129,130,131,135,138,139,140,141,144,145,146,149,150,
  151,152,155,158,159,161,163,169,170,171,182,185,188,189,190,196,197,198,200,202,203,
  204,207,209}) do hit[id] = true end

function Policy.kind(M)
  local id = M.effect
  if id == E.MULTI_HIT or id == E.DOUBLE_HIT or id == E.TWINEEDLE then return "multiHitEnd" end
  if id == E.TRIPLE_KICK then return "tripleKickEnd" end
  if id == E.BRICK_BREAK then return "brickBreak" end
  if hit[id] then return "hit" end
end

local effect = {
  [2]={2,"POISON"}, [4]={3,"BURN"}, [5]={4,"FREEZE"}, [6]={5,"PARALYSIS"},
  [31]={8,"FLINCH"}, [34]={11,"PAYDAY"}, [36]={9,"TRI_ATTACK"}, [42]={13,"WRAP"},
  [48]={0xCE,"RECOIL_25"}, [68]={22,"ATK_MINUS_1"}, [69]={23,"DEF_MINUS_1"},
  [70]={24,"SPD_MINUS_1"}, [71]={25,"SP_ATK_MINUS_1"}, [72]={26,"SP_DEF_MINUS_1"},
  [73]={27,"ACC_MINUS_1"}, [75]={8,"FLINCH"}, [76]={7,"CONFUSION"}, [77]={2,"POISON"},
  [80]={0xDD,"RECHARGE"}, [92]={8,"FLINCH"}, [105]={31,"STEAL_ITEM"}, [125]={3,"BURN"},
  [129]={0xA3,"RAPIDSPIN"}, -- native target guards, despite modifying user's hazards
  [138]={0x50,"DEF_PLUS_1"}, [139]={0x4F,"ATK_PLUS_1"}, [140]={0x62,"ALL_STATS_UP"},
  [146]={8,"FLINCH"}, [150]={8,"FLINCH"}, [152]={5,"PARALYSIS"},
  [158]={0x88,"FLINCH"}, [159]={0x4A,"UPROAR"}, [182]={0xE5,"ATK_DEF_DOWN"},
  [188]={54,"KNOCK_OFF"}, [198]={0xE6,"RECOIL_33"}, [200]={3,"BURN"},
  [202]={6,"TOXIC"}, [204]={0xFB,"SP_ATK_TWO_DOWN"}, [209]={2,"POISON"},
}
local terrain = {
  [0]={2,"POISON"}, [1]={1,"SLEEP"}, [2]={27,"ACC_MINUS_1"}, [3]={23,"DEF_MINUS_1"},
  [4]={22,"ATK_MINUS_1"}, [5]={24,"SPD_MINUS_1"}, [6]={7,"CONFUSION"}, [7]={8,"FLINCH"},
}

function Policy.prepare(M)
  local site = Policy.kind(M)
  if not site then return nil end
  local spec = effect[M.effect]
  if M.effect == E.SMELLINGSALT then
    spec = (M.target.substituteHP or 0) <= 0 and {0xA4,"REMOVE_PARALYSIS"} or nil
  elseif M.effect == E.RAMPAGE then
    spec = M.startRampage and {0x75,"THRASH"} or nil
  elseif M.effect == E.SEMI_INVULNERABLE and M.mnum == 340 then
    spec = {5,"PARALYSIS"} -- Bounce's attacking turn only; charge returns earlier
  elseif M.effect == E.SECRET_POWER then
    spec = terrain[require("src.core.game3.battle.engine").terrainOf(M.st)] or {5,"PARALYSIS"}
  end
  return {site = site, raw = spec and spec[1] or 0, effect = spec and spec[2]}
end

-- pokeruby/battle_script_commands.c:2978
function Policy.finish(M, descriptor, noEffect)
  if not descriptor then return false end
  if descriptor.consumed then return true end
  descriptor.consumed = true
  if noEffect == nil then noEffect = M.noEffect end
  local raw, ad = descriptor.raw, M.adapter
  local chance = tonumber(M.move.secondaryChance) or 0
  if ad:abilityOf(M.user) == "SERENE_GRACE" then chance = chance * 2 end
  local certain = raw >= 0x80
  local affectsUser = raw % 0x80 >= 0x40
  if certain and not noEffect then
    Secondary.set(M, descriptor.effect, false, true, affectsUser)
  else
    local roll = ad:roll(0, 99)
    if roll <= chance and raw ~= 0 and not noEffect then
      Secondary.set(M, descriptor.effect, false, chance >= 100, affectsUser)
    end
  end
  descriptor.raw = 0
  return true
end

return Policy
