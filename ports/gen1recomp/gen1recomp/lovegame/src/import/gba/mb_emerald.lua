local MB = require("src.core.game3.mb")
local Constants = require("src.core.game3.constants")

local M = { game = "emerald" }

local toCanon, toRaw

local function build()
  if toCanon then return end
  toCanon, toRaw = {}, {}
  local byId = Constants.of(M.game).metatile_behaviors.byId.MB_ or {}
  for raw = 0, 255 do
    local name = byId[raw]
    local canon = name and MB.id(name) or (MB.RSE_BASE + raw)
    toCanon[raw] = canon
    if toRaw[canon] == nil then toRaw[canon] = raw end
  end
end

-- pokeemerald/include/global.fieldmap.h:39
function M.canon(raw)
  build()
  raw = (tonumber(raw) or 0) % 256
  return toCanon[raw]
end

function M.raw(canon)
  build()
  return toRaw[tonumber(canon) or -1]
end

function M.table()
  build()
  local out = {}
  for raw, canon in pairs(toCanon) do out[raw] = canon end
  return out
end

-- pokeemerald/src/metatile_behavior.c:9
function M.tileBits(rom)
  local S = require("src.import.gba.syms").of(M.game)
  local off = S.off("sTileBitAttributes")
  local n = S.size("sTileBitAttributes")
  local out = {}
  for raw = 0, n - 1 do
    local bits = rom:get(off + raw) or 0
    if bits ~= 0 then out[M.canon(raw)] = bits end
  end
  return out
end

M.TILE_FLAG_HAS_ENCOUNTERS = 1
M.TILE_FLAG_SURFABLE = 2

return M
