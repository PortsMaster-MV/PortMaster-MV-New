local M = {}

-- pokeruby/src/mauville_man.c:638
M.bardFirstPhonemeSong, M.bardNumPhonemeSongs = 248, 51
-- pokeruby/src/bard_music.c:16
M.bardNativeGroups = true

local function stateBuffer(session, state)
  local codec = require("src.save_convert.Gen3Save").forVersion(session.version)
  local original = {}
  for i = 1, 64 do original[i] = string.char((state.nativeBytes and state.nativeBytes[i]) or 0) end
  local raw = require("src.save_convert.gen3_port.sections.rs_old_man").render(codec,
    table.concat(original), state, require("src.save_convert.gen3_port.rse").same)
  return codec, codec.newBuf(64, raw)
end

local function restoreState(state, bytes, codec)
  local decoded = require("src.save_convert.gen3_port.sections.rs_old_man").read(bytes, codec)
  for key in pairs(state) do state[key] = nil end
  for key, value in pairs(decoded) do state[key] = value end
end

local function copyString(w, at, encoded)
  local eos = encoded:find(string.char(255), 1, true)
  w:bytes(at, encoded:sub(1, eos or #encoded))
end

-- pokeruby/src/mauville_man.c:966
function M.recordStoryStat(session, story, slot, stat, value)
  local codec, w = stateBuffer(session, story)
  local encoded = codec.encodeString(require("src.core.game3.rse.town_common").playerName(session), 8, 0)
  local eos = encoded:find(string.char(255), 1, true)
  w:w8(4 + slot, stat)
  w:bytes(8 + slot * 7, string.rep(string.char(255), 7))
  w:bytes(8 + slot * 7, encoded:sub(1, (eos or 8) - 1))
  w:w32(36 + slot * 4, value)
  restoreState(story, w:str(), codec)
end

-- pokeruby/src/trader.c:42
function M.traderDoTrade(session, trader, receive, give, slot)
  local Inv = require("src.core.game3.rse.decoration_inventory")
  local codec, w = stateBuffer(session, trader)
  Inv.remove(give, session)
  Inv.add(receive, session)
  copyString(w, 5 + slot * 11, codec.encodeString(require("src.core.game3.rse.town_common").playerName(session), 8, 0))
  w:w8(1 + slot, give)
  for i = 0, 2 do
    for j = i + 1, 3 do
      local raw = w:str()
      if raw:byte(2 + i) == 0 then
        w:w8(1 + i, raw:byte(2 + j))
        w:w8(1 + j, 0)
        local a, b = raw:sub(6 + i * 11, 16 + i * 11), raw:sub(6 + j * 11, 16 + j * 11)
        copyString(w, 5 + i * 11, b)
        copyString(w, 5 + j * 11, a)
      end
    end
  end
  w:w8(49, 1)
  restoreState(trader, w:str(), codec)
end

-- pokeruby/src/mauville_man.c:305
function M.saveBardSongLyrics(session, bard)
  local Town = require("src.core.game3.rse.town_common")
  local Mix = require("src.core.game3.rse.record_mix_util")
  local codec = require("src.save_convert.Gen3Save").forVersion(session.version)
  local original = {}
  for i = 1, 64 do original[i] = string.char((bard.nativeBytes and bard.nativeBytes[i]) or 0) end
  local w = codec.newBuf(64, table.concat(original))
  bard.playerName = Town.playerName(session)
  local name = codec.encodeString(bard.playerName, 8, 0)
  local eos = name:find(string.char(255), 1, true)
  w:bytes(26, name:sub(1, eos or #name))
  bard.playerTrainerIdBytes = Mix.trainerIdBytes(session)
  bard.playerTrainerId = bard.playerTrainerIdBytes[1] + bard.playerTrainerIdBytes[2] * 256
  for i = 1, 4 do w:w8(36 + i, bard.playerTrainerIdBytes[i]) end
  for i = 1, 6 do
    bard.songLyrics[i] = bard.newSongLyrics[i]
    w:w16(2 + (i - 1) * 2, bard.songLyrics[i])
    w:w16(14 + (i - 1) * 2, bard.newSongLyrics[i])
  end
  bard.hasChangedSong = true
  w:w8(41, 1)
  local bytes = w:str()
  bard.nativeBytes = {}
  for i = 1, 64 do bard.nativeBytes[i] = bytes:byte(i) end
end

return M
