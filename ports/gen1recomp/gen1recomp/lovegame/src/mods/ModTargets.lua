-- Which games a mod is for.  One derivation for the manifest's `games` key,
-- the legacy `gen2compat` flag, and the labels both mod surfaces draw:
-- src/mods/LauncherMods.lua and src/mods/ManagerState.lua read this rather
-- than each keeping its own copy of the rule.
local GameVersion = require("src.core.GameVersion")

local ModTargets = {}

-- every version of one generation, in launcher order (GameVersion.ORDER)
function ModTargets.generationVersions(gen)
  local out = {}
  for _, id in ipairs(GameVersion.ORDER) do
    if GameVersion.generation(id) == gen then out[#out + 1] = id end
  end
  return out
end

-- the generations this engine has games for, ascending
local function generations()
  local seen, out = {}, {}
  for _, id in ipairs(GameVersion.ORDER) do
    local gen = GameVersion.generation(id)
    if not seen[gen] then
      seen[gen] = true
      out[#out + 1] = gen
    end
  end
  table.sort(out)
  return out
end

function ModTargets.familyVersions(family)
  local out = {}
  for _, id in ipairs(GameVersion.ORDER) do
    if GameVersion.layout(id) == family then out[#out + 1] = id end
  end
  return out
end

-- one manifest token -> the version ids it covers, or nil when it names no
-- game this engine knows: "red" | "gen1" | "all"
function ModTargets.expand(token)
  if type(token) ~= "string" then return nil end
  local key = token:lower():match("^%s*(.-)%s*$")
  if key == "all" then return GameVersion.ORDER end
  if GameVersion.VERSIONS[key] then return { key } end
  local gen = key:match("^gen%s*(%d+)$")
  if gen then
    local list = ModTargets.generationVersions(tonumber(gen))
    if #list > 0 then return list end
  end
  local family = ModTargets.familyVersions(key)
  if #family > 0 then return family end
  return nil
end

-- version-id lists are always ORDER-sorted and deduped, so two manifests that
-- say the same thing different ways encode and compare the same
local function fromSet(set)
  local out = {}
  for _, id in ipairs(GameVersion.ORDER) do
    if set[id] then out[#out + 1] = id end
  end
  return out
end

-- normalize a manifest `games` array; second return is the tokens that named
-- no game, which Manifest reports at its own api level
function ModTargets.normalize(list)
  local set, unknown = {}, {}
  for _, token in ipairs(type(list) == "table" and list or {}) do
    local ids = ModTargets.expand(token)
    if ids then
      for _, id in ipairs(ids) do set[id] = true end
    else
      unknown[#unknown + 1] = tostring(token)
    end
  end
  return fromSet(set), unknown
end

function ModTargets.union(a, b)
  local set = {}
  for _, list in ipairs({ a or {}, b or {} }) do
    for _, id in ipairs(list) do set[id] = true end
  end
  return fromSet(set)
end

-- The pre-`games` reading of a manifest: Gen 1 always, Gen 2 only where the
-- author claimed gen2compat (src/mods/Manifest.lua).
function ModTargets.legacy(gen2compat)
  local out = ModTargets.generationVersions(1)
  if gen2compat then
    return ModTargets.union(out, ModTargets.generationVersions(2))
  end
  return out
end

-- does a version-id list hold any game of that generation
function ModTargets.covers(versions, gen)
  for _, id in ipairs(versions or {}) do
    if GameVersion.generation(id) == gen then return true end
  end
  return false
end

-- the version ids a validated manifest targets; Manifest.validate resolves
-- `games` at load, so this is the same answer everywhere
function ModTargets.versions(manifest)
  local games = manifest and manifest.games
  if type(games) == "table" and #games > 0 then return games end
  return ModTargets.legacy(manifest and manifest.gen2compat)
end

-- Does the mod target this game?  `version` is a version id; pass nil with a
-- generation to ask about a whole generation (the loader's injected seam).
function ModTargets.supports(manifest, version, generation)
  local versions = ModTargets.versions(manifest)
  if version and GameVersion.VERSIONS[version] then
    for _, id in ipairs(versions) do
      if id == version then return true end
    end
    return false
  end
  return ModTargets.covers(versions, generation or GameVersion.generation())
end

-- What will actually happen here: the loader gates on this same answer, per
-- version (Loader:_gateGeneration), and the player's override forces past it,
-- so the two UIs report a run, not a claim.
function ModTargets.runsHere(manifest, version, generation, forced)
  if forced then return true end
  return ModTargets.supports(manifest, version, generation)
end

-- "Gen 1" / "Gen 1+2" while a mod takes whole generations, the version names
-- ("Red/Gold") once it takes only some of one
function ModTargets.label(manifest)
  local versions = ModTargets.versions(manifest)
  local set = {}
  for _, id in ipairs(versions) do set[id] = true end
  local whole, partial = {}, false
  for _, gen in ipairs(generations()) do
    local all, any = true, false
    for _, id in ipairs(ModTargets.generationVersions(gen)) do
      if set[id] then any = true else all = false end
    end
    if any and all then whole[#whole + 1] = tostring(gen)
    elseif any then partial = true end
  end
  if #whole > 0 and not partial then
    return "Gen " .. table.concat(whole, "+")
  end
  local names = {}
  for _, id in ipairs(versions) do
    names[#names + 1] = GameVersion.info(id).label or id
  end
  if #names == 0 then return "No game" end
  return table.concat(names, "/")
end

-- the same label as an all-caps chip, for the launcher tag and the GB font
function ModTargets.chip(manifest)
  return ModTargets.label(manifest):upper()
end

-- one game's own name, for a line that has to say which one this is
function ModTargets.gameLabel(version)
  local info = version and GameVersion.info(version)
  return (info and info.label) or tostring(version)
end

-- One launcher-voice line for a mod that does not target `version`
-- (src/mods/LauncherMods.lua statusFor).
function ModTargets.detail(manifest, version)
  return ("For %s, not %s"):format(ModTargets.label(manifest),
    ModTargets.gameLabel(version))
end

-- Does a dependency spec apply to this game / version?
-- If spec.games is provided, it must match version / generation.
-- If spec.game_version is provided, the engine version must satisfy it.
function ModTargets.specApplies(spec, version, generation)
  if not spec then return false end
  if type(spec.games) == "table" and #spec.games > 0 then
    if version or generation then
      local match = false
      for _, id in ipairs(spec.games) do
        if version and id == version then
          match = true
          break
        end
        if generation and GameVersion.generation(id) == generation then
          match = true
          break
        end
      end
      if not match then return false end
    end
  end
  if spec.game_version then
    local ok = pcall(function()
      local Semver = require("src.mods.Semver")
      local Version = require("src.core.Version")
      if Version and Version.engine and Version.engine:match("^0%.0%.0%-") == nil then
        return Semver.satisfies(Version.engine, spec.game_version)
      end
      return true
    end)
    if not ok then return false end
  end
  return true
end

return ModTargets
