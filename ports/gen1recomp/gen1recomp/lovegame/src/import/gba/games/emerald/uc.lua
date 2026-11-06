return function(V)
  local sym, count = V.sym, V.count
  local size = require("src.import.gba.syms").of("emerald").size
  local PSS = "pokemon_storage_system.o:"

  -- pokeemerald/src/pokemon_storage_system.c:3850
  V.STORAGE_PALETTES = {
    misc1 = sym(PSS .. "sHandCursor_Pal"),
    misc2 = sym(PSS .. "sWaveform_Pal"),
    menu = sym(PSS .. "sDisplayMenu_Pal"),
    scrollingBg = sym(PSS .. "sScrollingBg_Pal"),
    interface = sym(PSS .. "sInterface_Pal"),
    partyMenu = sym("gStorageSystemPartyMenu_Pal"),
    interfaceNoMon = sym(PSS .. "sPkmnDataGray_Pal"),
  }
  -- pokeemerald/src/pokemon_storage_system.c:3831
  V.STORAGE_BG1_BASE_TILE = 0x100
  V.STORAGE_SHEETS = {
    handCursor = { off = sym(PSS .. "sHandCursor_Gfx"), size = size(PSS .. "sHandCursor_Gfx") },
    handCursorShadow = { off = sym(PSS .. "sHandCursorShadow_Gfx"), size = size(PSS .. "sHandCursorShadow_Gfx") },
    boxScrollArrow = { off = sym(PSS .. "sArrow_Gfx"), size = size(PSS .. "sArrow_Gfx") },
    waveform = { off = sym(PSS .. "sWaveform_Gfx"), size = size(PSS .. "sWaveform_Gfx") },
    scrollingBg = { off = sym(PSS .. "sScrollingBg_Gfx"), lz = true },
    menu = { off = sym("gStorageSystemMenu_Gfx"), lz = true },
  }
  V.STORAGE_TILEMAPS = {
    menu = { off = sym(PSS .. "sDisplayMenu_Tilemap"), lz = true, w = 32, h = 20 },
    pkmnData = { off = sym(PSS .. "sPkmnData_Tilemap"), w = 8, h = 4 },
    closeBoxButton = { off = sym(PSS .. "sCloseBoxButton_Tilemap"), w = 9, h = 4 },
    partySlotFilled = { off = sym(PSS .. "sPartySlotFilled_Tilemap"), w = 4, h = 3 },
    partySlotEmpty = { off = sym(PSS .. "sPartySlotEmpty_Tilemap"), w = 4, h = 3 },
    partyMenu = { off = sym("gStorageSystemPartyMenu_Tilemap"), lz = true, w = 12, h = 22 },
  }
  -- pokeemerald/src/pokemon_storage_system.c:5376
  V.STORAGE_WALLPAPERS = sym(PSS .. "sWallpapers")
  V.STORAGE_WALLPAPER_COUNT = count(PSS .. "sWallpapers", 12)
  V.STORAGE_WALLPAPER_W = 20
  V.STORAGE_WALLPAPER_H = 18
  -- pokeemerald/include/constants/pokemon.h:283
  V.STORAGE_WALLPAPER_NAMES = {
    "forest", "city", "desert", "savanna",
    "crag", "volcano", "snow", "cave",
    "beach", "seafloor", "river", "sky",
    "polkadot", "pokecenter", "machine", "simple",
  }
  -- pokeemerald/src/pokemon_storage_system.c:5390
  V.STORAGE_FRIENDS = {
    patterns = sym(PSS .. "sWaldaWallpapers"),
    patternCount = count(PSS .. "sWaldaWallpapers", 12),
    icons = sym(PSS .. "sWaldaWallpaperIcons"),
    iconCount = count(PSS .. "sWaldaWallpaperIcons", 4),
  }

  -- pokeemerald/src/data/easy_chat/easy_chat_groups.h:26
  V.EASY_CHAT_GROUPS = sym("gEasyChatGroups")
  V.EASY_CHAT_GROUP_COUNT = count("gEasyChatGroups", 8)
  -- pokeemerald/src/easy_chat.c:1204
  V.EASY_CHAT_GROUP_NAMES = sym("easy_chat.o:sEasyChatGroupNamePointers")
  -- pokeemerald/src/easy_chat.c:428
  V.EASY_CHAT_TEMPLATES = {
    off = sym("easy_chat.o:sEasyChatScreenTemplates"),
    count = count("easy_chat.o:sEasyChatScreenTemplates", 24),
    frames = sym("easy_chat.o:sPhraseFrameDimensions"),
    frameCount = count("easy_chat.o:sPhraseFrameDimensions", 4),
  }

  -- pokeemerald/src/hall_of_fame.c:331
  V.HALL_OF_FAME = {
    pal = sym("hall_of_fame.o:sHallOfFame_Pal"),
    gfx = sym("hall_of_fame.o:sHallOfFame_Gfx"),
    confetti_sheet = sym("gConfetti_Gfx"),
    confetti_pal = sym("gConfetti_Pal"),
    confetti_frames = 17,
  }

  -- pokeemerald/src/shop.c:742
  V.SHOP_MENU = {
    gfx = sym("gShopMenu_Gfx"),
    pal = sym("gShopMenu_Pal"),
    tilemap = sym("gShopMenu_Tilemap"),
    -- pokeemerald/src/money.c:59
    moneyLabel = sym("gShopMenuMoney_Gfx"),
  }

  -- pokeemerald/src/mail.c:118
  V.MAIL_GRAPHICS = sym("mail.o:sMailGraphics")
  V.MAIL_GRAPHICS_COUNT = count("mail.o:sMailGraphics", 20)
  -- pokeemerald/src/mail.c:405
  V.MAIL_LAYOUTS_TALL = sym("mail.o:sMailLayouts_Tall")
  -- pokeemerald/src/mail.c:112
  V.MAIL_BG_COLORS = sym("mail.o:sBgColors")

  -- pokeemerald/src/data/decoration/header.h:1
  V.DECORATIONS = {
    table = sym("gDecorations"),
    stride = 32,
    count = count("gDecorations", 32),
    categoryNames = sym("decoration.o:sDecorationCategoryNames"),
    categoryCount = count("decoration.o:sDecorationCategoryNames", 4),
    icons = sym("gDecorIconTable"),
  }

  -- pokeemerald/src/data/credits.h:385
  V.CREDITS_RSE = {
    pages = sym("credits.o:sCreditsEntryPointerTable"),
    entriesPerPage = 5,
    pageCount = count("credits.o:sCreditsEntryPointerTable", 5 * 4),
    palette = sym("credits.o:sCredits_Pal"),
    theEndGfx = sym("credits.o:sCreditsCopyrightEnd_Gfx"),
    letterT = sym("credits.o:sTheEnd_LetterMap_T"),
    letterH = sym("credits.o:sTheEnd_LetterMap_H"),
    letterE = sym("credits.o:sTheEnd_LetterMap_E"),
    letterN = sym("credits.o:sTheEnd_LetterMap_N"),
    letterD = sym("credits.o:sTheEnd_LetterMap_D"),
    copyrightPal = sym("gIntroCopyright_Pal"),
    grassGfx = sym("gBirchBagGrass_Gfx"),
    grassMap = sym("gBirchGrassTilemap"),
    grassPal = sym("gBirchBagGrass_Pal"),
    animsPlayer = sym("credits.o:sAnims_Player"),
    animsPlayerCount = count("credits.o:sAnims_Player", 4),
    animsRival = sym("credits.o:sAnims_Rival"),
    animsRivalCount = count("credits.o:sAnims_Rival", 4),
    monSpritePos = sym("credits.o:sMonSpritePos"),
    monSpritePosCount = count("credits.o:sMonSpritePos", 2),
  }
end
