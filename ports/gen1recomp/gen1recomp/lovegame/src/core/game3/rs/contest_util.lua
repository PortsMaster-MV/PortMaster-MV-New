local Shared = require("src.core.game3.rse.contest_util")
local Contest = require("src.core.game3.rse.contest")
local U = setmetatable({}, {__index = Shared, __newindex = function(t, k, v)
  if k == "state" or k == "curWinner" then Shared[k] = v else rawset(t, k, v) end
end})
local function copy(t)
  if type(t) ~= "table" then return t end
  local out = {}; for k, v in pairs(t) do out[k] = copy(v) end; return out
end
local function number(v) return tonumber(v) or 0 end
function U.is(session)
  local C = require("src.core.game3.constants")
  local v = C.versionOf(session)
  return v == "ruby" or v == "sapphire"
end
U.WINNER = {ARTIST = 0, NORMAL = 1, SUPER = 2, HYPER_1 = 3, HYPER_2 = 4, HYPER_3 = 5,
  MASTER_1 = 6, MASTER_2 = 7, MASTER_3 = 8, MUSEUM_COOL = 9, MUSEUM_BEAUTY = 10,
  MUSEUM_CUTE = 11, MUSEUM_SMART = 12, MUSEUM_TOUGH = 13}

-- pokeruby/src/contest_2.c:4140
function U.winnerSaveIdx(session, rank, category, shift)
  rank = number(rank) % 256
  if rank == 0 or rank == 1 then return rank end
  if rank == 2 or rank == 3 then
    local first = rank == 2 and 2 or 5
    if shift then
      local winners = session.contestWinners or {}
      session.contestWinners = winners
      for i = first + 2, first + 1, -1 do winners[i + 1] = copy(winners[i]) end
    end
    return first
  end
  category = number(category)
  return category >= 0 and category <= 3 and 8 + category or 12
end
local function emptyWinner()
  local w = {personality = 0, trainerId = 0, species = 0, contestCategory = 0,
    monName = {}, trainerName = {}, nativeBytes = {}}
  for i = 1, 11 do w.monName[i] = 0 end
  for i = 1, 8 do w.trainerName[i] = 0 end
  for i = 1, 32 do w.nativeBytes[i] = 0 end
  return w
end
function U.clearHallWinners(session, data)
  local defaults = Shared.defaultWinners(data)
  session.contestWinners = session.contestWinners or {}
  for i = 0, 7 do
    local winner = emptyWinner()
    for k, v in pairs(defaults[i] or {}) do winner[k] = copy(v) end
    session.contestWinners[i + 1] = winner
  end
end
function U.clearAllWinners(session, data)
  session.contestWinners = {}; U.clearHallWinners(session, data)
  for i = 9, 13 do session.contestWinners[i] = emptyWinner() end
end

local function stringCopy(session, dst, value, size)
  local out = type(dst) == "table" and copy(dst) or {}
  local src = value
  if type(src) ~= "table" then
    local codec = require("src.save_convert.Gen3Save").forVersion(session.version)
    local encoded = codec.encodeString(tostring(src or ""), size)
    src = {}; for i = 1, #encoded do src[i] = encoded:byte(i) end
  end
  for i = 1, size do if out[i] == nil then out[i] = 0 end end
  for i = 1, size do
    local byte = src[i] or 255; out[i] = byte
    if byte == 255 then break end
  end
  return out
end

function U.linkTrainerName(c, index)
  local players = c.nativeLinkPlayers or c.linkPlayerInfo
  local row = players and players[players[0] ~= nil and index or index + 1]
  if type(row) == "table" then return row.nameBytes or row.name or row.trainerName end
  local link = c.link and c.link.link
  if link and type(link.players) == "function" then
    local list = link:players(); row = list and list[index + 1]
    if type(row) == "table" then return row.nameBytes or row.name or row.trainerName end
  end
  return (c.mons[index] or {}).trainerName
end
function U.trainerNameAt(c, index)
  local name = c:isLink() and U.linkTrainerName(c, index) or (c.mons[index] or {}).trainerName
  return Shared.trainerName({trainerName = name})
end

-- pokeruby/src/contest_2.c:4059
function U.saveContestWinner(session, rank, c)
  c = c or Shared.current(); rank = number(rank) % 256
  local caption = c:random() % 3
  local i = 0; while i < 3 and c.standings[i] ~= 0 do i = i + 1 end
  if rank == U.SAVE_FOR_MUSEUM and i ~= c.playerIndex then return false end
  if c.category >= 0 and c.category <= 4 then caption = caption + c.category * 3 end
  local m, row, idx = c.mons[i]
  if rank == U.SAVE_FOR_ARTIST then row = copy(Shared.curWinner) or emptyWinner()
  else
    session.contestWinners = session.contestWinners or {}
    idx = U.winnerSaveIdx(session, rank, c.category, true)
    row = copy(session.contestWinners[idx + 1]) or emptyWinner()
  end
  row.personality, row.species, row.trainerId = m.personality or 0, m.species or 0, m.otId or 0
  row.monName = stringCopy(session, row.monName, m.nickname, 11)
  local trainer = rank == U.SAVE_FOR_ARTIST and c:isLink() and U.linkTrainerName(c, i) or m.trainerName
  row.trainerName = stringCopy(session, row.trainerName, trainer, 8)
  row.contestCategory = (rank == U.SAVE_FOR_MUSEUM or rank == U.SAVE_FOR_ARTIST) and caption or c.category
  row.contestRank = nil
  if rank == U.SAVE_FOR_ARTIST then Shared.curWinner = row else session.contestWinners[idx + 1] = row end
  return true
end

function U.contestantFromMon(mon, session)
  local value = Shared.contestantFromMon(mon, session)
  local id = tonumber(mon.otId) or 0
  value.otId = id >= 65536 and id % 4294967296 or
    id % 65536 + ((tonumber(mon.otSecretId) or 0) % 65536) * 65536
  return value
end

-- pokeruby/src/contest_link_util.c:2560
-- contest_2.c:713
function U.tryEnterContestMon(session, index, category, rank, opts)
  opts = opts or {}
  local mon = session.party[index + 1]
  local result = Shared.eligibility(mon, category, rank)
  if result ~= 0 then
    local c = Contest.new({data = opts.data, category = category, rank = rank, rng = opts.rng})
    c:setContestants({gameClear = false, player = U.contestantFromMon(mon, session)})
    c:calculateRound1Points()
    Shared.state = {contest = c, partyIndex = index, category = category, rank = rank}
  end
  return result
end
local function player(session)
  local st = Shared.state
  return st and session.party and session.party[st.partyIndex + 1]
end
function U.giveMonContestRibbon(session)
  local c, st, mon = Shared.current(), Shared.state, player(session)
  if not c or not mon or c.standings[c.playerIndex] ~= 0 then return false end
  local R = require("src.core.game3.rse.ribbons")
  local name = Shared.categoryName(st.category)
  if not name then return false end
  local have = R.get(mon, name)
  if have <= st.rank and have < 4 then R.set(mon, name, have + 1); return true end
  return false
end
function U.giveMonArtistRibbon(session)
  local c, mon = Shared.current(), player(session)
  if not c or not mon then return false end
  local R = require("src.core.game3.rse.ribbons")
  if R.get(mon, "artist") == 0 and Shared.shouldReadyContestArtist(c) then
    R.set(mon, "artist", 1); return true
  end
  return false
end
return U
