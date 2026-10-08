local Std = require("src.core.game3.scripting.stdscripts")
local Rse = require("src.core.game3.rse.init")
local Town = require("src.core.game3.rse.town_common")
local Lottery = require("src.core.game3.rse.lottery")
require("src.core.game3.rse.daily_events")

local NativesLottery = {}

-- pokeemerald/include/constants/vars.h:287
local VAR_0x8004 = 0x8004
local VAR_0x8005 = 0x8005
local VAR_0x8006 = 0x8006
local VAR_RESULT = 0x800D

local function nickname(mon)
  local Pokemon = require("src.core.game3.pokemon")
  if mon.nickname and mon.nickname ~= "" then return tostring(mon.nickname) end
  return tostring(Pokemon.name(tonumber(mon.species or mon.speciesId) or 0) or "")
end

NativesLottery.BY_NAME = {
  -- pokeemerald/src/lottery_corner.c:42
  RetrieveLotteryNumber = function(ctx)
    local v = Lottery.getNumber() % 0x10000
    Rse.setSpecialVar(ctx, VAR_RESULT, v)
    return false, v
  end,
  -- pokeemerald/src/field_specials.c:1585
  BufferLottoTicketNumber = function(ctx, adapters)
    Town.setString(ctx, adapters, 1, Lottery.ticketString(Rse.specialVar(ctx, VAR_RESULT)))
    return false
  end,
  -- pokeemerald/src/lottery_corner.c:48
  PickLotteryCornerTicket = function(ctx, adapters)
    local r = Lottery.pickTicket(Rse.specialVar(ctx, VAR_RESULT))
    Rse.setSpecialVar(ctx, VAR_0x8004, r.tier)
    if r.tier ~= 0 then
      Rse.setSpecialVar(ctx, VAR_0x8005, r.prize)
      Rse.setSpecialVar(ctx, VAR_0x8006, r.where == "party" and 0 or 1)
      Town.setString(ctx, adapters, 1, nickname(r.mon))
    end
    return false
  end,
  -- pokeemerald/src/field_specials.c:1113
  DoLotteryCornerComputerEffect = function()
    Lottery.startComputerEffect()
    return false
  end,
  -- pokeemerald/src/field_specials.c:1161
  EndLotteryCornerComputerEffect = function()
    Lottery.endComputerEffect()
    return false
  end,
}

Std.legacyHandlers(NativesLottery)

return NativesLottery
