return {
  tasks = {
    {
      id = "battle_anims",
      run = "steps",
      weight = 0.06,
      steps = {
        { name = "battle_anim_extract", opts = { strict = true }, label = "Battle Animations" },
      },
    },
    {
      id = "battle_assets",
      run = "steps",
      weight = 0.04,
      steps = {
        { name = "battle_ai_extract", label = "Battle AI Scripts" },
        { name = "battle_chrome_extract", label = "Battle UI Graphics" },
        { name = "battle_transition_extract", label = "Battle Transitions" },
        { name = "ball_open_extract", label = "Poke Ball Graphics" },
        { name = "battle_rse_data_extract", label = "Battle Tables" },
      },
    },
  },
  sequential = { "battle_anims", "battle_assets" },
  dirs = {
    "/battle_ai",
    "/pokemon/battle",
    "/pokemon/battle/ball_open",
    "/pokemon/battle_anims",
    "/pokemon/battle_anims/tags",
    "/pokemon/battle_anims/animbg",
    "/pokemon/battle_anims/statmask",
    "/pokemon/battle_transition",
  },
}
