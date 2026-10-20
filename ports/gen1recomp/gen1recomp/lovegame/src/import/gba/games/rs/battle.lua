return function(V)
  local sym, S = V.sym, V.SYMS
  local function env(kind, palette)
    return { tiles = sym("gBattleEnvironmentTiles_" .. kind), tilemap = sym("gBattleEnvironmentTilemap_" .. kind),
      pal = sym("gBattleEnvironmentPalette_" .. (palette or kind)) }
  end
  -- pokeruby/src/battle_bg.c:139
  local B = { layout = "rse", gameLayout = "rs",
    textbox_gfx = sym("gBattleTextboxTiles"), textbox_pal = sym("gBattleTextboxPalette"), textbox_tilemap = sym("gBattleTextboxTilemap"),
    textbox_tilemap_raw_size = S.size("gBattleTextboxTilemap"),
    healthbox_elements = sym("gHealthboxElementsGfxTable"), healthbox_elements_size = S.size("gHealthboxElementsGfxTable"),
    healthbox_player = sym("gBattleWindowLargeGfx"), healthbox_enemy = sym("gBattleWindowSmallGfx"),
    healthbox_doubles_player = sym("gBattleWindowSmall2Gfx"), healthbox_doubles_opponent = sym("gBattleWindowSmall3Gfx"),
    healthbox_safari = sym("gBattleWindowLarge2Gfx"),
    healthbox_pal = sym("gUnknown_08D1212C"), healthbar_pal = sym("gUnknown_08D1214C"),
    party_summary_bar = sym("gBattleGfx_BallStatusBar"), window_text_pal_raw = sym("gFontDefaultPalette"),
    pp_text_pal = sym("gFontDefaultPalette"),
    rs_font4_glyphs = sym("gFont4LatinGlyphs"), rs_font_type1_map = V.RS_FONT_TYPE1_MAP.off,
    terrain_table = sym("sBattleEnvironmentTable"), terrain_count = S.count("sBattleEnvironmentTable", 20),
    terrain_grass = env("TallGrass"), terrain_building = env("Building"), scenes = {},
    window_templates = {}, window_template_counts = {},
  }
  -- pokeruby/src/data/graphics.c:300
  local span = 0
  for _, row in ipairs({ {"gHealthboxElementsGfxTable", 0x840}, {"Tiles_D129AC", 0x80},
    {"unused_gfx_ball_display_unused_extra", 0x20}, {"unused_gfx_status2", 0x1E0},
    {"unused_gfx_status3", 0x1E0}, {"unused_gfx_status4", 0x1E0},
    {"unused_gfx_unknown_D12FEC", 0x20}, {"unused_gfx_unknown_D1300C", 0x20} }) do
    assert(S.size(row[1]) == row[2] and sym(row[1]) == B.healthbox_elements + span,
      "native RS healthbox element span changed: " .. row[1])
    span = span + row[2]
  end
  B.healthbox_elements_span_size = span
  for _, row in ipairs({ {"tower", "Building", "BattleTower"}, {"groudon", "Cave", "Groudon"},
    {"kyogre", "Water", "Kyogre"}, {"leader", "Building", "BuildingLeader"}, {"champion", "Stadium", "StadiumSteven"},
    {"gym", "Building", "BuildingGym"}, {"magma", "Stadium", "StadiumMagma"}, {"aqua", "Stadium", "StadiumAqua"},
    {"sidney", "Stadium", "StadiumSidney"}, {"phoebe", "Stadium", "StadiumPhoebe"},
    {"glacia", "Stadium", "StadiumGlacia"}, {"drake", "Stadium", "StadiumDrake"} }) do
    B.scenes[#B.scenes + 1] = {key = row[1], cfg = env(row[2], row[3])}
  end
  V.BATTLE_UI = B
  -- pokeruby/src/battle_anim_special.c:85
  V.BALL_OPEN = { particle_sheets = sym("gBallOpenParticleSpritesheets"), particle_palettes = sym("gBallOpenParticlePalettes"),
    fade_colors = sym("gUnknown_0840B4D4"), sine_table = sym("gSineTable"),
    sprite_sheets = sym("pokeball.o:sBallSpriteSheets"), sprite_palettes = sym("pokeball.o:sBallSpritePalettes"),
    open_ball_gfx = sym("gUnknown_08D030D0") }
  V.BATTLE_AI_SCRIPTS_TABLE = sym("BattleAIs")
  V.BATTLE_AI_SCRIPT_COUNT = S.count("BattleAIs", 4)
end
