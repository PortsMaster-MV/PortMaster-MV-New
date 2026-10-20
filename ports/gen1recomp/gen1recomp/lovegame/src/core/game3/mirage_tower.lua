local MirageTower = {}

MirageTower._crumbles = nil
MirageTower._fossil = nil
MirageTower._crumbleImg = nil

local function Rse()
  return require("src.core.game3.rse.init")
end

local function FieldView()
  return require("src.core.game3.field_view")
end

local function Objects()
  return package.loaded["src.core.game3.objects"] or require("src.core.game3.objects")
end

local function Player()
  return package.loaded["src.core.game3.player"] or require("src.core.game3.player")
end

local function manifest()
  local FxRse = require("src.core.game3.field_effects_rse")
  local m = FxRse.fc()
  return m and m.mirageTower
end

local function playSe(name)
  local SE = require("src.core.game3.se_ids")
  local ok, Audio = pcall(require, "src.core.game3.audio")
  if ok and Audio and Audio.playSe and SE[name] then Audio.playSe(SE[name]) end
end

local function task(fn)
  return require("src.core.game3.task").spawn(fn)
end

local function waitFor(ctx, pred)
  ctx.stateWait = pred
  return false
end

-- pokeemerald/src/mirage_tower.c:262
function MirageTower.isVisible(session)
  session = session or Rse().session()
  if not (session and session.map == "EM_ROUTE111") then return false end
  return Rse().flag("FLAG_MIRAGE_TOWER_VISIBLE", session)
end

-- pokeemerald/src/mirage_tower.c:315
function MirageTower.setVisibility(random)
  if Rse().var("VAR_MIRAGE_TOWER_STATE") ~= 0 then
    Rse().setFlag("FLAG_MIRAGE_TOWER_VISIBLE", false)
    return false
  end
  random = random or require("src.core.game3.rng").Random
  local visible = (tonumber(random()) or 0) % 2 == 1
  if Rse().flag("FLAG_FORCE_MIRAGE_TOWER_VISIBLE") then visible = true end
  Rse().setFlag("FLAG_MIRAGE_TOWER_VISIBLE", visible)
  return visible
end

-- pokeemerald/src/mirage_tower.c:373
function MirageTower.screenShake(yOff, xOff, numShakes, delay, done)
  local timer, x, y = 0, xOff, yOff
  playSe("SE_M_STRENGTH")
  task(function()
    timer = timer + 1
    if timer % delay == 0 then
      timer = 0
      numShakes = numShakes - 1
      x, y = -x, -y
      FieldView().setCameraPanning(x, y)
      if numShakes == 0 then
        FieldView().setCameraPanning(0, 0)
        if done then done() end
        return true
      end
    end
    return false
  end)
end

-- pokeemerald/src/mirage_tower.c:420
function MirageTower.ceilingCrumble(done)
  local m = manifest()
  local finished, frames = 0, 0
  local list = {}
  for i, pos in ipairs(m and m.crumblePositions or {}) do
    list[#list + 1] = { large = true, x = pos[1] + 120, y = pos[2], yOff = 0, limit = pos[3], i = i }
  end
  for i, pos in ipairs(m and m.crumblePositions or {}) do
    list[#list + 1] = { large = false, x = pos[1] + 115, y = pos[2] - 3, yOff = 0, limit = pos[3], i = i }
  end
  MirageTower._crumbles = list
  local total = #list + 1
  MirageTower.screenShake(2, 1, 16, 3, function() finished = finished + 1 end)
  task(function()
    frames = frames + 1
    for idx = #list, 1, -1 do
      local c = list[idx]
      -- pokeemerald/src/mirage_tower.c:471
      c.yOff = c.yOff + 2
      if c.y + math.floor(c.yOff / 2) > c.limit then
        table.remove(list, idx)
        finished = finished + 1
      end
    end
    -- pokeemerald/src/mirage_tower.c:428
    if frames == 1000 or finished == total then
      MirageTower._crumbles = nil
      if done then done() end
      return true
    end
    return false
  end)
end

-- pokeemerald/src/mirage_tower.c:355
function MirageTower.fallingPlayerId()
  local flag = Rse().flagId("FLAG_HIDE_ROUTE_111_PLAYER_DESCENT")
  local O = Objects()
  for _, lid in ipairs(O._order or {}) do
    local eo = O._byId[lid]
    if eo and eo.def and tonumber(eo.def.flag) == flag then return lid end
  end
  return nil
end

-- pokeemerald/src/mirage_tower.c:349
function MirageTower.playerDescend(localId, done)
  local eo = localId and Objects().find(localId)
  local P = Player()
  if not eo then
    if done then done() end
    return
  end
  task(function()
    eo.raiseY = (eo.raiseY or 0) + 4
    if (eo.py or 0) + eo.raiseY >= (P.py or 0) then
      if done then done() end
      return true
    end
    return false
  end)
end

-- pokeemerald/src/mirage_tower.c:485
function MirageTower.setInvisibleMetatiles()
  local Field = package.loaded["src.core.game3.field"] or require("src.core.game3.field")
  for _, t in ipairs(manifest() and manifest().invisibleMetatiles or {}) do
    Field.setMetatile(t.x, t.y, t.metatile, false)
  end
end

-- pokeemerald/src/mirage_tower.c:532
function MirageTower.startShake()
  MirageTower.setInvisibleMetatiles()
  MirageTower._bgShake = { t = 0, x = 2 }
end

-- pokeemerald/src/mirage_tower.c:583
function MirageTower.startDisintegration(done)
  local rows, started, finished, sub = 0x60, 0, 0, 0
  local progress = {}
  task(function()
    if started <= rows - 1 then
      if sub > 1 then
        started = started + 1
        progress[started] = 0
        sub = 0
      end
      sub = sub + 1
    end
    for i = finished + 1, started do
      progress[i] = (progress[i] or 0) + 1
      if progress[i] > 0x30 - 1 and i == finished + 1 then finished = finished + 1 end
    end
    if (progress[rows] or 0) > 0x30 - 1 then
      MirageTower._bgShake = nil
      if done then done() end
      return true
    end
    return false
  end)
end

-- pokeemerald/src/mirage_tower.c:671
function MirageTower.startFossilFall(done)
  local f = { y = -16, idx = 0 }
  MirageTower._fossil = f
  task(function()
    -- pokeemerald/src/mirage_tower.c:736
    if f.idx >= 0x100 then
      MirageTower._fossil = nil
      if done then done() end
      return true
    elseif f.y >= 96 then
      f.idx = f.idx + 2
    else
      f.y = f.y + 1
    end
    return false
  end)
end

function MirageTower.step()
  local s = MirageTower._bgShake
  if s then
    s.t = s.t + 1
  end
end

local function crumbleImage()
  local img = MirageTower._crumbleImg
  if img ~= nil then return img or nil end
  local m = manifest()
  local FxRse = require("src.core.game3.field_effects_rse")
  local fc = FxRse.fc()
  local idx = m and require("src.core.game3.dataset").cache():read("data/generated/gba/field_fc/" .. m.crumbles.idx)
  local s = Rse().session()
  local tag = (tonumber(s and s.gender) or 0) == 0 and "gObjectEventPal_Brendan" or "gObjectEventPal_May"
  local pal
  for t, colors in pairs(fc and fc.palettes or {}) do
    local names = require("src.core.game3.field_effects").manifest()
    local name = names and names.paletteTags and names.paletteTags[t]
    if name == tag then pal = colors end
  end
  if not (idx and pal and love and love.image) then
    MirageTower._crumbleImg = false
    return nil
  end
  local data = love.image.newImageData(16, 16)
  for i = 0, 255 do
    local v = idx:byte(i + 1) or 0
    local c = pal[v + 1]
    if v ~= 0 and c then data:setPixel(i % 16, math.floor(i / 16), c[1] / 255, c[2] / 255, c[3] / 255, 1) end
  end
  img = love.graphics.newImage(data)
  if img.setFilter then img:setFilter("nearest", "nearest") end
  MirageTower._crumbleImg = img
  return img
end

function MirageTower.drawOverlay()
  local list = MirageTower._crumbles
  if list then
    local img = crumbleImage()
    if img then
      MirageTower._small = MirageTower._small or love.graphics.newQuad(0, 0, 8, 8, 16, 16)
      love.graphics.setColor(1, 1, 1, 1)
      for _, c in ipairs(list) do
        local y = c.y + math.floor(c.yOff / 2)
        if c.large then
          love.graphics.draw(img, c.x - 8, y - 8)
        else
          love.graphics.draw(img, MirageTower._small, c.x - 4, y - 4)
        end
      end
    end
  end
  local f = MirageTower._fossil
  if f then
    local Ow = package.loaded["src.core.game3.ow_sprites"]
    local Constants = require("src.core.game3.constants")
    local ok, gid = pcall(function()
      return Constants.of(Constants.versionOf(Rse().session())):require("event_objects", "OBJ_EVENT_GFX_FOSSIL")
    end)
    local spr = ok and Ow and Ow.getDraw and Ow.getDraw(gid)
    if spr and spr.quads[0] then
      love.graphics.setColor(1, 1, 1, 1 - math.min(1, f.idx / 0x100))
      love.graphics.draw(spr.image, spr.quads[0], 128, f.y - spr.height / 2)
      love.graphics.setColor(1, 1, 1, 1)
    end
  end
end

MirageTower.BY_NAME = {
  SetMirageTowerVisibility = function()
    MirageTower.setVisibility()
    return false
  end,
  DoMirageTowerCeilingCrumble = function(ctx)
    local done = false
    MirageTower.ceilingCrumble(function() done = true end)
    return waitFor(ctx, function() return done end)
  end,
  StartPlayerDescendMirageTower = function(ctx)
    local done = false
    MirageTower.playerDescend(MirageTower.fallingPlayerId(), function() done = true end)
    return waitFor(ctx, function() return done end)
  end,
  StartMirageTowerShake = function()
    MirageTower.startShake()
    return false
  end,
  StartMirageTowerDisintegration = function(ctx)
    local done = false
    MirageTower.startDisintegration(function() done = true end)
    return waitFor(ctx, function() return done end)
  end,
  StartMirageTowerFossilFallAndSink = function(ctx)
    local done = false
    MirageTower.startFossilFall(function() done = true end)
    return waitFor(ctx, function() return done end)
  end,
}

return MirageTower
