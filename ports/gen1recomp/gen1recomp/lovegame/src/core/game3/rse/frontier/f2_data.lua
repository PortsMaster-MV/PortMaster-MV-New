local Data = {}

Data.MANIFEST = "data/generated/gba/rse/frontier_f2/manifest.lua"

local cache = {}

local function load(rel)
  local GameVersion = require("src.core.GameVersion")
  local key = tostring(GameVersion.get()) .. ":" .. rel
  local hit = cache[key]
  if hit then return hit end
  local src = require("src.core.game3.dataset").cache():read(rel)
  if type(src) ~= "string" then error("frontier f2: " .. rel .. " missing from the cache", 0) end
  local chunk = assert((loadstring or load)(src, "@" .. rel))
  if setfenv then setfenv(chunk, {}) end
  local t = chunk()
  cache[key] = t
  return t
end

function Data.manifest()
  return load(Data.MANIFEST)
end

function Data.palace() return Data.manifest().palace end
function Data.arena() return Data.manifest().arena end
function Data.dome() return Data.manifest().dome end

function Data.reset()
  cache = {}
end

function Data.textPlain(ir, ctx)
  local TextIR = require("src.core.game3.scripting.text_ir")
  return TextIR.toPlain(ir or {}, ctx or {})
end

-- pokeemerald/src/battle_message.c:2297
function Data.battleText(ir, fill)
  local BattleText = require("src.core.game3.battle.battle_text")
  local RomText = require("src.core.game3.rom_text")
  local TextIR = require("src.core.game3.scripting.text_ir")
  local ctx = BattleText.context(fill or {})
  return TextIR.toAscii(RomText.translate(ir, ctx), ctx)
end

return Data
