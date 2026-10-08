local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/match_call"
M.FILES = { "window.png", "nav_icon.png" }
M.REQUIRED = K.required(M.SUB, M.FILES)

local MC = "match_call.o:"
local DATA = "pokenav_match_call_data.o:"

local function nameAt(c, ptr)
  if not ptr then return nil end
  local names = c.S.namesAt(ptr)
  for _, n in ipairs(names) do
    if not n:find(":", 1, true) then return n end
  end
  local n = names[1]
  if n then return (n:gsub("^.-:", "")) end
  error(string.format("match call: no symbol names the text at 0x%X", ptr))
end

local function textAt(c, off)
  local p = c:ptr(off)
  return p and nameAt(c, p) or nil
end

local function bytesOf(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) - 1 do
    local b = c:u8(off + i)
    out[#out + 1] = b
    if b == 0xFF then break end
  end
  return out
end

-- pokeemerald/src/match_call.c:171
local function trainers(c)
  local off, out = c:off("sMatchCallTrainers"), {}
  for i = 0, c.S.size("sMatchCallTrainers") / 20 - 1 do
    local b = off + i * 20
    out[i] = {
      trainerId = c:u16(b),
      battleTopicTextIds = { c:u16(b + 4), c:u16(b + 6), c:u16(b + 8) },
      generalTextId = c:u16(b + 10),
      streakTextIndex = c:u8(b + 12),
      sameRouteTextId = c:u16(b + 14),
      differentRouteTextId = c:u16(b + 16),
    }
  end
  return out
end

-- pokeemerald/src/match_call.c:112
local function textList(c, off, count)
  local out = {}
  for i = 0, count - 1 do
    local b = off + i * 8
    out[i + 1] = { text = textAt(c, b), vars = { c:s8(b + 4), c:s8(b + 5), c:s8(b + 6) } }
  end
  return out
end

local function topics(c, name)
  local off, out = c:off(MC .. name), {}
  for i = 0, c.S.size(MC .. name) / 4 - 1 do
    local p = assert(c:ptr(off + i * 4), "match call: null topic table")
    local tname = nameAt(c, p)
    out[i + 1] = textList(c, p, c.S.size(MC .. tname) / 8)
  end
  return out
end

local function ptrNames(c, name, stride)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / (stride or 4) - 1 do out[i] = textAt(c, off + i * (stride or 4)) end
  return out
end

-- pokeemerald/src/pokenav_match_call_data.c:29
local function textData(c, p)
  local out = {}
  if not p then return out end
  for i = 0, 63 do
    local b = p + i * 8
    local t = c:ptr(b)
    if not t then break end
    out[#out + 1] = { text = nameAt(c, t), availability = c:u16(b + 4), setFlag = c:u16(b + 6) }
  end
  return out
end

-- pokeemerald/src/pokenav_match_call_data.c:19
local TYPES = { [0] = "npc", "trainer", "wally", "birch", "rival", "leader" }

-- pokeemerald/src/pokenav_match_call_data.c:597
local function headers(c)
  local off, out = c:off(DATA .. "sMatchCallHeaders"), {}
  for i = 0, c.S.size(DATA .. "sMatchCallHeaders") / 4 - 1 do
    local h = assert(c:ptr(off + i * 4), "match call: null header")
    local kind = assert(TYPES[c:u8(h)], "match call: unknown header type")
    local row = { type = kind, flag = c:u16(h + 2) }
    if kind == "npc" then
      row.mapSec = c:u8(h + 1)
      row.desc, row.name = textAt(c, h + 4), textAt(c, h + 8)
      row.textData = textData(c, c:ptr(h + 12))
    elseif kind == "trainer" or kind == "leader" then
      row.mapSec = c:u8(h + 1)
      row.rematchTableIdx = c:u16(h + 4)
      row.desc, row.name = textAt(c, h + 8), textAt(c, h + 12)
      row.textData = textData(c, c:ptr(h + 16))
    elseif kind == "wally" then
      row.mapSec = c:u8(h + 1)
      row.rematchTableIdx = c:u16(h + 4)
      row.desc = textAt(c, h + 8)
      row.textData = textData(c, c:ptr(h + 12))
      row.locations = {}
      local lp = c:ptr(h + 16)
      for j = 0, 15 do
        local flag = c:u16(lp + j * 4)
        row.locations[#row.locations + 1] = { flag = flag, mapSec = c:u8(lp + j * 4 + 2) }
        if flag == 0xFFFF then break end
      end
    elseif kind == "birch" then
      row.mapSec = c:u8(h + 1)
      row.desc, row.name = textAt(c, h + 4), textAt(c, h + 8)
    elseif kind == "rival" then
      row.playerGender = c:u8(h + 1)
      row.desc, row.name = textAt(c, h + 4), textAt(c, h + 8)
      row.textData = textData(c, c:ptr(h + 12))
    end
    out[i] = row
  end
  return out
end

-- pokeemerald/src/pokenav_match_call_data.c:677
local function checkPageOverrides(c)
  local name = DATA .. "sCheckPageOverrides"
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 24 - 1 do
    local b = off + i * 24
    local texts = {}
    for j = 0, 3 do texts[j + 1] = textAt(c, b + 8 + j * 4) end
    out[#out + 1] = { idx = c:u16(b), facilityClass = c:u16(b + 2), flag = c:u32(b + 4), texts = texts }
  end
  return out
end

-- pokeemerald/src/data/text/match_call_messages.h:391
local function flavorTexts(c)
  local off, out = c:off("gMatchCallFlavorTexts"), {}
  for i = 0, c.S.size("gMatchCallFlavorTexts") / 16 - 1 do
    local row = {}
    for j = 0, 3 do row[j + 1] = textAt(c, off + i * 16 + j * 4) end
    out[i] = row
  end
  return out
end

local function u16list(c, name)
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 2 - 1 do out[i + 1] = c:u16(off + i * 2) end
  return out
end

-- pokeemerald/src/match_call.c:1669
local function multiTrainerNames(c)
  local off, out = c:off(MC .. "sMultiTrainerMatchCallTexts"), {}
  for i = 0, c.S.size(MC .. "sMultiTrainerMatchCallTexts") / 8 - 1 do
    out[#out + 1] = { trainerId = c:u16(off + i * 8), text = textAt(c, off + i * 8 + 4) }
  end
  return out
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)

  -- pokeemerald/src/match_call.c:1197
  local winPal = c:pal(MC .. "sMatchCallWindow_Pal", 16)
  local winIdx = K.bakeSprite(c:raw(MC .. "sMatchCallWindow_Gfx"), 64, 8, 0, 4)
  c:png("window.png", 64, 8, winIdx, winPal, false)
  local iconPal = c:pal(MC .. "sPokenavIcon_Pal", 16)
  local icon = c:lz(MC .. "sPokenavIcon_Gfx")
  local frames = {}
  for i = 0, 7 do
    frames[i + 1] = K.bakeText(icon, (function()
      local t = {}
      for n = 0, 15 do
        local v = i * 16 + n
        t[#t + 1] = string.char(v % 256, math.floor(v / 256))
      end
      return table.concat(t)
    end)(), 4, 4, { linear = true, mapWidth = 4 })
  end
  local sheet = K.stack(frames, 32, 32)
  c:png("nav_icon.png", 32, 256, sheet, iconPal, false)

  return true, c:finish({
    screen = "match_call",
    window = { png = c:path("window.png"), tiles = 8, pal = winPal },
    navIcon = { png = c:path("nav_icon.png"), w = 32, h = 32, frames = 8, pal = iconPal },
    trainers = trainers(c),
    battleTopics = topics(c, "sMatchCallBattleTopics"),
    requestTopics = topics(c, "sMatchCallBattleRequestTopics"),
    generalTopics = topics(c, "sMatchCallGeneralTopics"),
    multiTrainerNames = multiTrainerNames(c),
    frontierFacilityNames = ptrNames(c, MC .. "sBattleFrontierFacilityNames"),
    birchDexRatingTexts = ptrNames(c, MC .. "sBirchDexRatingTexts"),
    callEllipsis = bytesOf(c, MC .. "sText_PokenavCallEllipsis"),
    callingDots = bytesOf(c, "pokenav_match_call_gfx.o:sText_CallingDots"),
    headers = headers(c),
    checkPageOverrides = checkPageOverrides(c),
    flavorTexts = flavorTexts(c),
    gymLeaderRematchesAfterNewMauville = u16list(c, "GymLeaderRematches_AfterNewMauville"),
    gymLeaderRematchesBeforeNewMauville = u16list(c, "GymLeaderRematches_BeforeNewMauville"),
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
