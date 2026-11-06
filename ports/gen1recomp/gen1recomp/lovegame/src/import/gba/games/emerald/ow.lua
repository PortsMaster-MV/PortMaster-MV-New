return function(V)
  local sym, count = V.sym, V.count
  local P = "field_player_avatar.o:"

  -- pokeemerald/src/field_player_avatar.c:234
  V.PLAYER_AVATAR_GFX = {
    genders = 2,
    -- pokeemerald/include/global.fieldmap.h:278
    stateNames = {
      "NORMAL", "MACH_BIKE", "ACRO_BIKE", "SURFING", "UNDERWATER", "FIELD_MOVE", "FISHING", "WATERING",
    },
    player = sym(P .. "sPlayerAvatarGfxIds"),
    player_states = count(P .. "sPlayerAvatarGfxIds", 2),
    rival = sym(P .. "sRivalAvatarGfxIds"),
    rival_states = count(P .. "sRivalAvatarGfxIds", 2),
    -- pokeemerald/src/field_player_avatar.c:258
    link_frlg = sym(P .. "sFRLGAvatarGfxIds"),
    link_rs = sym(P .. "sRSAvatarGfxIds"),
    -- pokeemerald/src/field_player_avatar.c:274
    state_flags = sym(P .. "sPlayerAvatarGfxToStateFlag"),
    state_flag_count = count(P .. "sPlayerAvatarGfxToStateFlag", 4),
  }
end
