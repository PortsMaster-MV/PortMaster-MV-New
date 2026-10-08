local plan = {
  id = "rs", tasks = {}, sequential = {}, pokemonAfter = {}, aux = {},
  dirs = { "", "/intro", "/audio", "/items", "/pokemon", "/pokemon/pokedex", "/trades", "/berries" },
}
local function add(task)
  plan.tasks[#plan.tasks + 1] = task
  plan.sequential[#plan.sequential + 1] = task.id
end
for _, area in ipairs({ "maps", "scripts" }) do
  local fragment = require("src.import.gba.plans.rse." .. area)
  for _, task in ipairs(fragment.tasks) do add(task) end
  for _, dir in ipairs(fragment.dirs) do plan.dirs[#plan.dirs + 1] = dir end
end
add({ id = "rs_field", run = "steps", weight = 0.08, steps = {
  { name = "ow_extract", opts = { all = true }, label = "Native Overworld Sprites" },
  { name = "field_effect_extract", label = "Native Field Effects" },
  { name = "weather_extract", label = "Native Weather & Drought Palettes" },
  { name = "cave_transition_extract", label = "Cave Transition" },
  { name = "door_anim_extract", label = "Native Door Animations" },
  { name = "src.import.gba.rse.berry_tree_gfx_extract", label = "Native Berry Trees" },
  { name = "src.import.gba.rse.rotating_gate_gfx_extract", label = "Native Rotating Gates" },
  { name = "src.import.gba.rse.fc_field_extract", label = "Field Palettes" },
} })
for _, dir in ipairs({"/ow", "/field_effects", "/weather", "/cave_transition", "/doors", "/berry_trees", "/rotating_gates", "/field_fc"}) do plan.dirs[#plan.dirs + 1] = dir end
add({ id = "rs_world_tables", run = "steps", weight = 0.02, steps = {
  { name = "src.import.gba.rs.extract_region_map", label = "Native Hoenn Map & Sections" },
  { name = "src.import.gba.rs.extract_encounters", label = "Native Wild Encounters & Feebas" },
  { name = "multichoice_extract", label = "Native Dialog Menus" },
  { name = "heal_locations_extract", opts = { strict = true }, label = "Native Heal & Fly Locations" },
  { name = "roamer_extract", label = "Native Roamer Routes" },
} })
for _, dir in ipairs({"/heal_locations", "/roamer", "/region_map", "/rse", "/rse/region_map"}) do plan.dirs[#plan.dirs + 1] = dir end
add({ id = "rs_slots", run = "steps", weight = 0.02, steps = {
  { name = "src.import.gba.rs.extract_slot_machine", label = "Native Slot Machines & Reel Time" },
} })
plan.dirs[#plan.dirs + 1] = "/rse_slot_machine"
add({ id = "rs_missing_content", run = "steps", weight = 0.04, steps = {
  { name = "src.import.gba.rs.extract_hall_of_fame", label = "Native Hall of Fame" },
  { name = "src.import.gba.rs.extract_credits", label = "Native Ruby and Sapphire Credits" },
  { name = "src.import.gba.rs.extract_reset_rtc", label = "Native RTC Reset Controls" },
  { name = "src.import.gba.rs.extract_roulette", label = "Native Roulette Tables and Graphics" },
  { name = "src.import.gba.rs.extract_pokeblock", label = "Native Pokeblock Case and Feeding" },
  { name = "src.import.gba.rs.extract_move_relearner", label = "Native Move Relearner" },
  { name = "src.import.gba.rs.extract_decorations", label = "Native Decorations" },
  { name = "src.import.gba.rs.extract_secret_base", label = "Native Secret Bases" },
  { name = "src.import.gba.rs.extract_safari", label = "Native Safari and Pokeblock Tables" },
  { name = "src.import.gba.rs.extract_shop", label = "Native Shop Graphics and Text" },
  { name = "src.import.gba.rs.extract_contest_painting", label = "Native Contest Winner Paintings" },
} })
for _, dir in ipairs({"/hall_of_fame", "/credits_rse", "/reset_rtc", "/rse_roulette", "/rse/pokeblock", "/rse/move_relearner", "/decorations", "/secret_base", "/safari", "/items/shop", "/rse/contest_painting"}) do plan.dirs[#plan.dirs + 1] = dir end
add({ id = "rs_battle_assets", run = "steps", weight = 0.05, steps = {
  { name = "battle_ai_extract", label = "Native Battle AI Programs" },
  { name = "battle_chrome_extract", label = "Native Battle Environments & Healthboxes" },
  { name = "ball_open_extract", label = "Native Poke Balls & Particles" },
  { name = "src.import.gba.rs.extract_battle_transitions", label = "Native Battle Transitions & Steven Mugshot" },
  { name = "src.import.gba.rs.extract_battle_anims", opts = {strict = true}, label = "Native Battle Animation Scripts & Templates" },
} })
for _, dir in ipairs({"/pokemon/battle", "/pokemon/battle/ball_open", "/battle_ai", "/pokemon/battle_transition", "/pokemon/battle_anims", "/pokemon/battle_anims/tags"}) do plan.dirs[#plan.dirs + 1] = dir end
add({ id = "rs_newgame", run = "steps", weight = 0.04, steps = {
  { name = "src.import.gba.rs.extract_easy_chat", label = "Native Easy Chat Words & Groups" },
  { name = "src.import.gba.rs.extract_misc", label = "Native Town, Bard & Trader Defaults" },
  { name = "src.import.gba.rs.extract_tv", label = "Native TV Outbreak Species" },
  { name = "src.import.gba.rs.extract_battle_tower", label = "Native Battle Tower Trainers, Pokemon & Rules" },
  { name = "src.import.gba.rs.extract_battle_tower_records", label = "Native Battle Tower Records Board" },
  { name = "src.import.gba.rs.extract_secret_base_battle", label = "Native Secret Base Battle Metadata" },
  { name = "src.import.gba.rs.extract_fan_club", label = "Native Lilycove Fan Club Trainer Names" },
  { name = "src.import.gba.rs.extract_contest", label = "Native Contest Winner Defaults" },
  { name = "src.import.gba.rs.extract_contest_data", label = "Native Contest Opponents, AI and Entry Rules" },
  { name = "src.import.gba.rs.extract_contest_gfx", label = "Native Contest Stage and Results Graphics" },
  { name = "src.import.gba.rs.extract_berry_blender", label = "Native Berry Blender Graphics and Rules" },
  { name = "src.import.gba.rs.extract_cable_car", label = "Native Cable Car Graphics" },
  { name = "src.import.gba.rs.extract_birch", label = "Native Birch Speech & Main Menu" },
  { name = "src.import.gba.rs.extract_starter", label = "Native Starter Selection" },
  { name = "src.import.gba.rs.extract_wallclock", label = "Native Wall Clock" },
  { name = "src.import.gba.rs.extract_naming", label = "Native Naming Keyboard & Sprites" },
} })
for _, dir in ipairs({"/birch", "/starter_choose", "/wallclock", "/naming", "/easy_chat", "/rse/misc", "/rse/contest", "/rse/battle_tower", "/rse/secret_base_battle"}) do plan.dirs[#plan.dirs + 1] = dir end
add({ id = "rs_content_assets", run = "steps", weight = 0.06, steps = {
  { name = "src.import.gba.rs.extract_menus", label = "Native Option, Start & Party Menu Tables" },
  { name = "src.import.gba.rs.extract_common_ui", label = "Native Menu Cursor & Object Window" },
  { name = "src.import.gba.rs.extract_bag", label = "Native Bag Backgrounds, Pockets & Sprites" },
  { name = "src.import.gba.rs.extract_berry_tag", label = "Native Berry Tag, Flavors & Berry Pictures" },
  { name = "src.import.gba.rs.extract_party", label = "Native Party Panels, Icons & Coordinates" },
  { name = "src.import.gba.rs.extract_summary", label = "Native Summary Pages, Types & Status" },
  { name = "src.import.gba.rs.extract_mail", label = "Native Mail Stationery & Text Layouts" },
  { name = "src.import.gba.rs.extract_easy_chat_ui", label = "Native Easy Chat Mail Composer" },
  { name = "src.import.gba.rs.extract_trendy_phrase", label = "Native Dewford Trendy Phrase Editor" },
  { name = "src.import.gba.rs.extract_easy_chat_editor", label = "Native Easy Chat Editors and Phrase Messages" },
  { name = "src.import.gba.rs.extract_egg_hatch", label = "Native Egg Hatch Scene" },
  { name = "src.import.gba.rs.extract_storage", label = "Native Storage Wallpapers, Interface & Sprites" },
  { name = "src.import.gba.rs.extract_pokedex", label = "Native Pokedex Backgrounds & Search Tables" },
  { name = "src.import.gba.rs.extract_pokedex_detail", label = "Native Pokedex Area, Cry, Size & Search Details" },
  { name = "src.import.gba.rs.extract_diploma", label = "Native Hoenn and National Diplomas" },
  { name = "src.import.gba.rs.extract_trainer_card", label = "Native Trainer Card Art, Windows and Text" },
  { name = "src.import.gba.rs.extract_trade", label = "Native Cable Trade Art, Menus and Scenes" },
  { name = "src.import.gba.rs.extract_pokenav", label = "Native PokeNav Options, Headers & City Maps" },
  { name = "src.import.gba.rs.extract_pokenav_detail", label = "Native PokeNav Lists & Trainer's Eyes Records" },
  { name = "src.import.gba.rs.extract_pokenav_shell", label = "Native PokeNav Shell, Controls & Landmarks" },
  { name = "src.import.gba.rs.extract_pokenav_condition", label = "Native PokeNav Condition Graph & Search Layers" },
  { name = "src.import.gba.rs.extract_pokenav_ribbons", label = "Native PokeNav Ribbon Icons & Descriptions" },
  { name = "src.import.gba.rs.extract_content_assets", label = "Native UI, Contest, PokeNav, Storage & Link Assets" },
} })
plan.dirs[#plan.dirs + 1] = "/pokemon/storage"
plan.dirs[#plan.dirs + 1] = "/rse/menus"
plan.dirs[#plan.dirs + 1] = "/rse/common_ui"
plan.dirs[#plan.dirs + 1] = "/rse/bag"
plan.dirs[#plan.dirs + 1] = "/rse/berry_tag"
plan.dirs[#plan.dirs + 1] = "/rse/party"
plan.dirs[#plan.dirs + 1] = "/rse/summary"
plan.dirs[#plan.dirs + 1] = "/rse/mail"
plan.dirs[#plan.dirs + 1] = "/rse/easy_chat"
plan.dirs[#plan.dirs + 1] = "/rse/trendy_phrase"
plan.dirs[#plan.dirs + 1] = "/rse/easy_chat_editor"
plan.dirs[#plan.dirs + 1] = "/rse/rs_tv"
plan.dirs[#plan.dirs + 1] = "/rse/rs_egg_hatch"
plan.dirs[#plan.dirs + 1] = "/rse/pokedex"
plan.dirs[#plan.dirs + 1] = "/rse/pokedex_detail"
plan.dirs[#plan.dirs + 1] = "/rse/diploma"
plan.dirs[#plan.dirs + 1] = "/rse/trainer_card"
plan.dirs[#plan.dirs + 1] = "/rse/trade"
plan.dirs[#plan.dirs + 1] = "/rse/contest_data"
plan.dirs[#plan.dirs + 1] = "/rse/rs_contest_gfx"
plan.dirs[#plan.dirs + 1] = "/rse/berry_blender"
plan.dirs[#plan.dirs + 1] = "/cable_car"
plan.dirs[#plan.dirs + 1] = "/rse/battle_tower_records"
plan.dirs[#plan.dirs + 1] = "/rse/fan_club"
plan.dirs[#plan.dirs + 1] = "/rse/pokenav"
plan.dirs[#plan.dirs + 1] = "/rse/pokenav_detail"
plan.dirs[#plan.dirs + 1] = "/rse/pokenav_shell"
plan.dirs[#plan.dirs + 1] = "/rse/pokenav_condition"
plan.dirs[#plan.dirs + 1] = "/rse/pokenav_ribbons"
plan.dirs[#plan.dirs + 1] = "/pokemon/storage/wallpapers"
plan.dirs[#plan.dirs + 1] = "/rs"
plan.dirs[#plan.dirs + 1] = "/rs/assets"
add({ id = "rs_data_tables", run = "steps", weight = 0.08, steps = {
  { name = "items_extract", label = "Items" },
  { name = "battle_moves_extract", label = "Battle Moves" },
  { name = "contest_moves_extract", label = "Contest Moves" },
  { name = "ingame_trades_extract", label = "In-Game Trades" },
  { name = "berries_extract", label = "Berries" },
  { name = "pokedex_entries_extract", label = "Pokedex Entries" },
  { name = "text_placeholders_extract", label = "Edition Text" },
} })
add({ id = "rs_trainers", run = "steps", weight = 0.05, steps = {
  { name = "trainer_extract", label = "Trainers" },
} })
add({ id = "rs_text_chrome", run = "steps", weight = 0.03, steps = {
  { name = "src.import.gba.rs.text_chrome_extract", label = "Native Fonts & Text Windows" },
} })
plan.dirs[#plan.dirs + 1] = "/chrome"
plan.dirs[#plan.dirs + 1] = "/chrome/fonts"
add({ id = "rs_title", run = "steps", weight = 0.02, steps = {
  { name = "src.import.gba.rs.extract_title", label = "Ruby/Sapphire Title Screen" },
} })
plan.dirs[#plan.dirs + 1] = "/title"
add({ id = "rs_intro", run = "steps", weight = 0.05, steps = {
  { name = "src.import.gba.rs.extract_intro", label = "Ruby/Sapphire Intro & Double Battle" },
  { name = "src.import.gba.rs.extract_intro_scenery", label = "Native Intro & Credits Scenery" },
} })
plan.dirs[#plan.dirs + 1] = "/intro/rs"
plan.dirs[#plan.dirs + 1] = "/intro/rs/scenery"
add({ id = "rs_audio", run = "steps", weight = 0.10, steps = {
  { name = "extract_audio", label = "Native Music, Sound Streams & Cries" },
} })
plan.dirs[#plan.dirs + 1] = "/audio/songs"
add({ id = "rs_pokemon_data", run = "steps", weight = 0.05, steps = {
  { name = "pokemon_extract", opts = { part = "data" }, label = "Pokémon Species Data" },
  { name = "pic_coords_extract", label = "Pokémon Pic Coordinates" },
} })
for _, range in ipairs({ { "a", 0, 205 }, { "b", 206 } }) do
  add({ id = "rs_pokemon_gfx_" .. range[1], run = "steps", weight = 0.08, steps = {
    { name = "pokemon_extract", opts = { part = "gfx", spMin = range[2], spMax = range[3] }, label = "Pokémon Sprites" },
  } })
end
add({ id = "rs_pokemon_forms", run = "steps", weight = 0.04, steps = {
  { name = "pokemon_extract", opts = { part = "forms" }, label = "Pokémon Forms & Footprints" },
  { name = "egg_extract", label = "Egg & Hatching" },
} })
for _, dir in ipairs({ "/pokemon/front", "/pokemon/front_shiny", "/pokemon/back", "/pokemon/back_shiny",
    "/pokemon/icons", "/pokemon/footprints", "/pokemon/spinda", "/pokemon/egg", "/trainers/front" }) do
  plan.dirs[#plan.dirs + 1] = dir
end
plan.auxSteps = 0
return plan
