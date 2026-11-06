local Rse = require("src.core.game3.rse.init")

local Tutor = {}

-- pokeemerald/src/field_specials.c:3030,3064
local function group(which)
  return require("src.ui.game3.rse.frontier_preview").ids(which == 2 and "tutor2" or "tutor1")
end
Tutor.group = group

local function varId(name)
  return Rse.varId(name, Rse.session())
end

local function selectedMove(ctx)
  local tutor = Rse.var("VAR_TEMP_FRONTIER_TUTOR_ID") ~= 0 and 2 or 1
  local selection = Rse.var("VAR_TEMP_FRONTIER_TUTOR_SELECTION")
  return group(tutor)[selection + 1]
end

local function setString(ctx, adapters, value)
  local name = require("src.core.game3.pokemon").moveName(value) or ""
  if adapters and adapters.setStringVar then adapters.setStringVar(1, name) end
  if ctx and ctx.stringVars then ctx.stringVars[1] = name end
end

-- pokeemerald/src/field_specials.c:3087
function Tutor.bufferMoveName(ctx, adapters)
  local which = Rse.specialVar(ctx, varId("VAR_0x8005")) ~= 0 and 2 or 1
  local index = Rse.specialVar(ctx, varId("VAR_0x8004")) + 1
  local id = group(which)[index]
  if id then setString(ctx, adapters, id) end
  return false
end

-- pokeemerald/src/field_specials.c:3188
function Tutor.getMoveIndex(ctx)
  local selected = selectedMove(ctx)
  local MoveLearn = require("src.core.game3.move_learn")
  local moves = MoveLearn.tutorMoves()
  local index = 0
  if selected and moves then
    for i = 0, MoveLearn.tutorMoveCount() - 1 do
      if moves[i] == nil then break end
      if tonumber(moves[i]) == selected then index = i; break end
    end
  end
  Rse.setSpecialVar(ctx, varId("VAR_0x8005"), index)
  return false
end

Tutor.BY_NAME = {
  -- pokeemerald/src/field_specials.c:3161
  CloseBattleFrontierTutorWindow = function()
    require("src.ui.game3.screens").get("frontier_preview", Rse.session()).tutorOpen = false
    return false
  end,
  BufferBattleFrontierTutorMoveName = Tutor.bufferMoveName,
  GetBattleFrontierTutorMoveIndex = Tutor.getMoveIndex,
}

return Tutor
