local A = require("src.import.gba.rs.assets")
local K = require("src.import.gba.rse.boot_gfx")
local Bake = require("src.import.gba.bg_bake")
local M = { SUB = "hall_of_fame", FILES = { "bands.rgba", "stripes.rgba", "confetti.rgba" } }
M.REQUIRED = K.required(M.SUB, M.FILES)
local function bytes(s) local out = {}; for i = 1, #s do out[i] = s:byte(i) end; out._len = #s; return out end
local function map(stripes)
  local out = {}
  -- pokeruby/hall_of_fame.c:1214
  for y = 0, 31 do for x = 0, 31 do
    local tile = stripes and 2 or (y < 2 or (y >= 14 and y < 20)) and 1 or 0
    local at = (y * 32 + x) * 2 + 1; out[at], out[at + 1] = tile, 0
  end end
  out._len = 2048; return out
end
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local gfx = bytes(c:lz("gHallOfFame_Gfx"))
  local banks = Bake.loadPalBanks(bytes(c:raw("gHallOfFame_Pal", 32)), 1)
  c:write("bands.rgba", Bake.bakeRegionRgba(gfx, banks, map(false), 240, 160, { alpha0 = true }))
  c:write("stripes.rgba", Bake.bakeRegionRgba(gfx, banks, map(true), 240, 160, {}))
  local confetti = bytes(c:lz("gContestConfetti_Gfx"))
  assert(confetti._len == 0x220, "RS Hall of Fame confetti native length")
  local pal = Bake.loadPalBanks(bytes(c:lz("gContestConfetti_Pal")), 1)[0]
  local frames = {}; for i = 0, 16 do frames[#frames + 1] = Bake.bakeSpriteRgba(confetti, pal, i, 8, 8, false, false) end
  c:write("confetti.rgba", table.concat(frames))
  return A.finish(c, { format_version = 1, hofVersion = 1, width = 240, height = 160, confetti = { w = 8, h = 8, frames = 17 } })
end
function M.ready(cache, root)
  if not A.ready(M.SUB, cache, root) then return false end
  for _, file in ipairs(M.FILES) do if not cache:exists((root or "data/generated/gba") .. "/" .. M.SUB .. "/" .. file) then return false end end
  return true
end
return M
