local Window = require("src.ui.game3.window")
local Display = require("src.core.game3.display")
local Dataset = require("src.core.game3.dataset")
local Extract = require("src.import.gba.extract_island1")
local GameVersion = require("src.core.GameVersion")
local CacheFs = require("src.import.CacheFs")
local Serializer = require("src.core.SaveSerializer")

local MuseumPic = {}
local names = { [141] = "kabutops", [142] = "aerodactyl" }
local owner

local function session()
  local Runtime = package.loaded["src.core.game3.runtime"]
  return Runtime and Runtime.getSession and Runtime.getSession() or nil
end

local function binding()
  return { version = GameVersion.get(), root = Extract.CACHE_ROOT,
    override = Dataset.cacheRootOverride, directory = CacheFs.root(), cache = Dataset.cache() }
end

local function sameBinding(a, b)
  return a.version == b.version and a.root == b.root and a.override == b.override
    and a.directory == b.directory and a.cache == b.cache
end

local function clear()
  if not owner then return end
  if owner.ctx.museumFossilPic == owner.state then owner.ctx.museumFossilPic = nil end
  if owner.image and owner.image.release then owner.image:release() end
  owner = nil
end

function MuseumPic.reset()
  clear()
end

function MuseumPic.isActive()
  if not owner then return false end
  local Space = package.loaded["src.core.game3.scripting.space"]
  if not Space or Space.vm ~= owner.vm or Space.mapId ~= owner.map
      or owner.vm.ctx ~= owner.ctx or owner.ctx.museumFossilPic ~= owner.state
      or session() ~= owner.session
      or (owner.vm.isRunning and not owner.vm:isRunning())
      or not sameBinding(owner.binding, binding()) then
    clear()
    return false
  end
  return true
end

local function imageFor(species, current)
  local root = (current.root or "data/generated/gba") .. "/museum/"
  local source = current.cache:read(root .. "manifest.lua")
  local manifest = source and Serializer.decode(source)
  if type(manifest) ~= "table" or manifest.format_version ~= 1
      or manifest.width ~= 64 or manifest.height ~= 64 or type(manifest.species) ~= "table"
      or manifest.species.kabutops ~= 141 or manifest.species.aerodactyl ~= 142 then
    error("[game3/museum] required fossil manifest is invalid", 0)
  end
  local bytes = current.cache:read(root .. names[species] .. ".rgba")
  if type(bytes) ~= "string" or #bytes ~= 64 * 64 * 4 then
    error("[game3/museum] required fossil art is invalid: " .. names[species], 0)
  end
  local data = love.image.newImageData(64, 64, "rgba8", bytes)
  local image = love.graphics.newImage(data)
  image:setFilter("nearest", "nearest")
  return image
end

-- pokefirered/src/script_menu.c:1151
function MuseumPic.show(ctx, species, x, y)
  if not ctx or not names[species] then return false end
  if MuseumPic.isActive() or ctx.museumFossilPic then return false end
  local state = { species = species, x = tonumber(x) or 0, y = tonumber(y) or 0 }
  local Space = package.loaded["src.core.game3.scripting.space"]
  if Space and Space.vm and Space.vm.ctx == ctx then
    local current = binding()
    owner = { ctx = ctx, state = state, vm = Space.vm, map = Space.mapId, session = session(),
      binding = current, image = imageFor(species, current) }
  end
  ctx.museumFossilPic = state
  return true
end

-- pokefirered/src/script_menu.c:1184
function MuseumPic.hide(ctx)
  if owner and owner.ctx == ctx then clear() end
  if ctx then ctx.museumFossilPic = nil end
end

-- pokefirered/src/script_menu.c:1173
function MuseumPic.draw()
  if not MuseumPic.isActive() then return end
  local state = owner.state
  Window.stdFrame(Window.template(state.x + 1, state.y + 1, 8, 8))
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(owner.image, state.x * Display.TILE + 8, state.y * Display.TILE + 8)
end

return MuseumPic
