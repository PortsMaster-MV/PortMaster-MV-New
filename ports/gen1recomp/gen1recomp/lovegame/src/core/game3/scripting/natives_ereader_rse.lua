local Rse = require("src.core.game3.rse.init")

local EReader = {}
local VAR_RESULT = "VAR_RESULT"

local function var(name)
  return require("src.core.game3.constants").active(Rse.session()):var(name)
end

local function trainer(session)
  if not session then return nil end
  local frontier = require("src.core.game3.rse.frontier.util").frontier(session)
  local row = frontier.ereaderTrainer
  if type(row) == "table" and next(row) ~= nil then return row end
  local legacy = session.ereaderTrainer
  return type(legacy) == "table" and legacy or nil
end

local function speech(value)
  if type(value) == "string" then return value end
  if type(value) == "table" then
    local Trainers = require("src.core.game3.rse.frontier.trainers")
    local TextIR = require("src.core.game3.scripting.text_ir")
    return TextIR.toPlain(Trainers.speechToString(value), {}) -- pokeemerald/src/battle_tower.c:2931
  end
  return ""
end

local function setString(ctx, adapters, index, value)
  local text = tostring(value or "")
  if adapters and type(adapters.setStringVar) == "function" then pcall(adapters.setStringVar, index, text) end
  if ctx and type(ctx.stringVars) == "table" then ctx.stringVars[index] = text end
end

EReader.BY_NAME = {
  -- pokeemerald/src/battle_tower.c:2884
  ValidateEReaderTrainer = function(ctx)
    local row = trainer(Rse.session())
    local party = row and row.party
    local hasParty = type(party) == "table" and type(party[1]) == "table"
    -- pokeemerald/src/battle_tower.c:2884
    local valid = hasParty and row.valid ~= false and row.checksumValid ~= false
    local result = valid and 0 or 1
    Rse.setSpecialVar(ctx, var(VAR_RESULT), result)
    return false, result
  end,

  -- pokeemerald/src/battle_tower.c:2931
  CopyEReaderTrainerGreeting = function(ctx, adapters)
    local row = trainer(Rse.session())
    setString(ctx, adapters, 4, speech(row and row.greeting))
    return false
  end,

  -- pokeemerald/src/field_specials.c:1284
  BufferEReaderTrainerName = function(ctx, adapters)
    local row = trainer(Rse.session())
    setString(ctx, adapters, 1, row and row.name or "")
    return false
  end,

  -- pokeemerald/src/battle_tower.c:1253
  SetEReaderTrainerGfxId = function()
    local session = Rse.session()
    if not session then return false end
    local row = trainer(session)
    local Trainers = require("src.core.game3.rse.frontier.trainers")
    local gfx = Trainers.facilityClassToGfx(row and tonumber(row.facilityClass))
    Rse.setVar("VAR_OBJ_GFX_ID_0", gfx, session)
    return false
  end,
}

return EReader
