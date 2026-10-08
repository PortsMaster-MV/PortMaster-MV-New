return function(V)
  local S, sym = V.SYMS, V.sym
  local function raw(n) return {off = sym(n), size = S.size(n)} end
  -- pokeruby/src/battle_transition.c:178
  V.BATTLE_TRANSITION = {layout = "rse", gameLayout = "rs",
    big_pokeball_gfx = raw("sBigPokeball_Tileset"), big_pokeball_tilemap = raw("sBigPokeball_Tilemap"),
    sliding_pokeball_bin = raw("sPokeballTrail_Tileset"), sliding_pokeball_gfx = raw("sSpriteImage_83FC148"),
    sliding_pokeball_pal = raw("battle_transition.o:gFieldEffectObjectPalette10"),
    mugshot_banner_gfx = raw("sUnknown_083FC348"), grid_square_gfx = raw("sShrinkingBoxTileset"),
    vsbar_tilemap = raw("sMugshotsTilemap"), mugshot_keys = {"sidney", "phoebe", "glacia", "drake", "champion"},
    mugshot_pals = {sidney = sym("sMugshotPal_Sydney"), phoebe = sym("sMugshotPal_Phoebe"),
      glacia = sym("sMugshotPal_Glacia"), drake = sym("sMugshotPal_Drake"), champion = sym("sMugshotPal_Steven"),
      male = sym("sMugshotPal_Brendan"), female = sym("sMugshotPal_May")},
    mugshot_pic_ids = sym("sMugshotsTrainerPicIDsTable"), mugshot_rotation_scales = sym("sMugshotsOpponentRotationScales"),
    mugshot_coords = sym("sMugshotsOpponentCoords"), mugshot_count = S.count("sMugshotsTrainerPicIDsTable", 1),
    assets = {}}
end
