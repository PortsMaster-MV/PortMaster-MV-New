local Structs = require("src.save_convert.gen3_port.structs")

local U32 = 4294967296

local function u8(s, o) return s:byte(o + 1) end
local function u16(s, o) local a, b = s:byte(o + 1, o + 2); return a + b * 256 end
local function u32(s, o) local a, b, c, d = s:byte(o + 1, o + 4); return a + b * 256 + c * 65536 + d * 16777216 end
local function num(v, d) return tonumber(v) or d or 0 end

local function slice(w, off, n)
  local t = {}
  for i = 0, n - 1 do t[i + 1] = string.char(w.b[off + i] or 0) end
  return table.concat(t)
end

local function mg() return require("src.core.game3.mystery_gift") end

local function note(x, msg)
  if type(x.notes) == "table" then x.notes[#x.notes + 1] = msg end
end

-- pokefirered/include/global.h:786
local VS_COUNTER = 0x638
-- pokefirered/include/global.h:787
local VS_REMATCHES = 0x63A
-- pokefirered/include/constants/global.h:46
local MAX_REMATCH_ENTRIES = 100

-- pokefirered/include/global.h:820
local TOWER_CHALLENGE_ID = 0x3D34
-- pokefirered/include/global.h:821
local TOWER_RECORDS = 0x3D38
-- pokefirered/include/global.h:693
local TOWER_RECORD = {
  { name = "timer", off = 0, t = "u32" },
  { name = "floorsCleared", off = 8, t = "u8" },
  { name = "setId", off = 9, t = "u8" },
  { name = "receivedPrize", off = 10, t = "bits", of = "u8", shift = 0, width = 1, bool = true },
  { name = "checkedFinalTime", off = 10, t = "bits", of = "u8", shift = 1, width = 1, bool = true },
  { name = "spokeToOwner", off = 10, t = "bits", of = "u8", shift = 2, width = 1, bool = true },
  { name = "hasLost", off = 10, t = "bits", of = "u8", shift = 3, width = 1, bool = true },
  { name = "statusUnk", off = 10, t = "bits", of = "u8", shift = 4, width = 1, bool = true },
  { name = "validated", off = 10, t = "bits", of = "u8", shift = 5, width = 1, bool = true },
}
local TOWER_SPEC = {
  { name = "records", off = 0, t = "struct", n = 4, size = 12, spec = TOWER_RECORD },
}

-- pokefirered/include/global.h:808
local FRLG_MYSTERY_GIFT = 0x3120
-- pokefirered/include/global.h:810
local FRLG_RAM_SCRIPT = 0x361C

-- pokefirered/include/global.h:680
local MG = { newsCrc = 0x000, news = 0x004, cardCrc = 0x1C0, card = 0x1C4, cardMetadataCrc = 0x310,
  cardMetadata = 0x314, questionnaireWords = 0x338, newsMetadata = 0x340, trainerIds = 0x344, size = 0x36C }
local NEWS_SIZE, CARD_SIZE = 444, 332
-- pokefirered/include/global.h:443
local RAM_SCRIPT_SIZE, RAM_SCRIPT_DATA_SIZE = 1004, 999
-- pokefirered/src/script.c:12
local RAM_SCRIPT_MAGIC = 51
-- pokefirered/include/constants/easy_chat.h:1091
local EC_WORD_UNDEFINED = 0xFFFF

-- pokefirered/include/global.h:646
local NEWS_SPEC = {
  { name = "id", off = 0, t = "u16" },
  { name = "sendType", off = 2, t = "u8" },
  { name = "bgType", off = 3, t = "u8" },
  { name = "titleText", off = 4, t = "text", len = 40 },
  { name = "bodyText", off = 44, t = "text", len = 40, n = 10 },
}
-- pokefirered/include/global.h:655
local CARD_SPEC = {
  { name = "flagId", off = 0, t = "u16" },
  { name = "iconSpecies", off = 2, t = "u16" },
  { name = "idNumber", off = 4, t = "u32" },
  { name = "type", off = 8, t = "bits", of = "u8", shift = 0, width = 2 },
  { name = "bgType", off = 8, t = "bits", of = "u8", shift = 2, width = 4 },
  { name = "sendType", off = 8, t = "bits", of = "u8", shift = 6, width = 2 },
  { name = "maxStamps", off = 9, t = "u8" },
  { name = "titleText", off = 10, t = "text", len = 40 },
  { name = "subtitleText", off = 50, t = "text", len = 40 },
  { name = "bodyText", off = 90, t = "text", len = 40, n = 4 },
  { name = "footerLine1Text", off = 250, t = "text", len = 40 },
  { name = "footerLine2Text", off = 290, t = "text", len = 40 },
}
-- pokefirered/include/global.h:671
local CARD_METADATA_SPEC = {
  { name = "battlesWon", off = 0, t = "u16" },
  { name = "battlesLost", off = 2, t = "u16" },
  { name = "numTrades", off = 4, t = "u16" },
  { name = "iconSpecies", off = 6, t = "u16" },
  -- pokefirered/include/constants/mystery_gift.h:37
  { name = "stampData", off = 8, t = "struct", size = 28, spec = {
    { name = "species", off = 0, t = "u16", n = 7 },
    { name = "ids", off = 14, t = "u16", n = 7 },
  } },
}
-- pokefirered/include/global.h:638
local NEWS_METADATA_SPEC = {
  { name = "newsType", off = 0, t = "bits", of = "u8", shift = 0, width = 2 },
  { name = "sentRewardCounter", off = 0, t = "bits", of = "u8", shift = 2, width = 3 },
  { name = "rewardCounter", off = 0, t = "bits", of = "u8", shift = 5, width = 3 },
  { name = "berry", off = 1, t = "u8" },
}
local MG_META_SPEC = {
  { name = "cardMetadataCrc", off = MG.cardMetadataCrc, t = "u32" },
  { name = "cardMetadata", off = MG.cardMetadata, t = "struct", size = 36, spec = CARD_METADATA_SPEC },
  { name = "newsMetadata", off = MG.newsMetadata, t = "struct", size = 4, spec = NEWS_METADATA_SPEC },
  { name = "trainerIds", off = MG.trainerIds, t = "u32", n = 2, m = 5 },
}

local function mgBase(L)
  if L.FAMILY == "emerald" then return L.RSE.sb1.mysteryGift, L.RSE.sb1.ramScript end
  return FRLG_MYSTERY_GIFT, FRLG_RAM_SCRIPT
end

local function clampText(text, limit)
  if type(text) ~= "string" then return "" end
  if #text <= limit then return text end
  local count, i = 0, 1
  while i <= #text do
    local c = text:byte(i)
    local len = (c >= 0xF0 and 4) or (c >= 0xE0 and 3) or (c >= 0xC0 and 2) or 1
    count = count + 1
    if count > limit then return text:sub(1, i - 1) end
    i = i + len
  end
  return text
end

local function copyList(list, count, limit)
  local out = {}
  for i = 1, count do out[i] = clampText(type(list) == "table" and list[i] or "", limit) end
  return out
end

local function cardBytes(card)
  local gift = type(card.gift) == "table" and card.gift or {}
  local moveKeys = {}
  for slot in pairs(type(gift.moves) == "table" and gift.moves or {}) do moveKeys[#moveKeys + 1] = slot end
  table.sort(moveKeys)
  local parts = {
    tostring(num(card.flagId)), tostring(num(card.iconSpecies)),
    tostring(num(card.idNumber)), tostring(num(card.type)),
    tostring(num(card.bgType)), tostring(num(card.sendType)),
    tostring(num(card.maxStamps)),
    tostring(card.titleText or ""), tostring(card.subtitleText or ""),
    table.concat(copyList(card.bodyText, 4, 40), "\1"),
    tostring(card.footerLine1Text or ""), tostring(card.footerLine2Text or ""),
    tostring(gift.kind or "none"), tostring(gift.item or 0), tostring(gift.quantity or 0),
    tostring(gift.species or 0), tostring(gift.level or 0), tostring(gift.nickname or ""),
    tostring(gift.personality or 0), tostring(gift.otName or ""), tostring(gift.otId or 0),
    tostring(gift.doneFlag or 0), tostring(gift.slotVar or 0),
    tostring(gift.varAdd or 0), tostring(gift.varWrap or 0),
    tostring(gift.requireStat or 0), tostring(gift.requireValue or 0),
  }
  if gift.script then parts[#parts + 1] = "R" .. tostring(gift.script) end
  for _, slot in ipairs(moveKeys) do parts[#parts + 1] = tostring(slot) .. "=" .. tostring(gift.moves[slot]) end
  for _, id in ipairs(gift.setFlags or {}) do parts[#parts + 1] = "S" .. tostring(id) end
  for _, id in ipairs(gift.haveFlags or {}) do parts[#parts + 1] = "H" .. tostring(id) end
  if gift.heldItem then parts[#parts + 1] = "I" .. tostring(gift.heldItem) end
  return table.concat(parts, "\2")
end

local function newsBytes(news)
  return table.concat({
    tostring(num(news.id)), tostring(num(news.sendType)), tostring(num(news.bgType)),
    tostring(news.titleText or ""),
    table.concat(copyList(news.bodyText, 10, 40), "\1"),
  }, "\2")
end

local function giftNone()
  return { kind = "none", quantity = 1, level = 5, moves = {}, setFlags = {}, haveFlags = {} }
end

-- pokefirered/src/script.c:538
local function ramScriptValid(s, o)
  if u8(s, o + 4) ~= RAM_SCRIPT_MAGIC then return false end
  if u8(s, o + 5) ~= 0xFF or u8(s, o + 6) ~= 0xFF or u8(s, o + 7) ~= 0xFF then return false end
  return u32(s, o) == mg().crc16(s:sub(o + 5, o + 4 + RAM_SCRIPT_DATA_SIZE))
end

-- pokefirered/src/mystery_gift.c:104
local function cartNews(s, o, codec)
  local news = Structs.read(s, o + MG.news, NEWS_SPEC, codec)
  if u32(s, o + MG.newsCrc) ~= mg().crc16(s:sub(o + MG.news + 1, o + MG.news + NEWS_SIZE)) then return nil end
  if not mg().validateNews(news) then return nil end
  return news
end

-- pokefirered/src/mystery_gift.c:180
local function cartCard(s, o, rs, ro, codec)
  local card = Structs.read(s, o + MG.card, CARD_SPEC, codec)
  if u32(s, o + MG.cardCrc) ~= mg().crc16(s:sub(o + MG.card + 1, o + MG.card + CARD_SIZE)) then return nil end
  if not mg().validateCard(card) then return nil end
  if not ramScriptValid(rs, ro) then return nil end
  return card
end

local function engineNews(rec)
  local news = type(rec) == "table" and rec.news
  if type(news) ~= "table" then return nil end
  if num(rec.newsCrc) ~= mg().crc16(newsBytes(news)) or not mg().validateNews(news) then return nil end
  return news
end

local function engineCard(rec)
  local card = type(rec) == "table" and rec.card
  if type(card) ~= "table" then return nil end
  if num(rec.cardCrc) ~= mg().crc16(cardBytes(card)) or not mg().validateCard(card) then return nil end
  return card
end

local function sameFields(spec, a, b)
  for _, f in ipairs(spec) do
    local x, y = a[f.name], b[f.name]
    if f.n then
      for i = 1, f.n do
        local p, q = x[i], type(y) == "table" and y[i] or nil
        if f.t == "text" then q = tostring(q or "") else q = num(q) end
        if p ~= q then return false end
      end
    elseif f.t == "text" then
      if x ~= tostring(y or "") then return false end
    elseif x ~= num(y) then
      return false
    end
  end
  return true
end

local function modData(v)
  return type(v.modData) == "table" and v.modData or {}
end

return function(Rse)
  -- pokefirered/src/vs_seeker.c:664
  Rse.defineSection({
    name = "frlgVsSeeker",
    fields = { "vsSeeker" },
    read = function(x)
      local c, rem = u16(x.sb1, VS_COUNTER), {}
      for i = 0, MAX_REMATCH_ENTRIES - 1 do
        local r = u8(x.sb1, VS_REMATCHES + i)
        if r ~= 0 then rem[i] = r end
      end
      return { vsSeeker = { steps = c % 256, charging = math.floor(c / 256), rematches = rem } }
    end,
    write = function(x, v)
      local s = type(v.vsSeeker) == "table" and v.vsSeeker or {}
      local rem = type(s.rematches) == "table" and s.rematches or {}
      x.w1:w8(VS_COUNTER, num(s.steps))
      x.w1:w8(VS_COUNTER + 1, num(s.charging))
      for i = 0, MAX_REMATCH_ENTRIES - 1 do
        x.w1:w8(VS_REMATCHES + i, num(rem[i] or rem[tostring(i)]))
      end
    end,
  }, { frlg = true })

  -- pokefirered/src/trainer_tower.c:23
  Rse.defineSection({
    name = "frlgTrainerTower",
    fields = { "modData" },
    read = function(x)
      local t = Structs.read(x.sb1, TOWER_RECORDS, TOWER_SPEC, x.codec)
      t.challengeId = u32(x.sb1, TOWER_CHALLENGE_ID)
      return { modData = { trainerTower = t } }
    end,
    write = function(x, v)
      local t = modData(v).trainerTower
      if type(t) ~= "table" then return end
      x.w1:w32(TOWER_CHALLENGE_ID, num(t.challengeId))
      Structs.write(x.w1, TOWER_RECORDS, TOWER_SPEC, { records = type(t.records) == "table" and t.records or {} }, x.codec)
    end,
  }, { frlg = true })

  -- pokefirered/src/mystery_gift.c:93
  Rse.defineSection({
    name = "mysteryGiftNews",
    fields = { "modData" },
    read = function(x)
      local o = mgBase(x.L)
      local news = cartNews(x.sb1, o, x.codec)
      return { modData = { mysteryGift = { news = news, newsCrc = news and mg().crc16(newsBytes(news)) or 0 } } }
    end,
    write = function(x, v)
      local o = mgBase(x.L)
      local cur = slice(x.w1, o, MG.size)
      local rec = modData(v).mysteryGift
      if type(rec) ~= "table" then return end
      local was = cartNews(cur, 0, x.codec)
      local news = engineNews(rec)
      if not news then
        -- pokefirered/src/mystery_gift.c:128
        if was then x.w1:fill(o, MG.news + NEWS_SIZE, 0) end
        return
      end
      if was and sameFields(NEWS_SPEC, was, news) then return end
      x.w1:fill(o + MG.news, NEWS_SIZE, 0)
      Structs.write(x.w1, o + MG.news, NEWS_SPEC, news, x.codec)
      x.w1:w32(o + MG.newsCrc, mg().crc16(slice(x.w1, o + MG.news, NEWS_SIZE)))
      local back = slice(x.w1, o, MG.size)
      local now = cartNews(back, 0, x.codec)
      if not (now and sameFields(NEWS_SPEC, now, news)) then
        x.w1:fill(o, MG.news + NEWS_SIZE, 0)
        note(x, "The Wonder News does not fit the cartridge format and was not exported.")
      end
    end,
  }, { emerald = true, frlg = true })

  -- pokefirered/src/mystery_gift.c:166
  Rse.defineSection({
    name = "mysteryGiftCard",
    fields = { "modData" },
    read = function(x)
      local o, r = mgBase(x.L)
      local card = cartCard(x.sb1, o, x.sb1, r, x.codec)
      if not card then return { modData = { mysteryGift = { cardCrc = 0 } } } end
      card.gift = giftNone()
      return { modData = { mysteryGift = { card = card, cardCrc = mg().crc16(cardBytes(card)) } } }
    end,
    write = function(x, v)
      local o, r = mgBase(x.L)
      local cur, rs = slice(x.w1, o, MG.size), slice(x.w1, r, RAM_SCRIPT_SIZE)
      local rec = modData(v).mysteryGift
      if type(rec) ~= "table" then return end
      local was = cartCard(cur, 0, rs, 0, x.codec)
      local card = engineCard(rec)
      -- pokefirered/src/mystery_gift.c:155
      local function clear()
        x.w1:fill(o + MG.cardCrc, 4 + CARD_SIZE, 0)
        -- pokefirered/src/script.c:491
        x.w1:fill(r, RAM_SCRIPT_SIZE, 0)
      end
      if not card then
        if was then clear() end
        return
      end
      if was and sameFields(CARD_SPEC, was, card) then return end
      if was and was.flagId == num(card.flagId) and was.idNumber == num(card.idNumber) % U32 then
        Structs.write(x.w1, o + MG.card, CARD_SPEC, card, x.codec)
        x.w1:w32(o + MG.cardCrc, mg().crc16(slice(x.w1, o + MG.card, CARD_SIZE)))
        local now = cartCard(slice(x.w1, o, MG.size), 0, rs, 0, x.codec)
        if now and sameFields(CARD_SPEC, now, card) then return end
      end
      if was then clear() end
      note(x, "The Wonder Card was received in this port; its gift script exists only on a cartridge, so the card was not exported.")
    end,
  }, { emerald = true, frlg = true })

  -- pokefirered/src/mystery_gift.c:55
  Rse.defineSection({
    name = "mysteryGiftMetadata",
    fields = { "modData" },
    read = function(x)
      local o = mgBase(x.L)
      local m = Structs.read(x.sb1, o, MG_META_SPEC, x.codec)
      m.questionnaireWords = {}
      for i = 1, 4 do m.questionnaireWords[i] = u16(x.sb1, o + MG.questionnaireWords + (i - 1) * 2) end
      return { modData = { mysteryGift = m } }
    end,
    write = function(x, v)
      local rec = modData(v).mysteryGift
      local o = mgBase(x.L)
      local blank = slice(x.w1, o + MG.cardMetadataCrc, MG.size - MG.cardMetadataCrc)
        == string.rep("\0", MG.size - MG.cardMetadataCrc)
      if type(rec) ~= "table" then
        if not blank then return end
        rec = {}
      end
      Structs.write(x.w1, o, MG_META_SPEC, rec, x.codec)
      local words = type(rec.questionnaireWords) == "table" and rec.questionnaireWords or {}
      for i = 1, 4 do
        local at = o + MG.questionnaireWords + (i - 1) * 2
        local w = num(words[i])
        if w == 0 then
          local cur = (x.w1.b[at] or 0) + (x.w1.b[at + 1] or 0) * 256
          -- pokefirered/src/easy_chat.c:475
          w = (cur == 0 and not blank) and 0 or EC_WORD_UNDEFINED
        end
        x.w1:w16(at, w)
      end
    end,
  }, { emerald = true, frlg = true })
end
