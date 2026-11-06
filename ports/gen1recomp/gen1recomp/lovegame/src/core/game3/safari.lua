-- pokefirered/src/safari_zone.c:9 gNumSafariBalls / gSafariZoneStepCounter

local function lazyReq(name)
  local m = package.loaded[name]
  if type(m) == "table" then return m end
  return require(name)
end

local RomText = require("src.core.game3.rom_text")

local Safari = {}

-- pokefirered/include/constants/flags.h:1327
Safari.FLAG_SYS_SAFARI_MODE = 0x800
-- pokefirered/include/constants/vars.h:162
Safari.VAR_ENTRANCE_SCENE = 0x406E
-- pokefirered/src/safari_zone.c:31
Safari.BALLS = 30
Safari.STEPS = 600
-- pokefirered/data/scripts/safari_zone.inc:6
Safari.EXIT_MAP = "FR_FUCHSIA_CITY_SAFARI_ZONE_ENTRANCE"
Safari.EXIT_X = 4
Safari.EXIT_Y = 1

local function runtime()
  return package.loaded["src.core.game3.runtime"]
end

local function session_of(session)
  if session then return session end
  local Runtime = runtime()
  if Runtime and Runtime.getSession then
    local s = Runtime.getSession()
    if s then return s end
  end
  local Field = package.loaded["src.core.game3.field"]
  return Field and Field.getSession and Field.getSession() or nil
end

local function game_of(game)
  if game then return game end
  local Runtime = runtime()
  return (Runtime and Runtime._game) or nil
end

local function store()
  local Space = package.loaded["src.core.game3.scripting.space"]
  return Space and Space.store or nil
end

local function script_ctx()
  local Space = package.loaded["src.core.game3.scripting.space"]
  return (Space and Space.vm and Space.vm.ctx) or nil
end

local function rse_cfg(session)
  local ok, BattleProfile = pcall(lazyReq, "src.core.game3.battle.profile")
  if not ok then return nil end
  local okP, p = pcall(BattleProfile.get, session)
  return okP and p and p.safari or nil
end
Safari.rseConfig = rse_cfg

local function flag_id(session)
  local cfg = rse_cfg(session)
  if cfg then return lazyReq("src.core.game3.rse.init").flagId(cfg.flag, session) end
  return Safari.FLAG_SYS_SAFARI_MODE
end

local function set_flag(session, on)
  local Flags = lazyReq("src.core.game3.scripting.flags")
  local st = store()
  local id = flag_id(session)
  if st then Flags.setFlag(st, script_ctx(), id, on) end
  if session then
    session.flags = session.flags or {}
    session.flags[id] = on or nil
  end
end

local function se(id)
  pcall(function()
    local Audio = lazyReq("src.core.game3.audio")
    if Audio and Audio.playSe then Audio.playSe(id) end
  end)
end

-- pokefirered/src/safari_zone.c:9
function Safari.state(session)
  session = session_of(session)
  if not session then return nil end
  session.safari = session.safari or {}
  return session.safari
end

local function flag_set(session)
  local Flags = lazyReq("src.core.game3.scripting.flags")
  local st = store()
  local id = flag_id(session)
  if st and Flags.getFlag(st, script_ctx(), id) then return true end
  if session and session.flags and session.flags[id] then return true end
  return false
end

-- pokefirered/src/overworld.c:1381 ResetSafariZoneFlag_
function Safari.reset(session)
  session = session_of(session)
  set_flag(session, false)
  local state = session and session.safari
  if state then
    state.balls = 0
    state.steps = 0
  end
  return true
end

-- pokefirered/src/safari_zone.c:12 GetSafariZoneFlag
function Safari.isActive(session)
  session = session_of(session)
  if not flag_set(session) then return false end
  -- pokefirered/src/overworld.c:1695 CB2_ContinueSavedGame
  local state = session and session.safari
  if not (state and tonumber(state.steps)) then
    Safari.reset(session)
    return false
  end
  return true
end

-- pokefirered/src/safari_zone.c:26 EnterSafariMode
function Safari.enter(session)
  session = session_of(session)
  if not session then return false end
  set_flag(session, true)
  local state = Safari.state(session)
  local cfg = rse_cfg(session)
  if cfg then
    -- pokeemerald/src/safari_zone.c:55
    state.balls = cfg.balls
    state.steps = cfg.steps
    state.caughtMons = 0
    state.pkblkUses = 0
    state.feeders = {}
    return true
  end
  state.balls = Safari.BALLS
  state.steps = Safari.STEPS
  return true
end

-- pokefirered/src/safari_zone.c:34 ExitSafariMode
function Safari.exit(session)
  session = session_of(session)
  local state = Safari.state(session)
  if state and rse_cfg(session) then
    -- pokeemerald/src/safari_zone.c:68
    lazyReq("src.core.game3.rse.init").call("tv", "tryPutSafariFanClubOnAir", "TryPutSafariFanClubOnAir", nil,
      tonumber(state.caughtMons) or 0, tonumber(state.pkblkUses) or 0)
  end
  set_flag(session, false)
  if state then
    state.balls = 0
    state.steps = 0
    -- pokeemerald/src/safari_zone.c:70
    if rse_cfg(session) then state.feeders = {} end
  end
  return true
end

local function run_script(label)
  local Space = package.loaded["src.core.game3.scripting.space"]
  if not (Space and Space.startScript and Space.scriptKey) then return false end
  local key = Space.scriptKey(label)
  if not key then error("safari: no script " .. tostring(label)) end
  return Space.startScript(key)
end

-- pokeemerald/src/safari_zone.c:97
function Safari.endBattleRse(session, st)
  session = session_of(session)
  local cfg = rse_cfg(session)
  local state = Safari.state(session)
  if not (cfg and state) then return false end
  local sf = st and st.safariState or {}
  state.pkblkUses = (tonumber(state.pkblkUses) or 0) + (tonumber(sf.pokeblockThrows) or 0)
  if st and st.result == "catch" then state.caughtMons = (tonumber(state.caughtMons) or 0) + 1 end
  if (tonumber(state.balls) or 0) ~= 0 then return false end
  if st and st.endReason == "no_safari_balls" then
    -- pokeemerald/src/safari_zone.c:108
    local Space = package.loaded["src.core.game3.scripting.space"]
    if Space and Space.runImmediately then Space.runImmediately(cfg.outOfBallsMidBattle) end
    local dest = session.warpDestination
    if dest and dest.map then
      local Runtime = runtime()
      lazyReq("src.core.game3.warp").request(Runtime and Runtime._mod, game_of(nil), dest.map, dest.x, dest.y,
        "down", { fade = false, se = false })
    end
    return true
  end
  if st and st.result == "catch" then
    -- pokeemerald/src/safari_zone.c:115
    return run_script(cfg.outOfBalls)
  end
  return false
end

function Safari.balls(session)
  local state = Safari.state(session)
  return (state and tonumber(state.balls)) or 0
end

function Safari.steps(session)
  local state = Safari.state(session)
  return (state and tonumber(state.steps)) or 0
end

local function set_entrance_scene(session, value)
  local Flags = lazyReq("src.core.game3.scripting.flags")
  local st = store()
  if st then Flags.setVar(st, script_ctx(), Safari.VAR_ENTRANCE_SCENE, value) end
  if session then
    session.vars = session.vars or {}
    session.vars[Safari.VAR_ENTRANCE_SCENE] = value
  end
end

-- pokefirered/data/scripts/safari_zone.inc:7 SafariZone_EventScript_Exit
function Safari.exitToEntrance(session, game)
  session = session_of(session)
  game = game_of(game)
  set_entrance_scene(session, 1)
  Safari.exit(session)
  local Warp = lazyReq("src.core.game3.warp")
  local Runtime = runtime()
  Warp.request(Runtime and Runtime._mod, game, Safari.EXIT_MAP,
    Safari.EXIT_X, Safari.EXIT_Y, "down", { fade = true })
  return true
end

-- pokefirered/data/scripts/safari_zone.inc:1 SafariZone_EventScript_OutOfBallsMidBattle
function Safari.outOfBallsMidBattle(session, game)
  session = session_of(session)
  game = game_of(game)
  set_entrance_scene(session, 3)
  Safari.exit(session)
  local Warp = lazyReq("src.core.game3.warp")
  local Runtime = runtime()
  -- pokefirered/src/safari_zone.c:68
  Warp.request(Runtime and Runtime._mod, game, Safari.EXIT_MAP,
    Safari.EXIT_X, Safari.EXIT_Y, "down", { fade = false, se = false })
  return true
end

Safari.presenter = nil

local function presenter()
  if Safari.presenter then return Safari.presenter end
  if not (love and love.graphics) then return nil end
  local okM, Message = pcall(lazyReq, "src.ui.game3.message")
  if not (okM and Message and Message.show) then return nil end
  local okC, Choice = pcall(lazyReq, "src.ui.game3.choice")
  return {
    message = function(text, onDone) Message.show(text, onDone) end,
    yesNo = (okC and Choice and Choice.yesNo)
      and function(onPick) Choice.yesNo(onPick) end or nil,
    close = function() Message.close() end,
  }
end

local function announce(text, session, game, onDone)
  -- pokefirered/include/constants/songs.h:70
  se(lazyReq("src.core.game3.se_ids").SE_DING_DONG)
  local Field = package.loaded["src.core.game3.field"]
  if Field then Field.locked = true end
  local P = presenter()
  if P and P.message then
    P.message(text, function()
      if Field then Field.locked = false end
      onDone()
    end)
    return true
  end
  if Field then Field.locked = false end
  onDone()
  return true
end

-- pokefirered/data/scripts/safari_zone.inc:25 SafariZone_EventScript_TimesUp
function Safari.timesUp(session, game)
  return announce(
    RomText.ascii("SafariZone_Text_TimesUp"),
    session, game, function() Safari.exitToEntrance(session, game) end)
end

-- pokefirered/data/scripts/safari_zone.inc:31 SafariZone_EventScript_OutOfBalls
function Safari.outOfBalls(session, game)
  local cfg = rse_cfg(session_of(session))
  -- pokeemerald/src/safari_zone.c:115
  if cfg then return run_script(cfg.outOfBalls) end
  return announce(
    RomText.ascii("SafariZone_Text_OutOfBalls"),
    session, game, function() Safari.exitToEntrance(session, game) end)
end

-- pokefirered/src/safari_zone.c:41 SafariZoneTakeStep
function Safari.takeStep(session, game)
  session = session_of(session)
  if not Safari.isActive(session) then return false end
  local state = Safari.state(session)
  if not state then return false end
  local cfg = rse_cfg(session)
  if cfg then
    -- pokeemerald/src/safari_zone.c:75
    for _, f in pairs(state.feeders or {}) do
      if (tonumber(f.stepCounter) or 0) > 0 then
        f.stepCounter = f.stepCounter - 1
        if f.stepCounter == 0 then
          f.x, f.y, f.mapNum = 0, 0, 0
          f.pokeblock = require("src.core.game3.rse.pokeblock").empty()
        end
      end
    end
    state.steps = math.max(0, (tonumber(state.steps) or 0) - 1)
    if state.steps ~= 0 then return false end
    run_script(cfg.timesUp)
    return true
  end
  local steps = (tonumber(state.steps) or 0) - 1
  if steps < 0 then steps = 0 end
  state.steps = steps
  if steps ~= 0 then return false end
  Safari.timesUp(session, game)
  return true
end

-- pokefirered/src/safari_zone.c:54 SafariZoneRetirePrompt
function Safari.retirePrompt(session, game)
  session = session_of(session)
  game = game_of(game)
  if not Safari.isActive(session) then return false end
  local cfg = rse_cfg(session)
  -- pokeemerald/src/safari_zone.c:92
  if cfg then return run_script(cfg.retire) end
  local Field = package.loaded["src.core.game3.field"]
  -- pokefirered/data/text/safari_zone.inc:3 SafariZone_Text_WouldYouLikeToExit
  local ask = RomText.ascii("SafariZone_Text_WouldYouLikeToExit")
  local P = presenter()
  if not (P and P.message and P.yesNo) then
    Safari.exitToEntrance(session, game)
    return true
  end
  if Field then Field.locked = true end
  P.message(ask, function()
    P.yesNo(function(yes)
      if Field then Field.locked = false end
      if yes then
        Safari.exitToEntrance(session, game)
      elseif P.close then
        P.close()
      end
    end)
  end)
  return true
end

return Safari
