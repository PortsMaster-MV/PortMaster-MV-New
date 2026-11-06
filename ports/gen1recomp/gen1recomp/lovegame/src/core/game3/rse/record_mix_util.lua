local MixUtil = {}

-- pokeemerald/src/record_mixing.c:130
local ORDERS = {
  [2] = { { 1, 0 } },
  [3] = { { 1, 2, 0 }, { 2, 0, 1 } },
  [4] = {
    { 1, 0, 3, 2 }, { 3, 0, 1, 2 }, { 2, 0, 3, 1 },
    { 1, 3, 0, 2 }, { 2, 3, 0, 1 }, { 3, 2, 0, 1 },
    { 1, 2, 3, 0 }, { 2, 3, 1, 0 }, { 3, 2, 1, 0 },
  },
}
MixUtil.ORDERS = ORDERS

-- pokeemerald/include/constants/global.h:20
MixUtil.LANGUAGE_JAPANESE = 1
MixUtil.GAME_LANGUAGE = 2

function MixUtil.deep(v)
  if type(v) ~= "table" then return v end
  local out = {}
  for k, x in pairs(v) do out[k] = MixUtil.deep(x) end
  return out
end

function MixUtil.num(v)
  return tonumber(v) or 0
end

-- pokeemerald/src/link.c:326
function MixUtil.linkTrainerId(p)
  if type(p) ~= "table" then return 0 end
  local full = tonumber(p.linkTrainerId)
  if full then return full end
  return (tonumber(p.trainerId) or 0) % 0x10000
end

function MixUtil.sessionLinkTrainerId(sess)
  if type(sess) ~= "table" then return 0 end
  local tid = math.floor(tonumber(sess.trainerId or sess.playerId) or 0) % 0x10000
  local sid = math.floor(tonumber(sess.secretId) or 0) % 0x10000
  return tid + sid * 0x10000
end

function MixUtil.trainerIdBytes(sess)
  local full = MixUtil.sessionLinkTrainerId(sess)
  return { full % 256, math.floor(full / 256) % 256, math.floor(full / 65536) % 256, math.floor(full / 16777216) % 256 }
end

-- pokeemerald/src/new_game.c:72
function MixUtil.getTrainerId(bytes)
  if type(bytes) ~= "table" then return tonumber(bytes) or 0 end
  return MixUtil.num(bytes[1]) + MixUtil.num(bytes[2]) * 0x100 + MixUtil.num(bytes[3]) * 0x10000
    + MixUtil.num(bytes[4]) * 0x1000000
end

-- pokeemerald/src/record_mixing.c:604
function MixUtil.shuffle(players)
  local count = #players
  local out = {}
  local rows = ORDERS[count]
  if not rows then
    for i = 1, count do out[i] = i end
    return out
  end
  local row = rows[(MixUtil.linkTrainerId(players[1]) % #rows) + 1]
  for i = 1, count do out[i] = row[i] + 1 end
  return out
end

function MixUtil.partner(players, myIndex)
  local idx = MixUtil.shuffle(players)
  local from = idx[myIndex] or myIndex
  return players[from], from
end

return MixUtil
