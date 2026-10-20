local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local bit = require("bit")
local M = {SUB = "rse/trade", FILES = {"menu.gfx", "menu.map", "party_box.map", "moves_box.map", "mon_box.map",
  "menu_bg1.png", "stripes_bg2.png", "stripes_bg3.png", "party_box.png", "moves_box.png", "mon_box.png", "menu_tiles.png",
  "cursor.png", "gba.png", "shadow.png", "cable.png", "ball_symbol.png", "gba_affine.png", "scene_textbox.png",
  "ball.png", "glow.png", "glow2.png", "glow2_base.png", "glow2_color4.png", "cable_end.png", "gba_screen.png"}}
M.REQUIRED = K.required(M.SUB, M.FILES)
local windowFields = {"bgNum", "charBaseBlock", "screenBaseBlock", "priority", "paletteNum", "foregroundColor", "backgroundColor",
  "shadowColor", "fontNum", "textMode", "spacing", "tilemapLeft", "tilemapTop", "width", "height"}
local function window(c, name)
  local out, off = {}, c:off(name)
  for i, field in ipairs(windowFields) do out[field] = c:u8(off + i - 1) end
  return out
end
local function words(raw)
  local out = {}
  for i = 1, #raw, 2 do out[#out + 1] = raw:byte(i) + raw:byte(i + 1) * 256 end
  return out
end
local function packed(words)
  local out = {}
  for _, value in ipairs(words) do out[#out + 1] = string.char(value % 256, math.floor(value / 256)) end
  return table.concat(out)
end
local function textAt(c, off, key)
  local bytes = {}
  for i = 0, 1023 do
    local b = c:u8(off + i); bytes[#bytes + 1] = b
    if b == 255 then return {key = key, bytes = bytes, text = A.text(c, off)} end
  end
  error("native trade text is unterminated")
end
local menuKeys = {"TradeText_Cancel", "TradeText_ChoosePoke", "TradeText_Summary1", "TradeText_Trade1",
  "TradeText_CancelTradePrompt", "TradeText_PressBToExit"}
local messageKeys = {"TradeText_LinkStandby", "TradeText_TradeCancelled", "TradeText_OnlyPoke", "TradeText_NonTradablePoke",
  "TradeText_WaitingForFriend", "TradeText_WantToTrade"}
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local man = {screen = "trade", layers = {}, sprites = {}, palettes = {}, maps = {}, menuTexts = {}, messages = {}, actions = {},
    texts = {}, windows = {}, wireless = false, coverage = "native_cable_art_menu_tables_and_scene_metadata"}
  local gfx, pal = c:raw("gUnknown_08EA0348", 0x1280), c:pal("gUnknown_08EA02C8", 48)
  man.gfx = c:write("menu.gfx", gfx)
  man.palettes.menu, man.palettes.text = K.palList(pal, 0, 48), K.palList(c:pal("TradeScreenTextPalette", 16), 0, 16)
  local maps = {{"menu", "gUnknown_08EA15C8", 32, 32, false, "menu_bg1", 30, 20},
    {"stripes_bg2", "gTradeStripesBG2Tilemap", 32, 32, false, "stripes_bg2", 32, 20},
    {"stripes_bg3", "gTradeStripesBG3Tilemap", 32, 32, false, "stripes_bg3", 32, 20},
    {"party_box", "gTradePartyBoxTilemap", 15, 17, true, "party_box", 15, 17},
    {"moves_box", "gTradeMovesBoxTilemap", 15, 17, true, "moves_box", 15, 17},
    {"mon_box", "gTradeMonBoxTilemap", 6, 3, true, "mon_box", 6, 3}}
  for _, spec in ipairs(maps) do
    local raw = c:raw(spec[2], spec[3] * spec[4] * 2)
    man.maps[spec[1]] = {words = words(raw), width = spec[3], height = spec[4], linear = spec[5]}
    if spec[1] ~= "stripes_bg2" and spec[1] ~= "stripes_bg3" then man.maps[spec[1]].path = c:write(spec[1] .. ".map", raw) end
    local idx, w, h = K.bakeText(gfx, raw, spec[7], spec[8], {linear = spec[5], mapWidth = spec[3]})
    man.layers[spec[6]] = c:layer({key = spec[6], opaque = spec[1] == "stripes_bg3"}, idx, w, h, pal)
  end
  man.layers.stripes_bg3.backdrop = pal[0]
  local atlas = {}; for i = 0, 159 do atlas[#atlas + 1] = i < 148 and i or 0x3FF end
  local ai, aw, ah = K.bakeText(gfx, packed(atlas), 16, 10, {linear = true, mapWidth = 16})
  man.layers.menu_tiles = c:layer({key = "menu_tiles"}, ai, aw, ah, pal)
  man.layers.menu_tiles.columns, man.layers.menu_tiles.count = 16, 148
  man.sprites.cursor = c:spriteFrames("cursor", c:raw("gUnknown_08EA1DEC", 0x800),
    c:readTemplate("gSpriteTemplate_820C134"), c:pal("gUnknown_08EA0328", 16))
  man.textSprite = c:readTemplate("gSpriteTemplate_820C0EC")
  man.windows.menu, man.windows.spriteText, man.windows.measureName = window(c, "gWindowTemplate_81E6F84"),
    window(c, "gWindowTemplate_81E725C"), window(c, "gWindowTemplate_81E7294")
  man.windows.actions = window(c, "gMenuTextWindowTemplate")
  man.windows.sceneLink, man.windows.sceneNpc = man.windows.menu, window(c, "gWindowTemplate_81E717C")
  man.palettes.font = K.palList(c:pal("gFontDefaultPalette", 16), 0, 16)
  man.coords = {mon = A.pairs(c, "gTradeMonSpriteCoords"), level = A.pairs(c, "gTradeLevelDisplayCoords"),
    box = A.pairs(c, "gTradeMonBoxCoords"), owner = A.pairs(c, "gTradeUnknownSpriteCoords"),
    selectedText = A.pairs(c, "gUnknown_0820C334"), selectedBox = A.pairs(c, "gUnknown_0820C3D1"),
    sideRects = A.pairs(c, "gUnknown_0820C330")}
  local nav = c:off("gTradeNextSelectedMonTable")
  man.navigation = {}
  for slot = 0, 12 do
    man.navigation[slot] = {}
    for dir = 0, 3 do
      local list = {}; for i = 0, 5 do list[i + 1] = c:u8(nav + (slot * 4 + dir) * 6 + i) end
      man.navigation[slot][dir + 1] = list
    end
  end
  for _, spec in ipairs({{"gUnknown_0820C14C", menuKeys, man.menuTexts}, {"gUnknown_0820C2F0", messageKeys, man.messages}}) do
    local off = c:off(spec[1])
    for i, key in ipairs(spec[2]) do spec[3][i] = textAt(c, assert(c:ptr(off + (i - 1) * 4)), key) end
  end
  local ro, ao = c:off("gTradeMessageWindowRects"), c:off("gUnknown_0820C320")
  for i = 0, 5 do
    man.messages[i + 1].rect = {c:u8(ro + i * 4), c:u8(ro + i * 4 + 1), c:u8(ro + i * 4 + 2), c:u8(ro + i * 4 + 3)}
  end
  for i, key in ipairs({"TradeText_Summary2", "TradeText_Trade2"}) do
    local off = ao + (i - 1) * 8
    man.actions[i] = textAt(c, assert(c:ptr(off)), key)
    man.actions[i].callback = c.S.funcAt(c:u32(off + 4))
  end
  for _, key in ipairs({"gTradeText_TradeOkayPrompt", "gOtherText_FourQuestions", "gTradeText_WillBeSent", "gTradeText_ByeBye",
    "gTradeText_SentOverPoke", "gTradeText_TakeGoodCare", "gOtherText_LinkStandby2", "gSystemText_Saving", "OtherText_Yes", "OtherText_No", "gOtherText_PLink"}) do
    man.texts[key] = textAt(c, c:off(key), key)
  end
  man.geometry = {iconOffset = {14, -12}, cursorOffset = {32, 0}, cancelCursor = {224, 160}, nicknameWidth = 50,
    nicknameFont = 4, selectedNicknameWidth = 64, actionFrame = {18, 14, 28, 19}, actionOrigin = {19, 15}, actionCursorWidth = 9,
    yesNoFrame = {24, 14, 29, 19}, yesNoOrigin = {25, 15}, yesNoCursorWidth = 4,
    cancelTextCenters = {{214, 152}, {246, 152}}, chooseTextCenters = {{24, 150}, {56, 150}, {88, 150}, {120, 150}, {152, 150}}}
  man.timing = {confirmDelayGreaterThan = 120, selectedMoveFrames = 20, stripesBg2Step = 1, stripesBg3Step = -1}
  man.sceneTiming = {monSlideStart = 180, monSlideStep = 3, byeByeDelay = 80, receivedFanfareAt = 4, takeGoodCareAt = 240}
  man.sceneTextOrigin = {2, 15}
  man.songs = {menu = "MUS_SCHOOL", scene = "MUS_EVOLUTION", received = "MUS_EVOLVED"}
  man.cableClub = {countRect = {18, 10, 28, 13}, countOrigin = {19, 11}, countWidth = 72, countText = "gOtherText_PLink", minCount = 2}
  local sp = c:pal("gUnknown_0820C9F8", 80, nil, 16); sp[0] = 0
  man.palettes.scene = K.palList(sp, 0, 256)
  local sg = c:raw("gUnknown_0820CA98", 0x1300)
  for _, spec in ipairs({{"gba", "gUnknown_08210798", 32, 64}, {"shadow", "gUnknown_0820F798", 64, 32},
    {"cable", "gUnknown_08211798", 32, 32}}) do
    local idx, w, h = K.bakeText(sg, c:raw(spec[2], spec[3] * spec[4] * 2), spec[3], spec[4])
    man.layers[spec[1]] = c:layer({key = spec[1]}, idx, w, h, sp)
  end
  for _, spec in ipairs({{"ball_symbol", "gUnknown_0820DD98", 0x1A00, "gUnknown_08211F98"},
    {"gba_affine", "gUnknown_08213738", 0x2040, "gUnknown_08215778"}}) do
    local idx, w, h = K.bakeAffine(c:raw(spec[2], spec[3]), c:raw(spec[4], 0x100), 16)
    man.layers[spec[1]] = c:layer({key = spec[1]}, idx, w, h, sp)
  end
  local textbox = words(c:raw("gBattleTextboxTilemap", 0x500))
  for i = 1, #textbox do textbox[i] = bit.bor(textbox[i], 0x7000) end
  local tp = c:pal("gBattleTextboxPalette", 16, nil, 112, true); tp[0] = 0
  local ti, tw, th = K.bakeText(c:lz("gBattleTextboxTiles"), packed(textbox), 30, 20)
  man.layers.scene_textbox = c:layer({key = "scene_textbox", opaque = true}, ti, tw, th, tp)
  man.palettes.sceneTextbox = K.palList(tp, 0, 128)
  for _, spec in ipairs({{"ball", "gTradeBallTiles", "gSpriteTemplate_821595C", "gTradeBallPalette"},
    {"glow", "gTradeGlow1Tiles", "gSpriteTemplate_82159BC", "gTradeGlowPalette"},
    {"glow2", "gTradeGlow2Tiles", "gSpriteTemplate_82159FC", "gTradeGlowPalette"},
    {"cable_end", "gTradeCableEndTiles", "gSpriteTemplate_8215A30", "gTradeCableEndPalette"},
    {"gba_screen", "gTradeGBAScreenTiles", "gSpriteTemplate_8215A80", "gTradeCableEndPalette"}}) do
    local p = c:pal(spec[4], 16)
    man.sprites[spec[1]] = c:spriteFrames(spec[1], c:raw(spec[2]), c:readTemplate(spec[3]), p)
    man.palettes[spec[1]] = K.palList(p, 0, 16)
  end
  man.sprites.ball.affineAnims = {A.affine(c, "gSpriteAffineAnim_8215900"), A.affine(c, "gSpriteAffineAnim_8215910"), A.affine(c, "gSpriteAffineAnim_8215920")}
  man.sprites.glow.affineAnims = {A.affine(c, "gSpriteAffineAnim_8215988")}
  man.monMirror = A.affine(c, "gSpriteAffineAnim_8215AB0")
  man.glow2Colors = words(c:raw("gTradeGlow2PaletteAnimTable"))
  local glow, frames = man.sprites.glow2, {}
  local glowGfx = c:raw("gTradeGlow2Tiles")
  for i, tile in ipairs(glow.tiles) do frames[i] = K.bakeSprite(glowGfx, glow.w, glow.h, tile, glow.bpp) end
  local gi, gw, gh = K.stack(frames, glow.w, glow.h)
  glow.color4Mask = c:mask("glow2_color4.png", gw, gh, gi, {[4] = true})
  for i = 1, #gi do if gi[i] == 4 then gi[i] = 0 end end
  glow.base = c:png("glow2_base.png", gw, gh, gi, c:pal("gTradeGlowPalette", 16), true)
  glow.paletteAnimation = {index = 4, colors = man.glow2Colors, incrementBeforeRead = true, wrap = 12, disabledWhenData1Nonzero = true}
  man.sceneBackgrounds = {
    [0] = {layer = "shadow", mode = 0, bg = 2, priority = 2, scroll = {180, 0}},
    [1] = {layer = "gba", mode = 1, bg = 1, priority = 2, scroll = {0, 348}},
    [2] = {layer = "cable", mode = 1, bg = 1, priority = 2, scroll = {0, 0}},
    [3] = {layer = "ball_symbol", mode = 0, reference = {64, 64}, center = {120, -70}, rotation = 0},
    [4] = {layer = "gba_affine", mode = 1, bg = 2, priority = 3, reference = {64, 92}, scale = {32, 32}, storedUnusedYScale = 1024, rotation = 0},
    [5] = {layer = "scene_textbox", bg = 1, priority = 2, scroll = {0, 0}, eraseTextRect = {2, 15, 27, 18}},
    [6] = {layer = "gba_affine", mode = 1, bg = 2, priority = 3, reference = {64, 92}, scale = {256, 256}, storedUnusedYScale = 128, center = {120, 80}, rotation = 0},
    [7] = {layer = "shadow", bg = 2, priority = 2, scroll = {0, 0}}}
  return A.finish(c, man)
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
