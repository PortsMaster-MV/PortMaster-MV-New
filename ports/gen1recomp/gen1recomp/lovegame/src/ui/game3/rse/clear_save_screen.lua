local Kit = require("src.ui.game3.rse.scene_kit")
local Pal = require("src.core.game3.pal_fade")

local ClearSave = {}
ClearSave.__index = ClearSave

-- pokeemerald/src/clear_save_data_screen.c:47
local WIN_TEXT = { left = 3, top = 15, width = 26, height = 4 }
local YESNO = { left = 3, top = 2 }
-- pokeemerald/src/clear_save_data_screen.c:150
local BG_COLOR = 5 + 10 * 32 + 14 * 1024

local function defaultClear()
  local SaveData = require("src.core.SaveData")
  local GameVersion = require("src.core.GameVersion")
  local version = GameVersion.get()
  local slot = SaveData.activeSlot and SaveData.activeSlot(version) or nil
  if slot and SaveData.deleteSlot then return SaveData.deleteSlot(version, slot) end
  return false
end

function ClearSave.new(opts, ctx)
  if Kit.isBootState(opts) then opts = {} end
  opts = opts or {}
  local self = setmetatable({
    pal = Pal.new(),
    step = Kit.stepper(),
    state = "setup",
    clear = opts.clearSave or defaultClear,
    frameType = tonumber(opts.frameType) or 0,
  }, ClearSave)
  self.pal:blend(Pal.BG, 16, Pal.WHITE)
  self.pal:beginFade(Pal.BG, 0, 16, 0, Pal.WHITE)
  return self
end

function ClearSave:frame(inp)
  local st = self.state
  if st == "setup" then
    if not self.pal:fadeActive() then self.state = "ask" end
  elseif st == "ask" then
    -- pokeemerald/src/clear_save_data_screen.c:18
    self.printer = Kit.printer("gText_ClearAllSaveData", { speed = 0 })
    self.yesNo = Kit.yesNo(YESNO.left, YESNO.top, { frameType = self.frameType, initial = 1 })
    self.state = "choice"
  elseif st == "choice" then
    local r = self.yesNo:input(inp)
    if r == 0 then
      Kit.playSe("SE_SELECT")
      self.yesNo = nil
      self.printer = Kit.printer("gText_ClearingData", { speed = 0 })
      self.state = "clearing"
    elseif r == 1 or r == -1 then
      Kit.playSe("SE_SELECT")
      self.yesNo = nil
      self.state = "reset"
    end
  elseif st == "clearing" then
    -- pokeemerald/src/clear_save_data_screen.c:20
    self.cleared = true
    pcall(self.clear)
    self.state = "reset"
  elseif st == "reset" then
    -- pokeemerald/src/clear_save_data_screen.c:22
    self.pal:beginFade(Pal.BG, 0, 0, 16, Pal.WHITE)
    self.state = "resetting"
  elseif st == "resetting" then
    if not self.pal:fadeActive() then
      self.pal:updateFade()
      return "intro"
    end
  end
  self.pal:updateFade()
  return nil
end

function ClearSave:update(input, dt)
  self.step:collect(input)
  return self.step:run(dt, function(inp) return self:frame(inp) end)
end

function ClearSave:draw()
  local c = Kit.color555(BG_COLOR)
  love.graphics.clear(c[1], c[2], c[3], 1)
  if self.printer then
    local colors = Kit.messageColors("std_menu")
    Kit.userFrame(WIN_TEXT.left, WIN_TEXT.top, WIN_TEXT.width, WIN_TEXT.height, self.frameType, colors.bg)
    self.printer:draw(WIN_TEXT.left * 8, WIN_TEXT.top * 8 + 1, { colors = colors })
  end
  if self.yesNo then self.yesNo:draw() end
  Kit.drawFade(self.pal, 0)
end

return ClearSave
