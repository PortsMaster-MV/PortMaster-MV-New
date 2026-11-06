local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local IR = require("src.core.game3.scripting.text_ir")
local M = {SUB = "rse/trainer_card", FILES = {"badges.png", "star.png", "male.png", "female.png"}}
local sides = {"screen", "front", "front_no_dex", "link", "link_no_dex", "back"}
for stars = 0, 4 do
  for _, side in ipairs(sides) do
    for _, suffix in ipairs({"", "_female"}) do M.FILES[#M.FILES + 1] = side .. "_" .. stars .. suffix .. ".png" end
  end
end
M.REQUIRED = K.required(M.SUB, M.FILES)

local function entry(v) return string.char(v % 256, math.floor(v / 256)) end
local function clearDex(map)
  local out = {}
  for i = 1, #map, 2 do
    local at = math.floor((i - 1) / 2)
    local x, y = at % 32, math.floor(at / 32)
    out[#out + 1] = (y == 10 or y == 11) and x >= 3 and x < 17 and entry(1) or map:sub(i, i + 1)
  end
  return table.concat(out)
end
local function text(c, name)
  local off, bytes = c:off(name), {}
  for i = 0, 1023 do
    local b = c:u8(off + i); bytes[#bytes + 1] = b
    if b == 255 then
      local out = {}
      for _, seg in ipairs(IR.decode(bytes, {dialect = "rs"})) do
        if seg.t == "ext" then
          out[#out + 1] = string.char(0xFC, seg.cmd)
          for _, arg in ipairs(seg.args or {}) do out[#out + 1] = string.char(arg) end
        elseif seg.t == "tag" then out[#out + 1] = seg.tag
        else out[#out + 1] = IR.toAscii({seg}) end
      end
      return table.concat(out), bytes
    end
  end
  error("RS trainer card string is unterminated")
end
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  -- trainer_card.c:975
  local gfx = c:raw("gMenuTrainerCard_Gfx", 0x1480) .. c:raw("gBadgesTiles", 0x400)
  local maps = {screen = c:raw("gMenuTrainerCardBackground_Tilemap"), front = c:raw("gMenuTrainerCardFront_Tilemap"),
    link = c:raw("gMenuTrainerCardFront2_Tilemap"), back = c:raw("gMenuTrainerCardBack_Tilemap")}
  maps.front_no_dex, maps.link_no_dex = clearDex(maps.front), clearDex(maps.link)
  local man = {screen = "trainer_card", cardType = "rs", layers = {}, palettes = {}, windows = {}, strings = {}, textBytes = {},
    bgY = 4, pic = {x = 152, y = 40, w = 64, h = 64}, starPosition = {120, 48}, badgePosition = {32, 120, 24}}
  for stars = 0, 4 do
    local pal = c:pal("gMenuTrainerCard" .. stars .. "Star_Pal", 48)
    c:pal("gBadgesPalette", 16, pal, 48)
    c:pal("gUnknown_083B5F4C", 16, pal, 64)
    local female = {}; for i = 0, 79 do female[i] = pal[i] end
    c:pal("gUnknown_083B5F0C", 16, female, 16)
    man.palettes[stars] = {male = K.palList(pal, 0, 80), female = K.palList(female, 0, 80)}
    for side, map in pairs(maps) do
      assert(#map == 1280, "RS trainer card map must have native 32x20 rows")
      local idx, w, h = K.bakeText(gfx, map, 32, 32)
      local key = side .. "_" .. stars
      man.layers[key] = {png = c:png(key .. ".png", w, h, idx, pal, true),
        female = c:png(key .. "_female.png", w, h, idx, female, true), w = w, h = h}
    end
  end
  local badgeMap, badgeEntries = c:off("gTrainerCardBadgesMap"), {}
  for y = 0, 1 do
    for badge = 0, 7 do
      for x = 0, 1 do badgeEntries[#badgeEntries + 1] = entry(c:u16(badgeMap + badge * 8 + (y * 2 + x) * 2) + 0x3000) end
    end
  end
  local p = c:pal("gBadgesPalette", 16, {}, 48)
  local idx, w, h = K.bakeText(gfx, table.concat(badgeEntries), 16, 2, {linear = true, mapWidth = 16})
  man.badges = {png = c:png("badges.png", w, h, idx, p, true), w = w, h = h}
  p = c:pal("gUnknown_083B5F4C", 16, {}, 64)
  idx, w, h = K.bakeText(gfx, entry(0x408F), 1, 1)
  man.star = {png = c:png("star.png", w, h, idx, p, true)}
  local pics, pals = c:off("gTrainerFrontPicTable"), c:off("gTrainerFrontPicPaletteTable")
  man.pics = {}
  for gender, name in ipairs({"male", "female"}) do
    local i = gender - 1
    local data = c:lzAt(assert(c:ptr(pics + i * 8)))
    local pal = c:palFrom(c:lzAt(assert(c:ptr(pals + i * 8))), 16)
    local entries = {}; for tile = 0, 63 do entries[#entries + 1] = entry(tile) end
    idx, w, h = K.bakeText(data, table.concat(entries), 8, 8, {linear = true, mapWidth = 8})
    man.pics[name] = {png = c:png(name .. ".png", w, h, idx, pal, true)}
  end
  for key, name in pairs({values = "gWindowTemplate_TrainerCard_Back_Values", numbers = "gWindowTemplate_TrainerCard_Back_Labels"}) do
    local o, row = c:off(name), {}; for i = 0, 27 do row[i + 1] = c:u8(o + i) end
    man.windows[key] = {nativeBytes = row, paletteNum = row[5], foreground = row[6], background = row[7], shadow = row[8], font = row[9], spacing = row[11]}
  end
  man.textPalettes = {values = K.palList(c:pal("gFontDefaultPalette", 16), 0, 16),
    numbers = K.palList(c:pal("gUnknown_083B5F6C", 16), 0, 16)}
  for key, symbol in pairs({nameSuffix = "gOtherText_TrainersTrainerCard", hof = "gOtherText_FirstHOF", link = "gOtherText_LinkCableBattles",
    tower = "gOtherText_BattleTowerWinRecord", contest = "gOtherText_ContestRecord", blender = "gOtherText_MixingRecord", trade = "gOtherText_TradeRecord"}) do
    man.strings[key], man.textBytes[key] = text(c, symbol)
  end
  man.colonSeparator = A.text(c, c:off("gUnknown_083B5EF4"))
  return A.finish(c, man)
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
