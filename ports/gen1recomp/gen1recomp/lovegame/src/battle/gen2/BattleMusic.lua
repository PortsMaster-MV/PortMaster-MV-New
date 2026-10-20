-- Which song a battle plays, and which one its win plays.
--
-- engine/battle/start_battle.asm PlayBattleMusic and engine/battle/core.asm
-- PlayVictoryMusic, as pure lookups: the caller hands over the trainer class,
-- the region and the time of day, and gets a song label back.  Keeping it out
-- of World.lua is what lets a test assert the whole ladder -- Falkner's theme,
-- the Kanto split, the RIVAL2 cut-off -- without a window or an audio device.
--
-- Both routines start with `ld de, MUSIC_NONE / call PlayMusic`, i.e. the map
-- theme is stopped first; the port's Music.play replaces whatever is current,
-- so that step needs nothing here.

local BattleMusic = {}

-- data/trainers/leaders.asm.  The two lists are contiguous in the ROM and
-- IsGymLeader reads BOTH (GymLeaders falls through into KantoGymLeaders),
-- while IsKantoGymLeader starts at the second -- so a Kanto leader is in each
-- list and a Johto one only in the first.
BattleMusic.KANTO_GYM_LEADERS = {
  BROCK = true, MISTY = true, LT_SURGE = true, ERIKA = true,
  JANINE = true, SABRINA = true, BLAINE = true, BLUE = true,
}
BattleMusic.JOHTO_GYM_LEADERS = {
  FALKNER = true, WHITNEY = true, BUGSY = true, MORTY = true,
  PRYCE = true, JASMINE = true, CHUCK = true, CLAIR = true,
  WILL = true, BRUNO = true, KAREN = true, KOGA = true,
  -- The list carries these two as well; PlayBattleMusic never reaches them
  -- because it tests for them first, but PlayVictoryMusic's IsGymLeader call
  -- does, which is why the Champion's defeat plays the gym jingle.
  CHAMPION = true, RED = true,
}

-- IsGymLeader searches GymLeaders, which runs on into KantoGymLeaders.
function BattleMusic.isGymLeader(class)
  if not class then return false end
  return BattleMusic.JOHTO_GYM_LEADERS[class] == true
    or BattleMusic.KANTO_GYM_LEADERS[class] == true
end

function BattleMusic.isKantoGymLeader(class)
  return class ~= nil and BattleMusic.KANTO_GYM_LEADERS[class] == true
end

-- RegionCheck (engine/overworld/landmarks.asm) compares the map's landmark
-- against KANTO_LANDMARK; the Victory Road block above it counts as Johto
-- again, and so does the S.S. Aqua.
-- Indices into constants.lua's `landmarkOrder`.
BattleMusic.KANTO_LANDMARK = 46
BattleMusic.LANDMARK_VICTORY_ROAD = 87
BattleMusic.LANDMARK_FAST_SHIP = 94

function BattleMusic.isKanto(landmark)
  local index = landmark or 0
  if index == BattleMusic.LANDMARK_FAST_SHIP then return false end
  if index < BattleMusic.KANTO_LANDMARK then return false end
  return index < BattleMusic.LANDMARK_VICTORY_ROAD
end

-- The rival's theme becomes the Champion's from RIVAL2_2 onward (the Indigo
-- Plateau rematch): `cp RIVAL2_2_CHIKORITA / jr c, .done`, a comparison
-- against the MEMBER id inside the class.
BattleMusic.RIVAL2_CHAMPION_MEMBER = "RIVAL2_2_CHIKORITA"

-- ../pokecrystal/constants/battle_constants.asm:96
BattleMusic.BATTLETYPE_ROAMING = 5
BattleMusic.BATTLETYPE_SUICUNE = 12

function BattleMusic.battleSong(opts)
  opts = opts or {}
  local class = opts.class
  local kanto = BattleMusic.isKanto(opts.landmark)

  if opts.battleTheme then return opts.battleTheme end

  -- ../pokecrystal/engine/battle/start_battle.asm:60-66
  if opts.crystal and (opts.battleType == BattleMusic.BATTLETYPE_SUICUNE
      or opts.battleType == BattleMusic.BATTLETYPE_ROAMING) then
    return "Music_SuicuneBattle"
  end

  if not class then
    if kanto then return "Music_KantoWildBattle" end
    -- Only NITE has its own wild theme; DARK (an unlit cave) is a palette
    -- state, not a time of day, and keeps the day theme.
    if opts.daytime == "NITE" then return "Music_JohtoWildBattleNight" end
    return "Music_JohtoWildBattle"
  end

  if class == "CHAMPION" or class == "RED" then
    return "Music_ChampionBattle"
  end
  -- The cart's own bug, kept: only the two GRUNT classes get the Rocket
  -- theme, so an EXECUTIVE or SCIENTIST fights to the ordinary trainer song
  -- (docs/bugs_and_glitches.md).
  if class == "GRUNTM" or class == "GRUNTF" then
    return "Music_RocketBattle"
  end
  if BattleMusic.isKantoGymLeader(class) then
    return "Music_KantoGymBattle"
  end
  if BattleMusic.isGymLeader(class) then
    return "Music_JohtoGymBattle"
  end
  if class == "RIVAL1" then return "Music_RivalBattle" end
  if class == "RIVAL2" then
    local cutoff, index
    for i, id in ipairs(opts.members or {}) do
      if id == BattleMusic.RIVAL2_CHAMPION_MEMBER then cutoff = i end
      if id == opts.member then index = i end
    end
    if cutoff and index and index >= cutoff then
      return "Music_ChampionBattle"
    end
    return "Music_RivalBattle"
  end
  if kanto then return "Music_KantoTrainerBattle" end
  return "Music_JohtoTrainerBattle"
end

-- PlayVictoryMusic.  A wild win is SILENT unless the player still has a
-- participant standing (or an Exp. Share, or Pay Day money) -- `wBattle
-- ParticipantsNotFainted` zero falls through to `.lost` with no PlayMusic at
-- all, which is why a battle won by a mon that fainted to recoil ends on the
-- map theme.  Returns nil for that case.
function BattleMusic.victorySong(opts)
  opts = opts or {}
  if not opts.class then
    if opts.participantsFainted then return nil end
    return "Music_WildPokemonVictory"
  end
  if BattleMusic.isGymLeader(opts.class) then
    return "Music_GymLeaderVictory"
  end
  return "Music_TrainerVictory"
end

return BattleMusic
