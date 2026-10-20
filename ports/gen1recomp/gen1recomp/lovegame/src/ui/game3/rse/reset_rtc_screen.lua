local Kit = require("src.ui.game3.rse.scene_kit")
local Rtc = require("src.core.game3.rtc")
local RomText = require("src.core.game3.rom_text")
local FrlgFont = require("src.ui.game3.frlg_font")
local Constants = require("src.core.game3.constants")
local Pal = require("src.core.game3.pal_fade")

local ResetRtc = {}
ResetRtc.__index = ResetRtc

-- pokeemerald/src/reset_rtc_screen.c:44
local SEL = { DAYS = 1, HOURS = 2, MINS = 3, SECS = 4, CONFIRM = 5, NONE = 6 }
ResetRtc.SELECTION = SEL
-- pokeemerald/src/reset_rtc_screen.c:118
local INPUT_MAP = {
  [SEL.DAYS] = { key = "days", min = 1, max = 9999, left = 0, right = 2 },
  [SEL.HOURS] = { key = "hours", min = 0, max = 23, left = 1, right = 3 },
  [SEL.MINS] = { key = "minutes", min = 0, max = 59, left = 2, right = 4 },
  [SEL.SECS] = { key = "seconds", min = 0, max = 59, left = 3, right = 5 },
  [SEL.CONFIRM] = { key = "confirm", min = 0, max = 0, left = 4, right = 0 },
}
ResetRtc.INPUT_MAP = INPUT_MAP
-- pokeemerald/src/reset_rtc_screen.c:85
local WIN_TIME = { left = 1, top = 1, width = 19, height = 9 }
local WIN_MSG = { left = 2, top = 15, width = 27, height = 4 }
local WIN_INPUT = { left = 4, top = 9, width = 21, height = 2 }
-- pokeemerald/src/reset_rtc_screen.c:239
local CURSOR_X = { [SEL.DAYS] = 53, [SEL.HOURS] = 86, [SEL.MINS] = 101, [SEL.SECS] = 116, [SEL.CONFIRM] = 153 }

-- pokeemerald/src/reset_rtc_screen.c:218
local ARROW = { DOWN = 1, UP = 2, RIGHT = 3 }

-- pokeemerald/src/reset_rtc_screen.c:194
local function drawArrow(anim, cx, cy)
  local man = Kit.manifest("reset_rtc")
  local spr = man and man.sprites and man.sprites.arrow
  local img = spr and Kit.image(spr.png)
  local cmd = spr and spr.anims[anim] and spr.anims[anim][1]
  if not (img and cmd) then return end
  local w, h = spr.w, spr.h
  local quad = love.graphics.newQuad(0, cmd.frame * h, w, h, img:getDimensions())
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(img, quad, cx - w / 2, cy - h / 2 + (cmd.vFlip and h or 0), 0, 1, cmd.vFlip and -1 or 1)
end

-- pokeemerald/src/event_data.c:156
function ResetRtc.canReset(store, version)
  local C = Constants.of(version or "emerald")
  local Flags = require("src.core.game3.scripting.flags")
  return Flags.getFlag(store, nil, C:require("flags", "FLAG_SYS_RESET_RTC_ENABLE"))
    and Flags.getVar(store, nil, C:require("vars", "VAR_RESET_RTC_ENABLE")) == 0x920
end

-- pokeemerald/src/reset_rtc_screen.c:400
function ResetRtc.moveTimeUpDown(t, key, minVal, maxVal, keys)
  local v = t[key]
  if keys.down then
    v = v - 1
    if v < minVal then v = maxVal end
  elseif keys.up then
    v = v + 1
    if v > maxVal then v = minVal end
  elseif keys.left then
    v = v - 10
    if v < minVal then v = maxVal end
  elseif keys.right then
    v = v + 10
    if v > maxVal then v = minVal end
  else
    return false
  end
  t[key] = v
  return true
end

-- pokeemerald/src/reset_rtc_screen.c:366
function ResetRtc.formatTime(days, hours, minutes, seconds)
  return string.format("%4d", days) .. RomText.plain("gText_Day")
    .. string.format("%3d", hours) .. RomText.plain("gText_Colon3")
    .. string.format("%02d", minutes) .. RomText.plain("gText_Colon3")
    .. string.format("%02d", seconds)
end

function ResetRtc.canResetRtc(state)
  local raw = Kit.loadRawSave()
  if not raw then return false end
  local store = { flags = raw.flags or {}, vars = raw.vars or {} }
  return ResetRtc.canReset(store, require("src.core.GameVersion").get()) == true
end

function ResetRtc.new(opts, ctx)
  if Kit.isBootState(opts) then
    local raw = Kit.loadRawSave()
    opts = {
      save = raw,
      saveStatus = raw and "ok" or "empty",
      version = require("src.core.GameVersion").get(),
      writeSave = function(save)
        local SaveData = require("src.core.SaveData")
        return SaveData.save(save)
      end,
    }
  end
  opts = opts or {}
  local self = setmetatable({
    save = opts.save,
    saveStatus = opts.saveStatus or "ok",
    writeSave = opts.writeSave,
    version = opts.version or "emerald",
    pal = Pal.new(),
    step = Kit.stepper(),
    state = "fade_in",
    frameType = tonumber(opts.frameType) or 0,
  }, ResetRtc)
  return self
end

function ResetRtc:message(key)
  self.msg = Kit.printer(key, { speed = 0 })
end

function ResetRtc:frame(inp)
  local st = self.state
  local result
  if st == "fade_in" then
    -- pokeemerald/src/reset_rtc_screen.c:649
    self.pal:blend(Pal.ALL, 16, Pal.WHITE)
    self.pal:beginFade(Pal.ALL, 1, 16, 0, Pal.WHITE)
    self.state = "check_save"
  elseif st == "check_save" then
    if not self.pal:fadeActive() then
      if type(self.save) ~= "table" or self.saveStatus == "empty" or self.saveStatus == "invalid" then
        self:message("gText_NoSaveFileCantSetTime")
        self.state = "wait_exit"
      else
        self.present = Rtc.calcLocalTime(self.save)
        self.prompt = true
        self:message("gText_ResetRTCConfirmCancel")
        self.state = "prompt"
      end
    end
  elseif st == "prompt" then
    -- pokeemerald/src/reset_rtc_screen.c:577
    if inp.new.b then
      result = "intro"
    elseif inp.new.a then
      Kit.playSe("SE_SELECT")
      self.prompt = nil
      self.state = "start_set_time"
    end
  elseif st == "start_set_time" then
    -- pokeemerald/src/reset_rtc_screen.c:670
    self:message("gText_PleaseResetTime")
    local last = Rtc.copyTime(self.save.lastBerryTreeUpdate)
    self.input = { days = last.days, hours = last.hours, minutes = last.minutes, seconds = last.seconds }
    self.selection = SEL.HOURS
    self.state = "set_time"
  elseif st == "set_time" then
    -- pokeemerald/src/reset_rtc_screen.c:448
    local info = INPUT_MAP[self.selection]
    if inp.new.b then
      Kit.playSe("SE_SELECT")
      self.selection = SEL.NONE
      self.input = nil
      self.state = "start_set_time"
    elseif inp.new.right and info.right ~= 0 then
      self.selection = info.right
      Kit.playSe("SE_SELECT")
    elseif inp.new.left and info.left ~= 0 then
      self.selection = info.left
      Kit.playSe("SE_SELECT")
    elseif self.selection == SEL.CONFIRM then
      if inp.new.a then
        Kit.playSe("SE_SELECT")
        self.chosen = Rtc.newTime(self.input.days, self.input.hours, self.input.minutes, self.input.seconds)
        self.selection = SEL.NONE
        self.input = nil
        self.state = "apply"
      end
    else
      local rep = inp.rep or inp.new
      if ResetRtc.moveTimeUpDown(self.input, info.key, info.min, info.max, { up = rep.up, down = rep.down }) then
        Kit.playSe("SE_SELECT")
      end
    end
  elseif st == "apply" then
    -- pokeemerald/src/reset_rtc_screen.c:695
    local lt = self.chosen
    Rtc.calcLocalTimeOffset(self.save, lt.days, lt.hours, lt.minutes, lt.seconds)
    self.save.lastBerryTreeUpdate = Rtc.copyTime(lt)
    local C = Constants.of(self.version)
    local Flags = require("src.core.game3.scripting.flags")
    local store = { flags = self.save.flags or {}, vars = self.save.vars or {} }
    self.save.flags, self.save.vars = store.flags, store.vars
    Flags.setVar(store, nil, C:require("vars", "VAR_DAYS"), lt.days)
    -- pokeemerald/src/event_data.c:144
    Flags.setVar(store, nil, C:require("vars", "VAR_RESET_RTC_ENABLE"), 0)
    Flags.setFlag(store, nil, C:require("flags", "FLAG_SYS_RESET_RTC_ENABLE"), false)
    self:message("gText_ClockHasBeenReset")
    self.state = "save"
  elseif st == "save" then
    local ok = false
    if self.writeSave then
      local okCall, written = pcall(self.writeSave, self.save)
      ok = okCall and written ~= false
    end
    if ok then
      self:message("gText_SaveCompleted")
      Kit.playSe("SE_DING_DONG")
    else
      self:message("gText_SaveFailed")
      Kit.playSe("SE_BOO")
    end
    self.state = "wait_exit"
  elseif st == "wait_exit" then
    if inp.new.a then
      self.pal:beginFade(Pal.ALL, 1, 0, 16, Pal.WHITE)
      self.state = "exit"
    end
  elseif st == "exit" then
    if not self.pal:fadeActive() then result = "intro" end
  end
  self.pal:updateFade()
  return result
end

function ResetRtc:update(input, dt)
  self.step:collect(input)
  return self.step:run(dt, function(inp) return self:frame(inp) end)
end

function ResetRtc:draw()
  love.graphics.clear(0, 0, 0, 1)
  local colors = Kit.messageColors("std_menu")
  if self.prompt and self.present then
    local w = WIN_TIME
    Kit.userFrame(w.left, w.top, w.width, w.height, self.frameType, colors.bg)
    local x, y = w.left * 8, w.top * 8
    local p, l = self.present, Rtc.copyTime(self.save.lastBerryTreeUpdate)
    FrlgFont.draw(RomText.plain("gText_PresentTime"), x, y + 1, { colors = colors })
    FrlgFont.draw(ResetRtc.formatTime(p.days, p.hours, p.minutes, p.seconds), x, y + 17, { colors = colors })
    FrlgFont.draw(RomText.plain("gText_PreviousTime"), x, y + 33, { colors = colors })
    FrlgFont.draw(ResetRtc.formatTime(l.days, l.hours, l.minutes, l.seconds), x, y + 49, { colors = colors })
  end
  if self.input then
    local w = WIN_INPUT
    Kit.userFrame(w.left, w.top, w.width, w.height, self.frameType, colors.bg)
    local i = self.input
    FrlgFont.draw(ResetRtc.formatTime(i.days, i.hours, i.minutes, i.seconds), w.left * 8, w.top * 8 + 1,
      { colors = colors })
    FrlgFont.draw(RomText.plain("gText_Confirm2"), w.left * 8 + 126, w.top * 8 + 1, { colors = colors })
    local cx = CURSOR_X[self.selection]
    if cx then
      if self.selection == SEL.CONFIRM then
        drawArrow(ARROW.RIGHT, cx, 80)
      else
        drawArrow(ARROW.UP, cx, 68)
        drawArrow(ARROW.DOWN, cx, 92)
      end
    end
  end
  if self.msg then
    local w = WIN_MSG
    Kit.birchDialogueFrame(w.left, w.top, w.width, w.height)
    self.msg:draw(w.left * 8, w.top * 8 + 1, { colors = Kit.messageColors() })
  end
  Kit.drawFade(self.pal, 0)
end

return ResetRtc
