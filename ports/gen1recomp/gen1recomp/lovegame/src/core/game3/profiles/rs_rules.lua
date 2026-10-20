local Rules = {}
local function version(session)
  if type(session) == "table" and (session.version == "ruby" or session.version == "sapphire") then return session.version end
  local v = require("src.core.GameVersion").get()
  return v == "sapphire" and v or "ruby"
end
local function block(session) return require("src.core.game3.profile").of(version(session)).save end
local function constants(session) return require("src.core.game3.constants").of(version(session)) end

Rules.POKERUS = true
Rules.PERTURB_FIELD_RNG = false
function Rules.newGameMoney() return block().money end
function Rules.newGameFlags() return {} end
function Rules.newVsSeeker() return nil end
function Rules.restoreVsSeeker() return nil end

-- pokeruby/src/new_game.c:76
function Rules.newGameTrainerIds(opts)
  local Rng = require("src.core.game3.rng")
  if opts.rngSeed ~= nil then Rng.SeedRng(opts.rngSeed) end
  local secret, trainer = Rng.Random(), Rng.Random()
  if opts.trainerIdLower ~= nil then trainer = math.floor(tonumber(opts.trainerIdLower) or 0) % 65536 end
  return trainer, secret
end

-- pokeruby/src/player_pc.c:194
function Rules.newGamePcItems(storage)
  storage.items = {}
  for _, row in ipairs(block().pcItems) do
    storage.items[#storage.items + 1] = { id = constants():require("items", row.item), qty = row.qty }
  end
end

function Rules.runScriptImmediately(session, key)
  local bundle = require("src.core.game3.scripting.space").ensureBundle(nil)
  assert(bundle and bundle.scripts and bundle.scripts[key], "script bundle has no " .. tostring(key))
  local vm = require("src.core.game3.scripting.vm").new({ store = session, scripts = bundle.scripts,
    text = bundle.text, movements = bundle.movements, version = session.version })
  vm:start(key)
  for _ = 1, 1024 do if not vm:isRunning() then break end; vm:tick() end
  assert(not vm:isRunning(), "new-game reset script did not finish")
end

-- pokeruby/src/new_game.c:173
function Rules.newGameInit(session, opts)
  local save, C = block(session), constants(session)
  session.vars = session.vars or {}
  for _, name in ipairs(save.sizeRecordVars) do session.vars[C:require("vars", name)] = save.sizeRecordDefault end
end

-- pokeruby/src/new_game.c:205
function Rules.finishNewGameInit(session, opts)
  ((opts and opts.runScript) or Rules.runScriptImmediately)(session, block(session).resetScript)
end

-- pokeruby/src/overworld.c:1465
function Rules.resetStateOnContinue(session)
  require("src.core.game3.scripting.flags").setFlag(session, nil, constants(session):require("flags", "FLAG_SYS_SAFARI_MODE"), false)
  session.safari = nil
end

-- pokeruby/src/load_save.c:38
function Rules.useContinueGameWarp(session)
  session._continueWarpDeferred = nil
  local w = session.continueGameWarp
  if tonumber(session.specialSaveWarpFlags) == 1 and type(w) == "table" and type(w.map) == "string" then
    session.specialSaveWarpFlags = 0
    session.map, session.x, session.y, session.facing = w.map, tonumber(w.x), tonumber(w.y), "down"
  end
end

-- pokeruby/src/overworld.c:554
local LINK_ROOM = { TRADE_CENTER = true, SINGLE_BATTLE_COLOSSEUM = true, DOUBLE_BATTLE_COLOSSEUM = true, RECORD_CORNER = true }
function Rules.saveWarpFields(session)
  local map = type(session.map) == "string" and session.map:gsub("^[A-Z]+_", "")
  local w = session.dynamicWarp
  if LINK_ROOM[map] and type(w) == "table" and type(w.map) == "string" then
    return 1, { map = w.map, warpId = tonumber(w.warpId), x = tonumber(w.x), y = tonumber(w.y) }
  end
  return tonumber(session.specialSaveWarpFlags) or 0, session.continueGameWarp
end
return Rules
