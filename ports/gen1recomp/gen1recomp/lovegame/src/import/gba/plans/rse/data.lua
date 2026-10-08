return {
  tasks = {
    {
      id = "data_tables",
      run = "steps",
      weight = 0.04,
      steps = {
        { name = "items_extract", label = "Items" },
        { name = "battle_moves_extract", label = "Battle Moves" },
        { name = "contest_moves_extract", label = "Contest Moves" },
        { name = "tutor_extract", label = "Move Tutors" },
        { name = "ingame_trades_extract", label = "In-Game Trades" },
        { name = "berries_extract", label = "Berries" },
        { name = "pokedex_entries_extract", label = "Pokedex Entries" },
        { name = "frontier_data_extract", label = "Battle Frontier Data" },
      },
    },
    {
      id = "data_trainers",
      run = "steps",
      weight = 0.04,
      steps = {
        { name = "trainer_extract", label = "Trainers" },
      },
    },
  },
  sequential = { "data_tables", "data_trainers" },
  dirs = {
    "/items",
    "/pokemon",
    "/pokemon/pokedex",
    "/trainers",
    "/trainers/front",
    "/trades",
    "/berries",
    "/frontier",
  },
}
