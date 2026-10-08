-- Gen 2 GBC palette resolution: which four colors each tile, sprite and pic
-- draws with right now.  Pure table math over data/generated/palettes.lua --
-- no love calls -- so tests and tools can ask the same questions the renderer
-- does.  src/render/GbcPalette.lua turns the answers into draw calls.
--
-- Ported from engine/gfx/color.asm LoadMapPals and
-- engine/tilesets/timeofday_pals.asm ReplaceTimeOfDayPals:
--
--   real clock hour  -> wTimeOfDay        (GetTimeOfDay, engine/rtc/rtc.asm)
--   + map header     -> wMapTimeOfDay     (PALETTE_* override)
--   = wTimeOfDayPal  -> the daytime whose colors actually load
--
-- and then, for that daytime:
--
--   EnvironmentColorsPointers[environment][daytime] -> 8 TilesetBGPalette ids
--   RoofPals[mapGroup]                              -> PAL_BG_ROOF colors 1-2
--   MapObjectPals[daytime]                          -> the 8 OBJ palettes
--
-- A tile's slot within that 8-palette set comes from its tileset's PalMap
-- (tilesets.lua `tilePalettes`, 1-based); a sprite's comes from
-- sprites.lua `paletteId` (PAL_OW_*).

local Palettes = {}

-- wTimeOfDay order (the GetTimePalette jumptable): MORN_F, DAY_F, NITE_F,
-- DARKNESS_F.  bg_tiles.pal, npc_sprites.pal and every environment_colors row
-- are laid out in this same order, which is why one index works for all three.
Palettes.DAYTIMES = { "MORN", "DAY", "NITE", "DARK" }
Palettes.DAYTIME_ID = { MORN = 1, DAY = 2, NITE = 3, DARK = 4 }

-- engine/rtc/rtc.asm TimesOfDay: 0400-0959 morn, 1000-1759 day, 1800-0359
-- nite.  The table is a run of "hour < N -> this daytime" rows, so the last
-- row wrapping back to NITE is what makes midnight-to-4am night.
local MORN_HOUR, DAY_HOUR, NITE_HOUR = 4, 10, 18

-- PAL_OW_* (constants/sprite_data_constants.asm), 1-based for Lua indexing.
Palettes.OW_PALETTE_ID = {
  PAL_OW_RED = 1, PAL_OW_BLUE = 2, PAL_OW_GREEN = 3, PAL_OW_BROWN = 4,
  PAL_OW_PINK = 5, PAL_OW_EMOTE = 6, PAL_OW_TREE = 7, PAL_OW_ROCK = 8,
}

Palettes.BLACKOUT = {
  { 255, 255, 255 }, { 58, 58, 58 }, { 16, 25, 25 }, { 0, 0, 0 },
}

-- Roofs are only recolored outdoors; LoadMapPals returns early for anything
-- that is not TOWN or ROUTE, so an indoor map keeps the pool's roof palette.
local ROOF_ENVIRONMENTS = { TOWN = true, ROUTE = true }

-- ReplaceTimeOfDayPals.BrightnessLevels, read out as a plain lookup:
-- the map's PALETTE_* either follows the clock (AUTO) or pins one daytime.
local FORCED_DAYTIME = {
  PALETTE_AUTO = nil,
  PALETTE_DAY = "DAY",
  PALETTE_NITE = "NITE",
  PALETTE_MORN = "MORN",
  PALETTE_DARK = "DARK",
}

-- White and black bracket the two colors a mon/trainer pic actually ships
-- (data/pokemon/palettes.asm: "only the middle two colors are included").
local WHITE = { 255, 255, 255 }
local BLACK = { 0, 0, 0 }

-- The daytime the game clock is in, ignoring any map override.
--
-- `hour` is hHours, the value UpdateTime leaves after FixTime has added the
-- save's wStartHour base -- World:hour, or the World.clockHour pin a driver
-- sets.  Every caller that can reach a world or a save must pass it: the
-- no-argument fallback is the raw host clock, which is the cart's RTC WITHOUT
-- the base, so a save whose owner answered Oak reads a different hour there
-- than the rest of the game does.
function Palettes.clockDaytime(hour)
  if not hour then
    hour = tonumber(os.date("%H")) or 12
  end
  hour = math.floor(hour) % 24
  if hour < MORN_HOUR then return "NITE" end
  if hour < DAY_HOUR then return "MORN" end
  if hour < NITE_HOUR then return "DAY" end
  return "NITE"
end

-- The daytime whose colors load on this map: the clock, unless the map header
-- pins one.  PALETTE_DARK maps are pitch black until FLASH is used, at which
-- point they read as night (ReplaceTimeOfDayPals.UsedFlash).
function Palettes.daytimeFor(mapDef, hour, flashUsed)
  local clock = Palettes.clockDaytime(hour)
  local forced = mapDef and FORCED_DAYTIME[mapDef.palette]
  if forced == "DARK" then
    return flashUsed and "NITE" or "DARK"
  end
  return forced or clock
end

-- True when this map is lit by DARKNESS_PALSET right now, i.e. it is a
-- PALETTE_DARK map and FLASH has not been used.  That is the exact condition
-- FlashFunction.CheckUseFlash tests (`ld a, [wTimeOfDayPalset] / cp
-- DARKNESS_PALSET`), so FLASH is allowed here and refused everywhere else --
-- including inside a cave that is merely PALETTE_NITE, like Union Cave.
function Palettes.isDarkness(mapDef, hour, flashUsed)
  return Palettes.daytimeFor(mapDef, hour, flashUsed) == "DARK"
end

-- There is no vision mask in Gen 2.  A dark map is dark because the `dark`
-- rows of gfx/tilesets/bg_tiles.pal are colors 1-3 black on a color 0 of
-- RGB 01,01,02, and every environment's dark row ($18-$1f) points at them --
-- so the whole screen resolves to near-black through the ordinary bake, with
-- no second pass and nothing masked out.  The one exception is what actually
-- makes a dark cave navigable:
--
-- FlickeringCaveEntrancePalette (engine/tilesets/tileset_anims.asm) runs every
-- VBlank while wTimeOfDayPalset is DARKNESS_PALSET and rewrites PAL_BG_YELLOW
-- color 0 from either its own color 0 or its color 1, picked by bit 1 of
-- hVBlankCounter.  In the dark row those two are RGB 30,30,11 and black, so
-- the cave entrance blinks yellow-black-yellow on a four-frame cycle while
-- everything else stays flat.  That blink is the "where is the way out"
-- signal, and it is the only light in the map.
Palettes.PAL_BG_YELLOW = 5 -- 1-based slot, PAL_BG_YELLOW is $04
-- `and %10`: two frames on, two frames off.
Palettes.FLICKER_PERIOD = 4

-- Which of PAL_BG_YELLOW's own colors is copied into its color 0 this frame.
-- 1 is "leave color 0 alone", 2 is "use color 1", both 1-based.
function Palettes.caveFlickerSource(frame)
  return (math.floor((frame or 0) / 2) % 2 == 1) and 2 or 1
end

-- A copy of `set` with that copy already made.  `sourceIndex` is 1 or 2, the
-- value caveFlickerSource returns.  Only the yellow slot is rebuilt, so the
-- other seven palettes stay shared with the caller's set.
function Palettes.withCaveFlicker(set, sourceIndex)
  if not set then return set end
  local slot = set[Palettes.PAL_BG_YELLOW]
  if not slot then return set end
  local source = slot[sourceIndex == 2 and 2 or 1]
  if not source then return set end
  local out = {}
  for i = 1, 8 do out[i] = set[i] end
  local yellow = {}
  for i = 1, 4 do
    local c = slot[i]
    yellow[i] = c and { c[1], c[2], c[3] } or nil
  end
  yellow[1] = { source[1], source[2], source[3] }
  out[Palettes.PAL_BG_YELLOW] = yellow
  return out
end

-- LoadSpecialMapPalette (engine/tilesets/tileset_palettes.asm:1)
function Palettes.specialSet(data, mapDef)
  local sets = data and data.specialTilesets
  local tileset = mapDef and mapDef.tileset
  local set = sets and tileset and sets[tileset]
  if not set then return nil end
  if tileset == "TILESET_ICE_PATH" and mapDef.environment == "INDOOR" then
    return nil
  end
  local out = {}
  for slot = 1, 8 do
    local source = set[slot]
    local colors = {}
    for i = 1, 4 do
      local c = source and source[i] or BLACK
      colors[i] = { c[1], c[2], c[3] }
    end
    out[slot] = colors
  end
  return out
end

-- The eight BG palettes loaded for this map, each { {r,g,b} x4 }, with the
-- roof override already folded in.  Index with a tileset's tilePalettes value.
function Palettes.bgSet(data, mapDef, daytime)
  if not (data and data.bg and data.environments) then return nil end
  local env = mapDef and mapDef.environment
  -- LoadSpecialMapPalette wins over the pool -- engine/gfx/color.asm:1198
  local set = Palettes.specialSet(data, mapDef)
  if not set then
    local row = env and data.environments[env]
    row = row or data.environments.TOWN
    if not row then return nil end
    local indices = row[daytime] or row.DAY
    if not indices then return nil end

    set = {}
    for slot = 1, 8 do
      local pool = data.bg[indices[slot]]
      local colors = {}
      for i = 1, 4 do
        local c = pool and pool[i] or BLACK
        colors[i] = { c[1], c[2], c[3] }
      end
      set[slot] = colors
    end
  end

  local roofSlot = data.roofSlot or 7
  if mapDef and ROOF_ENVIRONMENTS[env] and data.roofs then
    local roof = data.roofs[mapDef.group]
    if roof then
      -- Colors 1 and 2 only; the pool keeps the roof palette's 0 and 3.
      local pair = (daytime == "MORN" or daytime == "DAY")
        and roof.mornDay or roof.nite
      if pair and pair[1] and pair[2] then
        set[roofSlot][2] = { pair[1][1], pair[1][2], pair[1][3] }
        set[roofSlot][3] = { pair[2][1], pair[2][2], pair[2][3] }
      end
    end
  end
  return set
end

-- The eight OBJ palettes for OW sprites at this time of day.
function Palettes.objectSet(data, daytime)
  if not (data and data.objects) then return nil end
  return data.objects[daytime] or data.objects.DAY
end

-- The object_event palette byte's own OBJ palette slot, or nil for "use the
-- sprite's default".  AddMapObject's tail (engine/overworld/player_object.asm
-- :187-194) is `ld hl, MAPOBJECT_PALETTE / add hl, bc / ld a, [hl] / and
-- MAPOBJECT_PALETTE_MASK / jr z, .skip_color_override / swap a / and
-- OAM_PALETTE`: a NON-ZERO field wins over whatever GetSpritePalette answered,
-- and only its low three bits reach OAM.
--
-- The PAL_NPC_* block is `const_def 1 << 3` over the same eight names as
-- PAL_OW_* (constants/sprite_data_constants.asm:15-38) -- bit 3 is nothing but
-- the "not the default" marker, which is why `and OAM_PALETTE` drops it and
-- PAL_NPC_BLUE lands on the same colors as PAL_OW_BLUE.  The extractor stores
-- the field already unswapped, as the plain constant.
function Palettes.objectPaletteId(objDef)
  local p = objDef and objDef.palette
  if not p or p == 0 then return nil end
  return p % 8
end

-- A sprite definition's OBJ palette (sprites.lua stores both the PAL_OW_*
-- name and the raw id; either resolves), unless the object_event standing on
-- the map overrode it -- see Palettes.objectPaletteId.  The override is what
-- makes the three legendary beasts three different animals: BurnedTowerB1F's
-- Raikou, Entei and Suicune are all SPRITE_GROWLITHE, whose own palette is
-- PAL_OW_RED, and only PAL_NPC_BROWN / PAL_NPC_RED / PAL_NPC_BLUE on the three
-- object_events tell them apart (maps/BurnedTowerB1F.asm:152-154).
function Palettes.spritePalette(data, daytime, spriteDef, objDef)
  local set = Palettes.objectSet(data, daytime)
  if not set then return nil end
  local id = Palettes.objectPaletteId(objDef)
  if not id then
    id = spriteDef and spriteDef.paletteId
    if not id then
      local name = spriteDef and spriteDef.palette
      id = name and (Palettes.OW_PALETTE_ID[name] or
        Palettes.OW_PALETTE_ID["PAL_OW_" .. tostring(name)])
      id = id and id - 1 or 0
    end
  end
  return set[(id or 0) + 1] or set[1]
end

-- A battle pic's four colors: white, the two shipped middle colors, black.
function Palettes.monColors(data, speciesId, shiny)
  local entry = data and data.pokemon and data.pokemon[speciesId]
  if not entry then return nil end
  local pair = (shiny and entry.shiny) or entry.normal
  if not (pair and pair[1] and pair[2]) then return nil end
  return {
    { WHITE[1], WHITE[2], WHITE[3] },
    { pair[1][1], pair[1][2], pair[1][3] },
    { pair[2][1], pair[2][2], pair[2][3] },
    { BLACK[1], BLACK[2], BLACK[3] },
  }
end

-- Trainer pics work the same way; row 0 is PLAYER (Chris shares Cal's colors).
function Palettes.trainerColors(data, className)
  local pair = data and data.trainers and data.trainers[className or "PLAYER"]
  if not (pair and pair[1] and pair[2]) then return nil end
  return {
    { WHITE[1], WHITE[2], WHITE[3] },
    { pair[1][1], pair[1][2], pair[1][3] },
    { pair[2][1], pair[2][2], pair[2][3] },
    { BLACK[1], BLACK[2], BLACK[3] },
  }
end

-- PAL_BG_TEXT is white/white/white/black in every set, which is what makes
-- text boxes readable at night; menus and the naming screen draw with it.
function Palettes.textColors(data)
  if not (data and data.bg) then return nil end
  local pool = data.bg[8] -- $07, the morn "text" row
  if not pool then return nil end
  return {
    { pool[1][1], pool[1][2], pool[1][3] },
    { pool[2][1], pool[2][2], pool[2][3] },
    { pool[3][1], pool[3][2], pool[3][3] },
    { pool[4][1], pool[4][2], pool[4][3] },
  }
end

return Palettes
