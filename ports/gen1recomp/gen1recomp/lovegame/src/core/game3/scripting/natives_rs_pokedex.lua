local Rse = require("src.core.game3.rse.init")
local M = {BY_NAME = {}}
-- pokeruby/src/birch_pc.c:33
M.BY_NAME.ScriptGetPokedexInfo = function(ctx)
  local s = Rse.session()
  local seen, caught = require("src.core.game3.profiles.rs.pokedex").counts(s, Rse.specialVar(ctx, 0x8004) ~= 0)
  Rse.setSpecialVar(ctx, 0x8005, seen)
  Rse.setSpecialVar(ctx, 0x8006, caught)
  return false, require("src.core.game3.dex").nationalEnabled(s) and 1 or 0
end
-- birch_pc.c:50
function M.ratingText(session, count)
  count = math.floor(tonumber(count) or 0) % 65536
  if count < 200 then return "gBirchDexRatingText_LessThan" .. ((math.floor(count / 10) + 1) * 10) end
  local Dex, C = require("src.core.game3.dex"), require("src.core.game3.constants").active(session)
  local dex = session and session.dex or {}
  local jirachi = Dex.isCaught(dex, C:require("species", "SPECIES_JIRACHI"))
  local deoxys = Dex.isCaught(dex, C:require("species", "SPECIES_DEOXYS"))
  if count == 200 then return (jirachi or deoxys) and "gBirchDexRatingText_LessThan200" or "gBirchDexRatingText_DexCompleted" end
  if count == 201 then return (jirachi and deoxys) and "gBirchDexRatingText_LessThan200" or "gBirchDexRatingText_DexCompleted" end
  if count == 202 then return "gBirchDexRatingText_DexCompleted" end
  return "gBirchDexRatingText_LessThan10"
end
-- birch_pc.c:111
M.BY_NAME.ShowPokedexRatingMessage = function(ctx, adapters)
  local key = M.ratingText(Rse.session(), Rse.specialVar(ctx, 0x8004))
  local text = require("src.core.game3.rom_text").box(key, ctx)
  if ctx then ctx.messageOpen = true end
  local stay = adapters and (adapters.openMessageStay or adapters.openMessageAsync)
  if stay then stay(text, nil)
  elseif adapters and adapters.openMessage then adapters.openMessage(text)
  else error("RS Birch rating message host missing") end
  return false
end
return M
