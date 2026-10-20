-- The Hall of Fame roster: what the save keeps when the champion is beaten.
--
-- Two pokegold routines, and neither of them draws anything:
--
--   engine/events/halloffame.asm HallOfFame     the induction's bookkeeping --
--     the status flag, wSpawnAfterChampion, the win counter and its cap, and
--     GetHallOfFameParty, which packs the party into the roster row
--   engine/menus/save.asm AddHallOfFameEntry    the SRAM shuffle that pushes
--     that row in at the front and drops the thirtieth
--
-- The screens (src/ui/gen2/HallOfFame.lua) read this and nothing else, which
-- is what lets the whole roster be tested headless.
--
-- THE ROW.  constants/pokemon_data_constants.asm spells the format out:
--
--   hof_mon:      species, id, dvs, level, nickname   HOF_MON_LENGTH $10
--   hall_of_fame: win count, party, terminator        HOF_LENGTH     $62
--
-- so a row is one win count, up to PARTY_LENGTH mons and a -1.  The nickname
-- really is capped at MON_NAME_LENGTH - 1 = 10 characters: GetHallOfFameParty
-- copies exactly that many bytes and DisplayHOFMon writes the '@' itself.  A
-- Lua list needs no terminator, so the -1 becomes `#entry.mons`, and the cap
-- is enforced on the way in rather than left to whoever reads it back.
--
-- WHAT IS NOT KEPT.  The row has no stats, no moves and no OT name.  That is
-- the cart's own choice and it is why the PC's viewer prints a species, a
-- nickname, a level and an ID and nothing else: a Hall of Fame entry is a
-- photograph, not a mon.  Nothing here should grow past those six fields.

local HallOfFame = {}

-- constants/pokemon_data_constants.asm
HallOfFame.NUM_TEAMS = 30        -- NUM_HOF_TEAMS
HallOfFame.PARTY_LENGTH = 6      -- PARTY_LENGTH
HallOfFame.MON_LENGTH = 0x10     -- HOF_MON_LENGTH, for the record
HallOfFame.LENGTH = 0x62         -- HOF_LENGTH, ditto
-- constants/text_constants.asm MON_NAME_LENGTH - 1
HallOfFame.NAME_LENGTH = 10
-- constants/misc_constants.asm
HallOfFame.MASTER_COUNT = 200    -- HOF_MASTER_COUNT

-- constants/ram_constants.asm.  wSpawnAfterChampion is one byte with two
-- values that matter: SPAWN_LANCE after the Elite Four, SPAWN_RED after the
-- Mt. Silver credits.  The port keeps the spawn's own name rather than the
-- enum, because that is what src/world/gen2/World.lua resolves against
-- landmarks.spawns.
HallOfFame.SPAWN_LANCE = "SPAWN_LANCE"
HallOfFame.SPAWN_RED = "SPAWN_RED"
-- engine/menus/intro_menu.asm .SpawnAfterE4 / SpawnAfterRed: where each of
-- those two actually puts the player back on CONTINUE.
HallOfFame.POST_CREDITS_SPAWN = {
  SPAWN_LANCE = "SPAWN_NEW_BARK",
  SPAWN_RED = "SPAWN_MT_SILVER",
}

--------------------------------------------------------------------------
-- The save's block
--------------------------------------------------------------------------

-- sHallOfFame plus wHallOfFameCount, as one table.  Created on demand so a
-- caller never has to check, and so src/core/gen2/Save.lua's normalize can
-- lean on the same shape a migration produces.
function HallOfFame.record(save)
  if type(save) ~= "table" then return nil end
  save.hallOfFame = save.hallOfFame or {}
  local record = save.hallOfFame
  record.count = tonumber(record.count) or 0
  if type(record.teams) ~= "table" then record.teams = {} end
  return record
end

-- STATUSFLAGS_HALL_OF_FAME_F (constants/ram_constants.asm), the bit
-- `HallOfFame::` sets before it saves.  It is not decoration: the Pokegear map
-- reads it to unlock Kanto (engine/pokegear/pokegear.asm), the radio reads it,
-- and Credits reads it to decide whether B may skip.
function HallOfFame.hasEntered(save)
  local record = HallOfFame.record(save)
  if not record then return false end
  return record.count > 0 or record.entered == true
end

function HallOfFame.count(save)
  local record = HallOfFame.record(save)
  return record and record.count or 0
end

-- `ld a, [hl] / cp HOF_MASTER_COUNT / jr nc, .ok / inc [hl]`.
--
-- `ld a, [hl]` leaves a holding the PRE-increment count, so the test is on the
-- OLD value: a save sitting at exactly 200 stops counting there.  Returns the
-- new count, which is what GetHallOfFameParty then writes into the row.
function HallOfFame.bumpCount(save)
  local record = HallOfFame.record(save)
  if not record then return 0 end
  if record.count < HallOfFame.MASTER_COUNT then
    record.count = record.count + 1
  end
  return record.count
end

--------------------------------------------------------------------------
-- GetHallOfFameParty
--------------------------------------------------------------------------

local function isEgg(mon)
  if not mon then return false end
  if mon.isEgg or mon.egg then return true end
  if mon.species == "EGG" then return true end
  local ok, Breeding = pcall(require, "src.core.gen2.Breeding")
  if ok and Breeding and Breeding.isEgg then return Breeding.isEgg(mon) end
  return false
end
HallOfFame.isEgg = isEgg

-- One hof_mon out of one party member.  The six fields are exactly the six
-- `ld [de], a` runs in GetHallOfFameParty's .mon block, in its order.
local function packMon(mon)
  return {
    species = mon.species,
    otId = tonumber(mon.otId) or 0,
    -- MON_DVS is two bytes and the port keeps them as the four nibbles; both
    -- forms are stored so the viewer can show a shiny or an Unown letter
    -- without a second table.
    dvs = mon.dvs,
    level = tonumber(mon.level) or 1,
    -- `ld bc, MON_NAME_LENGTH - 1 / call CopyBytes`: ten bytes, no terminator.
    nickname = tostring(mon.nickname or mon.name or mon.species or "")
      :sub(1, HallOfFame.NAME_LENGTH),
    shiny = mon.shiny or nil,
    gender = mon.gender or nil,
  }
end
HallOfFame.packMon = packMon

-- GetHallOfFameParty: the win count, then every party member that is not an
-- EGG, then the -1.
--
-- `cp EGG / jr nz, .mon` skips the egg WITHOUT copying it but still steps the
-- party index (`inc c`), which is why the mon behind an egg lands in the row
-- at its own party slot's data and not at the egg's.  A Lua walk gets that for
-- free; the loop is written the cart's way anyway so the skip is visible.
function HallOfFame.buildParty(save, party)
  local record = HallOfFame.record(save)
  local entry = { winCount = record and record.count or 0, mons = {} }
  for _, mon in ipairs(party or {}) do
    if #entry.mons >= HallOfFame.PARTY_LENGTH then break end
    if mon and not isEgg(mon) then
      entry.mons[#entry.mons + 1] = packMon(mon)
    end
  end
  return entry
end

--------------------------------------------------------------------------
-- AddHallOfFameEntry
--------------------------------------------------------------------------

-- The SRAM shuffle: every stored row is copied one slot UP (the copy runs
-- backwards, from the second-to-last row to the last, so nothing is clobbered
-- on the way), the thirtieth falls off the end, and the new row is written at
-- sHallOfFame.  So the roster is newest first and holds NUM_HOF_TEAMS.
function HallOfFame.addEntry(save, entry)
  local record = HallOfFame.record(save)
  if not (record and entry) then return nil end
  table.insert(record.teams, 1, entry)
  while #record.teams > HallOfFame.NUM_TEAMS do
    table.remove(record.teams)
  end
  return entry
end

-- LoadHOFTeam: `cp NUM_HOF_TEAMS / jr nc, .invalid` and then `ld a, [hl] /
-- and a / jr z, .absent` -- an index past the end of the table and a row whose
-- first byte (the win count) is zero both mean "stop", which is what ends the
-- PC's master loop at the oldest entry the player actually has.
function HallOfFame.team(save, index)
  local record = HallOfFame.record(save)
  if not record then return nil end
  index = tonumber(index) or 0
  if index < 1 or index > HallOfFame.NUM_TEAMS then return nil end
  local entry = record.teams[index]
  if not entry or (tonumber(entry.winCount) or 0) == 0 then return nil end
  return entry
end

function HallOfFame.teamCount(save)
  local record = HallOfFame.record(save)
  if not record then return 0 end
  local count = 0
  for index = 1, HallOfFame.NUM_TEAMS do
    if not HallOfFame.team(save, index) then break end
    count = count + 1
  end
  return count
end

--------------------------------------------------------------------------
-- The induction
--------------------------------------------------------------------------

-- Everything `HallOfFame::` does to the save, in its order and without the
-- screens:
--
--   set STATUSFLAGS_HALL_OF_FAME_F
--   wSpawnAfterChampion = SPAWN_LANCE
--   bump wHallOfFameCount, capped
--   SaveGameData
--   GetHallOfFameParty
--   AddHallOfFameEntry
--
-- The save really does happen BEFORE the roster row is written: the cart's
-- AddHallOfFameEntry pokes SRAM directly, so it needs no second save.  This
-- port has no SRAM, so `saveFn` is called after the row lands instead -- the
-- one deliberate reordering here, and it exists so a crash between the two
-- cannot leave a save whose count says "inducted" and whose roster is empty.
--
-- Returns the row, and SECOND the value STATUSFLAGS_HALL_OF_FAME_F held BEFORE
-- the induction.  That second value is not bookkeeping: `HallOfFame::` pushes
-- wStatusFlags before it sets the bit and hands the pushed copy to Credits,
-- which is the whole reason a first-time champion cannot fast-forward the
-- credits and a repeat one can.
function HallOfFame.induct(save, party, opts)
  opts = opts or {}
  local record = HallOfFame.record(save)
  if not record then return nil end
  local wasEntered = HallOfFame.hasEntered(save)
  record.entered = true
  save.spawnAfterChampion = opts.spawn or HallOfFame.SPAWN_LANCE
  HallOfFame.bumpCount(save)
  local entry = HallOfFame.buildParty(save, party or save.party)
  HallOfFame.addEntry(save, entry)
  if opts.saveFn then opts.saveFn(save) end
  return entry, wasEntered
end

-- RedCredits' half of the same thing: no roster row and no counter, just the
-- spawn that sends CONTINUE to Mt. Silver.  Kept here because the byte is the
-- same byte and nothing else in the port writes it.
function HallOfFame.markRedCredits(save)
  if type(save) ~= "table" then return end
  save.spawnAfterChampion = HallOfFame.SPAWN_RED
end

--------------------------------------------------------------------------
-- The post-game continue
--------------------------------------------------------------------------

-- engine/menus/intro_menu.asm: CONTINUE reads wSpawnAfterChampion, and a
-- non-zero one replaces the saved position with a spawn point and a WARP map
-- entry rather than a CONTINUE one.  PostCreditsSpawn then clears the byte, so
-- this only ever fires on the first load after the credits.
--
-- Returns the SPAWN_* id to start at, or nil for an ordinary continue.
function HallOfFame.consumePostGameSpawn(save)
  if type(save) ~= "table" then return nil end
  local pending = save.spawnAfterChampion
  if not pending then return nil end
  save.spawnAfterChampion = nil
  return HallOfFame.POST_CREDITS_SPAWN[pending]
end

return HallOfFame
