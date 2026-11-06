return {
  tasks = {
    {
      id = "rse_lmg",
      run = "steps",
      weight = 0.02,
      steps = {
        { name = "src.import.gba.rse.lmg_extract", label = "Wireless Minigames & Mystery Gift" },
      },
    },
  },
  sequential = { "rse_lmg" },
  dirs = { "/link", "/berry_crush", "/dodrio_berry_picking", "/pokemon_jump", "/mystery_gift" },
}
