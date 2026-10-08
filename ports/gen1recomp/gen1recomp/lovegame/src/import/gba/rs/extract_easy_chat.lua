local A = require("src.import.gba.rs.assets")
local V = require("src.import.gba.versions")
local M = {SUB = "easy_chat", REQUIRED = {"easy_chat/words.lua"}}
local VALUE_GROUPS = {[0] = "species", [18] = "move", [19] = "move", [21] = "species"}

function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local groups = {}
  local wordsOff, sizesOff = c:off("gEasyChatGroupWords"), c:off("gEasyChatGroupSizes")
  local ordersOff, namesOff = c:off("gEasyChatGroupOrders"), c:off("gEasyChatGroupNames")
  for gid = 0, c.S.count("gEasyChatGroupWords", 4) - 1 do
    local numWords = c:u8(sizesOff + gid)
    local data, order = c:ptr(wordsOff + gid * 4), c:ptr(ordersOff + gid * 4)
    local alphabetical = {}
    for i = 0, numWords - 1 do alphabetical[c:u16(order + i * 2)] = i end
    local words, kind, pos = {}, VALUE_GROUPS[gid], data
    for i = 0, numWords - 1 do
      local value, text
      if kind then
        value = c:u16(data + i * 2)
        local off = kind == "species" and V.SPECIES_NAMES + value * V.SPECIES_NAME_LENGTH
          or V.MOVE_NAMES + value * (V.MOVE_NAME_LENGTH + 1)
        text = A.text(c, off)
      else
        text = A.text(c, pos)
        while c:u8(pos) ~= 255 do pos = pos + 1 end
        pos = pos + 1
      end
      words[#words + 1] = {id = gid * 512 + (value or i), value = value, text = text,
        alphabeticalOrder = alphabetical[value or i], enabled = true}
    end
    groups[gid] = {id = gid, name = A.text(c, c:ptr(namesOff + gid * 4)), numWords = numWords,
      numEnabled = numWords, words = words}
  end
  local path = c:write("words.lua", require("src.import.LuaWriter").encode({format_version = 1,
    assetLayout = "rs", build = V.BUILD, groups = groups,
    availability = {[0] = "pokedex_seen", [17] = "game_clear", [18] = "game_clear", [19] = "game_clear",
      [20] = "hipster_and_unlocked_word", [21] = "national_dex"}}))
  return {ok = true, groupCount = 22, path = path}
end
function M.ready(cache, root)
  local s = cache:read((root or "data/generated/gba") .. "/easy_chat/words.lua")
  return s and s:find('assetLayout = "rs"', 1, true) ~= nil and s:find('build = "' .. V.BUILD .. '"', 1, true) ~= nil
end
return M
