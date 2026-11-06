local M = {}

-- pokeemerald/include/fieldmap.h:4
local P = 512

local function part(frames, dst, tiles, extra)
  local p = { frames = frames, dst = dst, tiles = tiles }
  for k, v in pairs(extra or {}) do p[k] = v end
  return p
end

local function one(name, period, phase, frames, dst, tiles)
  return { name = name, period = period, phase = phase, parts = { part(frames, dst, tiles) } }
end

local function slots(name, period, fn, build)
  local rows = {}
  for k = 0, period - 1 do
    rows[#rows + 1] = { name = name .. "_" .. k, period = period, phase = k, fn = fn, slot = k, parts = build(k) }
  end
  return rows
end

local function concat(...)
  local out = {}
  for _, list in ipairs({ ... }) do
    for _, row in ipairs(list) do out[#out + 1] = row end
  end
  return out
end

-- pokeemerald/src/tileset_anims.c:618
M.INITS = {
  InitTilesetAnim_General = { counter = "primary", max = 256, anims = {
    one("general_flower", 16, 0, "gTilesetAnims_General_Flower", 508, 4),
    one("general_water", 16, 1, "gTilesetAnims_General_Water", 432, 30),
    one("general_sand_water_edge", 16, 2, "gTilesetAnims_General_SandWaterEdge", 464, 10),
    one("general_waterfall", 16, 3, "gTilesetAnims_General_Waterfall", 496, 6),
    one("general_land_water_edge", 16, 4, "gTilesetAnims_General_LandWaterEdge", 480, 10),
  } },
  -- pokeemerald/src/tileset_anims.c:625
  InitTilesetAnim_Building = { counter = "primary", max = 256, anims = {
    one("building_tv_turned_on", 8, 0, "gTilesetAnims_Building_TvTurnedOn", 496, 4),
  } },
  -- pokeemerald/src/tileset_anims.c:676
  InitTilesetAnim_Petalburg = { counter = "secondary", max = "primary", anims = {} },
  -- pokeemerald/src/tileset_anims.c:837
  InitTilesetAnim_Rustboro = { counter = "secondary", max = "primary", anims = concat(
    slots("rustboro_windy_water", 8, "slot", function()
      return { part("gTilesetAnims_Rustboro_WindyWater", nil, 4,
        { dstTable = "gTilesetAnims_Rustboro_WindyWater_VDests" }) }
    end),
    { one("rustboro_fountain", 8, 0, "gTilesetAnims_Rustboro_Fountain", P + 448, 4) }
  ) },
  -- pokeemerald/src/tileset_anims.c:860
  InitTilesetAnim_Dewford = { counter = "secondary", max = "primary", anims = {
    one("dewford_flag", 8, 0, "gTilesetAnims_Dewford_Flag", P + 170, 6),
  } },
  -- pokeemerald/src/tileset_anims.c:866
  InitTilesetAnim_Slateport = { counter = "secondary", max = "primary", anims = {
    one("slateport_balloons", 16, 0, "gTilesetAnims_Slateport_Balloons", P + 224, 4),
  } },
  -- pokeemerald/src/tileset_anims.c:991
  InitTilesetAnim_Mauville = { counter = "secondary", max = "primary", start = "primary", anims =
    slots("mauville_flowers", 8, "mauville", function()
      return {
        part("gTilesetAnims_Mauville_Flower1", nil, 4,
          { framesB = "gTilesetAnims_Mauville_Flower1_B", dstTable = "gTilesetAnims_Mauville_Flower1_VDests" }),
        part("gTilesetAnims_Mauville_Flower2", nil, 4,
          { framesB = "gTilesetAnims_Mauville_Flower2_B", dstTable = "gTilesetAnims_Mauville_Flower2_VDests" }),
      }
    end) },
  -- pokeemerald/src/tileset_anims.c:964
  InitTilesetAnim_Lavaridge = { counter = "secondary", max = "primary", anims = {
    { name = "lavaridge_steam", period = 16, phase = 0, parts = {
      part("gTilesetAnims_Lavaridge_Steam", P + 288, 4),
      part("gTilesetAnims_Lavaridge_Steam", P + 292, 4, { offset = 2 }),
    } },
    one("lavaridge_lava", 16, 1, "gTilesetAnims_Lavaridge_Cave_Lava", P + 160, 4),
  } },
  -- pokeemerald/src/tileset_anims.c:718
  InitTilesetAnim_Fallarbor = { counter = "secondary", max = "primary", anims = {} },
  InitTilesetAnim_Fortree = { counter = "secondary", max = "primary", anims = {} },
  InitTilesetAnim_Lilycove = { counter = "secondary", max = "primary", anims = {} },
  InitTilesetAnim_Mossdeep = { counter = "secondary", max = "primary", anims = {} },
  -- pokeemerald/src/tileset_anims.c:1028
  InitTilesetAnim_EverGrande = { counter = "secondary", max = "primary", anims =
    slots("ever_grande_flowers", 8, "slot", function()
      return { part("gTilesetAnims_EverGrande_Flowers", nil, 4, { dstTable = "gTilesetAnims_EverGrande_VDests" }) }
    end) },
  -- pokeemerald/src/tileset_anims.c:920
  InitTilesetAnim_Pacifidlog = { counter = "secondary", max = "primary", start = "primary", anims = {
    one("pacifidlog_log_bridges", 16, 0, "gTilesetAnims_Pacifidlog_LogBridges", P + 464, 30),
    one("pacifidlog_water_currents", 16, 1, "gTilesetAnims_Pacifidlog_WaterCurrents", P + 496, 8),
  } },
  -- pokeemerald/src/tileset_anims.c:928
  InitTilesetAnim_Sootopolis = { counter = "secondary", max = "primary", anims = {
    one("sootopolis_stormy_water", 16, 0, "gTilesetAnims_Sootopolis_StormyWater", P + 240, 96),
  } },
  -- pokeemerald/src/tileset_anims.c:946
  InitTilesetAnim_BattleFrontierOutsideWest = { counter = "secondary", max = "primary", anims = {
    one("battle_frontier_outside_west_flag", 8, 0, "gTilesetAnims_BattleFrontierOutsideWest_Flag", P + 218, 6),
  } },
  InitTilesetAnim_BattleFrontierOutsideEast = { counter = "secondary", max = "primary", anims = {
    one("battle_frontier_outside_east_flag", 8, 0, "gTilesetAnims_BattleFrontierOutsideEast_Flag", P + 218, 6),
  } },
  -- pokeemerald/src/tileset_anims.c:781
  InitTilesetAnim_Underwater = { counter = "secondary", max = 128, anims = {
    one("underwater_seaweed", 16, 0, "gTilesetAnims_Underwater_Seaweed", P + 496, 4),
  } },
  -- pokeemerald/src/tileset_anims.c:1119
  InitTilesetAnim_SootopolisGym = { counter = "secondary", max = 240, anims = {
    { name = "sootopolis_gym_waterfalls", period = 8, phase = 0, count = "min", parts = {
      part("gTilesetAnims_SootopolisGym_SideWaterfall", P + 496, 12),
      part("gTilesetAnims_SootopolisGym_FrontWaterfall", P + 464, 20),
    } },
  } },
  -- pokeemerald/src/tileset_anims.c:940
  InitTilesetAnim_Cave = { counter = "secondary", max = "primary", anims = {
    one("cave_lava", 16, 1, "gTilesetAnims_Lavaridge_Cave_Lava", P + 416, 4),
  } },
  -- pokeemerald/src/tileset_anims.c:1078
  InitTilesetAnim_EliteFour = { counter = "secondary", max = 128, anims = {
    one("elite_four_ground_lights", 64, 1, "gTilesetAnims_EliteFour_FloorLight", P + 480, 4),
    one("elite_four_wall_lights", 8, 1, "gTilesetAnims_EliteFour_WallLights", P + 504, 1),
  } },
  -- pokeemerald/src/tileset_anims.c:1066
  InitTilesetAnim_MauvilleGym = { counter = "secondary", max = "primary", anims = {
    one("mauville_gym_electric_gates", 2, 0, "gTilesetAnims_MauvilleGym_ElectricGates", P + 144, 16),
  } },
  -- pokeemerald/src/tileset_anims.c:1086
  InitTilesetAnim_BikeShop = { counter = "secondary", max = "primary", anims = {
    one("bike_shop_blinking_lights", 4, 0, "gTilesetAnims_BikeShop_BlinkingLights", P + 496, 9),
  } },
  -- pokeemerald/src/tileset_anims.c:1092
  InitTilesetAnim_BattlePyramid = { counter = "secondary", max = "primary", anims = {
    { name = "battle_pyramid", period = 8, phase = 0, parts = {
      part("gTilesetAnims_BattlePyramid_Torch", P + 151, 8),
      part("gTilesetAnims_BattlePyramid_StatueShadow", P + 135, 8),
    } },
  } },
  -- pokeemerald/src/tileset_anims.c:1101
  InitTilesetAnim_BattleDome = { counter = "secondary", max = "primary", anims = {
    { name = "battle_dome_floor_lights", period = 4, phase = 0,
      palette = "sTilesetAnims_BattleDomeFloorLightPals", paletteSlot = 8 },
  } },
}

return M
