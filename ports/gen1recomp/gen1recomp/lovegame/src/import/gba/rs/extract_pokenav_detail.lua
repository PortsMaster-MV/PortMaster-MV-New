local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local M = {SUB = "rse/pokenav_detail", FILES = {"list.gfx", "list.map", "list_condition.png", "list_rank.png", "list_eyes.png",
  "eyes.map", "rematch.png", "no_rematch.png"}}
M.REQUIRED = K.required(M.SUB, M.FILES)
local function replace(map, patch, x, y, width, height)
  local bytes = {}; for i = 1, #map do bytes[i] = map:sub(i, i) end
  assert(#patch >= width * height * 2, "native PokeNav tile patch size")
  for row = 0, height - 1 do for col = 0, width - 1 do
    local s, d = (row * width + col) * 2, ((y + row) * 32 + x + col) * 2
    bytes[d + 1], bytes[d + 2] = patch:sub(s + 1, s + 1), patch:sub(s + 2, s + 2)
  end end
  return table.concat(bytes)
end
local function relative(map, tileBase)
  local out = {}
  for i = 1, #map, 2 do local lo, hi = map:byte(i, i + 1); local e = lo + hi * 256
    e = e % 1024 >= tileBase and e - tileBase or 0
    out[#out + 1] = string.char(e % 256, math.floor(e / 256))
  end
  return table.concat(out)
end
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local man = {screen = "pokenav_detail", coverage = "native_list_layers_and_trainers_eye_records", features = {trainersEyes = true, matchCall = false},
    layers = {}, palettes = {}, rematches = {}, leaders = {}, descriptions = {}, strings = {}}
  local gfx, map = c:lz("gPokenavConditionSearch2_Gfx"), c:lz("gUnknown_08E9FC64")
  man.gfx, man.map = c:write("list.gfx", gfx), c:write("list.map", map)
  local textPal, miscPal = c:pal("gUnknown_083E02B4", 16), c:pal("gUnknown_083E0334", 16)
  local eyes = replace(map, c:raw("gUnknown_08E9FE54"), 0, 4, 12, 4)
  eyes = replace(eyes, c:raw("gUnknown_08E9FD64"), 0, 8, 12, 10)
  man.eyesMap = c:write("eyes.map", eyes)
  for _, p in ipairs({{"condition", "gPokenavConditionSearch2_Pal"}, {"rank", "gUnknown_083E0274"}, {"eyes", "gUnknown_08E9F9E8"}}) do
    local base, pal = c:pal(p[2], 16), {}
    for i = 0, 15 do pal[48 + i], pal[64 + i], pal[176 + i], pal[240 + i] = base[i], miscPal[i], textPal[i], textPal[i] end
    pal[0] = base[5]
    if p[1] == "eyes" then c:pal("gUnknown_083E0314", 16, pal, 80); pal[95] = base[5]
    else
      c:pal("gUnknownPalette_81E6692", 16, pal, 176)
    end
    pal[177], pal[181], pal[191] = textPal[1], textPal[8], base[5]
    local idx, w, h = K.bakeText(gfx, p[1] == "eyes" and eyes or map, 32, 32)
    man.layers[p[1]] = c:layer({key = "list_" .. p[1], opaque = true}, idx, w, h, pal)
    man.layers[p[1]].backdrop = base[5]
    man.palettes[p[1]] = K.palList(pal, 0, 256)
  end
  local mg, mp = c:lz("gUnknown_083E0354"), c:pal("gUnknown_083E0334", 16, {}, 64)
  man.markers = {}
  for _, p in ipairs({{"rematch", "gUnknown_083E039C"}, {"no_rematch", "gUnknown_083E03A0"}}) do
    local idx, w, h = K.bakeText(mg, relative(c:raw(p[2], 4), 640), 1, 2, {linear = true, mapWidth = 1})
    man.markers[p[1]] = {png = c:png(p[1] .. ".png", w, h, idx, mp, true), w = w, h = h}
  end
  local ro = c:off("gTrainerEyeTrainers")
  assert(c.S.count("gTrainerEyeTrainers", 16) == 56, "native Trainer's Eyes rematch count")
  for i = 0, 55 do
    local o, ids = ro + i * 16, {}
    for j = 0, 4 do ids[j + 1] = c:u16(o + j * 2) end
    man.rematches[i] = {opponentIDs = ids, mapGroup = c:u16(o + 10), mapNum = c:u16(o + 12), descriptionId = i}
  end
  local lo = c:off("trainers_eye.o:sGymLeaderTrainersEye")
  for i = 0, c.S.count("trainers_eye.o:sGymLeaderTrainersEye", 4) - 1 do
    local o = lo + i * 4
    man.leaders[i] = {opponentId = c:u16(o), regionMapSectionId = c:u16(o + 2), descriptionId = 56 + i, rematchNo = 0}
  end
  local doff = c:off("gTrainerEyeDescriptions")
  assert(c.S.count("gTrainerEyeDescriptions", 4) == 69, "native Trainer's Eyes description count")
  for i = 0, 68 do
    local ptr, lines = assert(c:ptr(doff + i * 4)), {}
    for line = 1, 4 do
      lines[line] = A.text(c, ptr)
      local found = false
      for j = 0, 1023 do if c:u8(ptr + j) == 255 then ptr = ptr + j + 1; found = true; break end end
      assert(found, "native Trainer's Eyes line terminator")
    end
    man.descriptions[i] = lines
  end
  for _, name in ipairs({"Strategy", "TrainersPokemon", "SelfIntroduction", "NumberRegistered", "NumberBattles"}) do man.strings[name] = A.text(c, c:off("gOtherText_" .. name)) end
  man.geometry = {listX = 97, listTop = 8, rows = 8, spacing = 16, classWidth = 75, listWidth = 128,
    rematchColumn = 29, descriptionX = 97, descriptionWidth = 136, registeredRight = 80, registeredY = 72, battlesY = 104}
  man.nativeBackgrounds = {{id = 2, control = 0x1D0A}, {id = 3, control = 0x1E03, scrollY = 248}, {id = 0, control = 0x1F01}}
  man.registration = {requiresFirstOpponentFought = true, requiresLeaderFought = true, rematchSlots = 56, maxEntries = 69}
  man.shellManifest = "data/generated/gba/rse/pokenav/manifest.lua"
  return A.finish(c, man)
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
