local Rules = {}

local GAME = "emerald"

local function block()
  return require("src.core.game3.profile").of(GAME).save
end

local function constants()
  return require("src.core.game3.constants").of(GAME)
end

Rules.DEFAULT_NAME = nil
Rules.DEFAULT_RIVAL = nil
Rules.EASY_CHAT_PROFILE = nil
Rules.OWN_MON_MET_LOCATION = nil
-- pokeemerald/src/pokemon.c:6078
Rules.POKERUS = true

function Rules.newGameMoney()
  return block().money
end

function Rules.newGameFlags()
  return {}
end

function Rules.newVsSeeker()
  return nil
end

function Rules.restoreVsSeeker(_)
  return nil
end

-- pokeemerald/src/player_pc.c:358
function Rules.newGamePcItems(storage)
  local C = constants()
  storage.items = {}
  for _, row in ipairs(block().pcItems) do
    storage.items[#storage.items + 1] = { id = C:require("items", row.item), qty = row.qty }
  end
end

local function run_script_immediately(session, key)
  local Space = require("src.core.game3.scripting.space")
  local bundle = Space.ensureBundle(nil)
  assert(bundle and bundle.scripts and bundle.scripts[key], "script bundle has no " .. tostring(key))
  local Vm = require("src.core.game3.scripting.vm")
  local vm = Vm.new({
    store = session,
    scripts = bundle.scripts,
    text = bundle.text,
    movements = bundle.movements,
    version = session.version,
  })
  vm:start(key)
  for _ = 1, 1024 do
    if not vm:isRunning() then break end
    vm:tick()
  end
end

Rules.runScriptImmediately = run_script_immediately

function Rules.newGameInit(session, opts)
  local save = block()
  local C = constants()
  -- pokeemerald/src/new_game.c:178
  session.vars = session.vars or {}
  for _, name in ipairs(save.sizeRecordVars) do
    session.vars[C:require("vars", name)] = save.sizeRecordDefault
  end
  -- pokeemerald/src/new_game.c:196
  local run = (opts and opts.runScript) or run_script_immediately
  run(session, save.resetScript)
end

-- pokeemerald/src/overworld.c:1711
function Rules.resetStateOnContinue(session)
  local Flags = require("src.core.game3.scripting.flags")
  Flags.setFlag(session, nil, constants():require("flags", "FLAG_SYS_SAFARI_MODE"), false)
  session.safari = nil
end

local CONTINUE_GAME_WARP = 0x01

local UNION_ROOMS = { EM_UNION_ROOM = true, EM_UNION_ROOM_PLAZA = true }
-- pokeemerald/data/maps/OldaleTown_PokemonCenter_2F/map.json:79
local UNION_DOOR_X, UNION_DOOR_Y = 5, 1
local FIRST_CENTER_2F = "EM_OLDALE_TOWN_POKEMON_CENTER_2F"

local function union_room_door_map(session)
  local heal = type(session.healMap) == "string" and session.healMap or ""
  local city = heal:match("^(.+_POKEMON_CENTER)_1F$")
  if city then return city .. "_2F" end
  return FIRST_CENTER_2F
end

-- pokeemerald/src/load_save.c:134
function Rules.useContinueGameWarp(session)
  local Bit = require("bit")
  local f = tonumber(session.specialSaveWarpFlags) or 0
  local w = session.continueGameWarp
  session._continueWarpDeferred = nil
  if Bit.band(f, CONTINUE_GAME_WARP) ~= 0 and type(w) == "table" and type(w.map) == "string" then
    -- pokeemerald/src/overworld.c:1741
    session.specialSaveWarpFlags = Bit.band(f, Bit.bnot(CONTINUE_GAME_WARP))
    session.map, session.x, session.y, session.facing = w.map, tonumber(w.x), tonumber(w.y), "down"
    return
  end
  if UNION_ROOMS[session.map] then
    -- pokeemerald/data/scripts/cable_club.inc:845
    session.map, session.x, session.y, session.facing =
      union_room_door_map(session), UNION_DOOR_X, UNION_DOOR_Y, "down"
  end
end

-- pokeemerald/include/constants/map_groups.h:431
local LINK_ROOMS = {
  EM_BATTLE_COLOSSEUM_2P = true,
  EM_TRADE_CENTER = true,
  EM_RECORD_CORNER = true,
  EM_BATTLE_COLOSSEUM_4P = true,
  EM_UNION_ROOM = true,
  EM_UNION_ROOM_PLAZA = true,
}

-- pokeemerald/src/load_save.c:149 SetContinueGameWarpStatusToDynamicWarp
function Rules.saveWarpFields(session)
  local f = tonumber(session.specialSaveWarpFlags) or 0
  local w = session.continueGameWarp
  local dw = session.dynamicWarp
  if LINK_ROOMS[session.map] and type(dw) == "table" and type(dw.map) == "string"
      and tonumber(dw.x) and tonumber(dw.y) then
    -- pokeemerald/src/overworld.c:735 SetContinueGameWarpToDynamicWarp
    return require("bit").bor(f, CONTINUE_GAME_WARP), { map = dw.map, warpId = tonumber(dw.warpId), x = tonumber(dw.x), y = tonumber(dw.y) }
  end
  return f, w
end

return Rules
