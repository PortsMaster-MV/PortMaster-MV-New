local R = require("src.core.game3.rse.init")
local SB = require("src.core.game3.rse.secret_base")
local N = {BY_NAME = {}}
local function delegate(name)
  return function(...) return require("src.core.game3.scripting.natives_secret_base").BY_NAME[name](...) end
end
local aliases = {
  sub_80BB8CC = "SetPlayerSecretBase", CheckPlayerHasSecretBase = "CheckPlayerHasSecretBase",
  sub_80BBAF0 = "EnterSecretBase", sub_80BC440 = "ClearAndLeaveSecretBase", MoveOutOfSecretBase = "MoveOutOfSecretBase",
  sub_80BC114 = "IsCurSecretBaseOwnedByAnotherPlayer", GetCurSecretBaseRegistrationValidity = "GetCurSecretBaseRegistrationValidity",
  ToggleCurSecretBaseRegistry = "ToggleCurSecretBaseRegistry", sub_80FF474 = "SetDecoration",
  sub_80BB70C = "GetSecretBaseTypeInFrontOfPlayer", SetSecretBaseOwnerGfxId = "SetSecretBaseOwnerGfxId",
  sub_8100A7C = "PutAwayDecorationIteration", sub_80BBC78 = "EnterNewlyCreatedSecretBase",
  DoSecretBasePCTurnOffEffect = "DoSecretBasePCTurnOffEffect", GetSecretBaseNearbyMapName = "GetSecretBaseNearbyMapName",
  BufferSecretBaseOwnerName = "CopyCurSecretBaseOwnerName_StrVar1", MoveSecretBase = "MoveOutOfSecretBaseFromOutside",
}
for native, shared in pairs(aliases) do N.BY_NAME[native] = delegate(shared) end
N.BY_NAME.SecretBasePC_Decoration = function()
  require("src.ui.game3.rs.decoration").open({isPlayerRoom = false}); return false
end
N.BY_NAME.SecretBasePC_Registry = function()
  require("src.ui.game3.rs.decoration").openRegistry({}); return false
end
N.BY_NAME.GetShieldToyTVDecorationInfo = function(ctx, adapters)
  -- fldeff_decoration.c:334
  local x, y = SB.frontOfPlayer()
  local mid = SB.fieldGrid().metatile(x, y)
  local function str(i, value)
    ctx.stringVars = ctx.stringVars or {}; ctx.stringVars[i] = value
    if adapters and adapters.setStringVar then adapters.setStringVar(i, value) end
  end
  if mid == 822 or mid == 734 then
    str(1, mid == 822 and "100" or "50")
    str(2, require("src.core.game3.rom_text").plain(mid == 822 and "gSecretBaseText_GoldRank" or "gSecretBaseText_SilverRank"))
    R.setSpecialVar(ctx, 0x800D, 0)
  elseif mid >= 756 and mid <= 758 then R.setSpecialVar(ctx, 0x800D, mid - 755) end
  return false
end
return N
