local Anim = require("src.core.game3.battle.anim")
local SummaryData = require("src.core.game3.summary_data")

local ShinySeq = {}

function ShinySeq.isShiny(battler)
  local mon = battler and battler.mon
  return mon ~= nil and SummaryData.isShiny(mon) == true
end

function ShinySeq.startMany(battlers, keys, onDone)
  local shinyKeys = {}
  for i, battler in ipairs(battlers or {}) do
    if ShinySeq.isShiny(battler) then
      shinyKeys[#shinyKeys + 1] = (keys and keys[i]) or i - 1
    end
  end
  if #shinyKeys == 0 then return false end
  Anim.launchShiny(shinyKeys[1], { keys = shinyKeys, onEnd = onDone })
  return true
end

function ShinySeq.start(battler, key, onDone)
  return ShinySeq.startMany({ battler }, { key }, onDone)
end

return ShinySeq
