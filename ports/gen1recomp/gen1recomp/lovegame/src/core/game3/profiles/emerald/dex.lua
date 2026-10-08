return {
  regional = "hoenn",
  regionalPack = "pokemon/hoenn.lua",
  orderPack = "pokemon/regional_dex.lua",
  -- pokeemerald/include/constants/pokedex.h:426
  nationalMax = 386,
  -- pokeemerald/src/event_data.c:74
  national = {
    flag = "FLAG_SYS_NATIONAL_DEX",
    var = "VAR_NATIONAL_DEX",
    value = 0x302,
    magic = 0xDA,
    requireAll = true,
  },
  registerGate = false,
  evolutionGate = false,
}
