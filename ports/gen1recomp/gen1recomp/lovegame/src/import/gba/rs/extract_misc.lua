local A = require("src.import.gba.rs.assets")
local M = {SUB = "rse/misc", FILES = {}, REQUIRED = {"rse/misc/manifest.lua"}}
local function nameAt(c, off)
  for _, name in ipairs(c.S.namesAt(off)) do if not name:find(":", 1, true) then return name end end
  error(string.format("RS misc text has no symbol at 0x%X", off))
end
local function texts(c, symbol)
  local off, out = c:off(symbol), {}
  for i = 0, c.S.count(symbol, 4) - 1 do out[i + 1] = nameAt(c, c:ptr(off + i * 4)) end
  return out
end
local function u16s(c, symbol)
  local off, out = c:off(symbol), {}
  for i = 0, c.S.count(symbol, 2) - 1 do out[i + 1] = c:u16(off + i * 2) end
  return out
end
-- pokeruby/include/bard_music.h:7
local function bard(c)
  local off, groups = c:off("gBardSoundsTable"), {}
  for gid = 0, c.S.count("gBardSoundsTable", 4) - 1 do
    local p = c:ptr(off + gid * 4)
    local names = c.S.namesAt(p)
    local count = c.S.size(names[1]) / 48
    local t = {}
    for i = 0, count * 6 - 1 do
      local b = p + i * 8
      t[#t + 1], t[#t + 2], t[#t + 3] = c:u8(b), c:s8(b + 1), c:s16(b + 4)
    end
    groups[gid] = {words = count, t = t}
  end
  local pitch, po = {}, c:off("gBardSoundPitchTables")
  for i = 0, c.S.count("gBardSoundPitchTables", 4) - 1 do
    local p, row = c:ptr(po + i * 4), {}
    for j = 0, 15 do
      local v = c:s16(p + j * 2)
      if v == 0x1800 then break end
      row[#row + 1] = v
    end
    pitch[i] = row
  end
  local lengths, lo = {}, c:off("gBardSoundLengthTable")
  for i = 0, c.S.count("gBardSoundLengthTable", 4) - 1 do lengths[i] = c:u32(lo + i * 4) end
  return {defaultLyrics = u16s(c, "sDefaultBardSongLyrics"), groups = groups,
    pokemon = groups[0], moves = groups[18], pitchTables = pitch, phonemeLengths = lengths}
end
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local decor, off = {}, c:off("gTraderDecorations")
  for i = 0, c.S.size("gTraderDecorations") - 1 do decor[i + 1] = c:u8(off + i) end
  local stories, so = {}, c:off("sStorytellerStories")
  for i = 0, c.S.count("sStorytellerStories", 16) - 1 do
    local b = so + i * 16
    stories[#stories + 1] = {stat = c:u8(b), minVal = c:u8(b + 1), title = nameAt(c, c:ptr(b + 4)),
      action = nameAt(c, c:ptr(b + 8)), fullText = nameAt(c, c:ptr(b + 12))}
  end
  return A.finish(c, {screen = "misc", bard = bard(c), lotteryPrizes = u16s(c, "sLotteryPrizes"),
    oldMan = {traderNames = texts(c, "gUnknown_083F62D8"), traderDecorations = decor,
      giddyAdjectives = texts(c, "sGiddyAdjectives"), giddyQuestions = texts(c, "sGiddyQuestions"), stories = stories}})
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
