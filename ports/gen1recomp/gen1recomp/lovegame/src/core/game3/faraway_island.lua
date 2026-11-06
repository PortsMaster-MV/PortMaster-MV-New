local function lazyReq(name)
  local m = package.loaded[name]
  if type(m) == "table" then return m end
  return require(name)
end

local FarawayIsland = {}

FarawayIsland.MAP = "EM_FARAWAY_ISLAND_INTERIOR"

-- pokeemerald/src/faraway_island.c:29
FarawayIsland.ROCKS = { { 14, 9 }, { 18, 9 }, { 9, 10 }, { 13, 13 } }

local function Rse()
  return lazyReq("src.core.game3.rse.init")
end

local function Player()
  return package.loaded["src.core.game3.player"] or lazyReq("src.core.game3.player")
end

local function session()
  return Rse().session()
end

local function onMap(s)
  s = s or session()
  return s ~= nil and s.map == FarawayIsland.MAP
end
FarawayIsland.onMap = onMap

local function counter()
  return Rse().var("VAR_FARAWAY_ISLAND_STEP_COUNTER")
end

local function mewGfx()
  local ok, res = pcall(function()
    local Constants = lazyReq("src.core.game3.constants")
    return Constants.of(Constants.versionOf(session())):require("event_objects", "OBJ_EVENT_GFX_MEW")
  end)
  return ok and res or nil
end

-- pokeemerald/src/faraway_island.c:335
function FarawayIsland.isMew(eo)
  if not (onMap() and eo) then return false end
  local mgfx = mewGfx()
  local gid = tonumber(eo.graphicsId)
  local dgid = eo.def and tonumber(eo.def.graphicsId or eo.def.gfx)
  if mgfx and (gid == mgfx or dgid == mgfx) then return true end
  if eo.graphicsId == "OBJ_EVENT_GFX_MEW" or (eo.def and eo.def.graphicsId == "OBJ_EVENT_GFX_MEW") then return true end
  return false
end

-- pokeemerald/src/faraway_island.c:347
function FarawayIsland.isPlayingHideAndSeek()
  return onMap() and not Rse().flag("FLAG_CAUGHT_MEW") and not Rse().flag("FLAG_HIDE_MEW")
end

-- pokeemerald/src/faraway_island.c:321
function FarawayIsland.updateStepCounter()
  if not onMap() then return end
  local steps = counter() + 1
  if steps >= 9999 then steps = 0 end
  Rse().setVar("VAR_FARAWAY_ISLAND_STEP_COUNTER", steps)
end

-- pokeemerald/src/faraway_island.c:361
function FarawayIsland.shouldShakeGrass()
  local c = counter()
  return c ~= 0xFFFF and c % 4 == 0
end

local function isPokeGrass(x, y)
  local Collision = package.loaded["src.core.game3.collision"] or lazyReq("src.core.game3.collision")
  local MB = lazyReq("src.core.game3.mb")
  local b = Collision.behavior(x, y)
  return b ~= nil and (b == MB.id("TALL_GRASS") or b == MB.id("LONG_GRASS"))
end

-- pokeemerald/src/faraway_island.c:270
function FarawayIsland.canMewMoveTo(x, y, px, py)
  if px == x and py == y then return false end
  return isPokeGrass(x, y)
end

-- pokeemerald/src/faraway_island.c:46
function FarawayIsland.mewDirection(mew, P)
  P = P or Player()
  local prevX, prevY = P.prevCellX or P.cellX, P.prevCellY or P.cellY
  local curX, curY = P.moving and P.targetX or P.cellX, P.moving and P.targetY or P.cellY
  local mx, my = mew.cellX, mew.cellY
  local dx, dy = prevX - mx, prevY - my
  local function can(x, y) return FarawayIsland.canMewMoveTo(x, y, curX, curY) end
  if prevX == curX and prevY == curY then return nil end
  local c = counter()
  mew.invisible = c % 8 ~= 0
  if c % 9 == 0 then return nil end
  for _, r in ipairs(FarawayIsland.ROCKS) do
    if prevX == r[1] then
      local safe
      if prevY < r[2] then safe = my <= r[2] else safe = my >= r[2] end
      if not safe then
        if dx > 0 then
          if mx + 1 == prevX and can(mx + 1, my) then return "right" end
        elseif dx < 0 then
          if mx - 1 == prevX and can(mx - 1, my) then return "left" end
        end
        if mx == prevX then
          if dy > 0 then
            if can(mx, my - 1) then return "up" end
          else
            if can(mx, my + 1) then return "down" end
          end
        end
      end
    end
    if prevY == r[2] then
      local safe
      if prevX < r[1] then safe = mx <= r[1] else safe = mx >= r[1] end
      if not safe then
        if dy > 0 then
          if my + 1 == prevY and can(mx, my + 1) then return "down" end
        elseif dy < 0 then
          if my - 1 == prevY and can(mx, my - 1) then return "up" end
        end
        if my == prevY then
          if dx > 0 then
            if can(mx - 1, my) then return "left" end
          else
            if can(mx + 1, my) then return "right" end
          end
        end
      end
    end
  end
  local cand = {}
  local function north(i) if dy > 0 and can(mx, my - 1) then cand[i] = "up" return true end return false end
  local function east(i) if dx < 0 and can(mx + 1, my) then cand[i] = "right" return true end return false end
  local function south(i) if dy < 0 and can(mx, my + 1) then cand[i] = "down" return true end return false end
  local function west(i) if dx > 0 and can(mx - 1, my) then cand[i] = "left" return true end return false end
  local function pick(n) return cand[c % n + 1] end
  if north(1) then
    if east(2) or west(2) then return pick(2) end
    return "up"
  end
  if south(1) then
    if east(2) or west(2) then return pick(2) end
    return "down"
  end
  if east(1) then
    if north(2) or south(2) then return pick(2) end
    return "right"
  end
  if west(1) then
    if north(2) or south(2) then return pick(2) end
    return "left"
  end
  if dy == 0 then
    if curY > my and can(mx, my - 1) then return "up" end
    if curY < my and can(mx, my + 1) then return "down" end
    if can(mx, my - 1) then return "up" end
    if can(mx, my + 1) then return "down" end
  end
  if dx == 0 then
    if curX > mx and can(mx - 1, my) then return "left" end
    if curX < mx and can(mx + 1, my) then return "right" end
    if can(mx + 1, my) then return "right" end
    if can(mx - 1, my) then return "left" end
  end
  -- pokeemerald/src/faraway_island.c:282
  local valid = {}
  if can(mx, my - 1) then valid[#valid + 1] = "up" end
  if can(mx + 1, my) then valid[#valid + 1] = "right" end
  if can(mx, my + 1) then valid[#valid + 1] = "down" end
  if can(mx - 1, my) then valid[#valid + 1] = "left" end
  if #valid > 1 then return valid[c % #valid + 1] end
  return valid[1]
end

FarawayIsland._grass = nil

local function mewObject()
  local O = package.loaded["src.core.game3.objects"] or lazyReq("src.core.game3.objects")
  for _, lid in ipairs(O._order or {}) do
    local eo = O._byId[lid]
    if FarawayIsland.isMew(eo) then return eo end
  end
  return nil
end

-- pokeemerald/src/faraway_island.c:370
function FarawayIsland.setMewAboveGrass(ctx)
  local mew = mewObject()
  if not mew then return end
  mew.invisible = false
  if Rse().specialVar(ctx, 0x8004) == 1 then return end
  Rse().setVar("VAR_FARAWAY_ISLAND_STEP_COUNTER", 0xFFFF)
  local FxRse = lazyReq("src.core.game3.field_effects_rse")
  local e = FxRse.spawnAt("long_grass", mew.cellX, mew.cellY, 8, 8, { layer = "front", stopOnEnd = false })
  if e then e.a.paused = true end
  FarawayIsland._grass = e
end

-- pokeemerald/src/faraway_island.c:411
function FarawayIsland.destroyGrass()
  local e = FarawayIsland._grass
  FarawayIsland._grass = nil
  if not e then return end
  local FxRse = lazyReq("src.core.game3.field_effects_rse")
  FxRse.clear(function(x) return x == e end)
end

FarawayIsland.BY_NAME = {
  SetMewAboveGrass = function(ctx)
    FarawayIsland.setMewAboveGrass(ctx)
    return false
  end,
  DestroyMewEmergingGrassSprite = function()
    FarawayIsland.destroyGrass()
    return false
  end,
}

return FarawayIsland
