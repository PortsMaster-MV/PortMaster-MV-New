local Rules = {}

Rules.DEFAULT_NAME = "RED"
Rules.DEFAULT_RIVAL = "BLUE"
Rules.EASY_CHAT_PROFILE = { 2601, 4128, 526, 2611 }

-- pokefirered/include/constants/flags.h:1327
local FLAG_SYS_SAFARI_MODE = 0x800
-- pokefirered/include/constants/vars.h:162
local VAR_MAP_SCENE_FUCHSIA_CITY_SAFARI_ZONE_ENTRANCE = 0x406E

local function clear_saved_var(session, id)
  local vars = session.vars
  if type(vars) ~= "table" then return end
  local Flags = require("src.core.game3.scripting.flags")
  vars[tostring(id)] = nil
  vars[string.format("0x%X", id)] = nil
  local name = Flags.VAR_NAMES and Flags.VAR_NAMES[id]
  if name then vars[name] = nil end
  vars[id] = 0
end

-- pokefirered/src/overworld.c:345 Overworld_ResetStateOnContinue
function Rules.resetStateOnContinue(session)
  local Flags = require("src.core.game3.scripting.flags")
  Flags.setFlag(session, nil, FLAG_SYS_SAFARI_MODE, false)
  clear_saved_var(session, VAR_MAP_SCENE_FUCHSIA_CITY_SAFARI_ZONE_ENTRANCE)
  session.safari = nil
  if type(session.map) == "string" and session.map:find("^FR_SAFARI_ZONE_")
      and not Flags.getFlag(session, nil, FLAG_SYS_SAFARI_MODE) then
    -- pokefirered/data/scripts/safari_zone.inc:7 SafariZone_EventScript_Exit
    local Safari = require("src.core.game3.safari")
    Flags.setVar(session, nil, VAR_MAP_SCENE_FUCHSIA_CITY_SAFARI_ZONE_ENTRANCE, 1)
    session.map, session.x, session.y = Safari.EXIT_MAP, Safari.EXIT_X, Safari.EXIT_Y
    session.facing = "down"
  end
end

-- pokefirered/include/save_location.h:5
local CONTINUE_GAME_WARP = 0x01
-- pokefirered/data/maps/PokemonLeague_HallOfFame/scripts.inc:40
local HALL_OF_FAME_MAP = "FR_POKEMON_LEAGUE_HALL_OF_FAME"

local UNION_ROOMS = { FR_UNION_ROOM = true, FR_UNION_ROOM_PLAZA = true }
-- pokefirered/data/maps/ViridianCity_PokemonCenter_2F/map.json:84
local UNION_DOOR_X, UNION_DOOR_Y = 5, 1
local FIRST_CENTER_2F = "FR_VIRIDIAN_CITY_POKEMON_CENTER_2F"

local function union_room_door_map(session)
  local heal = type(session.healMap) == "string" and session.healMap or ""
  local city = heal:match("^(.+_POKEMON_CENTER)_1F$")
  if city then return city .. "_2F" end
  if heal:match("_POKECENTER$") then return heal .. "_2F" end
  return FIRST_CENTER_2F
end

-- pokefirered/src/overworld.c:1706 CB2_ContinueSavedGame
function Rules.useContinueGameWarp(session, mounted)
  local Bit = require("bit")
  local f = tonumber(session.specialSaveWarpFlags) or 0
  local w = session.continueGameWarp
  if Bit.band(f, CONTINUE_GAME_WARP) ~= 0 and type(w) == "table" and type(w.map) == "string" then
    session.specialSaveWarpFlags = Bit.band(f, Bit.bnot(CONTINUE_GAME_WARP))
    session.map, session.x, session.y, session.facing = w.map, tonumber(w.x), tonumber(w.y), "down"
    return
  end
  session._continueWarpDeferred = nil
  if UNION_ROOMS[session.map] then
    session.map, session.x, session.y, session.facing =
      union_room_door_map(session), UNION_DOOR_X, UNION_DOOR_Y, "down"
    return
  end
  if session.map == HALL_OF_FAME_MAP then
    local Field = require("src.core.game3.field")
    if not mounted and not Field.flyDestinationsMounted() then
      session._continueWarpDeferred = true
      return
    end
    -- pokefirered/src/post_battle_event_funcs.c:33
    local dest = assert(Field.flyDestination("MAPSEC_PALLET_TOWN"),
      "no heal location for MAPSEC_PALLET_TOWN")
    session.map, session.x, session.y, session.facing = dest.map, dest.x, dest.y, "down"
  end
end

-- pokefirered/include/constants/map_groups.h:9
local LINK_ROOMS = {
  FR_BATTLE_COLOSSEUM_2P = true,
  FR_TRADE_CENTER = true,
  FR_RECORD_CORNER = true,
  FR_BATTLE_COLOSSEUM_4P = true,
  FR_UNION_ROOM = true,
  FR_UNION_ROOM_PLAZA = true,
}

-- pokefirered/src/load_save.c:149 SetContinueGameWarpStatusToDynamicWarp
function Rules.saveWarpFields(session)
  local f = tonumber(session.specialSaveWarpFlags) or 0
  local w = session.continueGameWarp
  local dw = session.dynamicWarp
  if LINK_ROOMS[session.map] and type(dw) == "table" and type(dw.map) == "string"
      and tonumber(dw.x) and tonumber(dw.y) then
    -- pokefirered/src/overworld.c:701 SetContinueGameWarpToDynamicWarp
    return require("bit").bor(f, CONTINUE_GAME_WARP), { map = dw.map, warpId = tonumber(dw.warpId), x = tonumber(dw.x), y = tonumber(dw.y) }
  end
  return f, w
end

-- pokefirered/include/constants/region_map_sections.h:211 KANTO_MAPSEC_START
Rules.OWN_MON_MET_LOCATION = 88

-- pokefirered/include/constants/flags.h:1083
function Rules.purgeNoneItemFlags(save)
  for id = 0x3E8 + 51, 0x3E8 + 62 do
    save.flags[id] = nil
    save.flags[tostring(id)] = nil
  end
end

function Rules.newGameMoney()
  return 3000
end

function Rules.newGameFlags()
  local Flags = require("src.core.game3.scripting.flags")
  local hide = {}
  for _, id in ipairs(Flags.NEW_GAME_HIDE_FLAGS or {}) do
    hide[tostring(id)] = true
  end
  return hide
end

function Rules.newVsSeeker()
  return { steps = 0, charging = 0, rematches = {} }
end

function Rules.restoreVsSeeker(v)
  return type(v) == "table" and v or { steps = 0, charging = 0, rematches = {} }
end

function Rules.newGamePcItems(storage)
  storage.items[1] = { id = 13, qty = 1 } -- pokefirered/src/player_pc.c:100
end

function Rules.newGameInit(session)
  -- pokefirered/src/new_game.c:143 ResetTrainerFanClub
  require("src.core.game3.trainer_fan_club").reset(session)
  -- pokefirered/src/new_game.c:132 InitMagikarpSizeRecord
  local SizeRecord = require("src.core.game3.pokemon_size_record")
  SizeRecord.initMagikarpSizeRecord(session)
  SizeRecord.initHeracrossSizeRecord(session)
end

function Rules.repairSaveState(session)
  require("src.core.game3.scripting.flags").repairSaveState(session)
end

function Rules.repairRoamer(session)
  local FLAG_SYS_CAN_LINK_WITH_RS = 0x844
  local VAR_MAP_SCENE_ONE_ISLAND_POKEMON_CENTER_1F = 0x4076
  local VAR_STARTER_MON = 0x4031
  local flags = session.flags or {}
  local hasLink = (flags[FLAG_SYS_CAN_LINK_WITH_RS] == true) or (flags["FLAG_SYS_CAN_LINK_WITH_RS"] == true)
  local vars = session.vars or {}
  local sceneVal = tonumber(vars[VAR_MAP_SCENE_ONE_ISLAND_POKEMON_CENTER_1F] or vars["VAR_MAP_SCENE_ONE_ISLAND_POKEMON_CENTER_1F"]) or 0
  if hasLink or sceneVal >= 6 then
    local Roamer = require("src.core.game3.roamer")
    local starter = tonumber(vars[VAR_STARTER_MON] or vars["VAR_STARTER_MON"]) or 0
    Roamer.init(session, starter)
  end
end

return Rules
