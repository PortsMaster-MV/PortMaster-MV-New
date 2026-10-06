local M = {}
function M.completedHoenn(session)
  local Dex, Pokemon = require("src.core.game3.dex"), require("src.core.game3.pokemon")
  local dex = session and session.dex or {}
  local required = 0
  for nat = 1, 386 do
    local species = Pokemon.speciesFromNational(nat)
    local number = Dex.regionalNumber(species)
    if number and number >= 1 and number <= 200 then
      required = required + 1
      if not Dex.isCaught(dex, species) then return false end
    end
  end
  return required == 200
end
function M.counts(session, national)
  local Dex, Pokemon = require("src.core.game3.dex"), require("src.core.game3.pokemon")
  local dex, seen, caught = session and session.dex or {}, 0, 0
  for nat = 1, 386 do
    local sp = Pokemon.speciesFromNational(nat)
    local h = sp and Dex.regionalNumber(sp)
    if sp and (national or h and h >= 1 and h <= 202) then
      if Dex.isSeen(dex, sp) then seen = seen + 1 end
      if Dex.isCaught(dex, sp) then caught = caught + 1 end
    end
  end
  return seen, caught
end
-- pokeruby/src/pokedex.c:4100
function M.completedNational(session)
  local Dex, Pokemon = require("src.core.game3.dex"), require("src.core.game3.pokemon")
  local dex = session and session.dex or {}
  for _, range in ipairs({{1, 150}, {153, 250}, {253, 384}}) do
    for nat = range[1], range[2] do
      local sp = Pokemon.speciesFromNational(nat)
      if not sp or not Dex.isCaught(dex, sp) then return false end
    end
  end
  return true
end
return M
