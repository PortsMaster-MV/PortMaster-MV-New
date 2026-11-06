local AREAS = {
  "maps", "scripts", "data", "pokemon_gfx", "text", "ow", "field", "battle", "audio", "boot", "ui", "rse",
  "b1", "b2", "b3", "fa", "fb", "fc", "ua", "ub", "uc", "ud", "xa", "aa",
  "c1a", "c1b", "sb", "pb1", "pb2", "tv", "misc", "gc", "ma", "pn", "f1", "f2", "f3", "f4", "sav", "link", "lmg", "ver",
}

local plan = {
  id = "rse",
  tasks = {},
  sequential = {},
  pokemonAfter = {},
  aux = {},
  dirs = { "", "/intro", "/audio" },
}

local function append(dst, src)
  for _, v in ipairs(src or {}) do dst[#dst + 1] = v end
end

for _, area in ipairs(AREAS) do
  local ok, frag = pcall(require, "src.import.gba.plans.rse." .. area)
  if ok and type(frag) == "table" then
    append(plan.tasks, frag.tasks)
    append(plan.sequential, frag.sequential)
    append(plan.pokemonAfter, frag.pokemonAfter)
    append(plan.aux, frag.aux)
    append(plan.dirs, frag.dirs)
  elseif not ok and not tostring(frag):find("module 'src.import.gba.plans.rse." .. area .. "' not found", 1, true) then
    error(frag, 0)
  end
end

plan.auxSteps = #plan.aux

return plan
