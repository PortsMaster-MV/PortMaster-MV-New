local Rs = {}

function Rs.bind(E, H)
  return require("src.core.game3.encounter_rules.rse").bind(E, H, { nativeRS = true })
end

return Rs
