-- Gen 3 (FireRed) event, flag, and variable categorization for the save editor.
-- Slices the raw save.flags bitfield and save.vars space into clean categories:
-- Story flags, Trainers (0x500 + trainerId), Items taken, Object toggles,
-- System flags, and Script variables.

local FlagsTable = require("src.core.game3.scripting.flags_table")
local GameVersion = require("src.core.GameVersion")

local Gen3Flags = {}

local TRAINERS_CACHE = nil
local RSE_CACHE = {}

local function isRs(game) return game == "ruby" or game == "sapphire" end
-- pokeruby/include/constants/flags.h:773
local RS_TRAINER_START, RS_TRAINER_COUNT = 0x500, 694

local function rseGame()
  local v = GameVersion.get()
  if GameVersion.layout(v) == "rse" then return v end
  return nil
end
Gen3Flags.rseGame = rseGame

local function constants(game)
  return require("src.core.game3.constants").of(game)
end

-- pokeemerald/include/constants/opponents.h:4
local function loadTrainersRse(game)
  local hit = RSE_CACHE[game]
  if hit then return hit end
  local C = constants(game)
  local start = isRs(game) and RS_TRAINER_START or C:require("flags", "TRAINER_FLAGS_START")
  local count = isRs(game) and RS_TRAINER_COUNT or C:require("trainers", "TRAINERS_COUNT")
  local names = C.trainers.byId and C.trainers.byId.TRAINER_ or {}
  local trainers = {}
  for id = 1, count - 1 do
    local name = names[id] or string.format("TRAINER_0x%03X", id)
    trainers[#trainers + 1] = { id = id, name = name, flagId = start + id,
      label = string.format("%s (0x%03X)", name, start + id) }
  end
  RSE_CACHE[game] = trainers
  return trainers
end

local function readText(path)
  local fs = love and love.filesystem
  if fs and fs.read and fs.getInfo and fs.getInfo(path) then
    local ok, body = pcall(fs.read, path)
    if ok and body then return body end
  end
  local f = io.open(path, "r")
  if not f then return nil end
  local body = f:read("*a")
  f:close()
  return body
end

-- Parse pokefirered/include/constants/opponents.h for all 742 TRAINER_ constants
local function loadTrainers()
  local game = rseGame()
  if game then return loadTrainersRse(game) end
  if TRAINERS_CACHE then return TRAINERS_CACHE end
  local trainers = {}
  local seen = {}
  local header = readText("pokefirered/include/constants/opponents.h")
  if header then
    for line in header:gmatch("[^\r\n]+") do
      local name, idStr = line:match("^%s*#define%s+(TRAINER_[%w_]+)%s+(%d+)")
      if name and idStr then
        local id = tonumber(idStr)
        if id and id > 0 and not seen[id] then
          seen[id] = true
          trainers[#trainers + 1] = {
            id = id,
            name = name,
            flagId = 0x500 + id,
            label = string.format("%s (0x%03X)", name, 0x500 + id),
          }
        end
      end
    end
  end

  -- Fallback if opponents.h wasn't reachable
  if #trainers == 0 then
    for id = 1, 742 do
      trainers[#trainers + 1] = {
        id = id,
        name = string.format("TRAINER_0x%03X", id),
        flagId = 0x500 + id,
        label = string.format("TRAINER_0x%03X (0x%03X)", id, 0x500 + id),
      }
    end
  end

  table.sort(trainers, function(a, b) return a.id < b.id end)
  TRAINERS_CACHE = trainers
  return trainers
end

Gen3Flags.loadTrainers = loadTrainers

-- Item Ball check (strict range 0x154..0x1FE, 0x1A6, 0x1BC..0x1FD)
local function isItemBallFlag(name, id)
  if id >= 0x154 and id <= 0x1FE then return true end
  if id == 0x1A6 or id == 0x1BC or id == 0x1BD or (id >= 0x1BE and id <= 0x1FD) then return true end
  return false
end

-- Hidden item check (strict range 0x3E8..0x4A6)
local function isHiddenItemFlag(name, id)
  if id >= 0x3E8 and id <= 0x4A6 then return true end
  if type(name) == "string" and name:find("^FLAG_HIDDEN_ITEM_") then return true end
  return false
end

-- System flags (0x800..0x8FF)
local function isSystemFlag(name, id)
  if id >= 0x800 and id <= 0x8FF then return true end
  if type(name) == "string" then
    if name:find("^FLAG_SYS_") or name:find("^FLAG_BADGE") or name:find("^FLAG_WORLD_MAP_") or name:find("^FLAG_ENABLE_SHIP_") then
      return true
    end
  end
  return false
end

-- Object hide/show toggles (0x028..0x0AE, plus non-item FLAG_HIDE_ flags)
local function isObjectToggleFlag(name, id)
  if isItemBallFlag(name, id) or isHiddenItemFlag(name, id) then return false end
  if id >= 0x028 and id <= 0x0AE then return true end
  if type(name) == "string" and name:find("^FLAG_HIDE_") then return true end
  return false
end

-- Boss clear flags (0x4B0..0x4BC)
local function isBossClearFlag(name, id)
  if id >= 0x4B0 and id <= 0x4BC then return true end
  if type(name) == "string" and name:find("^FLAG_DEFEATED_") then return true end
  return false
end

-- Story flags (0x230..0x3E7, boss clears, and story prefixes)
local function isStoryFlag(name, id)
  if isItemBallFlag(name, id) or isHiddenItemFlag(name, id) or isSystemFlag(name, id) or isObjectToggleFlag(name, id) then
    return false
  end
  if id >= 0x500 and id <= 0x7FF then return false end -- trainer flag
  if (id >= 0x230 and id <= 0x3E7) or isBossClearFlag(name, id) then return true end
  if type(name) == "string" then
    if name:find("^FLAG_GOT_") or name:find("^FLAG_RESCUED_") or name:find("^FLAG_HELPED_")
        or name:find("^FLAG_BEAT_") or name:find("^FLAG_CAN_") or name:find("^FLAG_CINNABAR_GYM_")
        or name:find("^FLAG_DID_") or name:find("^FLAG_FOUGHT_") or name:find("^FLAG_FOUND_")
        or name:find("^FLAG_LEARNED_") or name:find("^FLAG_MET_") or name:find("^FLAG_OPENED_")
        or name:find("^FLAG_REVIVED_") or name:find("^FLAG_RETURNED_") or name:find("^FLAG_TALKED_TO_")
        or name:find("^FLAG_USED_") or name:find("^FLAG_WOKE_UP_") or name:find("^FLAG_SHOWN_")
        or name:find("^MOD_") then
      return true
    end
  end
  return false
end

-- pokeemerald/include/constants/flags.h:1572
local function rseCategories(game, extraDirs)
  local C = constants(game)
  local F, V = C.flags.byName, C.vars.byName
  local sys, dailyEnd = F.SYSTEM_FLAGS, isRs(game) and 0x8FF or F.DAILY_FLAGS_END
  local tStart = isRs(game) and RS_TRAINER_START or F.TRAINER_FLAGS_START
  local tEnd = isRs(game) and RS_TRAINER_START + RS_TRAINER_COUNT - 1 or F.TRAINER_FLAGS_END
  local tempEnd = isRs(game) and F.FLAG_TEMP_1F or F.TEMP_FLAGS_END
  local out = { story = {}, trainers = loadTrainersRse(game), items = {}, toggles = {}, system = {}, vars = {} }
  local function add(list, name, id, width)
    list[#list + 1] = { name = name, id = id, label = string.format("%s (0x%0" .. (width or 3) .. "X)", name, id) }
  end
  for name, id in pairs(F) do
    if type(id) == "number" and name:find("^FLAG_") and id > tempEnd and id <= dailyEnd then
      local trainer = id >= tStart and id <= tEnd
      if name:find("^FLAG_HIDDEN_ITEM_") or name:find("^FLAG_ITEM_") then
        add(out.items, name, id)
      elseif id >= sys then
        add(out.system, name, id)
      elseif not trainer and name:find("^FLAG_HIDE_") then
        add(out.toggles, name, id)
      elseif not trainer and not name:find("^FLAG_UNUSED_") and not name:find("^FLAG_TEMP_") then
        add(out.story, name, id)
      end
    end
  end
  local Catalog = require("Catalog")
  local seen = {}
  for _, e in ipairs(out.story) do seen[e.name] = true end
  for _, name in ipairs(Catalog.scrapeEvents(nil, nil, nil, extraDirs)) do
    if not seen[name] then
      seen[name] = true
      out.story[#out.story + 1] = { name = name, id = name, label = name }
    end
  end
  local seenVars = {}
  for name, id in pairs(V) do
    if type(id) == "number" and name:find("^VAR_") and id >= V.VARS_START and id <= V.VARS_END and not seenVars[id] then
      seenVars[id] = true
      add(out.vars, name, id, 4)
    end
  end
  local function sortById(a, b)
    local aid = type(a.id) == "number" and a.id or 999999
    local bid = type(b.id) == "number" and b.id or 999999
    if aid ~= bid then return aid < bid end
    return tostring(a.name) < tostring(b.name)
  end
  for _, k in ipairs({ "story", "items", "toggles", "system", "vars" }) do table.sort(out[k], sortById) end
  return out
end

function Gen3Flags.categories(extraDirs)
  local game = rseGame()
  if game then return rseCategories(game, extraDirs) end
  local trainers = loadTrainers()

  local story = {}
  local items = {}
  local toggles = {}
  local system = {}
  local vars = {}

  local seenStory = {}
  local seenItems = {}
  local seenToggles = {}
  local seenSystem = {}

  local flagsTable = FlagsTable.FLAGS or {}

  -- 1. Classify all known flags in FlagsTable
  for name, id in pairs(flagsTable) do
    if type(name) == "string" and type(id) == "number" then
      if isHiddenItemFlag(name, id) or isItemBallFlag(name, id) then
        if not seenItems[name] then
          seenItems[name] = true
          items[#items + 1] = { name = name, id = id, label = string.format("%s (0x%03X)", name, id) }
        end
      elseif isSystemFlag(name, id) then
        if not seenSystem[name] then
          seenSystem[name] = true
          system[#system + 1] = { name = name, id = id, label = string.format("%s (0x%03X)", name, id) }
        end
      elseif isObjectToggleFlag(name, id) then
        if not seenToggles[name] then
          seenToggles[name] = true
          toggles[#toggles + 1] = { name = name, id = id, label = string.format("%s (0x%03X)", name, id) }
        end
      elseif isStoryFlag(name, id) then
        if not seenStory[name] then
          seenStory[name] = true
          story[#story + 1] = { name = name, id = id, label = string.format("%s (0x%03X)", name, id) }
        end
      end
    end
  end

  -- Scrape mod flags into story
  local Catalog = require("Catalog")
  local modFlags = Catalog.scrapeEvents(nil, nil, nil, extraDirs)
  for _, name in ipairs(modFlags) do
    if not seenStory[name] then
      seenStory[name] = true
      story[#story + 1] = { name = name, id = name, label = name }
    end
  end

  -- 2. Variables (0x4000..0x40FF)
  local seenVars = {}
  for name, id in pairs(FlagsTable.VARS or {}) do
    if type(name) == "string" and type(id) == "number" and id >= 0x4000 and id <= 0x41FF then
      if not seenVars[id] then
        seenVars[id] = true
        vars[#vars + 1] = {
          name = name,
          id = id,
          label = string.format("%s (0x%04X)", name, id),
        }
      end
    end
  end
  for id, name in pairs(FlagsTable.VARS_BY_ID or {}) do
    if type(id) == "number" and id >= 0x4000 and id <= 0x41FF then
      if not seenVars[id] then
        seenVars[id] = true
        vars[#vars + 1] = {
          name = name,
          id = id,
          label = string.format("%s (0x%04X)", name, id),
        }
      end
    end
  end

  -- Sort lists by ID / label
  local function sortById(a, b)
    local aid = type(a.id) == "number" and a.id or 999999
    local bid = type(b.id) == "number" and b.id or 999999
    if aid ~= bid then return aid < bid end
    return tostring(a.name) < tostring(b.name)
  end

  table.sort(story, sortById)
  table.sort(items, sortById)
  table.sort(toggles, sortById)
  table.sort(system, sortById)
  table.sort(vars, sortById)

  return {
    story = story,
    trainers = trainers,
    items = items,
    toggles = toggles,
    system = system,
    vars = vars,
  }
end

-- Sets / lists of all flag IDs for bulk operations
function Gen3Flags.allTrainerFlagIds()
  local trainers = loadTrainers()
  local ids = {}
  for _, t in ipairs(trainers) do
    ids[#ids + 1] = t.flagId
  end
  return ids
end

function Gen3Flags.allItemFlagIds()
  local cats = Gen3Flags.categories()
  local ids = {}
  for _, it in ipairs(cats.items) do
    ids[#ids + 1] = it.id
  end
  return ids
end

function Gen3Flags.allToggleFlagIds()
  local cats = Gen3Flags.categories()
  local ids = {}
  for _, tg in ipairs(cats.toggles) do
    ids[#ids + 1] = tg.id
  end
  return ids
end

return Gen3Flags
