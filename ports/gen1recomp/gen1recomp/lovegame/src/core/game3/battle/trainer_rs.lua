local M = {}

-- pokeruby/src/battle_main.c:1047
function M.personalities(t, game)
  local Pokemon = require("src.core.game3.pokemon")
  local codec = require("src.save_convert.Gen3Save").forVersion(game)
  local function sum(text)
    local raw = codec.encodeString(text, 32, 255)
    local n = 0
    for i = 1, #raw do
      local b = raw:byte(i)
      if b == 255 then break end
      n = n + b
    end
    return n
  end
  local hash, out = 0, {}
  local base = t.doubleBattle and 0x80 or (tonumber(t.gender) == 1 and 0x78 or 0x88)
  for i, mon in ipairs(t.party or {}) do
    hash = (hash + sum(t.name) + sum(Pokemon.name(mon.species))) % 0x100000000
    out[i] = (base + hash * 256) % 0x100000000
  end
  return out
end

function M.prepareMon(foe)
  local Pokemon = require("src.core.game3.pokemon")
  local Rng = require("src.core.game3.rng")
  local out = {}
  for k, v in pairs(foe) do out[k] = v end
  local id
  repeat
    id = Rng.Random32()
    out.otId, out.otSecretId = id % 65536, math.floor(id / 65536)
  until not Pokemon.isShiny({personality = out.personality, otId = out.otId, otSecretId = out.otSecretId})
  out.item = tonumber(foe.heldItem) or tonumber(foe.item) or 0
  return out
end

-- pokeruby/src/pokemon_3.c:662
function M.isLeagueTrainerClass(class)
  class = tonumber(class)
  return class == 24 or class == 25 or class == 32
end

function M.adjustLeagueFriendshipMon(mon, ctx)
  return require("src.core.game3.battle.friendship_rs").applyLeague(mon, ctx)
end

return M
