local M = {}

local function part(frames, dst, tiles, extra)
  local row = {frames = frames, dst = dst, tiles = tiles}
  for k, v in pairs(extra or {}) do row[k] = v end
  return row
end

local function one(name, period, phase, frames, dst, tiles)
  return {name = name, period = period, phase = phase, parts = {part(frames, dst, tiles)}}
end

local function slots(name, fn, make)
  local rows = {}
  for i = 0, 7 do
    rows[#rows + 1] = {name = name .. "_" .. i, period = 8, phase = i, slot = i, fn = fn, parts = make()}
  end
  return rows
end

local function idle()
  return {counter = "secondary", max = "primary", anims = {}}
end

-- pokeruby/src/tileset_anim.c:539
M.INITS = {
  TilesetCB_General = {counter = "primary", max = 256, anims = {
    one("general_flower", 16, 0, "gTilesetAnims_General0", 127 * 4, 4),
    one("general_water", 16, 1, "gTilesetAnims_General1", 108 * 4, 30),
    one("general_sand_water_edge", 16, 2, "gTilesetAnims_General2", 116 * 4, 10),
    one("general_waterfall", 16, 3, "gTilesetAnims_General3", 124 * 4, 6),
    one("general_land_water_edge", 16, 4, "gTilesetAnims_General4", 120 * 4, 10),
  }},
  TilesetCB_Building = {counter = "primary", max = 256, anims = {
    one("building_tv_turned_on", 8, 0, "gTilesetAnims_InsideBuilding0", 124 * 4, 4),
  }},
  TilesetCB_Petalburg = idle(),
  TilesetCB_Rustboro = {counter = "secondary", max = "primary", anims = slots("rustboro_windy_water", "slot", function()
    return {part("gTilesetAnims_Rustboro0", nil, 4, {dstTable = "gTilesetAnims_RustboroVDests0"})}
  end)},
  TilesetCB_Dewford = idle(),
  TilesetCB_Slateport = idle(),
  TilesetCB_Mauville = {counter = "secondary", max = "primary", start = "primary", anims = slots("mauville_flowers", "mauville", function()
    return {
      part("gTilesetAnims_Mauville0", nil, 4, {framesB = "gTilesetAnims_Mauville2", dstTable = "gTilesetAnims_MauvilleVDests0"}),
      part("gTilesetAnims_Mauville1", nil, 4, {framesB = "gTilesetAnims_Mauville3", dstTable = "gTilesetAnims_MauvilleVDests1"}),
    }
  end)},
  TilesetCB_Lavaridge = {counter = "secondary", max = "primary", anims = {
    {name = "lavaridge_steam", period = 16, phase = 0, parts = {
      part("gTilesetAnims_Lavaridge0", 200 * 4, 4),
      part("gTilesetAnims_Lavaridge0", 201 * 4, 4, {offset = 2}),
    }},
    one("lavaridge_lava", 16, 1, "gTilesetAnims_Lavaridge1_Cave0", 168 * 4, 4),
  }},
  TilesetCB_Fallarbor = idle(),
  TilesetCB_Fortree = idle(),
  TilesetCB_Lilycove = idle(),
  TilesetCB_Mossdeep = idle(),
  TilesetCB_EverGrande = {counter = "secondary", max = "primary", anims = slots("ever_grande_flowers", "slot", function()
    return {part("gTilesetAnims_EverGrande0", nil, 4, {dstTable = "gTilesetAnims_EverGrandeVDests0"})}
  end)},
  TilesetCB_Pacifidlog = {counter = "secondary", max = "primary", start = "primary", anims = {
    one("pacifidlog_log_bridges", 16, 0, "gTilesetAnims_Pacifidlog0", 244 * 4, 30),
    one("pacifidlog_water_currents", 16, 1, "gTilesetAnims_Pacifidlog1", 252 * 4, 8),
  }},
  TilesetCB_Sootopolis = idle(),
  TilesetCB_Underwater = {counter = "secondary", max = 128, anims = {
    one("underwater_seaweed", 16, 0, "gTilesetAnims_Underwater0", 252 * 4, 4),
  }},
  TilesetCB_SootopolisGym = {counter = "secondary", max = 240, anims = {
    {name = "sootopolis_gym_waterfalls", period = 8, phase = 0, count = "min", parts = {
      part("gTilesetAnims_SootopolisGym0", 252 * 4, 12),
      part("gTilesetAnims_SootopolisGym1", 244 * 4, 20),
    }},
  }},
  TilesetCB_Cave = {counter = "secondary", max = "primary", anims = {
    one("cave_lava", 16, 1, "gTilesetAnims_Lavaridge1_Cave0", 232 * 4, 4),
  }},
  TilesetCB_EliteFour = {counter = "secondary", max = 128, anims = {
    one("elite_four_ground_lights", 64, 0, "gTilesetAnims_EliteFour0", 248 * 4, 4),
    one("elite_four_wall_lights", 8, 1, "gTilesetAnims_EliteFour1", 254 * 4, 1),
  }},
  TilesetCB_MauvilleGym = {counter = "secondary", max = "primary", anims = {
    one("mauville_gym_electric_gates", 2, 0, "gTilesetAnims_MauvilleGym0", 164 * 4, 16),
  }},
  TilesetCB_BikeShop = {counter = "secondary", max = "primary", anims = {
    one("bike_shop_blinking_lights", 4, 0, "gTilesetAnims_BikeShop0", 252 * 4, 9),
  }},
}

M.INITS.TilesetCB_Rustboro.anims[#M.INITS.TilesetCB_Rustboro.anims + 1] =
  one("rustboro_fountain", 8, 0, "gTilesetAnims_Rustboro1", 240 * 4, 4)

return M
