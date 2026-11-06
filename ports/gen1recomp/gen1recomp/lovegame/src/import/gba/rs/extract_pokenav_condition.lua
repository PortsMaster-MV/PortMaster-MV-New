local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local M = {SUB = "rse/pokenav_condition", FILES = {"party.png", "search.png", "graph.png", "portrait.png", "portrait_ribbons.png", "search_list.png", "ribbons_list.png"}}
for _, n in ipairs({"cool", "beauty", "cute", "smart", "tough", "party", "search"}) do M.FILES[#M.FILES + 1] = "header_" .. n .. ".png" end
for _, n in ipairs({"pokeball", "empty", "cancel_selected", "cancel_inactive", "sparkles"}) do M.FILES[#M.FILES + 1] = n .. ".png" end
M.REQUIRED = K.required(M.SUB, M.FILES)
local function replace(map, patch, x, y, w, h)
  local out = {}; for i = 1, #map do out[i] = map:sub(i, i) end
  assert(#patch >= w * h * 2, "native PokeNav condition patch")
  for row = 0, h - 1 do for col = 0, w - 1 do
    local a, b = (row * w + col) * 2, ((row + y) * 32 + col + x) * 2
    out[b + 1], out[b + 2] = patch:sub(a + 1, a + 1), patch:sub(a + 2, a + 2)
  end end
  return table.concat(out)
end
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local man = {screen = "pokenav_condition", layers = {}, palettes = {}, graph = {}, strings = {}}
  local gfx = string.rep("\0", 0x5000) .. c:lz("gPokenavConditionView_Gfx")
  local map, pal = c:lz("gUnknown_08E9AC4C"), {}
  local cp = c:pal("gPokenavConditionMenu2_Pal", 32)
  for i = 0, 15 do pal[32 + i] = cp[i] end
  c:pal("gUnknown_083E0254", 16, pal, 48)
  c:pal("gUnknownPalette_81E6692", 16, pal, 176)
  pal[177], pal[181], pal[191] = cp[2], cp[16], cp[30]
  man.palettes.condition = K.palList(pal, 0, 256)
  for _, variant in ipairs({{"party", map}, {"search", replace(map, c:raw("gUnknown_083E01AC"), 0, 5, 9, 4)}}) do
    local idx, w, h = K.bakeText(gfx, variant[2], 30, 20)
    man.layers[variant[1]] = c:layer({key = variant[1]}, idx, w, h, pal)
  end
  local idx, w, h = K.bakeText(gfx, c:lz("gUnknown_08E9FEB4"), 30, 20)
  man.layers.graph = c:layer({key = "graph"}, idx, w, h, pal)
  local pg, pm = string.rep("\0", 0x2000) .. c:raw("gPokenavRibbonPokeView_Gfx", 0xE0), c:lz("gUnknown_08E9FF58")
  local pi, pw, ph = K.bakeText(pg, pm, 30, 20)
  for _, p in ipairs({{"portrait", "gUnknown_083E0124"}, {"portrait_ribbons", "gUnknown_083E0144"}}) do
    local pp = c:pal(p[2], 16, {}, 208)
    man.layers[p[1]] = c:layer({key = p[1]}, pi, pw, ph, pp)
    man.palettes[p[1]] = K.palList(pp, 208, 16)
  end
  local lg, lm = c:lz("gPokenavConditionSearch2_Gfx"), c:lz("gUnknown_08E9FC64")
  lm = replace(lm, c:raw("gUnknown_08E9FD1C"), 0, 5, 9, 4)
  for _, p in ipairs({{"search_list", "gPokenavConditionSearch2_Pal"}, {"ribbons_list", "gUnknown_083E0274"}}) do
    local lp, base, text = {}, c:pal(p[2], 16), c:pal("gUnknown_083E02B4", 16)
    for i = 0, 15 do lp[48 + i], lp[176 + i], lp[240 + i] = base[i], text[i], text[i] end
    c:pal("gUnknownPalette_81E6692", 16, lp, 176)
    lp[0], lp[177], lp[181], lp[191] = base[5], text[1], text[8], base[5]
    local li, lw, lh = K.bakeText(lg, lm, 32, 32)
    man.layers[p[1]] = c:layer({key = p[1], opaque = true}, li, lw, lh, lp)
    man.palettes[p[1]] = K.palList(lp, 0, 256)
  end
  man.headers, man.sprites = {}, {}
  local options = {c:lz("gPokenavConditionMenuOptions_Gfx"), c:lz("gPokenavConditionMenuOptions2_Gfx")}
  local headerPals = {c:pal("gPokenavMenuOptions3_Pal", 16), c:pal("gPokenavCondition5_Pal", 16)}
  for i, name in ipairs({"cool", "beauty", "cute", "smart", "tough", "party", "search"}) do
    local group, chunk = i <= 4 and 1 or 2, i <= 4 and i - 1 or i - 5
    local atlas = K.blank(64, 16)
    for piece = 0, 1 do
      local px = K.bakeSprite(options[group], 32, 16, chunk * 16 + piece * 8, 4)
      for y = 0, 15 do for x = 0, 31 do atlas[y * 64 + piece * 32 + x + 1] = px[y * 32 + x + 1] end end
    end
    local pal = headerPals[(i == 5 or i == 6 or i == 7) and 2 or 1]
    man.headers[name] = {png = c:png("header_" .. name .. ".png", 64, 16, atlas, pal, true), w = 64, h = 16}
  end
  local ballPal = c:pal("gPokenavConditionPokeball_Pal", 16)
  man.sprites.pokeball = c:strip("pokeball", c:raw("gPokenavPokeballTiles"), 16, 16, 2, ballPal)
  man.sprites.empty = c:strip("empty", c:raw("gUnknown_083E3780"), 8, 8, 1, ballPal)
  local cancel = c:raw("gPokenavConditionMenuCancel_Gfx")
  man.sprites.cancelSelected = c:strip("cancel_selected", cancel, 32, 16, 1, ballPal)
  man.sprites.cancelInactive = c:strip("cancel_inactive", cancel, 32, 16, 1, c:pal("gPokenavCondition4_Pal", 16))
  man.sprites.sparkles = c:strip("sparkles", c:raw("gPokenavSparkle_Gfx"), 16, 16, 7, c:pal("gPokenavSparkle_Pal", 16))
  man.sparkleCoords = {}
  local sco = c:off("gUnknown_083E4794")
  for i = 0, 9 do man.sparkleCoords[i + 1] = {c:s16(sco + i * 4), c:s16(sco + i * 4 + 2)} end
  man.sparkleTiming = {frames = 7, frameTicks = 5, stagger = 16, restartTicks = 61}
  local radius, sine = c:off("gUnknown_083E4890"), c:off("gSineTable")
  man.graph.lineLength, man.graph.sine = {}, {}
  assert(c.S.size("gUnknown_083E4890") == 256, "native radius count")
  for i = 0, 255 do man.graph.lineLength[i + 1] = c:u8(radius + i) end
  for i = 0, c.S.count("gSineTable", 2) - 1 do man.graph.sine[i + 1] = c:s16(sine + i * 2) end
  man.graph.inputOrder = {"cool", "tough", "smart", "cute", "beauty"}
  man.graph.center, man.graph.rangeY, man.graph.interpolationSteps = {155, 91}, {56, 121}, 10
  man.graph.alpha = {eva = 11, evb = 4}
  man.graph.nativeCleanupDisabled = true
  for _, name in ipairs({"InParty", "Number"}) do man.strings[name] = A.text(c, c:off("gOtherText_" .. name)) end
  man.geometry = {name = {104, 8}, location = {104, 24}, rank = {8, 48}, portraitCenter = {38, 104},
    portraitSlideStep = 16, list = {104, 8, 8, 16}, listCursor = {91, 8}}
  return A.finish(c, man)
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
