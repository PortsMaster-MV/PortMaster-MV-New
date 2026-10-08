local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/pokenav_cr"
M.FILES = {
  "cond_bg.png", "cond_bg_search.png", "graph_fill.png", "balls.png", "ball_placeholder.png", "cancel.png",
  "cancel_lit.png", "sparkle.png", "markings.png", "markings_menu.png", "search_bg.png", "ribbon_list_bg.png",
  "ribbon_summary_bg.png", "ribbons_small.png", "ribbons_big.png",
}
M.REQUIRED = K.required(M.SUB, M.FILES)

local CG = "pokenav_conditions_gfx.o:"

local function nameAt(c, ptr)
  if not ptr then return nil end
  for _, n in ipairs(c.S.namesAt(ptr)) do
    if not n:find(":", 1, true) then return n end
  end
  local n = c.S.namesAt(ptr)[1]
  return n and (n:gsub("^.-:", "")) or nil
end

local function palList(p, base, n)
  local out = {}
  for i = 0, (n or 16) - 1 do out[i] = p[(base or 0) + i] or 0 end
  return out
end

local function bg(c, gfx, map)
  return K.bakeText(gfx, map, 32, 20, { linear = true, mapWidth = 32 })
end

local function ch(c, s) return math.floor(c / 2 ^ s) % 32 end

-- pokeemerald/include/gba/io_reg.h:613
local function blend(a, b, eva, evb)
  local out = 0
  for _, s in ipairs({ 0, 5, 10 }) do
    local v = math.floor((ch(a, s) * eva + ch(b, s) * evb) / 16)
    if v > 31 then v = 31 end
    out = out + v * 2 ^ s
  end
  return out
end

-- pokeemerald/src/menu_specialized.c:88
local function bytesAt(c, name, n)
  local off, out = c:off(name), {}
  for i = 0, (n or c.S.size(name)) - 1 do out[i] = c:u8(off + i) end
  return out
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)

  -- pokeemerald/src/pokenav_conditions_gfx.c:212
  local condGfx = c:lz("gPokenavCondition_Gfx")
  local condMap = c:lz("gPokenavCondition_Tilemap")
  local condPal = c:pal("gPokenavCondition_Pal", 16, {}, 16)
  local condIdx = bg(c, condGfx, condMap)
  c:png("cond_bg.png", 256, 160, condIdx, condPal, true)
  -- pokeemerald/src/pokenav_conditions_gfx.c:226
  local search = {}
  for i = 1, #condMap do search[i] = condMap:byte(i) end
  local optMap = c:raw("gPokenavOptions_Tilemap")
  for ty = 0, 3 do
    for tx = 0, 8 do
      local si = (ty * 9 + tx) * 2
      local di = ((5 + ty) * 32 + tx) * 2
      search[di + 1], search[di + 2] = optMap:byte(si + 1), optMap:byte(si + 2)
    end
  end
  local searchMap = string.char(unpack(search))
  local searchIdx = bg(c, condGfx, searchMap)
  c:png("cond_bg_search.png", 256, 160, searchIdx, condPal, true)

  -- pokeemerald/src/pokenav_conditions_gfx.c:237
  local graphPal = c:pal("gConditionGraphData_Pal", 16, {}, 48)
  local graphIdx = bg(c, c:lz("sConditionGraphData_Gfx"), c:lz("sConditionGraphData_Tilemap"))
  -- pokeemerald/src/pokenav_conditions_gfx.c:211
  local fillPal, fillIdx, seen = {}, K.blank(256, 160), {}
  for i = 1, 256 * 160 do
    local a = graphIdx[i]
    if a % 16 ~= 0 then
      local b = condIdx[i]
      local col = blend(graphPal[a] or 0, b % 16 ~= 0 and (condPal[b] or 0) or 0, 11, 4)
      local slot = seen[col]
      if not slot then
        slot = #fillPal + 1
        assert(slot < 256, "pokenav condition: blended graph palette overflow")
        fillPal[slot] = col
        seen[col] = slot
      end
      fillIdx[i] = slot
    end
  end
  c:png("graph_fill.png", 256, 160, fillIdx, fillPal, true)

  -- pokeemerald/src/menu_specialized.c:1197
  local cancelPals = c:pal("gPokenavConditionCancel_Pal", 32)
  local ballPal, cancelPal = palList(cancelPals, 0), palList(cancelPals, 16)
  local ballGfx = c:raw("sConditionPokeball_Gfx")
  c:png("balls.png", 16, 32, K.stack({ K.bakeSprite(ballGfx, 16, 16, 0), K.bakeSprite(ballGfx, 16, 16, 4) }, 16, 16), ballPal, true)
  c:png("ball_placeholder.png", 8, 8, K.bakeSprite(c:raw("sConditionPokeballPlaceholder_Gfx"), 8, 8, 0), ballPal, true)
  local cancel = K.bakeSprite(c:raw("gPokenavConditionCancel_Gfx"), 32, 16, 0)
  c:png("cancel.png", 32, 16, cancel, cancelPal, true)
  c:png("cancel_lit.png", 32, 16, cancel, ballPal, true)

  -- pokeemerald/src/menu_specialized.c:1244
  local sparkleGfx = c:raw("sConditionSparkle_Pal")
  local frames = {}
  for i = 0, 6 do frames[i + 1] = K.bakeSprite(sparkleGfx, 16, 16, i * 4) end
  c:png("sparkle.png", 16, 112, K.stack(frames, 16, 16), c:pal("sConditionSparkle_Gfx", 16), true)

  -- pokeemerald/src/mon_markings.c:585
  local markGfx = c:raw("mon_markings.o:sMonMarkings_Gfx")
  local combos = {}
  for i = 0, 15 do combos[i + 1] = K.bakeSprite(markGfx, 32, 8, i * 4) end
  c:png("markings.png", 32, 128, K.stack(combos, 32, 8), c:pal(CG .. "sMonMarkings_Pal", 16), true)
  -- pokeemerald/src/mon_markings.c:444
  local menuGfx = c:raw("gMonMarkingsMenu_Gfx")
  local menu = K.blank(32, 32 + 80)
  for t = 0, 8 do
    local px = K.bakeSprite(menuGfx, 8, 8, t)
    for y = 0, 7 do for x = 0, 7 do menu[(math.floor(t / 4) * 8 + y) * 32 + (t % 4) * 8 + x + 1] = px[y * 8 + x + 1] end end
  end
  local text = K.bakeSprite(menuGfx, 32, 32, 9)
  for y = 0, 31 do for x = 0, 31 do menu[(24 + y) * 32 + x + 1] = text[y * 32 + x + 1] end end
  c:png("markings_menu.png", 32, 112, menu, c:pal("gMonMarkingsMenu_Pal", 16), true)

  -- pokeemerald/src/pokenav_conditions_search_results.c:434
  local searchPal = c:pal("sConditionSearchResultFramePal", 16, {}, 16)
  c:png("search_bg.png", 256, 160, bg(c, c:lz("sConditionSearchResultTiles"), c:lz("sConditionSearchResultTilemap")), searchPal, true)
  -- pokeemerald/src/pokenav_ribbons_list.c:423
  local listPal = c:pal("sMonRibbonListFramePal", 16, {}, 16)
  c:png("ribbon_list_bg.png", 256, 160, bg(c, c:lz("sMonRibbonListFrameTiles"), c:lz("sMonRibbonListFrameTilemap")), listPal, true)

  -- pokeemerald/src/pokenav_ribbons_summary.c:566
  local sumPal = c:pal("gPokenavRibbonsSummaryBg_Pal", 16, {}, 16)
  c:png("ribbon_summary_bg.png", 256, 160, bg(c, c:lz("gPokenavRibbonsSummaryBg_Gfx"), c:lz("gPokenavRibbonsSummaryBg_Tilemap")), sumPal, true)
  local iconPals = c:palAt(c:off("sRibbonIcons1_Pal"), 80)
  -- pokeemerald/src/pokenav_ribbons_summary.c:1057
  local small = c:lz("sRibbonIconsSmall_Gfx")
  local smallIdx = K.blank(80, 192)
  local big = c:lz("sRibbonIconsBig_Gfx")
  local bigIdx = K.blank(160, 384)
  for icon = 0, 11 do
    local top, bottom = K.bakeSprite(small, 8, 8, icon * 2), K.bakeSprite(small, 8, 8, icon * 2 + 1)
    local bpx = K.bakeSprite(big, 32, 32, icon * 16)
    for p = 0, 4 do
      for y = 0, 15 do
        for x = 0, 15 do
          local sx = x < 8 and x or (15 - x)
          local v = (y < 8 and top or bottom)[(y % 8) * 8 + sx + 1]
          if v ~= 0 then smallIdx[(icon * 16 + y) * 80 + p * 16 + x + 1] = p * 16 + v end
        end
      end
      for y = 0, 31 do
        for x = 0, 31 do
          local v = bpx[y * 32 + x + 1]
          if v ~= 0 then bigIdx[(icon * 32 + y) * 160 + p * 32 + x + 1] = p * 16 + v end
        end
      end
    end
  end
  c:png("ribbons_small.png", 80, 192, smallIdx, iconPals, true)
  c:png("ribbons_big.png", 160, 384, bigIdx, iconPals, true)

  -- pokeemerald/src/pokenav_ribbons_summary.c:123
  local ribbonData = {}
  local rdOff = c:off("sRibbonData")
  for i = 0, c.S.size("sRibbonData") / 4 - 1 do
    local b = rdOff + i * 4
    ribbonData[i + 1] = { numBits = c:u8(b), numRibbons = c:u8(b + 1), ribbonId = c:u8(b + 2), isGift = c:u8(b + 3) ~= 0 }
  end
  -- pokeemerald/src/pokenav_ribbons_summary.c:1089
  local ribbonGfx = {}
  local rgOff = c:off("sRibbonGfxData")
  for i = 0, c.S.size("sRibbonGfxData") / 4 - 1 do
    ribbonGfx[i] = { tile = c:u16(rgOff + i * 4), pal = c:u16(rgOff + i * 4 + 2) }
  end
  -- pokeemerald/src/data/text/ribbon_descriptions.h:1
  local function descs(name)
    local off, out = c:off(name), {}
    for i = 0, c.S.size(name) / 8 - 1 do
      out[i] = { nameAt(c, c:ptr(off + i * 8)), nameAt(c, c:ptr(off + i * 8 + 4)) }
    end
    return out
  end

  -- pokeemerald/src/menu_specialized.c:1317
  local sparkleCoords = {}
  local scOff = c:off("sConditionSparkleCoords")
  for i = 0, 9 do sparkleCoords[i] = { c:s16(scOff + i * 4), c:s16(scOff + i * 4 + 2) } end
  local sine = {}
  local sOff = c:off("gSineTable")
  for i = 0, c.S.size("gSineTable") / 2 - 1 do sine[i] = c:s16(sOff + i * 2) end

  return true, c:finish({
    screen = "pokenav_condition_ribbons",
    layers = {
      condition = { png = c:path("cond_bg.png"), search = c:path("cond_bg_search.png"), w = 256, h = 160 },
      graphFill = { png = c:path("graph_fill.png"), w = 256, h = 160 },
      search = { png = c:path("search_bg.png"), w = 256, h = 160 },
      ribbonList = { png = c:path("ribbon_list_bg.png"), w = 256, h = 160 },
      ribbonSummary = { png = c:path("ribbon_summary_bg.png"), w = 256, h = 160 },
    },
    sprites = {
      balls = { png = c:path("balls.png"), w = 16, h = 16 },
      ballPlaceholder = { png = c:path("ball_placeholder.png"), w = 8, h = 8 },
      cancel = { png = c:path("cancel.png"), lit = c:path("cancel_lit.png"), w = 32, h = 16 },
      sparkle = { png = c:path("sparkle.png"), w = 16, h = 16, frames = 7 },
      markings = { png = c:path("markings.png"), w = 32, h = 8 },
      markingsMenu = { png = c:path("markings_menu.png"), w = 32, h = 112 },
      ribbonsSmall = { png = c:path("ribbons_small.png"), w = 16, h = 16 },
      ribbonsBig = { png = c:path("ribbons_big.png"), w = 32, h = 32 },
    },
    palettes = {
      conditionText = palList(c:pal("gConditionText_Pal", 16), 0),
      conditionBg = palList(condPal, 16),
      searchList = palList(c:pal("sListBg_Pal", 16), 0),
      searchFrame = palList(searchPal, 16),
      ribbonListUi = palList(c:pal("sMonRibbonListUi_Pal", 16), 0),
      ribbonListFrame = palList(listPal, 16),
      ribbonSummary = palList(sumPal, 16),
      monInfo = palList(c:pal("sMonInfo_Pal", 16), 0),
    },
    lineLength = bytesAt(c, "sConditionToLineLength"),
    sine = sine,
    sparkleCoords = sparkleCoords,
    ribbonData = ribbonData,
    ribbonGfx = ribbonGfx,
    ribbonDescriptions = descs("gRibbonDescriptionPointers"),
    giftRibbonDescriptions = descs("gGiftRibbonDescriptionPointers"),
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
