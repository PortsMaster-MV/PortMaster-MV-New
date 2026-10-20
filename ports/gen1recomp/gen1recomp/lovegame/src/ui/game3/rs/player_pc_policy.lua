local M = {}
function M.matches(session)
  local id = require("src.core.game3.profile").forSession(session).id
  return id == "ruby" or id == "sapphire"
end
-- pokeruby/src/player_pc.c:102
M.storageDescriptions = "gPCText_OptionDescList"
-- pokeruby/src/player_pc.c:110
-- pokeruby/src/strings.c:469
M.aliases = {
  gText_LanettesPC = "gPCText_LanettesPC", gText_SomeonesPC = "gPCText_SomeonesPC",
  gText_PlayersPC = "gPCText_PlayersPC", gText_HallOfFame = "gPCText_HallOfFame", gText_LogOff = "gPCText_LogOff",
  gText_ItemStorage = "SecretBaseText_ItemStorage", gText_Mailbox = "gPCText_Mailbox",
  gText_Decoration = "SecretBaseText_Decoration", gText_TurnOff = "SecretBaseText_TurnOff",
  gText_WhatWouldYouLike = "gOtherText_WhatWillYouDo", gText_WhatWouldYouLikeToDo = "gOtherText_WhatWillYouDo",
  gText_WithdrawItem = "PCText_WithdrawItem", gText_DepositItem = "PCText_DepositItem", gText_TossItem = "PCText_TossItem",
  gText_NoMailHere = "gOtherText_NoMailHere", gText_NoItems = "gOtherText_NoItems",
  gText_GoBackPrevMenu = "gMenuText_GoBackToPrev",
  gText_WithdrawXItems = "gOtherText_WithdrewThing", gText_NoRoomInBag = "gOtherText_NoMoreRoom",
  gText_TooImportantToToss = "gOtherText_TooImportant", gText_ConfirmTossItems = "gOtherText_OkayToThrowAwayPrompt",
  gText_TossHowManyVar1s = "gOtherText_HowManyToToss", gText_WithdrawHowManyItems = "gOtherText_HowManyToWithdraw",
  gText_MoveVar1Where = "gOtherText_SwitchWhichItem", gText_ThrewAwayVar2Var1s = "gOtherText_ThrewAwayItem",
  gText_Cancel2 = "gOtherText_CancelNoTerminator", gText_xVar1 = "gOtherText_xString1",
  gText_Yes = "OtherText_Yes", gText_No = "OtherText_No",
  gText_BagIsFull = "gOtherText_BagIsFull", gText_MailToBagMessageErased = "gOtherText_MailWasReturned",
  gText_NoPokemon = "gOtherText_NoPokemon", gText_MessageWillBeLost = "gOtherText_MessageWillBeLost",
  gText_WhatToDoWithVar1sMail = "gOtherText_WhatWillYouDoMail",
}
return M
