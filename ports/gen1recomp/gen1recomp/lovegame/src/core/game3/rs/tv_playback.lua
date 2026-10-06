local Tv = require("src.core.game3.rse.tv")
local Q = require("src.core.game3.rs.tv_queries")
local M = {names = {}, SHOW = {}}
local function n(v) return math.floor(tonumber(v) or 0) end
local function on(v) return v == true or n(v) ~= 0 end
local function random() return require("src.core.game3.rng").Random() end
local function signed(v) v = n(v) % 4294967296; return v >= 2147483648 and v - 4294967296 or v end
local function trunc(v) return v < 0 and math.ceil(v) or math.floor(v) end
local function same(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not same(v, b[k]) then return false end end
  for k in pairs(b) do if a[k] == nil then return false end end
  return true
end
local function codec(session) return require("src.save_convert.Gen3Save").forVersion(session.version) end
function M.rawShow(session, show)
  local raw = show.nativeBytes and string.char(unpack(show.nativeBytes)) or string.rep("\0", 36)
  return require("src.save_convert.gen3_port.sections.rs_tv_shows").render(codec(session), raw, show, same)
end
local function terminated(a)
  local out = {}
  for _, v in ipairs(a) do if v == 255 then break end; out[#out + 1] = v end
  out[#out + 1] = 255
  return out
end
local CONTROL_LENGTHS = {1, 2, 2, 2, 4, 2, 2, 1, 2, 1, 1, 3, 2, 2, 2, 1, 3, 2, 2, 2, 2, 1, 1}
local japanese
function M.displayBytes(session, a)
  local out, glyphs, i, jp = {}, {}, 1, false
  local function flush()
    if #glyphs > 0 then
      out[#out + 1] = codec(session).decodeString(string.char(unpack(glyphs)), 0, #glyphs)
      glyphs = {}
    end
  end
  while i <= #a and a[i] ~= 255 do
    if a[i] == 252 then
      flush()
      local command = a[i + 1] or 0
      local length = CONTROL_LENGTHS[command + 1] or 0
      local packet = {}; for j = i, math.min(#a, i + length) do packet[#packet + 1] = a[j] end
      out[#out + 1] = string.char(unpack(packet))
      if command == 21 then jp = true elseif command == 22 then jp = false end
      i = i + 1 + length
    elseif jp then
      if not japanese then
        japanese = {}
        for glyph, id in pairs(require("src.ui.game3.frlg_font").JAPANESE_GLYPHS) do
          if japanese[id] == nil or glyph < japanese[id] then japanese[id] = glyph end
        end
      end
      out[#out + 1] = japanese[a[i]] or codec(session).decodeString(string.char(a[i]), 0, 1)
      i = i + 1
    else glyphs[#glyphs + 1], i = a[i], i + 1 end
  end
  flush()
  return table.concat(out)
end
-- tv.c:2657
function M.international(bytes, language)
  local a = terminated(bytes)
  if n(language) < 2 then
    a = Q.strip(a); table.remove(a)
    table.insert(a, 1, 21); table.insert(a, 1, 252)
    a[#a + 1], a[#a + 2], a[#a + 3] = 252, 22, 255
  end
  return a
end
-- tv.c:1561
function M.decimal(value, width)
  value = signed(value)
  if not width then
    width = 1
    for i = 1, 8 do if trunc(value / 10 ^ i) == 0 then width = i; break end end
  end
  local out, power, started = {}, 10 ^ (width - 1), false
  while power >= 1 do
    local digit = trunc(value / power) % 65536
    if started or digit ~= 0 or power == 1 then
      started = true; out[#out + 1] = digit <= 9 and tostring(digit) or "?"
    end
    value = signed(value - power * digit)
    power = math.floor(power / 10)
  end
  return table.concat(out)
end
local function named(key, fallback, ...)
  local f = M.names[key] or (Tv.names and Tv.names[key])
  if f then return f(...) end
  return fallback(...)
end
local function speciesName(id)
  return named("species", function(i) return require("src.core.game3.pokemon").name(i) end, n(id))
end
local function moveName(id)
  return named("move", function(i) return require("src.core.game3.pokemon").moveName(i) end, n(id))
end
local function itemId(id, session)
  id = n(id) % 65536
  if id >= require("src.core.game3.constants").active(session):require("items", "ITEMS_COUNT") then return 0 end
  return id
end
local function itemName(id, session)
  return named("item", function(i) return require("src.core.game3.items_data").displayName(itemId(i, session)) end, n(id))
end
local function price(id, session)
  return n(named("itemPrice", function(i) return require("src.core.game3.items_data").info(itemId(i, session)).price end, n(id)))
end
local function romText(key)
  return named("text", function(k) return require("src.core.game3.rse.init").text(k) end, key)
end
-- easy_chat_2.c:2542
function M.word(id)
  id = n(id) % 65536
  return named("word", function(value)
    if value == 65535 then return "" end
    local E = require("src.core.game3.easy_chat_text")
    local group = E.group(math.floor(value / 512) % 128)
    if group then
      for _, word in ipairs(group.words) do if word.id == value then return word.text end end
    end
    return romText("gOtherText_ThreeQuestions")
  end, id)
end
function M.phrase(words, columns, rows)
  return named("phrase", function(w, cols, lines)
    local out, at = {}, 1
    for row = 1, lines do
      for col = 1, cols do
        local id = n(w[at] == nil and 65535 or w[at]); at = at + 1
        out[#out + 1] = M.word(id)
        if col < cols and id ~= 65535 then out[#out + 1] = " " end
      end
      if row < lines then out[#out + 1] = "\n" end
    end
    return table.concat(out)
  end, words or {}, columns, rows)
end
-- region_map.c:1119
function M.mapName(session, section)
  return named("mapName", function(sec)
    local C = require("src.core.game3.constants").active(session)
    if sec == C:require("region_map_sections", "MAPSEC_SECRET_BASE") then
      local R = require("src.core.game3.rse.init")
      local index = R.var("VAR_CURRENT_SECRET_BASE", session)
      local base = (session.secretBases or {})[index + 1] or {}
      require("src.core.game3.rse.secret_base")._curId = n(base.secretBaseId)
      local owner = Q.encode(session, base.trainerName or base.playerName, 7)
      table.remove(owner)
      return Q.text(session, owner) .. romText("gOtherText_PlayersBase")
    end
    if sec < C:require("region_map_sections", "MAPSEC_NONE") then return require("src.ui.game3.rse.mapsec").name(sec) end
    return string.rep(" ", 18)
  end, n(section))
end
function M.syncOutbreak(session)
  if n(session.outbreakPokemonSpecies) == 0 then session.outbreak = nil; return nil end
  local Profile = require("src.core.game3.profile").forSession(session)
  local C, map = require("src.core.game3.constants").active(session)
  for name, row in pairs(C.map_groups.byName) do
    if n(row.group) == n(session.outbreakLocationMapGroup) and n(row.num) == n(session.outbreakLocationMapNum) then
      map = Profile.map.enginePrefix .. name:sub(5); break
    end
  end
  local moves = {}; for i = 1, 4 do moves[i] = n((session.outbreakPokemonMoves or {})[i]) end
  session.outbreak = {species = n(session.outbreakPokemonSpecies), level = n(session.outbreakPokemonLevel),
    moves = moves, probability = n(session.outbreakPokemonProbability), map = map}
  return session.outbreak
end
local TEXT_OFFSETS = {
  [1] = {playerName = 16}, [2] = {playerName = 16}, [3] = {playerName = 5, nickname = 16},
  [5] = {pokemonName = 4, trainerName = 15}, [6] = {pokemonNickname = 8, playerName = 22},
  [7] = {playerName = 2, opponentName = 12}, [21] = {nickname = 4, playerName = 19},
  [22] = {playerName = 19}, [23] = {playerName = 19}, [24] = {playerName = 19}, [25] = {playerName = 19},
}
local GROUPS = {
  [1] = "gTVFanClubTextGroup", [2] = "gTVRecentHappeningsTextGroup", [3] = "gTVFanClubOpinionsTextGroup",
  [5] = "gTVNameRaterTextGroup", [6] = "gTVBravoTrainerTextGroup", [7] = "gTVBravoTrainerBattleTowerTextGroup",
  [21] = "gTVPokemonTodayTextGroup", [22] = "gTVSmartShopperTextGroup", [23] = "gTVPokemonTodayFailedCaptureTextGroup",
  [24] = "gTVFishingGuruAdviceTextGroup", [25] = "gTVWorldOfMastersTextGroup", [41] = "gTVPokemonOutbreakTextGroup",
}
M.GROUPS = GROUPS
local function context(session, show, vars, rawVars, rand)
  local raw = show and M.rawShow(session, show)
  local snapshot = raw and require("src.save_convert.gen3_port.sections.rs_tv_shows").readSlot(raw, codec(session))
  local t = {session = session, show = snapshot, vars = vars, bytes = rawVars, state = n(Tv._showState) % 256,
    raw = raw, random = rand or random, result = 0}
  function t.set(value) Tv._showState = n(value) % 256 end
  function t.done() t.result = 1; Tv._result = true; t.set(0); show.active = false end
  function t.putBytes(i, a) rawVars[i] = terminated(a); vars[i] = M.displayBytes(session, rawVars[i]) end
  function t.str(i, value) vars[i] = tostring(value or ""); rawVars[i] = Q.encode(session, vars[i]) end
  function t.nameBytes(field)
    local off = assert(TEXT_OFFSETS[n(t.show.kind)][field], "RS TV name field missing")
    local a = {}
    for at = off + 1, #t.raw do
      a[#a + 1] = t.raw:byte(at)
      if a[#a] == 255 then break end
    end
    return terminated(a)
  end
  function t.intl(i, field, language) t.putBytes(i, M.international(t.nameBytes(field), language)) end
  function t.convert(i, source, language) t.putBytes(i, M.international(rawVars[source] or Q.encode(session, vars[source]), language)) end
  function t.species(i, id) t.str(i, speciesName(id)) end
  function t.move(i, id) t.str(i, moveName(id)) end
  function t.item(i, id) t.str(i, itemName(id, session)) end
  function t.map(i, sec) t.str(i, M.mapName(session, sec)) end
  function t.word(i, id) t.str(i, M.word(id)) end
  function t.num(idx0, value) t.str(idx0 + 1, M.decimal(value)) end
  function t.category(idx0, cat)
    cat = n(cat); if cat >= 0 and cat <= 4 then t.str(idx0 + 1, romText("gStdStrings[" .. cat .. "]")) end
  end
  function t.rank(idx0, rank)
    rank = n(rank); if rank >= 0 and rank <= 3 then t.str(idx0 + 1, romText("gStdStrings[" .. (rank + 5) .. "]")) end
  end
  return t
end
-- tv.c:1929
local function randomWord(t)
  local words = t.show.words or {}; local at = n(t.random()) % 6
  for _ = 1, 6 do
    local id = words[at + 1]
    if id ~= nil and n(id) ~= 65535 then t.word(3, id); return end
    at = (at + 1) % 6
  end
  error("native RS TV six-word scan has no terminating non-FFFF word")
end
-- tv.c:2663
M.SHOW[6] = function(t)
  local s, st = t.show, t.state
  if st == 0 then
    t.intl(1, "playerName", s.language); t.category(1, s.contestCategory); t.rank(2, s.contestRank)
    t.set(Q.equal(Q.encode(t.session, speciesName(s.species), 11), t.nameBytes("pokemonNickname")) and 8 or 1)
  elseif st == 1 then t.species(1, s.species); t.intl(2, "pokemonNickname", s.pokemonNameLanguage); t.category(2, s.contestCategory); t.set(2)
  elseif st == 2 then t.intl(1, "playerName", s.language); t.set(n(s.contestResult) == 0 and 3 or 4)
  elseif st == 3 or st == 4 then
    t.intl(1, "playerName", s.language); t.word(2, (s.words or {})[1]); t.num(2, n(s.contestResult) + 1); t.set(5)
  elseif st == 5 then
    t.intl(1, "playerName", s.language); t.category(1, s.contestCategory); t.word(3, (s.words or {})[2]); t.set(n(s.move) ~= 0 and 6 or 7)
  elseif st == 6 then t.species(1, s.species); t.move(2, s.move); t.word(3, (s.words or {})[2]); t.set(7)
  elseif st == 7 then t.intl(1, "playerName", s.language); t.species(2, s.species); t.done()
  elseif st == 8 then t.species(1, s.species); t.set(2) end
  return st
end
-- tv.c:2734
M.SHOW[7] = function(t)
  local s, st = t.show, t.state
  if st == 0 then t.intl(1, "playerName", s.playerLanguage); t.species(2, s.species); t.set(n(s.numFights) >= 7 and 1 or 2)
  elseif st == 1 then t.num(0, s.btLevel); t.num(1, s.numFights); t.set(n(s.battleOutcome) == 1 and 3 or 4)
  elseif st == 2 then t.intl(1, "opponentName", s.playerLanguage); t.num(1, n(s.numFights) + 1); t.set(n(s.interviewResponse) == 0 and 5 or 6)
  elseif st == 3 or st == 4 then t.intl(1, "opponentName", s.playerLanguage); t.species(2, s.defeatedSpecies); t.set(n(s.interviewResponse) == 0 and 5 or 6)
  elseif st == 5 or st == 6 then t.intl(1, "opponentName", s.playerLanguage); t.set(11)
  elseif st == 7 then t.set(11)
  elseif st == 8 or st == 9 or st == 10 then t.intl(1, "playerName", s.playerLanguage); t.set(11)
  elseif st == 11 then t.word(1, (s.words or {})[1]); t.set(n(s.interviewResponse) == 0 and 12 or 13)
  elseif st == 12 or st == 13 then
    t.word(1, (s.words or {})[1]); t.intl(2, "playerName", s.playerLanguage); t.intl(3, "opponentName", s.playerLanguage); t.set(14)
  elseif st == 14 then t.intl(1, "playerName", s.playerLanguage); t.species(2, s.species); t.done() end
  return st
end
-- tv.c:2823
M.SHOW[22] = function(t)
  local s, st = t.show, t.state; local ids, amounts = s.itemIds or {}, s.itemAmounts or {}
  if st == 0 then t.intl(1, "playerName", s.language); t.map(2, s.shopLocation); t.set(n(amounts[1]) >= 255 and 11 or 1)
  elseif st == 1 then t.intl(1, "playerName", s.language); t.item(2, ids[1]); t.num(2, amounts[1]); t.set(st + n(t.random()) % 4 + 1)
  elseif st == 2 or st == 4 or st == 5 then t.set(n(ids[2]) ~= 0 and 6 or 10)
  elseif st == 3 then t.num(2, n(amounts[1]) + 1); t.set(n(ids[2]) ~= 0 and 6 or 10)
  elseif st == 6 then
    t.item(2, ids[2]); t.num(2, amounts[2]); t.set(n(ids[3]) ~= 0 and 7 or (n(s.priceReduced) == 1 and 8 or 9))
  elseif st == 7 then t.item(2, ids[3]); t.num(2, amounts[3]); t.set(n(s.priceReduced) == 1 and 8 or 9)
  elseif st == 8 then t.set(n(amounts[1]) < 255 and 9 or 12)
  elseif st == 9 then
    local total = 0
    for i = 1, 3 do if n(ids[i]) ~= 0 then total = signed(total + price(ids[i], t.session) * n(amounts[i])) end end
    if n(s.priceReduced) == 1 then total = math.floor(total / 2) end
    t.num(1, total); t.done()
  elseif st == 10 then t.set(n(s.priceReduced) == 1 and 8 or 9)
  elseif st == 11 then t.intl(1, "playerName", s.language); t.item(2, ids[1]); t.set(n(s.priceReduced) == 1 and 8 or 12)
  elseif st == 12 then t.intl(1, "playerName", s.language); t.done() end
  return st
end
-- tv.c:1948
local function nicknameHash(t)
  local a, sum = t.nameBytes("pokemonName"), 0
  for i = 1, math.min(11, #a) do if a[i] == 255 then break end; sum = sum + a[i] end
  return sum % 8
end
local function substring(t, destination0, pos, mode, which, species)
  local field = which == 0 and "trainerName" or which == 1 and "pokemonName" or nil
  local a = field and t.nameBytes(field) or Q.encode(t.session, speciesName(species), 11)
  local length = #a - 1
  local function at(index)
    if field then
      local offset = TEXT_OFFSETS[5][field]
      return t.raw:byte(offset + index + 1) or 255
    end
    return a[index + 1] or 255
  end
  local selected
  if mode == 0 then selected = {at(pos), 255}
  elseif mode == 1 then selected = {at(length - pos), 255}
  elseif mode == 2 then selected = {at(pos), at(pos + 1), 255}
  else selected = {at(length - (pos + 2)), at(length - (pos + 1)), 255} end
  t.putBytes(destination0 + 1, selected)
end
-- tv.c:2911
M.SHOW[5] = function(t)
  local s, st = t.show, t.state
  if st == 0 then
    t.intl(1, "trainerName", s.language); t.species(2, s.species); t.intl(3, "pokemonName", s.pokemonNameLanguage); t.set(nicknameHash(t) + 1)
  elseif st >= 1 and st <= 8 then
    if st == 2 then t.intl(1, "trainerName", s.language) end
    if n(s.random) <= 2 then t.set(n(s.random) + 9) end
  elseif st == 9 or st == 10 or st == 11 then
    substring(t, 0, 1, 0, 1, 0); t.convert(3, 1, s.pokemonNameLanguage)
    substring(t, 0, 0, 0, 1, 0); t.convert(2, 1, s.pokemonNameLanguage)
    t.intl(1, "pokemonName", s.pokemonNameLanguage); t.set(12)
  elseif st == 13 then
    substring(t, 0, 0, 3, 1, 0); t.convert(3, 1, s.pokemonNameLanguage)
    substring(t, 0, 0, 2, 0, 0); t.convert(2, 1, s.language)
    t.intl(1, "trainerName", s.language); t.set(14)
  elseif st == 14 then
    substring(t, 0, 0, 3, 0, 0); t.convert(3, 1, s.language)
    substring(t, 0, 0, 2, 1, 0); t.convert(2, 1, s.pokemonNameLanguage)
    t.intl(1, "trainerName", s.language); t.set(18)
  elseif st == 15 then
    substring(t, 1, 0, 2, 1, 0); t.convert(1, 2, s.pokemonNameLanguage); t.species(2, s.species)
    substring(t, 2, 0, 3, 2, s.species); t.set(16)
  elseif st == 16 then
    substring(t, 0, 0, 3, 1, 0); t.convert(3, 1, s.pokemonNameLanguage)
    substring(t, 0, 0, 2, 2, s.species); t.set(17)
  elseif st == 17 then
    substring(t, 1, 0, 2, 1, 0); t.convert(1, 2, s.pokemonNameLanguage)
    substring(t, 2, 0, 3, 2, s.randomSpecies); t.species(2, s.randomSpecies); t.set(18)
  elseif st == 12 or st == 18 then
    st = 18
    t.intl(1, "pokemonName", s.pokemonNameLanguage); t.intl(2, "trainerName", s.language); t.done()
  end
  return st
end
-- tv.c:3007
M.SHOW[21] = function(t)
  local s, st = t.show, t.state
  if st == 0 then
    t.intl(1, "playerName", s.language); t.species(2, s.species); t.intl(3, "nickname", s.language2)
    local master = require("src.core.game3.constants").active(t.session):require("items", "ITEM_MASTER_BALL")
    t.set(n(s.ball) == master and 5 or 1)
  elseif st == 1 then t.set(2)
  elseif st == 2 then t.item(2, s.ball); t.num(2, s.nBallsUsed); t.set(n(s.nBallsUsed) < 4 and 3 or 4)
  elseif st == 3 then t.intl(1, "playerName", s.language); t.species(2, s.species); t.intl(3, "nickname", s.language2); t.set(6)
  elseif st == 4 then t.set(6)
  elseif st == 5 then t.intl(1, "playerName", s.language); t.species(2, s.species); t.set(6)
  elseif st == 6 then
    t.intl(1, "playerName", s.language); t.species(2, s.species); t.intl(3, "nickname", s.language2); t.set(st + n(t.random()) % 4 + 1)
  elseif st == 7 or st == 8 then
    t.species(1, s.species); t.intl(2, "nickname", s.language2)
    t.species(3, Q.randomDifferentSpeciesSeen(t.session, n(s.species), t.random)); t.set(11)
  elseif st == 9 or st == 10 then t.species(1, s.species); t.intl(2, "nickname", s.language2); t.set(11)
  elseif st == 11 then t.done() end
  return st
end
-- tv.c:3076
M.SHOW[23] = function(t)
  local s, st = t.show, t.state
  if st == 0 then t.intl(1, "playerName", s.language); t.species(2, s.species); t.set(1)
  elseif st == 1 then
    t.intl(1, "playerName", s.language); t.map(2, s.location); t.species(3, s.species2); t.set(n(s.outcome) == 1 and 3 or 2)
  elseif st == 2 or st == 3 then t.intl(1, "playerName", s.language); t.num(1, s.nBallsUsed); t.set(n(t.random()) % 3 == 0 and 5 or 4)
  elseif st == 4 or st == 5 then t.intl(1, "playerName", s.language); t.set(6)
  elseif st == 6 then t.done() end
  return st
end
-- tv.c:3120
M.SHOW[1] = function(t)
  local s, st = t.show, t.state
  if st == 0 then t.intl(1, "playerName", s.language); t.species(2, s.species); t.set(50)
  elseif st == 1 then local choice = n(t.random()) % 4 + 1; t.set(choice == 1 and 2 or choice + 2)
  elseif st == 2 then t.set(51)
  elseif st == 3 then t.set(st + n(t.random()) % 3 + 1)
  elseif st == 4 or st == 5 or st == 6 then randomWord(t); t.set(7)
  elseif st == 7 then t.num(2, n(t.random()) % 31 + 70); t.done()
  elseif st == 50 or st == 51 then
    t.str(4, M.phrase(s.words, 2, 2)); t.set(st == 50 and 1 or 3); return nil, t.vars[4]
  end
  return st
end
M.SHOW[2] = function(t)
  local s, st = t.show, t.state
  if st == 0 then t.intl(1, "playerName", s.language); randomWord(t); t.set(50)
  elseif st == 1 then t.set(st + 1 + n(t.random()) % 3)
  elseif st == 2 or st == 3 or st == 4 then t.set(5)
  elseif st == 5 then t.done()
  elseif st == 50 then t.str(4, M.phrase(s.words, 2, 2)); t.set(1); return nil, t.vars[4] end
  return st
end
-- tv.c:3207
M.SHOW[3] = function(t)
  local s, st = t.show, t.state
  if st == 0 then
    t.intl(1, "playerName", s.language); t.species(2, s.species); t.intl(3, "nickname", s.pokemonNameLanguage); t.set(n(s.questionAsked) + 1)
  elseif st == 1 or st == 2 or st == 3 then
    t.intl(1, "playerName", s.language); t.species(2, s.species); t.word(3, (s.words or {})[1]); t.set(4)
  elseif st == 4 then t.intl(1, "playerName", s.language); t.word(3, (s.words or {})[2]); t.done() end
  return st
end
-- tv.c:3243
M.SHOW[41] = function(t)
  local s, session = t.show, t.session
  t.map(1, s.locationMapNum); t.species(2, s.species); t.done()
  session.outbreakPokemonSpecies, session.outbreakLocationMapNum, session.outbreakLocationMapGroup = n(s.species), n(s.locationMapNum), n(s.locationMapGroup)
  session.outbreakPokemonLevel, session.outbreakUnused1, session.outbreakUnused2 = n(s.level), n(s.unused1), n(s.unused2)
  session.outbreakPokemonMoves = {}; for i = 1, 4 do session.outbreakPokemonMoves[i] = n((s.moves or {})[i]) end
  session.outbreakUnused3, session.outbreakPokemonProbability, session.outbreakDaysLeft = n(s.unused3), n(s.probability), 2
  M.syncOutbreak(session)
  return 0
end
-- tv.c:3308
M.SHOW[24] = function(t)
  local s = t.show; local st = n(s.nBites) < n(s.nFails) and 0 or 1
  t.set(st); t.intl(1, "playerName", s.language); t.species(2, s.species)
  t.num(2, st == 0 and s.nFails or s.nBites); t.done()
  return st
end
M.SHOW[25] = function(t)
  local s, st = t.show, t.state
  if st == 0 then t.intl(1, "playerName", s.language); t.num(1, s.steps); t.num(2, s.numPokeCaught); t.set(1)
  elseif st == 1 then t.species(1, s.species); t.set(2)
  elseif st == 2 then t.intl(1, "playerName", s.language); t.map(2, s.location); t.species(3, s.caughtPoke); t.done() end
  return st
end
-- tv.c:2607
function M.doTVShow(session, index, vars, rawVars, rand)
  local show = Tv.state(session).tvShows[n(index)]
  if not show or Q.activeByte(show) == 0 then return nil, nil end
  local fn = M.SHOW[n(show.kind)]
  if not fn then return nil, nil end
  Tv._result = false
  local t = context(session, show, vars or {}, rawVars or {}, rand)
  local state, text = fn(t)
  if text ~= nil then return {text = text}, t.result end
  return {group = GROUPS[n(show.kind)], index = state}, t.result
end
-- tv.c:3254
function M.doGabby(session, vars, rawVars)
  local g = Tv.state(session).gabbyAndTyData
  local t = context(session, nil, vars or {}, rawVars or {})
  local st = t.state; Tv._result = false
  if st == 0 then t.map(1, g.mapnum); t.set(n(g.battleNum) > 1 and 1 or 2)
  elseif st == 1 then t.set(2)
  elseif st == 2 then
    if not on(g.battleTookMoreThanOneTurn) then t.set(4)
    elseif on(g.playerThrewABall) then t.set(5)
    elseif on(g.playerUsedHealingItem) then t.set(6)
    elseif on(g.playerLostAMon) then t.set(7)
    else t.set(3) end
  elseif st == 3 then t.species(1, g.mon1); t.move(2, g.lastMove); t.species(3, g.mon2); t.set(8)
  elseif st >= 4 and st <= 7 then t.set(8)
  elseif st == 8 then
    t.word(1, type(g.quote) == "table" and g.quote[0] or g.quote); t.species(2, g.mon1); t.species(3, g.mon2)
    t.result = 1; Tv._result = true; t.set(0); g.onAir = false
  end
  return {group = "gTVGabbyAndTyTextGroup", index = st}, t.result
end
-- tv.c:1391
function M.doNews(session, hours, vars, rawVars)
  local list, index = Tv.state(session).pokeNews
  for i = 0, 15 do
    local entry = list[i]
    if entry and n(entry.kind) ~= 0 and n(entry.state) == 1 and n(entry.dayCountdown) < 3 then index = i; break end
  end
  if not index then return nil, 0 end
  local entry, group = list[index]
  if n(entry.dayCountdown) == 0 then
    entry.state = 2; group = n(hours) < 20 and "gTVNewsTextGroup2" or "gTVNewsTextGroup3"
  else
    entry.state = 0; group = "gTVNewsTextGroup1"
    if vars then vars[1] = M.decimal(entry.dayCountdown, 1) end
    if rawVars then rawVars[1] = Q.encode(session, M.decimal(entry.dayCountdown, 1)) end
  end
  return {group = group, index = n(entry.kind)}, 1
end
return M
