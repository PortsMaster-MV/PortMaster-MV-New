local DecorInv = require("src.core.game3.rse.decoration_inventory")
local MB = require("src.core.game3.mb")

local Decor = {}

Decor.MANIFEST = "data/generated/gba/secret_base/manifest.lua"
-- pokeemerald/include/fieldmap.h:4
Decor.PRIMARY = 0x200
Decor.ICON_PAIR = "secret_base__secret_base_red_cave"
-- pokeemerald/include/constants/global.h:57
Decor.MAX_SECRET_BASE = 16
Decor.MAX_PLAYERS_HOUSE = 12
-- pokeemerald/include/decoration.h:9
Decor.PERM = { SOLID_FLOOR = 0, PASS_FLOOR = 1, BEHIND_FLOOR = 2, NA_WALL = 3, SPRITE = 4 }
-- pokeemerald/include/decoration.h:32
Decor.CAT = { DESK = 0, CHAIR = 1, PLANT = 2, ORNAMENT = 3, MAT = 4, POSTER = 5, DOLL = 6, CUSHION = 7 }
Decor.CATEGORY_COUNT = 8
-- pokeemerald/include/decoration.h:18
Decor.SHAPE = { [0] = { 1, 1 }, { 2, 1 }, { 3, 1 }, { 4, 2 }, { 2, 2 }, { 1, 2 }, { 1, 3 }, { 2, 4 }, { 3, 3 }, { 3, 2 } }
Decor.SHAPE_1x2 = 5
Decor.SHAPE_1x3 = 6
-- pokeemerald/include/constants/decorations.h:37
Decor.DECOR_SOLID_BOARD = 33
Decor.DECOR_SLIDE = 34
Decor.DECOR_STAND = 38
Decor.DECOR_SAND_ORNAMENT = 41
Decor.DECOR_SILVER_SHIELD = 42
Decor.DECOR_GOLD_SHIELD = 43
Decor.NUM_DECORATIONS = 120
-- pokeemerald/include/global.fieldmap.h:39
local ATTR_BEHAVIOR_MASK = 0xFF
local ATTR_LAYER_SHIFT = 12

local manifest

function Decor.manifest()
  if manifest then return manifest end
  local src = assert(require("src.core.game3.dataset").cache():read(Decor.MANIFEST), Decor.MANIFEST .. " is not in the cache")
  manifest = assert(load(src, "@" .. Decor.MANIFEST, "t", {}))()
  return manifest
end

function Decor.install(pack, inventoryPack)
  manifest = pack
  if inventoryPack then DecorInv.install(inventoryPack) end
end

function Decor.reset()
  manifest = nil
end

function Decor.info(decor)
  decor = tonumber(decor) or 0
  local d = DecorInv.info(decor)
  if not d then return nil end
  local out = {}
  for k, v in pairs(d) do out[k] = v end
  out.id = decor
  out.tiles = Decor.manifest().decorTiles[decor] or {}
  return out
end

function Decor.dims(decor)
  local d = DecorInv.info(decor)
  local s = Decor.SHAPE[d and d.shape or 0] or Decor.SHAPE[0]
  return s[1], s[2]
end

function Decor.isSprite(decor)
  local d = DecorInv.info(decor)
  return d ~= nil and d.permission == Decor.PERM.SPRITE
end

function Decor.attributes(tile)
  return tonumber(Decor.manifest().secondaryAttributes[tonumber(tile) or 0]) or 0
end

function Decor.layerType(tile)
  return math.floor(Decor.attributes(tile) / 2 ^ ATTR_LAYER_SHIFT) % 16
end

function Decor.tileBehavior(tile)
  local game = "emerald"
  if Decor.manifest().assetLayout == "rs" then
    game = require("src.core.game3.constants").versionOf(require("src.core.game3.rse.init").session())
  end
  return MB.fromRaw(game, Decor.attributes(tile) % (ATTR_BEHAVIOR_MASK + 1))
end

local function isBeh(beh, name)
  return beh ~= nil and beh == MB.id(name)
end
Decor.isBeh = isBeh

-- pokeemerald/src/decoration.c:1192
local function elevationFor(decor, idx)
  local m = Decor.manifest()
  if decor == Decor.DECOR_STAND then return m.standElevations[idx + 1] end
  if decor == Decor.DECOR_SLIDE then return m.slideElevations[idx + 1] end
  return nil
end

-- pokeemerald/src/decoration.c:1208
function Decor.showOnMap(grid, mapX, mapY, decor)
  local d = Decor.info(decor)
  if not d then return false end
  local w, h = Decor.dims(decor)
  for j = 0, h - 1 do
    local y = mapY - h + 1 + j
    for i = 0, w - 1 do
      local x = mapX + i
      local tile = d.tiles[j * w + i + 1] or 0
      local impassable = isBeh(Decor.tileBehavior(tile), "SECRET_BASE_IMPASSABLE")
        or (d.permission ~= Decor.PERM.PASS_FLOOR and Decor.layerType(tile) ~= 0)
      local overlapsWall = d.permission ~= Decor.PERM.NA_WALL and isBeh(grid.behavior(x, y), "SECRET_BASE_NORTH_WALL")
      grid.setMetatile(x, y, tile + Decor.PRIMARY + (overlapsWall and 1 or 0), impassable, elevationFor(decor, j * w + i))
    end
  end
  return true
end

-- pokeemerald/src/decoration.c:1503
local function floorOrBoardAndHole(beh, decor)
  if isBeh(beh, "SECRET_BASE_TRAINER_SPOT") then return false end
  if decor == Decor.DECOR_SOLID_BOARD and isBeh(beh, "SECRET_BASE_HOLE") then return true end
  return isBeh(beh, "NORMAL")
end

-- pokeemerald/src/decoration.c:1494
local function notInitial(place, x, y, layer)
  return not (x == place.initialX and y == place.initialY and layer ~= 0)
end

-- pokeemerald/src/decoration.c:1528
function Decor.canPlace(grid, place, decor)
  local d = Decor.info(decor)
  if not d then return false end
  local w, h = Decor.dims(decor)
  local cx, cy = place.x, place.y
  local P = Decor.PERM
  if d.permission == P.SOLID_FLOOR or d.permission == P.PASS_FLOOR then
    for i = 0, h - 1 do
      local y = cy - i
      for j = 0, w - 1 do
        local x = cx + j
        local layer = Decor.layerType(d.tiles[(h - 1 - i) * w + j + 1] or 0)
        if not floorOrBoardAndHole(grid.behavior(x, y), decor) then return false end
        if not notInitial(place, x, y, layer) then return false end
        local obj = grid.objectAt(x, y)
        if obj ~= nil and obj ~= 0 then return false end
      end
    end
  elseif d.permission == P.BEHIND_FLOOR then
    for i = 0, h - 2 do
      local y = cy - i
      for j = 0, w - 1 do
        local x = cx + j
        local beh = grid.behavior(x, y)
        local layer = Decor.layerType(d.tiles[(h - 1 - i) * w + j + 1] or 0)
        if not isBeh(beh, "NORMAL") and not (isBeh(beh, "SECRET_BASE_TRAINER_SPOT") and layer == 0) then return false end
        if not notInitial(place, x, y, layer) then return false end
        if grid.objectAt(x, y) ~= nil then return false end
      end
    end
    local y = cy - h + 1
    for j = 0, w - 1 do
      local x = cx + j
      local beh = grid.behavior(x, y)
      local layer = Decor.layerType(d.tiles[j + 1] or 0)
      if not isBeh(beh, "NORMAL") and not isBeh(beh, "SECRET_BASE_NORTH_WALL") then return false end
      if not notInitial(place, x, y, layer) then return false end
      local obj = grid.objectAt(x, y)
      if obj ~= nil and obj ~= 0 then return false end
    end
  elseif d.permission == P.NA_WALL then
    local broken = grid.metatileId("METATILE_SecretBase_SandOrnament_BrokenBase")
    for i = 0, h - 1 do
      local y = cy - i
      for j = 0, w - 1 do
        local x = cx + j
        if not isBeh(grid.behavior(x, y), "SECRET_BASE_NORTH_WALL") then return false end
        if broken and grid.metatile(x, y + 1) == broken then return false end
      end
    end
  elseif d.permission == P.SPRITE then
    local y = cy
    for j = 0, w - 1 do
      local x = cx + j
      local beh = grid.behavior(x, y)
      if d.shape == Decor.SHAPE_1x2 then
        if not isBeh(beh, "HOLDS_LARGE_DECORATION") then return false end
      elseif not isBeh(beh, "HOLDS_SMALL_DECORATION") and not isBeh(beh, "HOLDS_LARGE_DECORATION") then
        return false
      end
      if grid.objectAt(x, y) ~= nil then return false end
    end
  end
  return true
end

local function list(t, n)
  for i = 1, n do t[i] = tonumber(t[i]) or 0 end
  return t
end

-- pokeemerald/src/decoration.c:515
function Decor.context(sess, isPlayerRoom)
  if isPlayerRoom then
    sess.playerRoomDecorations = list(type(sess.playerRoomDecorations) == "table" and sess.playerRoomDecorations or {},
      Decor.MAX_PLAYERS_HOUSE)
    sess.playerRoomDecorationPositions = list(type(sess.playerRoomDecorationPositions) == "table"
      and sess.playerRoomDecorationPositions or {}, Decor.MAX_PLAYERS_HOUSE)
    return { items = sess.playerRoomDecorations, pos = sess.playerRoomDecorationPositions,
      size = Decor.MAX_PLAYERS_HOUSE, isPlayerRoom = true }
  end
  local SecretBase = require("src.core.game3.rse.secret_base")
  local base = SecretBase.base(sess, 0)
  return { items = base.decorations, pos = base.decorationPositions, size = Decor.MAX_SECRET_BASE, isPlayerRoom = false }
end

function Decor.encodePos(x, y)
  return (x % 16) * 16 + (y % 16)
end

function Decor.decodePos(p)
  p = tonumber(p) or 0
  return math.floor(p / 16), p % 16
end

-- pokeemerald/src/decoration.c:1313
function Decor.hasSpace(ctx)
  for i = 1, ctx.size do
    if ctx.items[i] == 0 then return true end
  end
  return false
end

function Decor.hasInUse(ctx)
  for i = 1, ctx.size do
    if ctx.items[i] ~= 0 then return true end
  end
  return false
end

-- pokeemerald/src/decoration.c:1685
function Decor.record(ctx, decor, x, y)
  for i = 1, ctx.size do
    if ctx.items[i] == 0 then
      ctx.items[i] = decor
      ctx.pos[i] = Decor.encodePos(x, y)
      return i
    end
  end
  return nil
end

-- pokeemerald/src/decoration.c:1070
function Decor.inUse(sess, cat)
  local items = DecorInv.inventories(sess)[cat]
  local size = DecorInv.SIZES[cat]
  local base = require("src.core.game3.rse.secret_base").base(sess, 0)
  local room = Decor.context(sess, true)
  local inBase, inRoom = {}, {}
  local function claim(set, other, decor)
    for j = 1, size do
      if items[j] == decor and not set[j] and not (other and other[j]) then
        set[j] = true
        return
      end
    end
  end
  for i = 1, Decor.MAX_SECRET_BASE do
    local decor = base.decorations[i]
    if decor ~= 0 then claim(inBase, nil, decor) end
  end
  for i = 1, Decor.MAX_PLAYERS_HOUSE do
    local decor = room.items[i]
    if decor ~= 0 then claim(inRoom, inBase, decor) end
  end
  return inBase, inRoom
end

-- pokeemerald/src/decoration.c:1128
function Decor.isInPc(sess, cat, index)
  local inBase, inRoom = Decor.inUse(sess, cat)
  return not inBase[index] and not inRoom[index]
end

-- pokeemerald/src/decoration.c:2740
function Decor.toss(sess, cat, index)
  local items = DecorInv.inventories(sess)[cat]
  items[index] = DecorInv.DECOR_NONE
  DecorInv.condense(cat, sess)
end

-- pokeemerald/src/decoration.c:2420
function Decor.shapeOf(decor)
  local w, h = Decor.dims(decor)
  return { width = w, height = h }
end

-- pokeemerald/src/decoration.c:2482
local function underCursor(grid, ctx, idx, shape, cx, cy)
  local ox, oy = Decor.decodePos(ctx.pos[idx])
  local ht = shape.height
  if ctx.items[idx] == Decor.DECOR_SAND_ORNAMENT
      and grid.metatile(ox, oy) == grid.metatileId("METATILE_SecretBase_SandOrnament_BrokenBase") then
    ht = ht - 1
  end
  return cx >= ox and cx < ox + shape.width and cy > oy - ht and cy <= oy
end

-- pokeemerald/src/decoration.c:2570
function Decor.markForRemoval(grid, ctx, cx, cy)
  local marked = {}
  local function spriteFlag(idx)
    local ox, oy = Decor.decodePos(ctx.pos[idx])
    return grid.visibleDecorationFlagAt and grid.visibleDecorationFlagAt(ox, oy) or nil
  end
  for i = 1, ctx.size do
    local decor = ctx.items[i]
    if decor ~= 0 and Decor.isSprite(decor) then
      local shape = Decor.shapeOf(decor)
      if underCursor(grid, ctx, i, shape, cx, cy) then
        marked[1] = { idx = i, width = shape.width, height = shape.height, flagId = spriteFlag(i) }
        return marked
      end
    end
  end
  for i = 1, ctx.size do
    local decor = ctx.items[i]
    if decor ~= 0 then
      local shape = Decor.shapeOf(decor)
      if underCursor(grid, ctx, i, shape, cx, cy) then
        marked[1] = { idx = i, width = shape.width, height = shape.height }
        break
      end
    end
  end
  if marked[1] then
    local ox, oy = Decor.decodePos(ctx.pos[marked[1].idx])
    local top, right = oy - marked[1].height + 1, marked[1].width + ox - 1
    -- pokeemerald/src/decoration.c:2549
    for i = 1, ctx.size do
      local decor = ctx.items[i]
      local x, y = Decor.decodePos(ctx.pos[i])
      if decor ~= 0 and Decor.isSprite(decor) and ox <= x and top <= y and right >= x and oy >= y then
        marked[#marked + 1] = { idx = i, flagId = spriteFlag(i) }
      end
    end
  end
  return marked
end

-- pokeemerald/src/decoration.c:2231
function Decor.clearNonSprites(grid, ctx, marked)
  for _, m in ipairs(marked) do
    local decor = ctx.items[m.idx]
    if decor ~= 0 and not Decor.isSprite(decor) then
      local px, py = Decor.decodePos(ctx.pos[m.idx])
      for y = 0, (m.height or 1) - 1 do
        for x = 0, (m.width or 1) - 1 do
          grid.restoreMetatile(px + x, py - y, 3)
        end
      end
      ctx.items[m.idx], ctx.pos[m.idx] = 0, 0
    end
  end
end

-- pokeemerald/src/decoration.c:2191
function Decor.putAwayIteration(ctx, marked, i)
  if i >= #marked then return { done = true } end
  local m = marked[i + 1]
  local decor = ctx.items[m.idx]
  if decor ~= 0 and Decor.isSprite(decor) then
    ctx.items[m.idx], ctx.pos[m.idx] = 0, 0
    return { flagId = m.flagId or 0 }
  end
  return { flagId = 0 }
end

function Decor.decorationFlags(C)
  local out = {}
  local first = C:require("flags", "FLAG_DECORATION_1")
  local last = C:require("flags", "FLAG_DECORATION_14")
  for f = first, last do out[#out + 1] = f end
  return out
end

-- pokeemerald/src/decoration.c:853
function Decor.categoryName(cat)
  return DecorInv.categoryName(cat)
end

return Decor
