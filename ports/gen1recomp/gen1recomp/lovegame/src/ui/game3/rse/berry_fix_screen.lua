local Kit = require("src.ui.game3.rse.scene_kit")
local RomText = require("src.core.game3.rom_text")
local FrlgFont = require("src.ui.game3.frlg_font")

local BerryFix = {}
BerryFix.__index = BerryFix

-- pokeemerald/src/berry_fix_program.c:125
local SCENE_TEXT = {
  begin = "sText_BerryProgramWillBeUpdatedPressA",
  connect = "sText_EnsureGBAConnectionMatches",
  turn_off = "sText_TurnOffPowerHoldingStartSelect",
  transmitting = "sText_TransmittingPleaseWait",
  follow = "sText_PleaseFollowInstructionsOnScreen",
  failed = "sText_TransmissionFailureTryAgain",
}
BerryFix.SCENE_TEXT = SCENE_TEXT

function BerryFix.new()
  return setmetatable({ state = "begin", step = Kit.stepper() }, BerryFix)
end

-- pokeemerald/src/berry_fix_program.c:212
function BerryFix:frame(inp)
  local st = self.state
  if inp.new.b then return "intro" end
  if st == "begin" then
    if inp.new.a then self.state = "connect" end
  elseif st == "connect" then
    if inp.new.a then self.state = "turn_off" end
  elseif st == "failed" then
    if inp.new.a then self.state = "begin" end
  end
  return nil
end

function BerryFix:update(input, dt)
  self.step:collect(input)
  return self.step:run(dt, function(inp) return self:frame(inp) end)
end

function BerryFix:draw()
  love.graphics.clear(0, 0, 0, 1)
  local colors = FrlgFont.COLOR.WHITE
  local title = RomText.plain("sText_BerryProgramUpdate")
  FrlgFont.draw(title, math.floor((240 - FrlgFont.measure(title)) / 2), 8, { colors = colors })
  local text = RomText.plain(SCENE_TEXT[self.state] or SCENE_TEXT.begin)
  local y = 48
  for line in (text .. "\n"):gmatch("(.-)\n") do
    if line ~= "" then
      FrlgFont.draw(line, 16, y, { colors = colors })
      y = y + 16
    end
  end
  FrlgFont.draw(RomText.plain("gText_MenuExit"), 16, 136, { colors = colors })
end

return BerryFix
