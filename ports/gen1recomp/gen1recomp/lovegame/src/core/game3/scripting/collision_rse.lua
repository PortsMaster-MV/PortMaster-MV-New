local MB = require("src.core.game3.mb")
local Frlg = require("src.core.game3.scripting.collision_frlg")

local Collision = {}

-- pokeemerald/src/metatile_behavior.c:6
Collision.TILE_FLAG_SURFABLE = 2

Collision._tileBits = nil

function Collision.setTileBits(bits)
  Collision._tileBits = type(bits) == "table" and bits or nil
end

local function set(list)
  local out = {}
  for _, name in ipairs(list) do out[MB.require(name)] = true end
  return out
end

-- pokeemerald/src/metatile_behavior.c:721
local WALK_ON_WATER = set({ "PUDDLE", "SHALLOW_WATER" })
-- pokeemerald/src/metatile_behavior.c:175
local GRASS = set({ "TALL_GRASS", "LONG_GRASS" })
-- pokeemerald/src/metatile_behavior.c:183
local SAND = set({ "SAND", "DEEP_SAND" })
local JUMP_DIR = {
  [MB.require("JUMP_EAST")] = "E",
  [MB.require("JUMP_WEST")] = "W",
  [MB.require("JUMP_NORTH")] = "N",
  [MB.require("JUMP_SOUTH")] = "S",
}
-- pokeemerald/src/field_control_avatar.c:751
local DOOR = set({
  "ANIMATED_DOOR", "NON_ANIMATED_DOOR", "WATER_DOOR", "DEEP_SOUTH_WARP", "AQUA_HIDEOUT_WARP",
  "EAST_ARROW_WARP", "WEST_ARROW_WARP", "NORTH_ARROW_WARP", "SOUTH_ARROW_WARP",
  "WATER_SOUTH_ARROW_WARP", "SHOAL_CAVE_ENTRANCE", "STAIRS_OUTSIDE_ABANDONED_SHIP",
})
-- pokeemerald/src/field_control_avatar.c:512
local KEEP_FACING_WARP = set({
  "CRACKED_FLOOR_HOLE", "LAVARIDGE_GYM_B1F_WARP", "LAVARIDGE_GYM_1F_WARP", "MOSSDEEP_GYM_WARP",
  "MT_PYRE_HOLE", "BATTLE_PYRAMID_WARP",
})
local WARP_STAIR = set({ "LADDER", "UP_ESCALATOR", "DOWN_ESCALATOR" })
local PC = MB.require("PC")
local COUNTER = MB.require("COUNTER")
local CAVE = MB.require("CAVE")
local MOUNTAIN_TOP = MB.require("MOUNTAIN_TOP")

local function surfable(beh)
  local bits = Collision._tileBits and Collision._tileBits[beh]
  return bits ~= nil and math.floor(bits / Collision.TILE_FLAG_SURFABLE) % 2 == 1
end

function Collision.classify(_, mapColl, behavior, kind)
  kind = kind or "route"
  local beh = behavior or 0
  local blocked = (mapColl or 0) ~= 0
  if surfable(beh) then
    if blocked then return "BLOCKED", nil end
    return "WATER", nil
  end
  if WALK_ON_WATER[beh] then
    if blocked then return "BLOCKED", nil end
    return "PATH", nil
  end
  if GRASS[beh] then return "TALL_GRASS", nil end
  if SAND[beh] then return "SAND", nil end
  if JUMP_DIR[beh] then return "LEDGE", JUMP_DIR[beh] end
  if WARP_STAIR[beh] then return "STAIR", "WARP" end
  if DOOR[beh] then return "DOOR", nil end
  if KEEP_FACING_WARP[beh] then return "WARP_KEEP_FACING", nil end
  if beh == PC then return "PC", nil end
  if beh == COUNTER then return "COUNTER", nil end
  if beh == CAVE then return "CAVE", nil end
  if beh == MOUNTAIN_TOP then return "ROCK_DECK", nil end
  if blocked then return "BLOCKED", nil end
  if kind == "town" then return "TOWN_PATH", nil end
  return "SHORT_GRASS", nil
end

Collision.seed = Frlg.seed

function Collision.fromCell(mid, mapColl, behavior, kind)
  local cat, ledge = Collision.classify(mid, mapColl, behavior, kind)
  return Collision.seed(cat, ledge, kind), cat, ledge
end

return Collision
