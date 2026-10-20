local Names = require("src.import.gba.rs.anim_names")
return function(V)
  local S, sym = V.SYMS, V.sym
  local pals = {}; for i = 1, 8 do pals[i] = sym("gBattleStatMask" .. i .. "_Pal") end
  V.BATTLE_ANIMS = {moves_table = sym("gBattleAnims_Moves"), move_count = S.count("gBattleAnims_Moves", 4),
    status_table = sym("gBattleAnims_StatusConditions"), status_count = S.count("gBattleAnims_StatusConditions", 4),
    general_table = sym("gBattleAnims_General"), general_count = S.count("gBattleAnims_General", 4),
    special_table = sym("gBattleAnims_Special"), special_count = S.count("gBattleAnims_Special", 4),
    pic_table = sym("gBattleAnimPicTable"), pal_table = sym("gBattleAnimPaletteTable"), tag_count = S.count("gBattleAnimPicTable", 8),
    sprites_start = 10000, bg_table = sym("gBattleAnimBackgroundTable"), bg_count = S.count("gBattleAnimBackgroundTable", 12),
    substitute_pal = sym("gSubstituteDollPal"), substitute_front = sym("gSubstituteDollGfx"),
    substitute_back = sym("gSubstituteDollTilemap"),
    stat_mask_gfx = sym("gBattleStatMask_Gfx"), stat_mask_tilemap1 = sym("gBattleStatMask1_Tilemap"),
    stat_mask_tilemap2 = sym("gBattleStatMask2_Tilemap"), stat_mask_pal = pals[1], stat_mask_pals = pals,
    smokescreen_gfx = sym("gSmokescreenImpactTiles"), smokescreen_pal = sym("gSmokescreenImpactPalette"),
    muddy_water_pal = sym("gBattleAnimBackgroundImageMuddyWater_Pal"),
    named_bgs = {
      ATTRACT = {gfx = sym("gAttractGfx"), pal = sym("gAttractPal"), map = sym("gAttractTilemap")},
      SCARY_FACE_PLAYER = {gfx = sym("gBattleAnimBackgroundImage_ScaryFace"), pal = sym("gBattleAnimBackgroundPalette_ScaryFace"), map = sym("gBattleAnimBackgroundTilemap_ScaryFacePlayer")},
      SCARY_FACE_OPPONENT = {gfx = sym("gBattleAnimBackgroundImage_ScaryFace"), pal = sym("gBattleAnimBackgroundPalette_ScaryFace"), map = sym("gBattleAnimBackgroundTilemap_ScaryFaceOpponent")},
      METAL_SHINE = {gfx = sym("gUnknown_08D1D410"), pal = sym("gUnknown_08D1D54C"), map = sym("gUnknown_08D1D574")},
      CURE_BUBBLES = {gfx = sym("gUnknown_08D2E014"), pal = sym("gUnknown_08D2E150"), map = sym("gUnknown_08D2E170")},
      CURSE = {gfx = sym("gUnknown_08D20A14"), map = sym("gUnknown_08D20A30"), pal_white1 = true},
      FOG = {gfx_raw = sym("gWeatherFog1Tiles"), gfx_size = S.size("gWeatherFog1Tiles"), pal_raw = sym("gUnknown_083970E8"), map = sym("gBattleAnimFogTilemap")},
      SANDSTORM = {gfx = sym("gBattleAnimBackgroundImage_SandstormBrew"), pal_tag = "FLYING_DIRT", map = sym("gBattleAnimBackgroundTilemap_SandstormBrew")},
      SURF_PLAYER = {gfx = sym("gBattleAnimBackgroundImage_Surf"), pal = sym("gBattleAnimBackgroundPalette_Surf"), map = sym("gUnknown_08E70C38")},
      SURF_OPPONENT = {gfx = sym("gBattleAnimBackgroundImage_Surf"), pal = sym("gBattleAnimBackgroundPalette_Surf"), map = sym("gUnknown_08E70968")},
    }}
  V.ANIM_NAMES, V.ANIM_TAG_NAMES = Names, Names.tagNames
  local function byPrefix(prefix)
    local out = {}
    for n, id in pairs(require("src.core.game3.constants").of(V.GAME).battle.byName) do
      if n:sub(1, #prefix) == prefix then out[id] = n:sub(8) end
    end
    return out
  end
  V.BATTLE_ANIM_STATUS_NAMES = byPrefix("B_ANIM_STATUS_")
  V.BATTLE_ANIM_GENERAL_NAMES = {[0] = "CASTFORM_CHANGE", "STATS_CHANGE", "SUBSTITUTE_FADE", "SUBSTITUTE_APPEAR", "POKEBLOCK_THROW", "ITEM_KNOCKOFF", "TURN_TRAP", "ITEM_EFFECT", "SMOKEBALL_ESCAPE", "HANGED_ON", "RAIN_CONTINUES", "SUN_CONTINUES", "SANDSTORM_CONTINUES", "HAIL_CONTINUES", "LEECH_SEED_DRAIN", "MON_HIT", "ITEM_STEAL", "SNATCH_MOVE", "FUTURE_SIGHT_HIT", "DOOM_DESIRE_HIT", "FOCUS_PUNCH_SETUP", "INGRAIN_HEAL", "WISH_HEAL"}
  V.BATTLE_ANIM_SPECIAL_NAMES = {[0] = "LVL_UP", "SWITCH_OUT_PLAYER_MON", "SWITCH_OUT_OPPONENT_MON", "BALL_THROW", "BALL_THROW_WITH_TRAINER", "SUBSTITUTE_TO_MON", "MON_TO_SUBSTITUTE"}
  local templates, callbacks, tasks = {}, {}, {}
  local function functionOffset(name)
    if S.hasFunc(name) then return S.funcOff(name) end
    if S.hasFunc(":" .. name) then return S.funcOff(":" .. name) end
    error("RS animation function needs an explicit native object qualifier: " .. name)
  end
  for n, canonical in pairs(Names.templates) do templates[0x08000000 + S.off(n)] = canonical end
  for n, canonical in pairs(Names.callbacks) do callbacks[0x08000000 + functionOffset(n) + 1] = canonical end
  for n, canonical in pairs(Names.tasks) do tasks[0x08000000 + functionOffset(n) + 1] = canonical end
  V.ANIM_TEMPLATE_NAMES, V.ANIM_CALLBACK_NAMES, V.ANIM_TASK_NAMES = templates, callbacks, tasks
end
