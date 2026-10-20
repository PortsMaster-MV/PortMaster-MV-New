local Std = require("src.core.game3.scripting.stdscripts")

local Clock = {}

local VAR_0x8004 = 0x8004

local function flagsMod()
  return require("src.core.game3.scripting.flags")
end

local function session()
  local rt = package.loaded["src.core.game3.runtime"]
  return rt and rt.getSession and rt.getSession() or nil
end

local function specialVar(ctx, id)
  local v = tonumber(flagsMod().getVar(nil, ctx, id)) or 0
  if v == 0 and ctx and type(ctx.getVar) == "function" then
    v = tonumber(ctx:getVar(id)) or 0
  end
  return v
end

local function frameType(sess)
  local ok, Options = pcall(require, "src.core.game3.options")
  if not ok or not (Options and Options.block) then return 0 end
  local okB, block = pcall(Options.block, sess and sess.options)
  return okB and type(block) == "table" and tonumber(block.frameType) or 0
end

local function openClock(ctx, adapters, mode, onConfirmed)
  local Natives = require("src.core.game3.scripting.natives")
  local WallClock = require("src.ui.game3.rse.wall_clock")
  local sess = session()
  return Natives.yieldHost(ctx, adapters, function(done)
    -- pokeemerald/src/wallclock.c:665
    local okClr, FadeClr = pcall(require, "src.ui.game3.fade")
    if okClr and FadeClr and FadeClr.clear then FadeClr.clear() end
    WallClock.open({
      mode = mode,
      gender = specialVar(ctx, VAR_0x8004),
      session = sess,
      frameType = frameType(sess),
      onDone = function(result)
        if onConfirmed and result and result.confirmed then onConfirmed(sess) end
        local okF, Fade = pcall(require, "src.ui.game3.fade")
        if okF and Fade and Fade.begin and Fade.MODE then
          Fade.clear()
          Fade.begin(Fade.MODE.FROM_BLACK, 1)
        end
        done()
      end,
    })
  end)
end

Clock.BY_NAME = {
  -- pokeemerald/src/clock.c:82
  StartWallClock = function(ctx, adapters)
    return openClock(ctx, adapters, "set", function(sess)
      -- pokeemerald/src/clock.c:76
      require("src.core.game3.time_events").init(sess)
    end)
  end,
  -- pokeemerald/src/field_specials.c:147
  Special_ViewWallClock = function(ctx, adapters)
    return openClock(ctx, adapters, "view")
  end,
}
Std.legacyHandlers(Clock)

return Clock
