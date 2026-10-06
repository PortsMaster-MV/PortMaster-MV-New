local NAME = 11
local BOX_STRUCT = 32
local PARTY_STRUCT = 48

local ROWS = {
  -- ram/sram.asm:1
  { "scratch", 0x0000, 0x0000, 0x600, "T2", { ids = "G2-07" } },
  { "partyMail", 0x0600, 0x0600, 0x11A, "T1", { ids = "G2-07" } },
  { "partyMailBackup", 0x071A, 0x071A, 0x11A, "T1", { ids = "G2-07" } },
  { "mailbox", 0x0834, 0x0834, 0x1D7, "T1", { ids = "G2-07" } },
  { "mailboxBackup", 0x0A0B, 0x0A0B, 0x1D7, "T1", { ids = "G2-07" } },
  { "mysteryGift", 0x0BE2, 0x0BE2, 0x4E, "T2", { ids = "G2-20" } },
  { "rtcStatusFlags", 0x0C60, 0x0C60, 8, "T2", { ids = "G2-12" } },
  { "luckyNumber", 0x0C68, 0x0C68, 3, "T2" },
  { "backupPlayerData3", 0x0C6B, nil, 0x47D, "T3", { derived = true, ids = "G2-08 G2-09" } },
  { "backupPokemonData", 0x10E8, nil, 0x4DF, "T3", { derived = true, ids = "G2-08 G2-09" } },
  { "backupPlayerData1", 0x15C7, nil, 0x226, "T3", { derived = true, ids = "G2-08 G2-09" } },
  { "backupPlayerData2", 0x3D96, nil, 0x1AA, "T3", { derived = true, ids = "G2-08 G2-09" } },
  { "backupOptionsAndMap", 0x7E30, nil, 0x3D, "T3", { derived = true, ids = "G2-08" } },
  { "backupChecksum", 0x7E6D, nil, 2, "T3", { derived = true, ids = "G2-08" } },
  { "backupCheckValue2", 0x7E6F, nil, 1, "T3" },
  { "backupOptions", nil, 0x1200, 8, "T3", { derived = true, ids = "G2-19" } },
  { "backupCheckValue1", nil, 0x1208, 1, "T3" },
  { "backupGameData", nil, 0x1209, 0xB7A, "T3", { derived = true, ids = "G2-10" } },
  { "backupChecksum", nil, 0x1F0D, 2, "T3", { derived = true } },
  { "backupCheckValue2", nil, 0x1F0F, 1, "T3" },
  { "options", 0x2000, 0x2000, 8, "T1", { ids = "G2-21" } },
  { "checkValue1", 0x2008, 0x2008, 1, "T3" },
  { "gameData", 0x2009, 0x2009, nil, "T1" },
  { "playerId", 0x2009, 0x2009, 2, "T1" },
  { "playerName", 0x200B, 0x200B, NAME, "T1", { ids = "G2-21" } },
  { "momsName", 0x2016, 0x2016, NAME, "T1" },
  { "rivalName", 0x2021, 0x2021, NAME, "T1" },
  { "redsName", 0x202C, 0x202C, NAME, "T2" },
  { "greensName", 0x2037, 0x2037, NAME, "T2" },
  { "savedAtLeastOnce", 0x2042, 0x2042, 2, "T2" },
  { "rtcStart", 0x2044, 0x2044, 0x0E, "T2", { ids = "G2-12" } },
  { "gameTime", 0x2053, 0x2052, 5, "T1" },
  { "objectStructs", 0x2065, 0x2064, 13 * 0x28, "T2", { ids = "G2-11" } },
  { "mapObjects", 0x22AD, 0x22AC, 16 * 16, "T2", { ids = "G2-11" } },
  { "objectMasks", 0x23AD, 0x23AC, 16, "T2" },
  { "variableSprites", 0x23BD, 0x23BC, 16, "T1" },
  { "statusFlags", 0x23D9, 0x23DA, 2, "T1" },
  { "money", 0x23DB, 0x23DC, 3, "T1" },
  { "momsMoney", 0x23DE, 0x23DF, 4, "T1", { ids = "G2-21" } },
  { "coins", 0x23E2, 0x23E3, 2, "T1" },
  { "badges", 0x23E4, 0x23E5, 2, "T1" },
  { "tmsHms", 0x23E6, 0x23E7, 57, "T1" },
  { "items", 0x241F, 0x2420, 42, "T1", { ids = "G2-13" } },
  { "keyItems", 0x2449, 0x244A, 27, "T1", { ids = "G2-13" } },
  { "balls", 0x2464, 0x2465, 26, "T1", { ids = "G2-13" } },
  { "pcItems", 0x247E, 0x247F, 102, "T1", { ids = "G2-13" } },
  { "pokegearFlags", 0x24E4, 0x24E5, 1, "T1" },
  { "lastDexModeAndRegistered", 0x24E6, 0x24E7, 3, "T2", { ids = "G2-16" } },
  { "playerState", 0x24EA, 0x24EB, 1, "T1", { ids = "G2-21" } },
  { "hallOfFameCount", 0x24EB, 0x24EC, 2, "T2", { ids = "G2-16" } },
  { "tradeFlags", 0x24ED, 0x24EE, 2, "T2", { ids = "G2-16" } },
  { "eventFlags", 0x261F, 0x2600, 256, "T1" },
  { "curBox", 0x2724, 0x2700, 1, "T1", { ids = "G2-18" } },
  { "boxNames", 0x2727, 0x2703, 14 * 9, "T1" },
  { "decorations", 0x27C1, 0x279D, 8, "T2", { ids = "G2-16" } },
  { "momItem", 0x27C9, 0x27A5, 5, "T1", { ids = "G2-21" } },
  { "dailyFlags", 0x27CE, 0x27AA, 0x57, "T2", { ids = "G2-16" } },
  { "stepCounts", 0x2825, 0x2801, 9, "T2", { ids = "G2-16" } },
  { "phoneList", 0x282E, 0x280A, 33, "T2", { ids = "G2-16" } },
  { "visitedSpawns", 0x2856, 0x2833, 4, "T1" },
  { "spawnAndBackupMap", 0x285E, 0x283B, 10, "T2", { ids = "G2-16" } },
  { "mapGroupNumber", 0x2868, 0x2843, 2, "T1" },
  { "yxCoord", 0x286A, 0x2845, 2, "T1", { ids = "G2-11" } },
  { "screenSave", 0x286C, 0x2847, 30, "T2", { ids = "G2-11" } },
  { "pokedexCaught", 0x2A4C, 0x2A27, 32, "T1" },
  { "pokedexSeen", 0x2A6C, 0x2A47, 32, "T1" },
  { "unownDex", 0x2A8C, 0x2A67, 28, "T1", { ids = "G2-14" } },
  { "dayCare", 0x2AA8, 0x2A83, 0xDA, "T2", { ids = "G2-16" } },
  { "roamers", 0x2B82, 0x2B5D, 0x19, "T2", { ids = "G2-16" } },
  { "magikarpRecord", 0x2B9B, 0x2B76, 13, "T2" },
  -- engine/menus/save.asm:424
  { "checksum", 0x2D69, 0x2D0D, 2, "T3", { derived = true } },
  { "checkValue2", 0x2D6B, 0x2D0F, 1, "T3" },
  { "linkBattleStats", 0x31BA, 0x3260, 0x60, "T2" },
  { "hallOfFame", 0x321A, 0x32C0, 0xB7C, "T2", { ids = "G2-16" } },
  { "gsBallFlag", nil, 0x3E3C, 1, "T2" },
  { "crystalData", nil, 0x3E3D, 7, "T1" },
  { "gsBallFlagBackup", nil, 0x3E44, 1, "T2" },
  { "battleTower", nil, 0x3E45, 0x20, "T2", { ids = "G2-16" } },
}

local GAME_DATA_END = { gs = 0x2D69, crystal = 0x2B83 }
local PARTY = { gs = 0x288A, crystal = 0x2865 }
local ACTIVE_BOX = { gs = 0x2D6C, crystal = 0x2D10 }
local BOXES = { 0x4000, 0x4450, 0x48A0, 0x4CF0, 0x5140, 0x5590, 0x59E0,
                0x6000, 0x6450, 0x68A0, 0x6CF0, 0x7140, 0x7590, 0x79E0 }

local Gen2State = require("src.save_convert.Gen2State")
local Gen2Layout = require("src.save_convert.Gen2Layout")

local SKIP_ROWS = { gameData = true, mysteryGift = true, rtcStatusFlags = true, luckyNumber = true,
                    linkBattleStats = true, hallOfFame = true, gsBallFlag = true, gsBallFlagBackup = true,
                    battleTower = true }

local function spanOf(spec, S)
  if spec.abs then return spec.abs, spec.len end
  local from = S[spec[1]]
  if not from then return nil end
  from = from + (spec.plus or 0)
  local to = spec.len and from + spec.len or S[spec[2]]
  if not to then return nil end
  return from, to - from
end

local function build(which)
  local regions = {}
  local names = {}
  local function R(offset, size, tier, name, extra)
    local base = name
    local n = 1
    while names[name] do n = n + 1; name = base .. "#" .. n end
    names[name] = true
    local r = { offset = offset, size = size, tier = tier, name = name }
    for k, v in pairs(extra or {}) do r[k] = v end
    regions[#regions + 1] = r
  end
  local function list(prefix, base, cap, structSize, tier, extra)
    R(base, 2 + cap + cap * (structSize + 2 * NAME), tier, prefix, extra)
    R(base, 1, tier, prefix .. ".count")
    R(base + 1, cap + 1, tier, prefix .. ".species", { ids = "G2-01 G2-02" })
    local monsAt = base + 2 + cap
    local otAt = monsAt + cap * structSize
    local nickAt = otAt + cap * NAME
    for i = 1, cap do
      R(monsAt + (i - 1) * structSize, structSize, tier, ("%s.mon%d"):format(prefix, i))
      R(otAt + (i - 1) * NAME, NAME, tier, ("%s.ot%d"):format(prefix, i))
      R(nickAt + (i - 1) * NAME, NAME, tier, ("%s.nick%d"):format(prefix, i), { ids = "G2-03" })
    end
  end
  for _, row in ipairs(ROWS) do
    local off
    if which == "gs" then off = row[2] else off = row[3] end
    local inside = off and off >= 0x2009 and off < GAME_DATA_END[which]
    if off and not SKIP_ROWS[row[1]] and not inside then
      local size = row[4] or (GAME_DATA_END[which] - off)
      R(off, size, row[5], row[1], row[6])
    end
  end
  local S = Gen2State.symsFor(which == "gs" and "gold" or "crystal")
  for _, mod in ipairs(Gen2State.modules()) do
    for _, row in ipairs(mod.coverage or {}) do
      local spec = row.both or row[which]
      if spec then
        local from, size = spanOf(spec, S)
        if from then
          local label = spec[1] or ("abs" .. string.format("%04X", from))
          R(from, size, row.mode == "modeled" and "T1" or "T2", label .. (spec.plus and "+" .. spec.plus or ""))
        end
      end
    end
    for _, row in ipairs(mod.sram or {}) do
      local spec = row.both or row[which]
      if spec then
        local from, size = spanOf(spec, S)
        if from then R(from, size, row.mode == "modeled" and "T1" or "T2", spec[1]) end
      end
    end
  end
  list("party", PARTY[which], 6, PARTY_STRUCT, "T1")
  list("activeBox", ACTIVE_BOX[which], 20, BOX_STRUCT, "T1", { ids = "G2-05" })
  for i, base in ipairs(BOXES) do
    list(("box%02d"):format(i), base, 20, BOX_STRUCT, "T1")
  end
  R(0x8000, 0x30, "T2", "rtcFooter", { ids = "G2-12" })
  return regions
end

local gs, crystal = build("gs"), build("crystal")

return {
  generation = 2,
  size = 0x8000,
  layouts = { gold = gs, silver = gs, crystal = crystal, default = gs },
  gs = gs,
  crystal = crystal,
}
