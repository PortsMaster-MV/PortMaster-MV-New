local Std = require("src.core.game3.scripting.stdscripts")
local Rse = require("src.core.game3.rse.init")

local GameCorner = {}

-- pokeemerald/include/constants/vars.h:287
local VAR_0x8004 = 0x8004
local VAR_RESULT = 0x800D

local function session()
  local rt = package.loaded["src.core.game3.runtime"]
  return rt and rt.getSession and rt.getSession() or nil
end

local function coins(sess)
  return require("src.core.game3.bag").Coins.get(sess)
end

local function setCoins(sess, n)
  require("src.core.game3.bag").Coins.set(sess, n)
end

local function screen(id, path)
  local ok, Screens = pcall(require, "src.ui.game3.screens")
  local mod = ok and Screens.get(id, session()) or nil
  return mod or require(path)
end

local function slotTables()
  return require("src.core.game3.rse.slot_machine").loadTables().fieldIds
end

local function pokeNewsActive(sess, kind)
  local Tv = require("src.core.game3.rse.tv")
  local shouldApply = function(k)
    local impl = Rse.system("tv")
    local f = impl and impl.shouldApplyPokeNews
    return type(f) == "function" and f(k) == true
  end
  local ok, r = pcall(Tv.isPokeNewsActive, sess, kind, shouldApply)
  return ok and r == true
end

-- pokeemerald/src/field_specials.c:1289
function GameCorner.getSlotMachineId(ctx, opts)
  opts = opts or {}
  local sess = opts.session or session()
  local ids = opts.fieldIds or slotTables()
  local trend = sess and type(sess.dewfordTrends) == "table" and sess.dewfordTrends[1] or nil
  local which = Rse.specialVar(ctx, VAR_0x8004)
  local rnd = (tonumber(trend and trend.trendiness) or 0) + (tonumber(trend and trend.rand) or 0) + (ids.seeds[which] or 0)
  local active = opts.serviceDay
  if active == nil then active = pokeNewsActive(sess, require("src.core.game3.rse.tv").POKENEWS_GAME_CORNER) end
  if active then return ids.serviceDay[rnd % 12] end
  return ids.normal[rnd % 12]
end

local function yieldUntil(ctx, poll)
  local Natives = require("src.core.game3.scripting.natives")
  ctx.mode = "native"
  ctx.status = "waiting"
  ctx.nativePoll = poll
  Natives.awaitState(ctx, poll)
end

local function closeMessages(adapters)
  if adapters and adapters.closeMessage then pcall(adapters.closeMessage) end
  local ok, Message = pcall(require, "src.ui.game3.message")
  if ok and Message and Message.close then pcall(Message.close) end
end

-- pokeemerald/src/slot_machine.c:1025
function GameCorner.playSlotMachine(ctx, machineId, adapters, opts)
  opts = opts or {}
  local sess = session()
  closeMessages(adapters)
  local done = false
  local function poll()
    if done and ctx.stateWait then ctx.stateWait = nil end
    return done
  end
  yieldUntil(ctx, poll)
  local Fade = require("src.ui.game3.fade")
  GameCorner.last = { machineId = machineId, phase = "fade" }
  local function open()
    GameCorner.last.phase = "slots"
    Fade.clear()
    local UI = screen("slot_machine", "src.ui.game3.rse.slot_machine")
    GameCorner.last.screen = UI.open({
      machineId = machineId,
      coins = coins(sess),
      session = sess,
      setCoins = function(n) setCoins(sess, n) end,
      onDone = function()
        GameCorner.last.phase = "done"
        Fade.mode, Fade.t, Fade.active = Fade.MODE.TO_BLACK, 16, false
        Fade.begin(Fade.MODE.FROM_BLACK, 1)
        -- pokeemerald/src/overworld.c:1684
        pcall(function() require("src.core.game3.audio").mapLoadMusic({}) end)
        done = true
      end,
    })
  end
  -- pokeemerald/src/slot_machine.c:1007
  if opts.skipFade then open() else Fade.begin(Fade.MODE.TO_BLACK, 1, open) end
  return true
end

-- pokeemerald/src/scrcmd.c:1915
function GameCorner.opPlaySlotMachine(vm, row, B)
  local machineId = B.varGet(vm.store, vm.ctx, row[1] or row.id)
  return GameCorner.playSlotMachine(vm.ctx, tonumber(machineId) or 0, vm.adapters)
end

-- pokeemerald/src/roulette.c:3475
function GameCorner.playRoulette(ctx, adapters)
  local sess = session()
  closeMessages(adapters)
  local done = false
  local function poll()
    if done and ctx.stateWait then ctx.stateWait = nil end
    return done
  end
  yieldUntil(ctx, poll)
  local UI = screen("roulette", "src.ui.game3.rse.roulette")
  GameCorner.last = { roulette = true, phase = "entry" }
  GameCorner.last.entry = UI.playEntry({
    var8004 = Rse.specialVar(ctx, VAR_0x8004),
    coins = coins(sess),
    session = sess,
    setCoins = function(n) setCoins(sess, n) end,
    setVar8004 = function(v) Rse.setSpecialVar(ctx, VAR_0x8004, v) end,
    onPhase = function(p) GameCorner.last.phase = p end,
    onScreen = function(s) GameCorner.last.screen = s end,
    onDone = function()
      GameCorner.last.phase = "done"
      done = true
    end,
  })
  return true
end

GameCorner.BY_NAME = {
  -- pokeemerald/src/field_specials.c:1289
  GetSlotMachineId = function(ctx)
    local v = GameCorner.getSlotMachineId(ctx)
    Rse.setSpecialVar(ctx, VAR_RESULT, v)
    return false, v
  end,
  -- pokeemerald/src/roulette.c:3475
  PlayRoulette = function(ctx, adapters)
    return GameCorner.playRoulette(ctx, adapters)
  end,
}
Std.legacyHandlers(GameCorner)

Rse.register("slotMachine", GameCorner)

return GameCorner
