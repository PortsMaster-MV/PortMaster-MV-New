local Tv = require("src.core.game3.rse.tv")
local M = {}
local CONTROL_LENGTHS = {1, 2, 2, 2, 4, 2, 2, 1, 2, 1, 1, 3, 2, 2, 2, 1, 3, 2, 2, 2, 2, 1, 1}
local function number(v) return math.floor(tonumber(v) or 0) end
local function codec(session) return require("src.save_convert.Gen3Save").forVersion(session.version) end
local function random() return require("src.core.game3.rng").Random() end
local function species(mon) return number(mon and (mon.species or mon.speciesId)) end
local function terminated(a, limit)
  local out = {}
  for i = 1, math.min(#a, limit or #a) do
    if a[i] == 255 then break end
    out[#out + 1] = a[i]
  end
  out[#out + 1] = 255
  return out
end
local function byteString(a) return string.char(unpack(a)) end
function M.encode(session, text, limit)
  text = tostring(text or ""):gsub("{JPN}", "{FC}{15}"):gsub("{ENG}", "{FC}{16}")
  local raw = codec(session).encodeString(text, limit or 256, 255)
  return terminated({raw:byte(1, -1)})
end
-- pokeruby/text.c:439
function M.strip(a)
  local out, i = {}, 1
  while i <= #a and a[i] ~= 255 do
    if a[i] == 252 then i = i + 1 + (CONTROL_LENGTHS[(a[i + 1] or 0) + 1] or 0)
    else out[#out + 1], i = a[i], i + 1 end
  end
  out[#out + 1] = 255
  return out
end
function M.equal(a, b) return byteString(M.strip(a)) == byteString(M.strip(b)) end
function M.text(session, a)
  local out, glyphs, i = {}, {}, 1
  local function flush()
    if #glyphs > 0 then
      out[#out + 1] = codec(session).decodeString(byteString(glyphs), 0, #glyphs)
      glyphs = {}
    end
  end
  while i <= #a and a[i] ~= 255 do
    if a[i] == 252 then
      flush()
      local control, length = a[i + 1], CONTROL_LENGTHS[(a[i + 1] or 0) + 1] or 0
      if control == 21 then out[#out + 1] = "{JPN}"
      elseif control == 22 then out[#out + 1] = "{ENG}"
      else
        for j = i, math.min(i + length, #a) do out[#out + 1] = string.format("{%02X}", a[j]) end
      end
      i = i + 1 + length
    else glyphs[#glyphs + 1], i = a[i], i + 1 end
  end
  flush()
  return table.concat(out)
end
-- pokemon_2.c:340
function M.nicknameBytes(session, mon)
  mon = mon or {}
  if mon.isBadEgg then return M.encode(session, require("src.core.game3.rse.init").text("gBadEggNickname")) end
  if mon.isEgg == true or mon.egg == true then
    return M.encode(session, require("src.core.game3.rse.init").text("gEggNickname"))
  end
  local nick = Tv.nickname(mon)
  local raw = mon.cartExtra and mon.cartExtra.nicknameRaw
  local a
  if type(raw) == "table" and codec(session).decodeString(byteString(raw), 0, #raw) == nick then
    a = terminated(raw, 10)
  else a = M.encode(session, nick, 10) end
  if number(mon.language) == 1 then
    a = M.strip(a)
    table.remove(a)
    table.insert(a, 1, 21); table.insert(a, 1, 252)
    a[#a + 1], a[#a + 2], a[#a + 3] = 252, 22, 255
  end
  return a
end
local function kind(show) return number(show and show.kind) % 256 end
function M.activeByte(show)
  if not show then return 0 end
  local raw = show.nativeBytes
  if raw and raw[2] ~= nil and show.active == (raw[2] ~= 0) then return raw[2] end
  if type(show.active) == "number" then return number(show.active) % 256 end
  return show.active == true and 1 or 0
end
-- tv.c:470
function M.randomActive(session, rand)
  local list = Tv.state(session).tvShows
  local stop = 5
  while stop < 24 and kind(list[stop]) ~= 0 do stop = stop + 1 end
  local idx = number((rand or random)()) % stop
  local first = idx
  repeat
    local show, k = list[idx], kind(list[idx])
    local days = number(show.daysBeforeOutbreak)
    if show.daysBeforeOutbreak == nil then
      if show.nativeBytes then days = number(show.nativeBytes[23]) + number(show.nativeBytes[24]) * 256
      elseif show.raw then days = number(show.raw[21]) + number(show.raw[22]) * 256 end
    end
    if M.activeByte(show) == 1 and (k <= 40 or k > 60 or days == 0) then return idx end
    idx = idx == 0 and 23 or idx - 1
  until idx == first
  return 255
end
-- tv.c:582
function M.nonOutbreakActive(session, idx)
  local list = Tv.state(session).tvShows
  if kind(list[idx]) == 41 and number(session.outbreakPokemonSpecies) ~= 0 then
    for i = 0, 23 do
      local k = kind(list[i])
      if k ~= 0 and k ~= 41 and M.activeByte(list[i]) == 1 then return i end
    end
    return 255
  end
  return idx
end
-- field_specials.c:1857
function M.leadNickname(session)
  local party, mon = session.party or {}
  for i = 1, 6 do
    local candidate = party[i]
    if species(candidate) == 0 then break end
    if not (candidate.isEgg == true or candidate.egg == true or candidate.isBadEgg == true) then mon = candidate; break end
  end
  mon = mon or party[1]
  local nick = M.nicknameBytes(session, mon)
  local standard = M.encode(session, Tv.speciesName(species(mon)), 11)
  return not M.equal(nick, standard), nick
end
-- tv.c:1646
local function nameRaterSlot(session)
  local list = Tv.state(session).tvShows
  for i = 0, 4 do
    if kind(list[i]) == 5 then
      if M.activeByte(list[i]) == 1 then Tv._result = true; return nil, nil, 1 end
      Tv.deleteShow(list, i); Tv.compactShows(list)
      break
    end
  end
  local index = Tv.firstEmptyNormalSlot(list)
  Tv._curSlot, Tv._var8006, Tv._result = index, index == -1 and 65535 or index, index == -1
  return index, Tv._var8006, Tv._result and 1 or 0
end
-- tv.c:1867
function M.randomDifferentSpeciesSeen(session, excluded, rand)
  local count = require("src.core.game3.constants").active(session):require("species", "NUM_SPECIES")
  local candidate = number((rand or random)()) % (count - 1) + 1
  local first = candidate
  local Dex = require("src.core.game3.dex")
  while not Dex.isSeen(session.dex, candidate) or candidate == excluded do
    candidate = candidate == 1 and count - 1 or candidate - 1
    if candidate == first then return excluded end
  end
  return candidate
end
local function stringCopy(buf, off, a)
  for i, v in ipairs(a) do
    if off + i > 36 then break end
    buf:w8(off + i - 1, v)
    if v == 255 then break end
  end
end
-- tv.c:1040
function M.nameRater(session, monIndex, oldNickname, rand)
  local mon = (session.party or {})[monIndex + 1]
  local nick = M.nicknameBytes(session, mon)
  if M.equal(M.encode(session, oldNickname), nick) then return false, nick end
  local index, var8006, queueResult = nameRaterSlot(session)
  if not index or index == -1 then return true, nick, var8006, queueResult end
  local trainer = M.encode(session, session.name or session.playerName, 8)
  if #trainer <= 2 or #nick <= 2 then return true, nick, var8006, queueResult end
  local list, C = Tv.state(session).tvShows, codec(session)
  local template = list[index].nativeBytes
  local raw = template and byteString(template) or string.rep("\0", 36)
  local buf = C.newBuf(36, raw)
  local draw = rand or random
  buf:w8(0, 5); buf:w8(1, 1); buf:w16(2, species(mon))
  buf:w8(26, number(draw()) % 3); buf:w8(27, number(draw()) % 2)
  buf:w16(28, M.randomDifferentSpeciesSeen(session, species(mon), draw))
  stringCopy(buf, 15, trainer)
  stringCopy(buf, 4, nick)
  local id = Tv.playerId(session) % 65536
  buf:w16(32, id); buf:w16(34, id); buf:w8(30, 2)
  buf:w8(31, nick[1] == 252 and nick[2] == 21 and 1 or 2)
  stringCopy(buf, 4, M.strip(nick))
  list[index] = require("src.save_convert.gen3_port.sections.rs_tv_shows").readSlot(buf:str(), C)
  return true, nick, var8006, queueResult
end
return M
