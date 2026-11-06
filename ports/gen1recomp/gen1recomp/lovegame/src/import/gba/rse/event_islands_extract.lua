local K = require("src.import.gba.rse.boot_gfx")

local M = {}

M.SUB = "rse/event_islands"
M.FILES = {}
M.REQUIRED = K.required(M.SUB, M.FILES)

-- pokeemerald/data/mystery_gift.s:23
M.GIFT_SCRIPTS = {
  { id = "aurora", labels = { "MysteryGiftScript_AuroraTicket", "AuroraTicket_NoBagSpace", "AuroraTicket_Obtained" } },
  { id = "mystic", labels = { "MysteryGiftScript_MysticTicket", "MysticTicket_NoBagSpace", "MysticTicket_Obtained" } },
  { id = "oldSeaMap", labels = { "MysteryGiftScript_OldSeaMap", "OldSeaMap_NoBagSpace", "OldSeaMap_Obtained" } },
  -- pokeemerald/data/scripts/gift_pichu.inc:1
  { id = "surfPichu", labels = { "MysteryGiftScript_SurfPichu", "SurfPichu_GiveIfPossible", "SurfPichu_FullParty",
    "SurfPichu_GiveEgg", "SurfPichu_Slot1", "SurfPichu_Slot2", "SurfPichu_Slot3", "SurfPichu_Slot4",
    "SurfPichu_Slot5" } },
  -- pokeemerald/data/scripts/gift_battle_card.inc:1
  { id = "battleCard", labels = { "MysteryGiftScript_BattleCard", "MysteryGiftScript_BattleCardInfo" } },
  -- pokeemerald/data/scripts/gift_stamp_card.inc:1
  { id = "stampCard", labels = { "MysteryGiftScript_StampCard" } },
  -- pokeemerald/data/scripts/gift_altering_cave.inc:1
  { id = "alteringCave", labels = { "MysteryGiftScript_AlteringCave", "MysteryGiftScript_AlteringCave_" } },
}

local function bytesAt(c, off, maxLen)
  local out = {}
  for i = 0, (maxLen or 1024) - 1 do
    local b = c:u8(off + i)
    out[#out + 1] = b
    if b == 0xFF then break end
  end
  return out
end

local function isRomPtr(p)
  return type(p) == "number" and p >= 0x08000000 and p < 0x0A000000
end

-- pokeemerald/src/scrcmd.c:191
local function giftScript(c, label, texts)
  local Disasm = require("src.core.game3.scripting.disasm")
  local Opcodes = require("src.core.game3.scripting.opcodes")
  local TextIR = require("src.core.game3.scripting.text_ir")
  local set = Opcodes.forGame("emerald")
  local off = c:off(label)
  local raw = c.rom:readString(off, 256)
  local bytes = { raw:byte(1, #raw) }
  local rows, i = {}, 1
  while i <= #bytes do
    local row
    row, i = Disasm.decodeOne(bytes, i, set)
    if row.op == "unknown" then error("event_islands_extract: unknown opcode in " .. label) end
    if row.op == "vmessage" and isRomPtr(row[1]) then
      local key = Opcodes.key(row[1])
      texts[key] = TextIR.decode(bytesAt(c, row[1] - 0x08000000), { dialect = "rse" })
      row[1] = key
      row.ptr = key
    elseif (row.op == "vgoto_if" or row.op == "vcall_if") and isRomPtr(row[2]) then
      row[2] = Opcodes.key(row[2])
      row.target = row[2]
    elseif (row.op == "vgoto" or row.op == "vcall") and isRomPtr(row[1]) then
      row[1] = Opcodes.key(row[1])
      row.target = row[1]
    end
    rows[#rows + 1] = row
    if row.op == "end" or row.op == "return" then break end
  end
  return string.format("g3:%08x", off + 0x08000000), rows
end

-- pokeemerald/src/field_specials.c:3269
local function rockPalettes(c)
  local name = "sDeoxysRockPalettes"
  local off, out = c:off(name), {}
  for i = 0, c.S.size(name) / 32 - 1 do out[i + 1] = K.palList(c:palAt(off + i * 32, 16), 0, 16) end
  return out
end

function M.run(rom, cache, opts)
  local c = K.context(rom, cache, opts, M.SUB)
  local coords, co = {}, c:off("sDeoxysRockCoords")
  for i = 0, c.S.size("sDeoxysRockCoords") / 2 - 1 do coords[i + 1] = { c:u8(co + i * 2), c:u8(co + i * 2 + 1) } end
  local steps, so = {}, c:off("sStoneMaxStepCounts.480")
  for i = 0, c.S.size("sStoneMaxStepCounts.480") - 1 do steps[i + 1] = c:u8(so + i) end
  local texts, scripts, gifts = {}, {}, {}
  for _, g in ipairs(M.GIFT_SCRIPTS) do
    local keys = {}
    for j, label in ipairs(g.labels) do
      local key, rows = giftScript(c, label, texts)
      scripts[key] = rows
      keys[j] = key
    end
    gifts[#gifts + 1] = { id = g.id, script = keys[1], labels = g.labels, keys = keys }
  end
  return true, c:finish({
    screen = "event_islands",
    deoxysRockCoords = coords,
    deoxysRockMaxSteps = steps,
    deoxysRockPalettes = rockPalettes(c),
    gifts = gifts,
    giftScripts = scripts,
    giftTexts = texts,
  })
end

function M.ready(cache, cacheRoot)
  return K.ready(M.SUB, cache, cacheRoot)
end

return M
