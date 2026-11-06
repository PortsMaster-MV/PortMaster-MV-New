local Family = require("src.core.game3.link.family")

local RecordMix = {}

RecordMix.MSG = { PACKET = "rse_record_mix" }

RecordMix.state = "off"
RecordMix.last = nil

local function rse()
  return require("src.core.game3.rse.init")
end

local function link()
  return require("src.core.game3.link")
end

local function sessionOf(session)
  if type(session) == "table" then return session end
  return link().session()
end

local MODULES = {
  tv = "src.core.game3.rse.tv",
  secretBase = "src.core.game3.rse.secret_base",
  oldMan = "src.core.game3.rse.old_man",
  dewfordTrend = "src.core.game3.rse.dewford_trend",
  lilycoveLady = "src.core.game3.rse.lilycove_lady",
  daycareMail = "src.core.game3.rse.daycare_mail_mix",
  tower = "src.core.game3.rse.frontier.tower",
  gift = "src.core.game3.rse.record_mixing_gift",
  apprentice = "src.core.game3.rse.frontier.apprentice",
  rankingHall = "src.core.game3.rse.frontier.ranking_hall",
}

local function system(name)
  local path = MODULES[name]
  if path then
    local okR, mod = pcall(require, path)
    if okR and type(mod) == "table" then return mod end
  end
  local ok, impl = pcall(rse().system, name)
  return ok and type(impl) == "table" and impl or nil
end

local function call(impl, fn, ...)
  local f = impl and impl[fn]
  if type(f) ~= "function" then return nil, false end
  local ok, value = pcall(f, ...)
  if not ok then return nil, false end
  return value, true
end

local function deep(v)
  if type(v) ~= "table" then return v end
  local out = {}
  for k, x in pairs(v) do out[k] = deep(x) end
  return out
end

function RecordMix.toWire(v)
  if type(v) ~= "table" then return v end
  local out = {}
  for k, x in pairs(v) do
    if type(k) == "number" then out["#" .. tostring(k)] = RecordMix.toWire(x)
    elseif type(k) == "string" then out[k] = RecordMix.toWire(x) end
  end
  return out
end

function RecordMix.fromWire(v)
  if type(v) ~= "table" then return v end
  local out = {}
  for k, x in pairs(v) do
    local n = type(k) == "string" and tonumber(k:match("^#(%-?%d+)$")) or nil
    out[n or k] = RecordMix.fromWire(x)
  end
  return out
end

-- pokeemerald/src/record_mixing.c:220 PrepareExchangePacket
function RecordMix.packet(session, multiplayerId, partners)
  session = sessionOf(session)
  local sess = type(session) == "table" and session or {}
  local MixUtil = require("src.core.game3.rse.record_mix_util")
  if Family.isRubySapphire(sess.version or Family.activeVersion()) then
    return require("src.core.game3.link.rs_record_mix").packet(sess, tonumber(multiplayerId) or 0)
  end
  if sess.version == "emerald" and require("src.core.game3.link.rs_record_cross").anyRS(partners) then
    return require("src.core.game3.link.rs_record_cross").packet(sess, tonumber(multiplayerId) or 0)
  end
  local out = {
    version = sess.version or Family.activeVersion(),
    trainerId = tonumber(sess.trainerId or sess.id) or 0,
    linkTrainerId = MixUtil.sessionLinkTrainerId(sess),
    language = MixUtil.GAME_LANGUAGE,
    name = sess.name or sess.playerName,
  }
  out.secretBases = call(system("secretBase"), "mixExport", session)
  local Tv = system("tv")
  pcall(function() Tv.deactivateAllNormalShows(session) end)
  local tvData = call(Tv, "mixExport", session)
  if type(tvData) == "table" then
    out.tvShows, out.pokeNews, out.tvShowByteSum = tvData.tvShows, tvData.pokeNews, tvData.tvShowByteSum
  end
  out.oldMan = call(system("oldMan"), "mixExport", session)
  local lady = system("lilycoveLady")
  out.lilycoveLady = call(lady, "mixExport", session)
  if out.lilycoveLady == nil then out.lilycoveLady = deep(call(lady, "state", session)) end
  out.dewfordTrends = call(system("dewfordTrend"), "mixExport", session)
  out.daycareMail = call(system("daycareMail"), "mixExport", session)
  out.battleTowerRecord = call(system("tower"), "mixExport", session)
  out.giftItem = call(system("gift"), "mixExport", session, tonumber(multiplayerId) or 0) or 0
  out.apprentices = call(system("apprentice"), "mixExport", session)
  out.hallRecords = call(system("rankingHall"), "mixExport", session)
  return deep(out)
end

-- pokeemerald/src/record_mixing.c:253 ReceiveExchangePacket
function RecordMix.receive(session, packets, myIndex, logger)
  session = sessionOf(session)
  local players = {}
  for i, p in ipairs(packets or {}) do players[i] = type(p) == "table" and deep(p) or {} end
  myIndex = tonumber(myIndex) or 1
  local Cross = require("src.core.game3.link.rs_record_cross")
  if Cross.mixed(session, players) then
    local applied = Cross.receive(session, players, myIndex)
    RecordMix.last = { players = #players, myIndex = myIndex, applied = applied }
    return applied
  end
  if Family.isRubySapphire(type(session) == "table" and session.version or Family.activeVersion()) then
    local applied = require("src.core.game3.link.rs_record_mix").receive(session, players, myIndex)
    RecordMix.last = { players = #players, myIndex = myIndex, applied = applied }
    return applied
  end
  for _, player in ipairs(players) do
    if Family.isRubySapphire(player.version) then
      return { unsupportedReason = "rs_record_mixing_cross_family_not_implemented" }
    end
  end
  local applied = {}
  local randSum = call(system("daycareMail"), "randSum", players[1]) or 0
  local bases = {}
  for i, p in ipairs(players) do bases[i] = p.secretBases or {} end
  local _, okS = call(system("secretBase"), "mixImport", session, bases, myIndex)
  applied.secretBases = okS
  local Tv = system("tv")
  local tvPlayers = {}
  for i, p in ipairs(players) do
    tvPlayers[i] = { tvShows = p.tvShows or {}, pokeNews = p.pokeNews or {}, trainerId = p.trainerId }
  end
  local _, okTv = call(Tv, "receiveShows", session, tvPlayers, myIndex)
  applied.tvShows = okTv
  local _, okNews = call(Tv, "receivePokeNews", session, tvPlayers, myIndex)
  applied.pokeNews = okNews
  local _, okOld = call(system("oldMan"), "mixImport", players, session, myIndex)
  applied.oldMan = okOld
  if not okOld then rse().missing("oldMan", "ReceiveOldManData", logger) end
  local trends = {}
  for i, p in ipairs(players) do trends[i] = p.dewfordTrends or {} end
  local _, okDew = call(system("dewfordTrend"), "mixImport", trends, session)
  applied.dewfordTrends = okDew
  local _, okMail = call(system("daycareMail"), "mixImport", players, session, myIndex, randSum)
  applied.daycareMail = okMail
  local _, okTower = call(system("tower"), "mixImport", players, session, myIndex)
  applied.battleTower = okTower
  local gift, okGift = call(system("gift"), "mixImport", players, session, myIndex)
  applied.giftItem = okGift
  applied.gift = gift
  local lady = system("lilycoveLady")
  local _, okLady = call(lady, "mixImport", players, session, myIndex)
  if not okLady then
    local _, okReset = call(lady, "resetForRecordMix", session)
    okLady = okReset
    rse().missing("lilycoveLady", "ReceiveLilycoveLadyData", logger)
  end
  applied.lilycoveLady = okLady
  local _, okApp = call(system("apprentice"), "mixImport", players, session, myIndex)
  applied.apprentices = okApp
  local _, okHall = call(system("rankingHall"), "mixImport", players, session, myIndex)
  applied.hallRecords = okHall
  RecordMix.last = { players = #players, myIndex = myIndex, applied = applied }
  return applied
end

local function flagSet(session, name)
  local version = type(session) == "table" and session.version or Family.activeVersion()
  local ok, id = pcall(Family.flag, version, name)
  if not ok then return end
  local store = link().store() or (type(session) == "table" and session.store)
  if type(store) == "table" then
    store.flags = store.flags or {}
    store.flags[id] = true
  end
end

local function varSet(ctx, session, name, value)
  local version = type(session) == "table" and session.version or Family.activeVersion()
  local ok, id = pcall(Family.var, version, name)
  if ok then link().setVar(ctx, id, value) end
end

local function message(text, opts)
  if not (type(love) == "table" and love.graphics) then return false end
  local okM, Message = pcall(require, "src.ui.game3.message")
  local okR, RomText = pcall(require, "src.core.game3.rom_text")
  if not (okM and okR and Message.show and RomText.has and RomText.has(text)) then return false end
  Message.show(RomText.plain(text), opts or { stay = true })
  return true
end

-- pokeemerald/src/record_mixing.c:166 RecordMixingPlayerSpotTriggered
function RecordMix.playerSpotTriggered(ctx, adapters)
  local L = link()
  local session = L.session()
  local lk = L.link
  if not (lk and lk:isOpen()) then
    RecordMix.state = "off"
    return false
  end
  local LB = require("src.core.game3.link.battle")
  local spot = L.getVar(ctx, LB.VAR_0x8005)
  local isRs = Family.isRubySapphire(type(session) == "table" and session.version or Family.activeVersion())
  local partners = lk.players and lk:players() or {}
  local nativeRsGroup = isRs or require("src.core.game3.link.rs_record_cross").anyRS(partners)
  for _, player in ipairs(partners) do
    if nativeRsGroup and not Family.isRubySapphire(player.version) and player.version ~= "emerald" then
      local applied = { unsupportedReason = "rs_record_mixing_unsupported_partner" }
      RecordMix.last = { applied = applied }
      RecordMix.state = "off"
      L.closeLink(applied.unsupportedReason)
      return false
    end
  end
  -- pokeemerald/src/record_mixing.c:321
  varSet(ctx, session, isRs and "VAR_TEMP_0" or "VAR_TEMP_MIXED_RECORDS", 1)
  local mine = RecordMix.packet(session, spot, partners)
  mine.spot = spot
  lk:send({ type = RecordMix.MSG.PACKET, spot = spot, packet = RecordMix.toWire(mine) })
  RecordMix.state = "mixing"
  message(isRs and "gOtherText_MixingRecordsWithFriend" or "gText_MixingRecords")
  local got = {}
  local Natives = require("src.core.game3.scripting.natives")
  local yielded = Natives.yieldHost(ctx, adapters, function() end)
  if not yielded then
    RecordMix.state = "off"
    return false
  end
  local ticks, shown = 0, nil
  ctx.nativePoll = function()
    ticks = ticks + 1
    if shown then
      -- pokeruby/src/record_mixing.c:157
      shown = shown + 1
      if shown <= 60 then return false end
      local okM, Message = pcall(require, "src.ui.game3.message")
      if okM and Message.closeStay then Message.closeStay() end
      RecordMix.state = "done"
      return true
    end
    local live = L.link
    if not (live and live:isOpen()) then
      RecordMix.state = "off"
      return true
    end
    live:update(0)
    local msg = live:take(RecordMix.MSG.PACKET)
    while msg do
      got[#got + 1] = msg
      msg = live:take(RecordMix.MSG.PACKET)
    end
    local want = math.max(1, LB.playerCount() - 1)
    if #got < want then return false end
    local rows = {}
    for _, m in ipairs(got) do
      rows[#rows + 1] = { spot = tonumber(m.spot) or 1, packet = RecordMix.fromWire(m.packet) }
    end
    rows[#rows + 1] = { spot = tonumber(spot) or 0, packet = mine, mine = true }
    table.sort(rows, function(a, b) return a.spot < b.spot end)
    local packets, myIndex = {}, 1
    for i, row in ipairs(rows) do
      packets[i] = row.packet
      if row.mine then myIndex = i end
    end
    local applied = RecordMix.receive(session, packets, myIndex, adapters and adapters.log)
    if applied and applied.unsupportedReason then
      RecordMix.state = "off"
      RecordMix.last = { players = #packets, myIndex = myIndex, applied = applied }
      L.closeLink(applied.unsupportedReason)
      return true
    end
    local gift = applied and applied.gift
    if type(gift) == "table" and (tonumber(gift.item) or 0) ~= 0 then
      -- pokeemerald/src/record_mixing.c:976
      if adapters and adapters.setStringVar then adapters.setStringVar(1, tostring(gift.from or "")) end
      if ctx.stringVars then ctx.stringVars[1] = tostring(gift.from or "") end
    end
    -- pokeemerald/src/record_mixing.c:333
    flagSet(session, "FLAG_SYS_MIX_RECORD")
    if message(isRs and "gOtherText_MixingComplete" or "gText_RecordMixingComplete") then
      shown = 0
      return false
    end
    RecordMix.state = "done"
    return true
  end
  return true
end

-- pokeemerald/src/cable_club.c:636 Task_ValidateMixingGameLanguage
function RecordMix.validateMixingGameLanguage()
  return false
end

function RecordMix.reset()
  RecordMix.state = "off"
  RecordMix.last = nil
end

return RecordMix
