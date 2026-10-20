local RomText = require("src.core.game3.rom_text")

local MGText = {}

MGText.ALIASES = {
  rse = {
    -- pokeemerald/src/berry_crush.c:405
    gText_BerryCrush_AreYouReady = "gText_ReadyPickBerry",
    gText_BerryCrush_WaitForOthersToChooseBerry = "gText_WaitForAllChooseBerry",
    gText_BerryCrush_GainedXUnitsOfPowder = "gText_EndedWithXUnitsPowder",
    gText_BerryCrush_RecordingGameResults = "gText_RecordingGameResults",
    gText_BerryCrush_WantToPlayAgain = "gText_PlayBerryCrushAgain",
    gText_BerryCrush_NoBerries = "gText_YouHaveNoBerries",
    gText_BerryCrush_MemberDroppedOut = "gText_MemberDroppedOut",
    gText_BerryCrush_TimeUp = "gText_TimesUpNoGoodPowder",
    gText_BerryCrush_CommunicationStandby = "gText_CommunicationStandby2",
    -- pokeemerald/src/berry_crush.c:3240
    gText_SavingDontTurnOffThePower2 = "gText_SavingDontTurnOffPower",
    -- pokeemerald/src/berry_crush.c:910
    gText_StrVar1Berry = "gText_Var1Berry",
    gText_CooperativeRankings = "gText_CoopRankings",
    -- pokeemerald/src/berry_crush.c:1653
    gText_1_ClrBluShdwLtBlu_Dynamic0 = "gText_1DotBlueF700",
    gText_1_Dynamic0 = "gText_1DotF700",
    -- pokeemerald/src/data/union_room.h:2
    gText_UR_Colon = "sText_Colon",
    gText_UR_ID = "sText_ID",
    gText_UR_AwaitingCommunication = "sText_AwaitingCommunication",
    gText_UR_AwaitingLinkPressStart = "sText_AwaitingLinkPressStart",
    gText_UR_BButtonCancel = "sText_BButtonCancel",
    gText_UR_ChooseJoinCancel = "sText_ChooseJoinCancel",
    gTexts_UR_PlayersNeededOrMode = "sPlayersNeededOrModeTexts",
    gTexts_UR_ChooseTrainer = "sChooseTrainerTexts",
  },
}

local function family()
  local ok, fam = pcall(function() return require("src.core.game3.profile").family() end)
  return ok and fam or "frlg"
end

function MGText.map(key)
  if type(key) ~= "string" then return key end
  local map = MGText.ALIASES[family()]
  if not map then return key end
  if map[key] then return map[key] end
  local name, rest = key:match("^([%w_]+)(%[.*)$")
  if name and map[name] then return map[name] .. rest end
  return key
end

function MGText.name(name)
  local map = MGText.ALIASES[family()]
  return map and map[name] or name
end

local KEYED = { "ir", "has", "box", "plain", "ascii" }
for _, fn in ipairs(KEYED) do
  MGText[fn] = function(key, ...) return RomText[fn](MGText.map(key), ...) end
end

function MGText.translate(ir, ctx, key)
  return RomText.translate(ir, ctx, MGText.map(key))
end

function MGText.at(name, i, j, ctx)
  return RomText.at(MGText.name(name), i, j, ctx)
end

function MGText.list(name, ctx)
  return RomText.list(MGText.name(name), ctx)
end

function MGText.count(name)
  return RomText.count(MGText.name(name))
end

return setmetatable(MGText, { __index = RomText })
