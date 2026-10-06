local SongFields = require("src.core.game3.song_fields")

local Songs = {}

Songs.ALIASES = {
  rse = {
    -- pokeemerald/src/berry_crush.c:2313
    MUS_GAME_CORNER = "MUS_RG_GAME_CORNER",
    -- pokeemerald/src/pokemon_jump.c:708
    MUS_POKE_JUMP = "MUS_RG_POKE_JUMP",
    -- pokeemerald/src/dodrio_berry_picking.c:680
    MUS_BERRY_PICK = "MUS_RG_BERRY_PICK",
    -- pokeemerald/src/dodrio_berry_picking.c:1083
    MUS_VICTORY_WILD = "MUS_RG_VICTORY_WILD",
  },
}

local function family()
  local ok, fam = pcall(function() return require("src.core.game3.profile").family() end)
  return ok and fam or "frlg"
end

function Songs.resolve(name)
  local Song = require("src.core.game3.song_ids")
  local alias = Songs.ALIASES[family()]
  alias = alias and alias[name]
  if alias and Song[alias] ~= nil then return Song[alias] end
  return Song[name]
end

function Songs.fields(t)
  SongFields(t)
  local mt = getmetatable(t)
  local prev = mt.__index
  mt.__index = function(self, k)
    if type(k) == "string" and k:find("^MUS_") then
      local v = Songs.resolve(k)
      if v ~= nil then return v end
    end
    if type(prev) == "function" then return prev(self, k) end
    if type(prev) == "table" then return prev[k] end
    return nil
  end
  return t
end

return Songs
