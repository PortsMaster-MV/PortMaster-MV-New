return {
  fonts = require("src.core.game3.profiles.emerald.font"),
  screens = {
    frontier_preview = "src.ui.game3.rse.frontier_preview",
    option = "src.ui.game3.rse.option_menu",
    -- pokeemerald/src/start_menu.c:639
    pokedex = "src.ui.game3.rse.pokedex",
    -- pokeemerald/src/start_menu.c:685
    pokenav = "src.ui.game3.rse.pokenav.init",
    -- pokeemerald/src/item_use.c:628
    pokeblock_case = "src.ui.game3.rse.pokeblock_case",
    -- pokeemerald/src/item_menu.c:1967
    berry_tag = "src.ui.game3.rse.berry_tag",
    -- pokeemerald/src/slot_machine.c:1025
    slot_machine = "src.ui.game3.rse.slot_machine",
    -- pokeemerald/src/roulette.c:3464
    roulette = "src.ui.game3.rse.roulette",
    -- pokeemerald/src/berry_blender.c:1047
    berry_blender = "src.ui.game3.rse.berry_blender",
    -- pokeemerald/src/start_menu.c:711
    frontier_pass = "src.ui.game3.rse.frontier_pass",
    -- pokeemerald/src/battle_factory_screen.c:1108
    factory_select = "src.ui.game3.rse.factory_select",
    -- pokeemerald/src/battle_factory_screen.c:3267
    factory_swap = "src.ui.game3.rse.factory_swap",
    -- pokeemerald/src/start_menu.c:794
    pyramid_bag = "src.ui.game3.rse.pyramid_bag",
    -- pokeemerald/src/start_menu.c:778
    retire_frontier = "src.ui.game3.rse.pyramid_retire",
    -- pokeemerald/src/battle_records.c:465
    trainer_hill_records = "src.ui.game3.rse.trainer_hill_records",
    -- pokeemerald/src/battle_dome.c:5661
    dome_tourney = "src.ui.game3.rse.dome_tourney",
  },
  skins = {
    bag = "src.ui.game3.rse.bag_menu",
    summary = "src.ui.game3.rse.summary_menu",
  },
  -- pokeemerald/src/start_menu.c:182
  startMenu = "src.ui.game3.rse.start_menu_data",
  -- pokeemerald/src/start_menu.c:1332
  saveMenu = "rse",
  -- pokeemerald/src/battle_bg.c:282
  levelUpBox = { x = 19, y = 8, w = 10, h = 11, pitch = 15 },
  -- pokeemerald/src/trainer_card.c:764
  trainerCard = { cardType = "emerald" },
  -- pokeemerald/src/data/party_menu.h:598
  party = {
    manifest = "rse/menus",
    text = {
      boostPp = "gText_BoostPP",
      -- pokeemerald/src/menu_specialized.c:1503
      levelUpStats = { "gText_MaxHP", "gText_Attack", "gText_Defense", "gText_SpAtk", "gText_SpDef", "gText_Speed" },
    },
    -- pokeemerald/src/data/party_menu.h:658
    cursorOptionTexts = {
      "gText_Summary5", "gText_Switch2", "gText_Cancel2", "gText_Item", "gMenuText_Give", "gText_Take",
      "gText_Mail", "gText_Take2", "gText_Read2", "gText_Cancel2", "gText_Shift", "gText_SendOut",
      "gText_Enter", "gText_NoEntry", "gText_Store", "gText_Register", "gText_Trade4", "gText_Trade4",
      "gMenuText_Toss",
    },
    -- pokeemerald/src/party_menu.c:2101
    buttons = { cancel = "gText_Cancel", confirm = "gMenuText_Confirm" },
    -- pokeemerald/src/party_menu.c:2557
    insets = { msgX = 0, msgY = 1, actX = 8, actY = 1, cursorX = 0 },
  },
  -- pokeemerald/src/strings.c:224
  textAliases = {
    gText_4Qmark = "sText_FourQuestionMarks",
    gText_IsThisTradeOkay = "sText_IsThisTradeOkay",
    gText_TradeAction_Summary = "sText_Summary",
    gText_TradeAction_Trade = "sText_Trade",
    gText_Trade_CommunicationStandby = "gText_CommunicationStandby",
    gText_TradeHasBeenCanceled = "sText_TheTradeHasBeenCanceled",
    gText_WaitingForFriendToFinish = "sText_WaitingForYourFriend",
    gText_FriendWantsToTrade = "sText_YourFriendWantsToTrade",
    gText_SavingDontTurnOffThePower2 = "gText_SavingDontTurnOffPower",
    gText_ThreeHyphens = "gText_ThreeDashes",
    gText_ItemCantBeHeld = "gText_Var1CantBeHeld",
    gText_NoRoomToStoreItems = "gText_NoRoomForItems",
    gText_ThereIsNoPokemon = "gText_NoPokemon",
    gText_DepositedStrVar2StrVar1s = "gText_DepositedVar2Var1s",
    gText_PokeSum_Item_None = "gText_None",
    -- pokeemerald/src/move_relearner.c:772
    gText_TeachWhichMoveToMon = "gText_TeachWhichMoveToPkmn",
    gText_TeachMoveQues = "gText_MoveRelearnerTeachMoveConfirm",
    gText_GiveUpTryingToTeachNewMove = "gText_MoveRelearnerGiveUp",
    gFameCheckerText_Cancel = "gText_Cancel",
    gText_MonLearnedMove = "gText_MoveRelearnerPkmnLearnedMove",
    gText_1_2_and_Poof = "gText_MoveRelearnerAndPoof",
    gText_StopLearningMove = "gText_MoveRelearnerStopTryingToTeachMove",
    gText_MonIsTryingToLearnMove = "gText_MoveRelearnerPkmnTryingToLearnMove",
    gText_WhichMoveShouldBeForgotten = "gText_MoveRelearnerWhichMoveToForget",
    gText_MonForgotOldMoveAndMonLearnedNewMove = "gText_MoveRelearnerPkmnForgotMoveAndLearnedNew",
  },
  -- pokeemerald/src/berry_powder.c:223
  berryPowderBox = { left = 1, top = 1, width = 7, height = 4, title = "gText_Powder", titleX = 0, titleY = 1,
    amountX = 26, amountY = 17 },
  -- pokeemerald/src/field_specials.c:1678
  elevatorWindow = { left = 21, top = 1, width = 8, height = 4, nowOn = "gText_ElevatorNowOn", center = 64,
    titleY = 1, labelY = 17 },
  -- pokeemerald/src/item_menu.c:930
  sounds = { bagCursor = "SE_SELECT", bagPocket = "SE_SELECT" },
  frames = {
    manifest = "data/generated/gba/chrome/manifest.lua",
    -- pokeemerald/include/text_window.h:4
    userCount = 20,
    user = "data/generated/gba/chrome/user_frame_%d.rgba",
    -- pokeemerald/src/menu.c:213
    std = "user",
    sign = false,
    -- pokeemerald/src/menu.c:319
    dialogue = { path = "data/generated/gba/chrome/message_box.rgba", manifestKey = "message_box", layout = "message_box" },
    -- pokeemerald/src/menu.c:84
    dialogueWindow = { left = 2, top = 15, width = 27, height = 4 },
    -- pokeemerald/src/text.c:787
    arrow = { path = "data/generated/gba/chrome/fonts/down_arrow.rgba", manifestKey = "down_arrow", delay = 8, lastPage = false },
  },
}
