local MB = require("src.core.game3.mb")
local Constants = require("src.core.game3.constants")
local M = {}
local aliases = {
  UNUSED_DEEP_SAND = "DEEP_SAND", UNUSED_CAVE = "CAVE", SEMI_DEEP_WATER = "INTERIOR_DEEP_WATER",
  UNUSED_DEEP_WATER = "DEEP_WATER", UNUSED_EASTWARD_CURRENT = "EASTWARD_CURRENT",
  UNUSED_EAST_ARROW_WARP = "EAST_ARROW_WARP", UNUSED_DEEP_SOUTH_WARP = "DEEP_SOUTH_WARP",
  WARP_OR_BRIDGE = "BRIDGE_OVER_OCEAN", UNUSED_71 = "BRIDGE_OVER_POND_LOW",
  ROUTE120_NORTH_BRIDGE_1 = "BRIDGE_OVER_POND_MED", ROUTE120_NORTH_BRIDGE_2 = "BRIDGE_OVER_POND_HIGH",
  ROUTE120_SOUTH_BRIDGE_1 = "BRIDGE_OVER_POND_MED_EDGE_1", ROUTE120_SOUTH_BRIDGE_2 = "BRIDGE_OVER_POND_MED_EDGE_2",
  ROUTE120_NORTH_BRIDGE_3 = "BRIDGE_OVER_POND_HIGH_EDGE_1", ROUTE120_NORTH_BRIDGE_4 = "BRIDGE_OVER_POND_HIGH_EDGE_2",
  PACIFIDLOG_VERTICAL_LOG_1 = "PACIFIDLOG_VERTICAL_LOG_TOP", PACIFIDLOG_VERTICAL_LOG_2 = "PACIFIDLOG_VERTICAL_LOG_BOTTOM",
  PACIFIDLOG_HORIZONTAL_LOG_1 = "PACIFIDLOG_HORIZONTAL_LOG_LEFT", PACIFIDLOG_HORIZONTAL_LOG_2 = "PACIFIDLOG_HORIZONTAL_LOG_RIGHT",
  ROUTE110_BRIDGE = "BIKE_BRIDGE_OVER_BARRIER", LINK_BATTLE_RECORDS = "CABLE_BOX_RESULTS_1",
  RUNNING_SHOES_MANUAL = "RUNNING_SHOES_INSTRUCTION",
  SECRET_BASE_SPOT_TREE_1 = "SECRET_BASE_SPOT_TREE_LEFT", SECRET_BASE_SPOT_TREE_1_OPEN = "SECRET_BASE_SPOT_TREE_LEFT_OPEN",
  SECRET_BASE_SPOT_TREE_2 = "SECRET_BASE_SPOT_TREE_RIGHT", SECRET_BASE_SPOT_TREE_2_OPEN = "SECRET_BASE_SPOT_TREE_RIGHT_OPEN",
  RECORD_MIXING_SECRET_BASE_PC = "SECRET_BASE_REGISTER_PC", SECRET_BASE_UNUSED = "SECRET_BASE_SCENERY",
  BLOCK_DECORATION = "SECRET_BASE_TRAINER_SPOT", SECRET_BASE_LARGE_MAT_EDGE = "HOLDS_SMALL_DECORATION",
  LARGE_MAT_CENTER = "HOLDS_LARGE_DECORATION", SECRET_BASE_MUSIC_NOTE_MAT = "SECRET_BASE_SOUND_MAT",
  SECRET_BASE_SHIELD_OR_TOY_TV = "SECRET_BASE_TV_SHIELD",
}
function M.of(game)
  assert(game == "ruby" or game == "sapphire", "native RS metatile translator needs Ruby/Sapphire")
  local t = {game = game, TILE_FLAG_HAS_ENCOUNTERS = 1, TILE_FLAG_SURFABLE = 2, UNMAPPED_BASE = 0x200}
  local toCanon, toRaw, sourceNames = {}, {}, {}
  local byId = Constants.of(game).metatile_behaviors.byId.MB_ or {}
  for raw = 0, 255 do
    local full = byId[raw]
    local name = full and full:gsub("^MB_", "")
    local canon = name and MB.id(aliases[name] or name)
    canon = canon or (t.UNMAPPED_BASE + raw)
    assert(toRaw[canon] == nil, "native RS metatile canonical collision")
    toCanon[raw], toRaw[canon], sourceNames[canon] = canon, raw, full
  end
  function t.canon(raw) return toCanon[(tonumber(raw) or 0) % 256] end
  function t.raw(canon) return toRaw[tonumber(canon) or -1] end
  function t.sourceName(canon) return sourceNames[tonumber(canon) or -1] end
  function t.table()
    local out = {}
    for raw, canon in pairs(toCanon) do out[raw] = canon end
    return out
  end
  function t.tileBits(rom)
    local V = require("src.import.gba.versions")
    assert(V.GAME == game, "RS tile flags require selected native edition/revision")
    local S = assert(V.SYMS, "RS tile flags require selected revision symbols")
    local symbol = "metatile_behavior.o:sTileBitAttributes"
    local off, out = S.off(symbol), {}
    for raw = 0, S.size(symbol) - 1 do
      local bits = rom:get(off + raw)
      if bits ~= 0 then out[t.canon(raw)] = bits end
    end
    return out
  end
  return t
end
return M
