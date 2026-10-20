local MonAnimData = {}

MonAnimData.FRONT = "data/generated/gba/pokemon/front_anims.lua"
MonAnimData.BACK = "data/generated/gba/pokemon/back_anims.lua"
MonAnimData.SHEET = "data/generated/gba/pokemon/front_anim/%d.rgba"
MonAnimData.SHEET_SHINY = "data/generated/gba/pokemon/front_anim_shiny/%d.rgba"

-- pokeemerald/src/pokemon.c:1864
MonAnimData.PP_UP_GET_MASK_0 = 0x03

local packs = {}

local function versionKey()
  local GameVersion = require("src.core.GameVersion")
  return tostring(GameVersion.get()) .. ":" .. tostring(GameVersion.cachePrefix())
end

function MonAnimData.useCache(cache)
  MonAnimData._cache = cache
  packs = {}
end

function MonAnimData.cache()
  if MonAnimData._cache then return MonAnimData._cache end
  local ok, cache = pcall(function() return require("src.core.game3.dataset").cache() end)
  return ok and cache or nil
end

local function read(rel)
  local cache = MonAnimData.cache()
  local ok = cache ~= nil
  if not ok or not cache or not cache.read then return nil end
  local src = cache:read(rel)
  if type(src) ~= "string" or src == "" then return nil end
  return src
end

local function loadLua(rel)
  local src = read(rel)
  if not src then return nil end
  local chunk, err = load(src, "@" .. rel, "t", {})
  if not chunk then error("mon_anim_data: " .. tostring(err)) end
  return chunk()
end

function MonAnimData.get()
  local key = versionKey()
  local hit = packs[key]
  if hit ~= nil then return hit or nil end
  local front = loadLua(MonAnimData.FRONT)
  local back = front and loadLua(MonAnimData.BACK)
  if not (front and back) then
    packs[key] = false
    return nil
  end
  local byName = {}
  for id, name in pairs(front.functions or {}) do byName[name] = id end
  hit = { front = front, back = back, fnIds = byName }
  packs[key] = hit
  return hit
end

function MonAnimData.reset()
  packs = {}
end

function MonAnimData.available()
  return MonAnimData.get() ~= nil
end

function MonAnimData.functionName(id)
  local d = MonAnimData.get()
  return d and d.front.functions[id] or nil
end

function MonAnimData.functionCount()
  local d = MonAnimData.get()
  if not d then return 0 end
  local n = 0
  for _ in pairs(d.front.functions) do n = n + 1 end
  return n
end

function MonAnimData.anims(species)
  local d = MonAnimData.get()
  if not d then return nil end
  local row = d.front.species[tonumber(species) or 0] or d.front.species[0]
  local out = {}
  for i, id in ipairs(row) do
    local l = d.front.lists[id]
    out[i - 1] = l and l.cmds or nil
  end
  return out
end

-- pokeemerald/src/pokemon.c:6852
function MonAnimData.frontAnimId(species)
  local d = MonAnimData.get()
  if not d then return nil end
  local ids = d.front.animIds
  local i = tonumber(species) or 0
  if ids[i] ~= nil then return ids[i] end
  return d.front.animDelays[i - #ids]
end

-- pokeemerald/src/pokemon.c:6841
function MonAnimData.delay(species)
  local d = MonAnimData.get()
  if not d then return 0 end
  local t = d.front.animDelays
  local i = tonumber(species) or 0
  if t[i] ~= nil then return t[i] end
  if i == #t + 1 then return MonAnimData.PP_UP_GET_MASK_0 end
  return 0
end

-- pokeemerald/src/pokemon_animation.c:885
function MonAnimData.backAnimSet(species)
  local d = MonAnimData.get()
  if not d then return 0 end
  local v = d.back.sets[tonumber(species) or 0] or 0
  if v ~= 0 then return v - 1 end
  return 0
end

-- pokeemerald/src/pokemon_animation.c:968
function MonAnimData.backAnimId(backAnimSet, nature)
  local d = MonAnimData.get()
  if not d then return nil end
  local mod = d.back.natureMods[tonumber(nature) or 0] or 0
  return d.back.ids[3 * backAnimSet + mod]
end

return MonAnimData
