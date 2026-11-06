return function(V)
  local sym = V.sym

  -- pokeemerald/src/data/trade.h:624
  V.TRADE_POKEBALL_PAL = sym("trade.o:sPokeball_Pal")
  V.TRADE_POKEBALL_GFX = sym("trade.o:sPokeball_Gfx")
  V.TRADE_CABLE_CLOSEUP_MAP = sym("trade.o:sCableCloseup_Map")
  V.TRADE_GBA_PAL = sym("trade.o:sGba_Pal")
  V.TRADE_LINK_MON_PAL = sym("trade.o:sLinkMon_Pal")
  V.TRADE_LINK_MON_GLOW_GFX = sym("trade.o:sLinkMonGlow_Gfx")
  V.TRADE_LINK_MON_SHADOW_GFX = sym("trade.o:sLinkMonShadow_Gfx")
  V.TRADE_CABLE_END_GFX = sym("trade.o:sCableEnd_Gfx")
  V.TRADE_GBA_SCREEN_GFX = sym("trade.o:sGbaScreen_Gfx")
  V.TRADE_GBA_MAP_WIRELESS = sym("trade.o:sGbaMapWireless")
  V.TRADE_GBA_MAP_CABLE = sym("trade.o:sGbaMapCable")
  -- pokeemerald/src/trade.c:3178
  V.TRADE_MON_SHADOW_MAP = sym("gTradePlatform_Tilemap")
  -- pokeemerald/src/data/trade.h:907
  V.TRADE_GBA_SCREEN_ANIM = sym("trade.o:sAnim_GbaScreen_Long")
  -- pokeemerald/src/data/trade.h:27
  V.TRADE_MOVES_BOX_MAP = sym("trade.o:sTradeMovesBoxTilemap")
  V.TRADE_PARTY_BOX_MAP = sym("trade.o:sTradePartyBoxTilemap")
  V.TRADE_STRIPES_BG2_MAP = sym("trade.o:sTradeStripesBG2Tilemap")
  V.TRADE_STRIPES_BG3_MAP = sym("trade.o:sTradeStripesBG3Tilemap")
  -- pokeemerald/src/graphics.c:1457
  V.TRADE_GBA_GFX = sym("gTradeGba_Gfx")
  V.TRADE_GBA_PAL2 = sym("gTradeGba2_Pal")
  V.TRADE_MENU_PAL = sym("gTradeMenu_Pal")
  V.TRADE_CURSOR_PAL = sym("gTradeCursor_Pal")
  V.TRADE_MENU_GFX = sym("gTradeMenu_Gfx")
  V.TRADE_CURSOR_GFX = sym("gTradeCursor_Gfx")
  V.TRADE_MENU_MAP = sym("gTradeMenu_Tilemap")
  V.TRADE_MENU_MON_BOX_MAP = sym("gTradeMenuMonBox_Tilemap")

  -- pokeemerald/src/link_rfu_3.c:37
  V.WIRELESS_ICON_PAL = sym("link_rfu_3.o:sWirelessLinkIconPalette")
  V.WIRELESS_ICON_GFX = sym("link_rfu_3.o:sWirelessLinkIconPic")
  -- pokeemerald/src/wireless_communication_status_screen.c:64
  V.WIRELESS_STATUS_PALS = sym("wireless_communication_status_screen.o:sPalettes")
  V.WIRELESS_STATUS_GFX = sym("wireless_communication_status_screen.o:sBgTiles_Gfx")
  V.WIRELESS_STATUS_TILEMAP = sym("wireless_communication_status_screen.o:sBgTiles_Tilemap")
  -- pokeemerald/src/wireless_communication_status_screen.c:264
  V.WIRELESS_STATUS_LAYOUT = { title_y = 6, label_x = 24, label_y = 8, row_step = 30, count_x = 204, total_y = 98 }
  -- pokeemerald/src/graphics.c:1422, pokeemerald/src/union_room_chat.c:754
  V.UR_CHAT_BG_PAL = sym("gUnionRoomChat_Background_Pal")
  V.UR_CHAT_BG_GFX = sym("gUnionRoomChat_Background_Gfx")
  V.UR_CHAT_BG_TILEMAP = sym("gUnionRoomChat_Background_Tilemap")
  V.UR_CHAT_ICONS_GFX = sym("gUnionRoomChat_RButtonLabels")
  V.UR_CHAT_PANEL_PAL = sym("gUnionRoomChat_Keyboard_Pal")
  V.UR_CHAT_PANEL_GFX = sym("gUnionRoomChat_Keyboard_Gfx")
  V.UR_CHAT_PANEL_TILEMAP = sym("gUnionRoomChat_Keyboard_Tilemap")
  V.UR_CHAT_OBJECTS_PAL = sym("union_room_chat.o:sUnionRoomChatInterfacePal")
  V.UR_CHAT_SELECTOR_GFX = sym("union_room_chat.o:sKeyboardCursorTiles")
  V.UR_CHAT_TEXT_CURSOR_GFX = sym("union_room_chat.o:sTextEntryCursorTiles")
  V.UR_CHAT_CHAR_CURSOR_GFX = sym("union_room_chat.o:sTextEntryArrowTiles")
  V.UR_CHAT_R_BUTTON_GFX = sym("union_room_chat.o:sRButtonGfxTiles")
  -- pokeemerald/src/union_room_player_avatar.c:28
  V.UR_OBJ_GFX_IDS = sym("union_room_player_avatar.o:sUnionRoomObjGfxIds")
  V.UR_PLAYER_COORDS = sym("union_room_player_avatar.o:sUnionRoomPlayerCoords")
  V.UR_GROUP_OFFSETS = sym("union_room_player_avatar.o:sUnionRoomGroupOffsets")
  V.UR_OPPOSITE_FACING = sym("union_room_player_avatar.o:sOppositeFacingDirection")
  V.UR_MEMBER_FACING = sym("union_room_player_avatar.o:sMemberFacingDirections")
  -- pokeemerald/src/pokemon.c:1897
  V.UNION_ROOM_FACILITY_CLASSES = sym("gUnionRoomFacilityClasses")
  V.UNION_ROOM_CLASS_COUNT = V.count("gUnionRoomFacilityClasses", 2)

  -- pokeemerald/src/graphics.c:1379, pokeemerald/src/trainer_card.c:171
  V.TRAINER_CARD_BG_TILES = sym("gKantoTrainerCard_Gfx")
  V.TRAINER_CARD_FRONT_MAP = sym("gKantoTrainerCardFront_Tilemap")
  V.TRAINER_CARD_BG_MAP = sym("gKantoTrainerCardBg_Tilemap")
  V.TRAINER_CARD_BACK_MAP = sym("gKantoTrainerCardBack_Tilemap")
  V.TRAINER_CARD_FRONT_LINK_MAP = sym("gKantoTrainerCardFrontLink_Tilemap")
  V.TRAINER_CARD_PAL = sym("gKantoTrainerCardBlue_Pal")
  V.TRAINER_CARD_GREEN_PAL = sym("trainer_card.o:sKantoTrainerCardGreen_Pal")
  V.TRAINER_CARD_BRONZE_PAL = sym("trainer_card.o:sKantoTrainerCardBronze_Pal")
  V.TRAINER_CARD_SILVER_PAL = sym("trainer_card.o:sKantoTrainerCardSilver_Pal")
  V.TRAINER_CARD_GOLD_PAL = sym("trainer_card.o:sKantoTrainerCardGold_Pal")
  V.TRAINER_CARD_FEMALE_PAL = sym("trainer_card.o:sKantoTrainerCardFemaleBg_Pal")
  V.TRAINER_CARD_BADGES_PAL = sym("trainer_card.o:sKantoTrainerCardBadges_Pal")
  V.TRAINER_CARD_BADGES_TILES = sym("trainer_card.o:sKantoTrainerCardBadges_Gfx")
  V.TRAINER_CARD_STAR_PAL = sym("trainer_card.o:sTrainerCardStar_Pal")
  V.TRAINER_CARD_STICKERS_TILES = sym("trainer_card.o:sTrainerCardStickers_Gfx")
  V.TRAINER_CARD_STICKER_PAL1 = sym("trainer_card.o:sTrainerCardSticker1_Pal")
  V.TRAINER_CARD_STICKER_PAL2 = sym("trainer_card.o:sTrainerCardSticker2_Pal")
  V.TRAINER_CARD_STICKER_PAL3 = sym("trainer_card.o:sTrainerCardSticker3_Pal")
  V.TRAINER_CARD_STICKER_PAL4 = sym("trainer_card.o:sTrainerCardSticker4_Pal")
  -- pokeemerald/src/trainer_card.c:1507
  V.TRAINER_CARD_STAR_TILE = 143
  -- pokeemerald/src/trainer_card.c:301
  V.TRAINER_CARD_PIC_CLASSES = { male = 0x4E, female = 0x4F }
  V.HOENN_CARD_PIC_CLASSES = { male = 0x3C, female = 0x3F }
end
