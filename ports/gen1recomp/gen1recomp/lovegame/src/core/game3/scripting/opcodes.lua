local Opcodes = {}

local COMMON = require("src.core.game3.scripting.opcodes_common")

local TAILS = {
  firered = "src.core.game3.scripting.opcodes_frlg",
  emerald = "src.core.game3.scripting.opcodes_emerald",
  ruby = "src.core.game3.scripting.opcodes_rs",
}

local function build(tail, limit)
  local t = {}
  for byte, row in pairs(COMMON) do
    if not limit or byte <= limit then t[byte] = row end
  end
  local max = 0
  for byte, row in pairs(tail) do
    t[byte] = row
    if byte > max then max = byte end
  end
  return t, max
end

Opcodes.TABLE, Opcodes.MAX = build(require(TAILS.firered))

Opcodes.COND = {
  LT = 0, EQ = 1, GT = 2, LE = 3, GE = 4, NE = 5,
}

-- pokefirered/data/event_scripts.s:77
Opcodes.STD = {
  OBTAIN_ITEM = 0,
  FIND_ITEM = 1,
  MSGBOX_NPC = 2,
  MSGBOX_SIGN = 3,
  MSGBOX_DEFAULT = 4,
  MSGBOX_YESNO = 5,
  MSGBOX_AUTOCLOSE = 6,
  OBTAIN_DECORATION = 7,
  PUT_ITEM_AWAY = 8,
  RECEIVED_ITEM = 9,
}

-- pokeemerald/data/event_scripts.s:96
local STD_EMERALD = {
  OBTAIN_ITEM = 0,
  FIND_ITEM = 1,
  MSGBOX_NPC = 2,
  MSGBOX_SIGN = 3,
  MSGBOX_DEFAULT = 4,
  MSGBOX_YESNO = 5,
  MSGBOX_AUTOCLOSE = 6,
  OBTAIN_DECORATION = 7,
  REGISTER_MATCH_CALL = 8,
  MSGBOX_GETPOINTS = 9,
  MSGBOX_POKENAV = 10,
}

local STD_RS = {}
for name, id in pairs(Opcodes.STD) do
  if id < 8 then STD_RS[name] = id end
end

-- pokeemerald/asm/macros/event.inc:1024
local BRAILLE_FORMAT_SIZE = { firered = 0, emerald = 6, ruby = 6 }

Opcodes.LOCALID_PLAYER = 0xFF

Opcodes.STEP_END = 0xFE

function Opcodes.get(byte)
  return Opcodes.TABLE[byte]
end

function Opcodes.key(addr)
  if type(addr) == "string" then return addr end
  return string.format("g3:%08x", tonumber(addr) or 0)
end

local function trainerBattleTypes(game)
  local battle = require("src.core.game3.constants." .. game .. ".battle")
  local out = {}
  for id, name in pairs(battle.byId.TRAINER_BATTLE_) do
    out[id] = name:gsub("^TRAINER_BATTLE_", "")
  end
  return out
end

local sets = {}

local SetMethods = {}
SetMethods.__index = SetMethods

function SetMethods:get(byte)
  return self.TABLE[byte]
end

function SetMethods:trainerBattleType(typ)
  return self.TRAINER_BATTLE[tonumber(typ) or -1]
end

local function gameKey(version)
  local Profile = require("src.core.game3.profile")
  local Constants = require("src.core.game3.constants")
  return Constants.gameKey(Profile.resolveId(version))
end

function Opcodes.forGame(version)
  local game = gameKey(version)
  local set = sets[game]
  if set then return set end
  local tbl, max
  if game == "firered" then
    tbl, max = Opcodes.TABLE, Opcodes.MAX
  else
    tbl, max = build(require(assert(TAILS[game], "no opcode table for " .. game)),
      game == "ruby" and 0xC5 or nil)
  end
  set = setmetatable({
    game = game,
    TABLE = tbl,
    MAX = max,
    STD = game == "firered" and Opcodes.STD or game == "ruby" and STD_RS or STD_EMERALD,
    TRAINER_BATTLE = trainerBattleTypes(game),
    brailleFormatSize = BRAILLE_FORMAT_SIZE[game] or 0,
  }, SetMethods)
  sets[game] = set
  return set
end

function Opcodes.active()
  local GameVersion = require("src.core.GameVersion")
  return Opcodes.forGame(GameVersion.get())
end

return Opcodes
