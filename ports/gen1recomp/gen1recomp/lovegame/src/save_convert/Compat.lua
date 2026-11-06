local bit = require("bit")

local Compat = {}

Compat.ERROR, Compat.WARN = "error", "warn"

Compat.RULES = {
  ["size"] = "error",
  ["gen1.partyList"] = "error",
  ["gen1.curBoxList"] = "error",
  ["gen1.bankList"] = "error",
  ["gen1.listSpecies0"] = "error",
  ["gen1.mainChecksum"] = "error",
  ["gen1.currentBoxIndex"] = "error",
  ["gen1.japaneseCollision"] = "error",
  ["gen1.openhomeMisdetect"] = "error",
  ["gen1.unknownSpecies"] = "warn",
  ["gen1.boxesUninitialized"] = "warn",
  ["gen1.bankChecksum"] = "warn",
  ["gen1.versionMarker"] = "warn",
  ["gen1.openhomeHp255"] = "warn",
  ["gen1.blackoutMap"] = "warn",
  ["gen2.checkValues"] = "error",
  ["gen2.checksum"] = "error",
  ["gen2.backupChecksum"] = "error",
  ["gen2.openhomeChecksum"] = "error",
  ["gen2.partyList"] = "error",
  ["gen2.boxList"] = "error",
  ["gen2.listSpecies0"] = "error",
  ["gen2.gen1Collision"] = "error",
  ["gen2.gsCollision"] = "error",
  ["gen2.openhomeJapanCollision"] = "error",
  ["gen2.listStructMismatch"] = "warn",
  ["gen2.unknownSpecies"] = "warn",
  ["gen2.blankNickname"] = "warn",
  ["gen2.unownDex"] = "warn",
  ["gen2.pkhexHallOfFame"] = "warn",
  ["gen3.trailer"] = "warn",
  ["gen3.trailerUnreadable"] = "error",
  ["gen3.slotCounter"] = "warn",
  ["gen3.language"] = "warn",
  ["gen3.sectionIds"] = "error",
  ["gen3.signature"] = "error",
  ["gen3.sectorChecksum"] = "error",
  ["gen3.checksumWindow"] = "error",
  ["gen3.gameCode"] = "error",
  ["gen3.emeraldData"] = "error",
  ["gen3.securityKey"] = "error",
  ["gen3.japaneseOt"] = "error",
  ["gen3.partyCount"] = "error",
  ["gen3.species0"] = "error",
  ["gen3.monChecksumMajority"] = "error",
  ["gen3.extraSector"] = "warn",
  ["gen3.monChecksum"] = "warn",
  ["gen3.foreignSpecies"] = "warn",
  ["gen3.openhomeSpecies"] = "warn",
  ["gen3.badEgg"] = "warn",
}

local GEN = {
  red = 1, blue = 1, yellow = 1,
  gold = 2, silver = 2, crystal = 2,
  firered = 3, leafgreen = 3, emerald = 3, ruby = 3, sapphire = 3,
}

function Compat.generationOf(version)
  return GEN[version]
end

local function u8(s, o) return s:byte(o + 1) or 0 end
local function u16le(s, o) return u8(s, o) + u8(s, o + 1) * 256 end
local function u32le(s, o) return u16le(s, o) + u16le(s, o + 2) * 65536 end

local function sum8(s, from, toExcl)
  local v = 0
  for i = from, toExcl - 1 do v = (v + u8(s, i)) % 256 end
  return v
end

local function sum16(s, from, toExcl)
  local v = 0
  for i = from, toExcl - 1 do v = (v + u8(s, i)) % 65536 end
  return v
end

local function newReport(version, gen)
  local r = { version = version, generation = gen, errors = {}, warnings = {}, ok = true }
  function r.add(rule, msg, at)
    local sev = Compat.RULES[rule] or "warn"
    local item = { rule = rule, msg = msg, at = at, severity = sev }
    if sev == "error" then
      r.errors[#r.errors + 1] = item
      r.ok = false
    else
      r.warnings[#r.warnings + 1] = item
    end
  end
  return r
end

local function listValid(s, at, cap)
  local count = u8(s, at)
  return count <= cap and u8(s, at + 1 + count) == 0xFF, count
end

local G1_GLITCH = {}
for _, i in ipairs({ 0x1F, 0x20, 0x32, 0x34, 0x38, 0x3D, 0x3E, 0x3F, 0x43, 0x44, 0x45, 0x4F,
  0x50, 0x51, 0x56, 0x57, 0x5E, 0x5F, 0x73, 0x79, 0x7A, 0x7F, 0x86, 0x87, 0x89, 0x8C, 0x92,
  0x9C, 0x9F, 0xA0, 0xA1, 0xA2, 0xAC, 0xAE, 0xAF, 0xB5, 0xB6, 0xB7, 0xB8 }) do
  G1_GLITCH[i] = true
end

local G1_BOX = 0x462

local function g1BoxBase(i)
  return i < 6 and (0x4000 + i * G1_BOX) or (0x6000 + (i - 6) * G1_BOX)
end

local function g1List(s, r, at, cap, rule, label, structSize, checkHp)
  local valid, count = listValid(s, at, cap)
  if not valid then
    r.add(rule, ("%s list at 0x%04X: count %d with no 0xFF terminator after it"):format(label, at, count), at)
    return
  end
  for i = 0, count - 1 do
    local sp = u8(s, at + 1 + i)
    if sp == 0 or sp == 0xFF then
      r.add("gen1.listSpecies0", ("%s slot %d: species byte 0x%02X inside the counted list"):format(label, i + 1, sp), at + 1 + i)
    elseif sp > 190 or G1_GLITCH[sp] then
      r.add("gen1.unknownSpecies", ("%s slot %d: internal species 0x%02X has no Pokemon"):format(label, i + 1, sp), at + 1 + i)
    end
    if checkHp then
      local mon = at + 2 + cap + i * structSize
      if u8(s, mon + 2) == 0xFF then
        r.add("gen1.openhomeHp255", ("%s slot %d: HP low byte 0xFF, OpenHome PK1.ts:61 drops this mon"):format(label, i + 1), mon)
      end
    end
  end
end

local function openhomeG2Valid(s)
  local c1 = sum8(s, 0x2009, 0x2B83)
  local crystal = c1 == u8(s, 0x2D0D) and sum8(s, 0x1209, 0x1D83) == u8(s, 0x1F0D)
  local g1 = sum8(s, 0x2009, 0x2D69)
  local g2 = (sum8(s, 0x15C7, 0x17ED) + sum8(s, 0x3D96, 0x3F40) + sum8(s, 0x0C6B, 0x10E8)
    + sum8(s, 0x7E39, 0x7E6D) + sum8(s, 0x10E8, 0x15C7)) % 256
  local gs = g1 == u8(s, 0x2D69) and g2 == u8(s, 0x7E6D)
  return crystal, gs, c1, g1, g2
end

local function openhomeG2JapanValid(s)
  for _, last in ipairs({ 0x2C8C, 0x2AE3 }) do
    local sum = sum16(s, 0x2009, last)
    if sum ~= 0 and sum == u16le(s, 0x2D0D) and sum == u16le(s, 0x7F0D) then return true end
  end
  return false
end

local function openhomeG1JapanValid(s)
  if (255 - sum8(s, 0x2598, 0x3594)) ~= u8(s, 0x3594) then return false end
  local n = u8(s, 0x2ED5)
  if n < 1 or n > 6 then return false end
  return n == 6 or u8(s, 0x2ED5 + 1 + n) == 0xFF
end

local G1_BLACKOUT_MAPS = { [0]=true, true, true, true, true, true, true, true, true, true, true, [0x0F]=true, [0x15]=true }

local function checkGen1(s, r, version)
  if #s ~= 0x8000 then
    r.add("size", ("Gen 1 saves are 32768 bytes, this is %d"):format(#s))
    return r
  end
  g1List(s, r, 0x2F2C, 6, "gen1.partyList", "party", 44, false)
  local curByte = u8(s, 0x284C)
  local cur = curByte % 128
  local initialized = curByte >= 128
  if cur >= 12 then
    r.add("gen1.currentBoxIndex", ("wCurrentBoxNum low bits %d is not a box (0-11)"):format(cur), 0x284C)
  end
  g1List(s, r, 0x30C0, 20, "gen1.curBoxList", "current box", 33, true)
  for i = 0, 11 do
    local base = g1BoxBase(i)
    if initialized then
      if i ~= cur then g1List(s, r, base, 20, "gen1.bankList", ("box %d"):format(i + 1), 33, true) end
    elseif listValid(s, base, 20) and u8(s, base) > 0 then
      r.add("gen1.boxesUninitialized",
        ("box %d holds a list but bit 7 of 0x284C is clear; PKHeX and the game treat it as empty"):format(i + 1), 0x284C)
      break
    end
  end
  -- engine/menus/save.asm:240
  if 255 - sum8(s, 0x2598, 0x3523) ~= u8(s, 0x3523) then
    r.add("gen1.mainChecksum", "main data checksum at 0x3523 does not match 0x2598-0x3522", 0x3523)
  end
  if initialized then
    for bank = 0, 1 do
      local base = bank == 0 and 0x4000 or 0x6000
      local ok = 255 - sum8(s, base, base + 6 * G1_BOX) == u8(s, base + 6 * G1_BOX)
      for b = 0, 5 do
        local at = base + b * G1_BOX
        if 255 - sum8(s, at, at + G1_BOX) ~= u8(s, base + 6 * G1_BOX + 1 + b) then ok = false end
      end
      if not ok then
        r.add("gen1.bankChecksum", ("bank %d box checksums are stale"):format(bank + 2), base + 6 * G1_BOX)
      end
    end
  end
  -- data/maps/special_warps.asm:64
  local blackout = u8(s, 0x29C5)
  if not G1_BLACKOUT_MAPS[blackout] then
    r.add("gen1.blackoutMap", ("wLastBlackoutMap 0x%02X is not a FlyWarpDataPtr town"):format(blackout), 0x29C5)
  end
  local starter, pika = u8(s, 0x29C3), u8(s, 0x271C)
  local looksYellow = (starter ~= 0 and starter == 0x54) or (starter == 0 and pika ~= 0)
  if (version == "red" or version == "blue") and pika ~= 0 and not looksYellow then
    r.add("gen1.versionMarker", "a Red/Blue save whose byte 0x271C is nonzero; OpenHome reads it as Yellow", 0x271C)
  end
  if version == "yellow" and not looksYellow then
    r.add("gen1.versionMarker", "a Yellow save that PKHeX and OpenHome will read as Red/Blue", 0x29C3)
  elseif (version == "red" or version == "blue") and looksYellow then
    r.add("gen1.versionMarker", "a Red/Blue save that PKHeX and OpenHome will read as Yellow", 0x29C3)
  end
  if listValid(s, 0x2ED5, 30) and listValid(s, 0x302D, 30) then
    r.add("gen1.japaneseCollision", "the Japanese party and box lists also validate; PKHeX tries Japanese first", 0x2ED5)
  end
  local crystal, gs = openhomeG2Valid(s)
  local jp = openhomeG1JapanValid(s) or openhomeG2JapanValid(s)
  if crystal or gs or jp then
    r.add("gen1.openhomeMisdetect",
      ("OpenHome G1SAV.fileIsSave refuses it (%s checksums validate)"):format(crystal and "Crystal" or gs and "Gold/Silver" or "Japanese"), 0x2009)
  end
  return r
end

local G2 = {
  gs = { cv2 = 0x2D6B, sum = 0x2D69, gameEnd = 0x2D69, party = 0x288A, activeBox = 0x2D6C,
         caught = 0x2A4C, unownDex = 0x2A8C, firstUnown = 0x2AA7 },
  crystal = { cv2 = 0x2D0F, sum = 0x2D0D, gameEnd = 0x2B83, party = 0x2865, activeBox = 0x2D10,
              caught = 0x2A27, unownDex = 0x2A67, firstUnown = 0x2A82 },
}
local G2_BOXES = { 0x4000, 0x4450, 0x48A0, 0x4CF0, 0x5140, 0x5590, 0x59E0,
                   0x6000, 0x6450, 0x68A0, 0x6CF0, 0x7140, 0x7590, 0x79E0 }

local function g2List(s, r, at, cap, structSize, rule, label)
  local valid, count = listValid(s, at, cap)
  if not valid then
    r.add(rule, ("%s list at 0x%04X: count %d with no 0xFF terminator after it"):format(label, at, count), at)
    return
  end
  local monsAt = at + 2 + cap
  local nickAt = monsAt + cap * structSize + cap * 11
  for i = 0, count - 1 do
    local sp = u8(s, at + 1 + i)
    local struct = u8(s, monsAt + i * structSize)
    if sp == 0 or sp == 0xFF then
      r.add("gen2.listSpecies0", ("%s slot %d: species byte 0x%02X inside the counted list"):format(label, i + 1, sp), at + 1 + i)
    elseif sp ~= 0xFD then
      if sp > 251 then
        r.add("gen2.unknownSpecies", ("%s slot %d: species %d is past Celebi"):format(label, i + 1, sp), at + 1 + i)
      end
      if struct ~= sp then
        r.add("gen2.listStructMismatch", ("%s slot %d: list says %d, struct says %d"):format(label, i + 1, sp, struct), at + 1 + i)
      end
    end
    if u8(s, nickAt + i * 11) == 0x50 then
      r.add("gen2.blankNickname", ("%s slot %d: blank nickname"):format(label, i + 1), nickAt + i * 11)
    end
  end
end

local function rtcFooterOk(n)
  local extra = n - 0x8000
  if extra == 0 then return true end
  return extra == 7 or (extra >= 0x0C and extra <= 0x30 and extra % 2 == 0)
end

local function checkGen2(s, r, version)
  if #s < 0x8000 or not rtcFooterOk(#s) then
    r.add("size", ("Gen 2 saves are 32768 bytes plus an optional RTC footer, this is %d"):format(#s))
    return r
  end
  local which = version == "crystal" and "crystal" or "gs"
  local L = G2[which]
  -- PKHeX.Core/Saves/SAV2.cs:214; pokegold/ram/sram.asm:134,139
  if which == "gs" then
    local tail = s:sub(0x3D69 + 1, 0x3D96)
    if tail ~= string.rep("\0", 0x2D) and tail ~= s:sub(0x222F + 1, 0x222F + 0x2D) then
      r.add("gen2.pkhexHallOfFame",
        "PKHeX can overwrite the end of this Hall of Fame data when writing Gold/Silver saves; keep a backup before editing",
        0x3D69)
    end
  end
  if u8(s, 0x2008) ~= 0x63 or u8(s, L.cv2) ~= 0x7F then
    r.add("gen2.checkValues", "check values 0x63/0x7F are missing", 0x2008)
  end
  local primary = sum16(s, 0x2009, L.gameEnd)
  if primary ~= u16le(s, L.sum) then
    r.add("gen2.checksum", ("primary checksum 0x%04X stored, 0x%04X computed"):format(u16le(s, L.sum), primary), L.sum)
  end
  if which == "crystal" then
    local backup = sum16(s, 0x1209, 0x1D83)
    if backup ~= u16le(s, 0x1F0D) or u8(s, 0x1208) ~= 0x63 or u8(s, 0x1F0F) ~= 0x7F then
      r.add("gen2.backupChecksum", "Crystal backup at 0x1209 is not sealed (0x1F0D / check values)", 0x1F0D)
    end
  elseif primary ~= u16le(s, 0x7E6D) then
    r.add("gen2.backupChecksum",
      ("PKHeX checksum 2 at 0x7E6D is 0x%04X, primary sum is 0x%04X"):format(u16le(s, 0x7E6D), primary), 0x7E6D)
  end
  local crystal, gs, c1, g1, g2 = openhomeG2Valid(s)
  if which == "crystal" then
    if not crystal or (c1 == 0 and u8(s, 0x1F0D) == 0) then
      r.add("gen2.openhomeChecksum", "OpenHome G2SAV Crystal 8-bit checksums do not validate", 0x2D0D)
    end
  elseif not gs or (g1 == 0 and g2 == 0) then
    r.add("gen2.openhomeChecksum", "OpenHome G2SAV Gold/Silver 8-bit checksums do not validate", 0x2D69)
  end
  g2List(s, r, L.party, 6, 48, "gen2.partyList", "party")
  g2List(s, r, L.activeBox, 20, 32, "gen2.boxList", "active box")
  for i, base in ipairs(G2_BOXES) do g2List(s, r, base, 20, 32, "gen2.boxList", ("box %d"):format(i)) end
  if (listValid(s, 0x2ED5, 30) and listValid(s, 0x302D, 30)) or (listValid(s, 0x2F2C, 20) and listValid(s, 0x30C0, 20)) then
    r.add("gen2.gen1Collision", "the Gen 1 party/box lists validate; PKHeX tries Gen 1 first and opens it as Red/Blue", 0x2F2C)
  end
  if which == "crystal" and listValid(s, 0x288A, 20) and listValid(s, 0x2D6C, 20) then
    r.add("gen2.gsCollision", "the Gold/Silver lists validate; PKHeX tries Gold/Silver before Crystal", 0x288A)
  end
  if openhomeG2JapanValid(s) then
    r.add("gen2.openhomeJapanCollision", "OpenHome's Japanese Gen 2 checksums validate too; it asks which class to use", 0x2D0D)
  end
  local unownCaught = u8(s, L.caught + 25) % 2 == 1
  if unownCaught then
    local any = false
    for i = 0, 25 do if u8(s, L.unownDex + i) ~= 0 then any = true end end
    if not any or u8(s, L.firstUnown) == 0 then
      r.add("gen2.unownDex", "Unown is caught but the Unown dex is empty (PKHeX SAV2.cs:636 crash warning)", L.unownDex)
    end
  end
  return r
end

local G3_CHUNKS = {
  rs = { [0] = 0x890, 0xF80, 0xF80, 0xF80, 0xC40, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0x7D0 },
  frlg = { [0] = 0xF24, 0xF80, 0xF80, 0xF80, 0xEE8, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0x7D0 },
  emerald = { [0] = 0xF2C, 0xF80, 0xF80, 0xF80, 0xF08, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0xF80, 0x7D0 },
}
local G3_PARTY = { rs = { count = 0x234, mons = 0x238 }, frlg = { count = 0x34, mons = 0x38 }, emerald = { count = 0x234, mons = 0x238 } }
-- include/save.h:15
local SIGNATURE = 0x08012025

local ORDERS = {
  "GAEM", "GAME", "GEAM", "GEMA", "GMAE", "GMEA", "AGEM", "AGME", "AEGM", "AEMG", "AMGE", "AMEG",
  "EGAM", "EGMA", "EAGM", "EAMG", "EMGA", "EMAG", "MGAE", "MGEA", "MAGE", "MAEG", "MEGA", "MEAG",
}

function Compat.gen3SectorChecksum(s, off, size)
  local acc = 0
  for i = 0, size - 1, 4 do acc = (acc + u32le(s, off + i)) % 4294967296 end
  return (math.floor(acc / 65536) + acc % 65536) % 65536
end

local function blank(s, off, n)
  local first = u8(s, off)
  if first ~= 0 and first ~= 0xFF then return false end
  for i = off, off + n - 1 do if u8(s, i) ~= first then return false end end
  return true
end

local function scanSlot(s, slot)
  local seen, uniq, allBlank = {}, 0, true
  for i = 0, 13 do
    local off = (slot * 14 + i) * 0x1000
    if not blank(s, off, 0x1000) then allBlank = false end
    local id = u16le(s, off + 0xFF4)
    if id < 14 and not seen[id] then seen[id] = off; uniq = uniq + 1 end
  end
  return { complete = uniq == 14, blank = allBlank, at = seen,
           counter = seen[0] and u32le(s, seen[0] + 0xFFC) or nil }
end

function Compat.gen3Blocks(s, family)
  local chunks = G3_CHUNKS[family]
  local slots = { scanSlot(s, 0), scanSlot(s, 1) }
  local active
  if slots[1].complete and slots[2].complete then
    local a, b = slots[1].counter, slots[2].counter
    if a == 0xFFFFFFFF and b ~= 0xFFFFFFFE then active = 2
    elseif b == 0xFFFFFFFF and a ~= 0xFFFFFFFE then active = 1
    else active = b > a and 2 or 1 end
  elseif slots[1].complete then active = 1
  elseif slots[2].complete then active = 2 end
  if not active then return nil, slots end
  local at = slots[active].at
  local function join(first, last)
    local parts = {}
    for id = first, last do parts[#parts + 1] = s:sub(at[id] + 1, at[id] + chunks[id]) end
    return table.concat(parts)
  end
  return { sb2 = join(0, 0), sb1 = join(1, 4), storage = join(5, 13), slot = active, slots = slots }, slots
end

local function decryptMon(raw)
  local pid, otid = u32le(raw, 0), u32le(raw, 4)
  local key = bit.bxor(pid, otid)
  local words = {}
  for i = 0, 11 do words[i] = bit.bxor(u32le(raw, 0x20 + i * 4), key) % 4294967296 end
  local order = ORDERS[pid % 24 + 1]
  local g = order:find("G") - 1
  local species = words[g * 3] % 65536
  local sum = 0
  for i = 0, 11 do sum = (sum + words[i] % 65536 + math.floor(words[i] / 65536)) % 65536 end
  return species, sum == u16le(raw, 0x1C)
end

local function checkMon(r, raw, label, tally)
  local flags = u8(raw, 0x13)
  local hasSpecies = math.floor(flags / 2) % 2 == 1
  local present = hasSpecies or u16le(raw, 0x20) ~= 0
  if not present then return end
  tally.n = tally.n + 1
  if flags % 2 == 1 then r.add("gen3.badEgg", label .. ": bad egg flag set, PKHeX hides this mon") end
  if u8(raw, 0x12) > 11 then
    r.add("gen3.language", ("%s: language byte %d is not a language; OpenHome drops the mon"):format(label, u8(raw, 0x12)))
  end
  local species, ok = decryptMon(raw)
  if not ok then
    tally.bad = tally.bad + 1
    r.add("gen3.monChecksum", label .. ": PK3 checksum does not match")
    return
  end
  if species == 0 and hasSpecies then
    r.add("gen3.species0", label .. ": has-species flag set with species 0")
  elseif not ((species >= 1 and species <= 251) or (species >= 277 and species <= 412)) then
    r.add("gen3.foreignSpecies", ("%s: internal species %d is not vanilla (PKForge SuspectedHack)"):format(label, species))
  end
  if species >= 252 and species <= 276 then
    r.add("gen3.openhomeSpecies", ("%s: internal species %d is dropped by OpenHome"):format(label, species))
  end
end

local function checkGen3(s, r, version)
  if #s < 0x20000 or #s > 0x20100 then
    r.add("size", ("Gen 3 saves are 131072 bytes, this is %d"):format(#s))
    return r
  end
  if #s ~= 0x20000 then
    local extra = #s - 0x20000
    local footer = extra == 7 or (extra >= 0x0C and extra <= 0x30 and extra % 2 == 0)
    local first = u8(s, 0x20000)
    local uniform = (first == 0 or first == 0xFF) and blank(s, 0x20000, extra)
    if footer then
      r.add("gen3.trailer", ("%d trailing bytes after the flash image"):format(extra))
    elseif uniform then
      r.add("gen3.trailer", ("%d uniform pad bytes after the flash image; only PKForge trims them"):format(extra))
    else
      r.add("gen3.trailerUnreadable",
        ("%d trailing bytes are neither an RTC footer (7 or an even 12-48) nor a uniform pad; PKHeX refuses the file"):format(extra), 0x20000)
    end
  end
  local family = (version == "ruby" or version == "sapphire") and "rs" or (version == "emerald" and "emerald" or "frlg")
  r.family = family
  local chunks = G3_CHUNKS[family]
  local blocks, slots = Compat.gen3Blocks(s, family)
  for i, sl in ipairs(slots) do
    if not sl.complete and not sl.blank then
      r.add("gen3.sectionIds", ("slot %d is written but does not hold section ids 0-13 once each"):format(i), (i - 1) * 0xE000)
    end
    if sl.complete then
      for id = 0, 13 do
        local off = sl.at[id]
        if u32le(s, off + 0xFF8) ~= SIGNATURE then
          r.add("gen3.signature", ("slot %d section %d signature is not 0x08012025"):format(i, id), off + 0xFF8)
        end
        if Compat.gen3SectorChecksum(s, off, chunks[id]) ~= u16le(s, off + 0xFF6) then
          r.add("gen3.sectorChecksum", ("slot %d section %d checksum mismatch"):format(i, id), off + 0xFF6)
        end
        if chunks[id] < 0xF80 then
          for k = off + chunks[id], off + 0xF7F do
            if u8(s, k) ~= 0 then
              r.add("gen3.checksumWindow",
                ("slot %d section %d has nonzero bytes between 0x%X and 0xF80; PKHeX's checksum will differ"):format(i, id, chunks[id]), k)
              break
            end
          end
        end
      end
    end
  end
  if not blocks then
    r.add("gen3.sectionIds", "no save slot holds all 14 sections")
    return r
  end
  local counters = {}
  for i, sl in ipairs(slots) do
    if sl.complete then
      counters[i] = sl.counter
      for id = 1, 13 do
        if u32le(s, sl.at[id] + 0xFFC) ~= sl.counter then
          r.add("gen3.slotCounter", ("slot %d section %d has a different save counter than section 0"):format(i, id),
            sl.at[id] + 0xFFC)
          break
        end
      end
    end
  end
  if counters[1] and counters[2] and counters[1] == counters[2] then
    r.add("gen3.slotCounter", "both slots carry the same save counter; PKHeX picks slot A and OpenHome slot B", 0xFFC)
  end
  for sector = 28, 31 do
    local off = sector * 0x1000
    if not blank(s, off, 0x1000) and Compat.gen3SectorChecksum(s, off, 0xF80) ~= u16le(s, off + 0xFF4) then
      r.add("gen3.extraSector",
        ("sector %d: PKHeX would rewrite its checksum, so PKForge refuses writes (CorruptingLayout)"):format(sector), off + 0xFF4)
    end
  end
  local sb2, sb1, st = blocks.sb2, blocks.sb1, blocks.storage
  local code = u32le(sb2, 0xAC)
  if family == "frlg" then
    if code ~= 1 then
      r.add("gen3.gameCode", ("FireRed/LeafGreen needs 1 at SB2 0xAC, found 0x%X"):format(code), 0xAC)
    end
    -- include/global.h:358
    if u32le(sb2, 0xF20) == 0 then
      r.add("gen3.securityKey", "encryption key at SB2 0xF20 is 0", 0xF20)
    end
    if u32le(sb2, 0xAF8) == 0 then
      r.add("gen3.securityKey", "SB2 0xAF8 (berry powder XOR key) is 0; OpenHome G3SAV rejects the file", 0xAF8)
    end
  elseif family == "emerald" then
    if code == 0 or code == 1 then
      r.add("gen3.gameCode", ("Emerald key at SB2 0xAC is %d, readers type the file as %s"):format(code,
        code == 0 and "Ruby/Sapphire" or "FireRed/LeafGreen"), 0xAC)
    end
    local any = false
    for i = 0x890, math.min(0xF2B, #sb2 - 1) do if u8(sb2, i) ~= 0 then any = true; break end end
    if not any then r.add("gen3.emeraldData", "SB2 0x890-0xF2B is empty; PKHeX types the file as Ruby/Sapphire", 0x890) end
  end
  if u16le(sb2, 6) == 0 then
    r.add("gen3.japaneseOt", "OT name bytes 6-7 are both 0; PKHeX and OpenHome read it as Japanese", 6)
  end
  local P = G3_PARTY[family]
  local count = u8(sb1, P.count)
  if count > 6 then r.add("gen3.partyCount", ("party count %d"):format(count), P.count) end
  local partyTally, boxTally = { n = 0, bad = 0 }, { n = 0, bad = 0 }
  for i = 0, math.min(count, 6) - 1 do
    local o = P.mons + i * 100
    checkMon(r, sb1:sub(o + 1, o + 80), ("party %d"):format(i + 1), partyTally)
  end
  for i = 0, 419 do
    local o = 4 + i * 80
    checkMon(r, st:sub(o + 1, o + 80), ("box %d slot %d"):format(math.floor(i / 30) + 1, i % 30 + 1), boxTally)
  end
  if (partyTally.n > 0 and partyTally.bad * 2 > partyTally.n) or (boxTally.n >= 3 and boxTally.bad * 2 > boxTally.n) then
    r.add("gen3.monChecksumMajority", "more than half the mons fail their checksum; PKForge refuses writes")
  end
  return r
end

function Compat.check(bytes, version)
  local gen = GEN[version]
  local r = newReport(version, gen)
  if type(bytes) ~= "string" then
    r.add("size", "no bytes")
    return r
  end
  if gen == 1 then return checkGen1(bytes, r, version) end
  if gen == 2 then return checkGen2(bytes, r, version) end
  if gen == 3 then return checkGen3(bytes, r, version) end
  r.add("size", "unknown game version " .. tostring(version))
  return r
end

function Compat.describe(report)
  local out = {}
  for _, e in ipairs(report.errors) do out[#out + 1] = ("[error %s] %s"):format(e.rule, e.msg) end
  for _, w in ipairs(report.warnings) do out[#out + 1] = ("[warn %s] %s"):format(w.rule, w.msg) end
  return table.concat(out, "\n")
end

function Compat.gate(bytes, version, source)
  local report = Compat.check(bytes, version)
  if source ~= nil and bytes == source and not report.ok then
    local kept = {}
    for _, e in ipairs(report.errors) do
      if e.rule == "gen2.openhomeChecksum" then
        e.severity = "warn"
        report.warnings[#report.warnings + 1] = e
      else
        kept[#kept + 1] = e
      end
    end
    report.errors = kept
    report.ok = #kept == 0
  end
  if not report.ok then
    local e = report.errors[1]
    return nil, ("export failed reader check %s: %s"):format(e.rule, e.msg), report
  end
  return true, report.warnings, report
end

return Compat
