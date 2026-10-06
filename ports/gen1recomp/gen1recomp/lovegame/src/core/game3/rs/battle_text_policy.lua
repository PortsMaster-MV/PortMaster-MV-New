local M = {}

M.aliases = {
  gText_Yes = "OtherText_Yes",
  gText_No = "OtherText_No",
  gText_BattleYesNoChoice = "BattleText_YesNo",
  gText_BattleMenu = "BattleText_MenuOptions",
  gText_SafariZoneMenu = "BattleText_MenuOptionsSafari",
  gText_WhatWillPkmnDo = "BattleText_OtherMenu",
  gText_WhatWillWallyDo = "BattleText_WallyMenu",
  gText_BattleSwitchWhich = "BattleText_SwitchWhich",
  gText_MoveInterfacePP = { key = "BattleText_PP", line = 1 },
  gText_MoveInterfaceType = { key = "BattleText_PP", line = 2 },
  gText_SafariBalls = "BattleText_SafariBalls",
  gText_Sleep = "BattleText_Sleep",
  gText_Poison = "BattleText_PoisonStatus",
  gText_Burn = "BattleText_Burn",
  gText_Paralysis = "BattleText_Paralysis",
  gText_Ice = "BattleText_IceStatus",
  gText_Confusion = "BattleText_Confusion",
  gText_Love = "BattleText_Love",
  sText_WildPkmnAppeared = "BattleText_WildAppeared1",
  sText_WildPkmnAppeared2 = "BattleText_WildAppeared2",
  sText_WildPkmnAppearedPause = "BattleText_WildAppeared3",
  sText_TwoWildPkmnAppeared = "BattleText_WildDoubleAppeared",
  sText_Trainer1WantsToBattle = "BattleText_SingleWantToBattle1",
  sText_LinkTrainerWantsToBattle = "BattleText_SingleWantToBattle2",
  sText_TwoLinkTrainersWantToBattle = "BattleText_DoubleWantToBattle",
  sText_Trainer1SentOutPkmn = "BattleText_SentOutSingle1",
  sText_Trainer1SentOutTwoPkmn = "BattleText_SentOutDouble1",
  sText_Trainer1SentOutPkmn2 = "BattleText_SentOutSingle2",
  sText_LinkTrainerSentOutPkmn = "BattleText_SentOutSingle3",
  sText_LinkTrainerSentOutTwoPkmn = "BattleText_SentOutDouble2",
  sText_TwoLinkTrainersSentOutPkmn = "BattleText_SentOutDouble3",
  sText_LinkTrainerSentOutPkmn2 = "BattleText_SentOutSingle4",
  sText_LinkTrainerMultiSentOutPkmn = "BattleText_SentOutSingle5",
  sText_GoPkmn = "BattleText_SentOutSingle6",
  sText_GoTwoPkmn = "BattleText_SentOutDouble4",
  sText_GoPkmn2 = "BattleText_SentOutSingle7",
  sText_DoItPkmn = "BattleText_SentOutSingle8",
  sText_GoForItPkmn = "BattleText_SentOutSingle9",
  sText_YourFoesWeakGetEmPkmn = "BattleText_SentOutSingle10",
  sText_LinkPartnerSentOutPkmnGoPkmn = "BattleText_SentOutSingle11",
  sText_PkmnThatsEnough = "BattleText_ComeBackSingle1",
  sText_PkmnComeBack = "BattleText_ComeBackSingle2",
  sText_PkmnOkComeBack = "BattleText_ComeBackSingle3",
  sText_PkmnGoodComeBack = "BattleText_ComeBackSingle4",
  sText_Trainer1WithdrewPkmn = "BattleText_WithdrewPoke1",
  sText_LinkTrainer1WithdrewPkmn = "BattleText_WithdrewPoke2",
  sText_LinkTrainer2WithdrewPkmn = "BattleText_WithdrewPoke3",
  sText_WildPkmnPrefix = "BattleText_Wild",
  sText_FoePkmnPrefix = "BattleText_Foe",
  sText_FoePkmnPrefix2 = "BattleText_Foe2",
  sText_AllyPkmnPrefix = "BattleText_Ally",
  sText_FoePkmnPrefix3 = "BattleText_Foe3",
  sText_AllyPkmnPrefix2 = "BattleText_Ally2",
  sText_FoePkmnPrefix4 = "BattleText_Foe4",
  sText_AllyPkmnPrefix3 = "BattleText_Ally3",
  sText_AttackerUsedX = "BattleText_OpponentUsedMove",
  sText_ExclamationMark = "BattleText_Exclamation",
  sText_GotAwaySafely = "BattleText_GotAwaySafely",
  sText_WildFled = "BattleText_FledSingle",
  sText_TwoWildFled = "BattleText_FledDouble",
  sText_PlayerDefeatedLinkTrainer = "BattleText_PlayerDefeatedTrainer",
  sText_TwoLinkTrainersDefeated = "BattleText_PlayerDefeatedTrainers",
  sText_PlayerLostAgainstLinkTrainer = "BattleText_PlayerLostTrainer",
  sText_PlayerLostToTwo = "BattleText_PlayerLostTrainers",
  sText_PlayerBattledToDrawLinkTrainer = "BattleText_PlayerTiedTrainer",
  sText_PlayerBattledToDrawVsTwo = "BattleText_PlayerTiedTrainers",
  sText_Lanettes = "BattleText_Lanette",
  sText_Someones = "BattleText_Someone",
  STRINGID_YOUTHROWABALLNOWRIGHT = "BattleText_WallyBall",
  STRINGID_GOTCHAPKMNCAUGHTWALLY = "BattleText_BallCaught2",
  -- pokeruby/src/data/battle_strings_en.h:603
  STRINGID_STATSHARPLY = "BattleText_Sharply",
  STRINGID_STATROSE = "BattleText_Rose",
  STRINGID_STATHARSHLY = "BattleText_Harshly",
  STRINGID_STATFELL = "BattleText_Fell",
  STRINGID_ATTACKERSSTATROSE = "BattleText_UnknownString7",
  STRINGID_DEFENDERSSTATROSE = "BattleText_UnknownString3",
  STRINGID_ATTACKERSSTATFELL = "BattleText_UnknownString5",
  STRINGID_DEFENDERSSTATFELL = "BattleText_UnknownString6",
  STRINGID_USINGITEMSTATOFPKMNROSE = "BattleText_UnknownString4",
  STRINGID_STATSWONTINCREASE = "BattleText_AttackingStatNoHigher",
  STRINGID_STATSWONTDECREASE = "BattleText_DefendingStatNoHigher",
  STRINGID_STATSWONTINCREASE2 = "BattleText_StatNoHigher",
  STRINGID_STATSWONTDECREASE2 = "BattleText_StatNoLower",
  STRINGID_PKMNPROTECTEDBYMIST = "BattleText_MistProtect",
  STRINGID_PKMNPREVENTSSTATLOSSWITH = "BattleText_PreventedStatLoss",
  STRINGID_PKMNSXPREVENTSYLOSS = "BattleText_PreventedLoss",
  STRINGID_PKMNCUTSATTACKWITH = "BattleText_CutsAttack",
  STRINGID_PKMNCOPIEDSTATCHANGES = "BattleText_CopyStatChanges",
  STRINGID_STATCHANGESGONE = "BattleText_StatElim",
  STRINGID_PKMNUSEDXTOGETPUMPED = "BattleText_HustleUse",
  STRINGID_PKMNGETTINGPUMPED = "BattleText_GetPumped",
  STRINGID_PKMNSHROUDEDINMIST = "BattleText_MistShroud",
}

-- pokeruby/src/data/battle_strings_en.h:844
-- pokeruby/src/battle_message.c:917
for i = 0, 7 do
  M.aliases["gStatNamesTable[" .. i .. "]"] = "gUnknown_08400F58[" .. i .. "]"
end

for i = 0, 17 do
  M.aliases["sATypeMove_Table[" .. i .. "]"] = "gUnknown_08401674[" .. i .. "]"
end

function M.matches()
  local id = require("src.core.game3.profile").forSession().id
  return id == "ruby" or id == "sapphire"
end

function M.resolvers(common, rse)
  local out = { [0] = common[0], [1] = common[1] }
  for code = 0x02, 0x21 do out[code] = common[code + 3] end
  out[0x22] = common[0x26]
  for code = 0x23, 0x29 do out[code] = rse[code + 4] end
  out[0x2A] = common[0x30]
  return out
end

return M
