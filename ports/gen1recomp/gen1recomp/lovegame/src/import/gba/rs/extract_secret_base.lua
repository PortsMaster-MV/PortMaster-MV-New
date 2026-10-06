local A = require("src.import.gba.rs.assets")
local K = require("src.import.gba.rse.boot_gfx")
local M = {SUB = "secret_base", FILES = {"put_away_cursor_male.png", "put_away_cursor_female.png", "in_use_red.png", "in_use_blue.png",
  "primary.gfx", "primary.pal", "secondary.metatiles", "secondary.attributes"}, packVersion = 2}
M.REQUIRED = K.required(M.SUB, M.FILES)
local function u8s(c, name)
  local out, off = {}, c:off(name)
  for i = 0, c.S.size(name) - 1 do out[i + 1] = c:u8(off + i) end
  return out
end
local function u16s(c, name)
  local out, off = {}, c:off(name)
  for i = 0, c.S.count(name, 2) - 1 do out[i] = c:u16(off + i * 2) end
  return out
end
local function window(c, name)
  local out, off = {}, c:off(name)
  for i, key in ipairs({"bg", "charbase", "screenbase", "priority", "palette", "foregroundColor",
    "backgroundColor", "shadowColor", "fontNum", "textMode", "spacing", "left", "top", "width", "height"}) do out[key] = c:u8(off + i - 1) end
  return out
end
local function actions(c, name)
  local out, off = {}, c:off(name)
  for i = 0, c.S.count(name, 8) - 1 do
    out[i + 1] = {text = A.text(c, assert(c:ptr(off + i * 8))), callback = c.S.funcAt(c:u32(off + i * 8 + 4))}
  end
  return out
end
function M.run(rom, cache, opts)
  local c = require("src.import.gba.rs.scoped_symbols").bind(A.context(rom, cache, opts, M.SUB))
  local data = require("src.import.gba.rs.decorations_data").read(c)
  local man = {screen = "secret_base", packVersion = M.packVersion, entrances = {}, entranceMetatiles = {},
    ownerGfx = u8s(c, "secret_base.o:sSecretBaseOwnerGfxIds"), decorTiles = data.decorTiles, decorations = data.decorations,
    decorCount = data.count, categoryNames = data.categoryNames, secondaryAttributes = u16s(c, "gMetatileAttributes_SecretBaseSecondary"),
    movement = {}, spriteAssembly = {}, standElevations = u8s(c, "gUnknown_083EC97C"), slideElevations = u8s(c, "gUnknown_083EC984"),
    facilityClasses = u8s(c, "gSecretBaseTrainerClasses"), strings = {}, textBytes = {}, placementArt = {},
    actions = {main = actions(c, "gUnknown_083EC604"), registry = actions(c, "gUnknown_083D13D4")}}
  local eo = c:off("gUnknown_083D1374")
  assert(c.S.size("gUnknown_083D1374") == 96, "native24 secret-base groups")
  for i = 0, 23 do man.entrances[i] = {mapNum = c:u8(eo + i * 4), warpId = c:u8(eo + i * 4 + 1), x = c:u8(eo + i * 4 + 2), y = c:u8(eo + i * 4 + 3)} end
  local mo = c:off("gUnknown_083D1358")
  assert(c.S.size("gUnknown_083D1358") == 28, "native seven entrance pairs")
  for i = 0, 6 do man.entranceMetatiles[i + 1] = {closed = c:u16(mo + i * 4), open = c:u16(mo + i * 4 + 2)} end
  local ao, vo = c:off("gUnknown_083EC860"), c:off("gUnknown_083EC900")
  assert(c.S.size("gUnknown_083EC860") == 160 and c.S.size("gUnknown_083EC900") == 40, "native ten shape descriptors")
  for shape = 0, 9 do
    local b, count = ao + shape * 16, c:u8(ao + shape * 16 + 12)
    local dest, ys, xs = assert(c:ptr(b)), assert(c:ptr(b + 4)), assert(c:ptr(b + 8))
    local row = {tiles = {}, metatiles = {}, subtiles = {}, count = count}
    for j = 0, count - 1 do row.tiles[j + 1], row.metatiles[j + 1], row.subtiles[j + 1] = c:u8(dest + j), c:u8(ys + j), c:u8(xs + j) end
    man.spriteAssembly[shape] = row
    local v = vo + shape * 4
    man.movement[shape] = {shape = c:u8(v), size = c:u8(v + 1), cameraX = c:u8(v + 2), cameraY = c:u8(v + 3)}
  end
  for _, def in ipairs({{"primary.gfx", "gTilesetTiles_SecretBase"}, {"primary.pal", "gTilesetPalettes_SecretBase"},
    {"secondary.metatiles", "gMetatiles_SecretBaseSecondary"}, {"secondary.attributes", "gMetatileAttributes_SecretBaseSecondary"}}) do
    local bytes = c:raw(def[2])
    man.placementArt[def[1]] = {path = c:write(def[1], bytes), bytes = #bytes}
  end
  man.placementArt.primaryTiles = man.placementArt["primary.gfx"]
  man.placementArt.primaryPalettes = man.placementArt["primary.pal"]
  man.placementArt.secondaryMetatiles = man.placementArt["secondary.metatiles"]
  man.placementArt.secondaryAttributes = man.placementArt["secondary.attributes"]
  man.menuPalette = K.palList(c:pal("gUnknownPalette_81E6692", 16), 0, 16)
  man.menuPalette[2], man.menuPalette[9], man.menuPalette[16] = 29596, 25368, 32767
  local cursor = c:raw("gSpriteImage_83EC9DC")
  man.putAwayCursor = c:strip("put_away_cursor", cursor, 16, 16, 1,
    K.variants({{name = "male", pal = c:pal("gUnknown_083EC98C", 16)}, {name = "female", pal = c:pal("Unknown_3EC9AC", 16)}}))
  man.putAwayCursor.template = c:readTemplate("gSpriteTemplate_83ECA88")
  local ip = c:pal("menu_helpers.o:Palette_3E5948", 16)
  man.inUseRed = c:strip("in_use_red", c:raw("menu_helpers.o:gSpriteImage_83E5908"), 8, 8, 1, ip)
  man.inUseBlue = c:strip("in_use_blue", c:raw("menu_helpers.o:gSpriteImage_83E5928"), 8, 8, 1, ip)
  man.inUseTemplate = c:readTemplate("menu_helpers.o:gSpriteTemplate_83E5A00")
  man.yesNoWindow = {left = 21, top = 9, width = 5, height = 4}
  man.window = window(c, "gMenuTextWindowTemplate")
  man.geometry = {mainFrame = {0, 0, 10, 9}, categoryFrame = {0, 0, 14, 19}, category = {8, 8, 16, 9},
    list = {8, 16, 16, 8}, categorySummaryFrame = {15, 0, 29, 3}, descriptionFrame = {15, 12, 29, 19},
    description = {128, 104, 104, 48}, inUseCenters = {108, 24, 16}, arrows = {{60, 8}, {60, 152}},
    registryFrame = {17, 0, 29, 19}, registry = {144, 16, 16, 8}, registryActionsFrame = {1, 0, 12, 5},
    placementAvatar = {193, 194}, putAwayCenter = {120, 80}, putAwayAvatarCenter = {136, 72}}
  for _, symbol in ipairs({"SecretBaseText_Decorate", "SecretBaseText_PutAway", "SecretBaseText_Toss", "gOtherText_Exit",
    "SecretBaseText_PutOutDecor", "SecretBaseText_StoreChosenDecor", "SecretBaseText_ThrowAwayDecor", "gMenuText_GoBackToPrev",
    "SecretBaseText_DelRegist", "gSecretBaseText_NoDecors", "gSecretBaseText_DecorCantPlace", "gSecretBaseText_InUseAlready",
    "gSecretBaseText_NoMoreDecor", "gSecretBaseText_NoMoreDecor2", "gSecretBaseText_CancelDecorating", "gSecretBaseText_PlaceItHere",
    "gSecretBaseText_CantBePlacedHere", "gSecretBaseText_NoDecorInUse", "gSecretBaseText_DecorReturned",
    "gSecretBaseText_StopPuttingAwayDecor", "gSecretBaseText_ReturnDecor", "gSecretBaseText_NoDecor", "gSecretBaseText_WillBeDiscarded",
    "gSecretBaseText_DecorThrownAway", "gSecretBaseText_DecorInUse", "gSecretBaseText_NoRegistry", "gOtherText_OkayToDeleteFromRegistry",
    "gOtherText_RegisteredDataDeleted", "gOtherText_PlayersBase"}) do
    local bytes, off = {}, c:off(symbol)
    for i = 0, 1023 do local b = c:u8(off + i); bytes[#bytes + 1] = b; if b == 255 then break end end
    assert(bytes[#bytes] == 255, "native decoration/registry text termination")
    man.strings[symbol], man.textBytes[symbol] = A.text(c, off), bytes
  end
  man.baseVersion = M.packVersion
  return A.finish(c, man)
end
function M.ready(cache, root)
  if not A.ready(M.SUB, cache, root) then return false end
  local base = (root or "data/generated/gba") .. "/" .. M.SUB .. "/"
  if not cache:read(base .. "manifest.lua"):find("packVersion = " .. M.packVersion, 1, true) then return false end
  if not cache:read(base .. "manifest.lua"):find("baseVersion = " .. M.packVersion, 1, true) then return false end
  for _, file in ipairs(M.FILES) do if not cache:exists(base .. file) then return false end end
  return true
end
return M
