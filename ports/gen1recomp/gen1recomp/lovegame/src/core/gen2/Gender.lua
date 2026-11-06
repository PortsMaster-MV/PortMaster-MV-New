local Gender = {}

-- pokecrystal/engine/pokemon/mon_stats.asm:124
function Gender.of(ratio, dvs)
  if not ratio or ratio == 0xff then return "unknown" end
  if ratio == 0 then return "male" end
  if ratio == 0xfe then return "female" end
  local value = (dvs and dvs.attack or 0) * 16 + (dvs and dvs.speed or 0)
  return value <= ratio and "female" or "male"
end

return Gender
