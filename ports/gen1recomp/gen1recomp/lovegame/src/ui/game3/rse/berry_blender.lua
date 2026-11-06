local bit = require("bit")
local band, bor = bit.band, bit.bor

local Kit = require("src.ui.game3.rse.gc_kit")
local Ppu = require("src.core.game3.gba_ppu")
local Sprites = require("src.core.game3.gba_sprites")
local Machine = require("src.ui.game3.rse.gba_machine")
local Affine = require("src.core.game3.bg_affine")
local B = require("src.core.game3.rse.berry_blender")
local CacheBlob = require("src.import.CacheBlob")

local UI = {}
UI.__index = UI

UI.STACK_ID = "rse_berry_blender"

local W, H = 240, 160
local SC = B.SCORE
local CMD = B.CMD

-- pokeemerald/src/berry_blender.c:90
local PROGRESS_BAR_FILLED_TOP = 0x80E9
local PROGRESS_BAR_FILLED_BOTTOM = 0x80F9
local PROGRESS_BAR_EMPTY_TOP = 0x80E1
local PROGRESS_BAR_EMPTY_BOTTOM = 0x80F1
local RPM_DIGIT = 0x8072
-- pokeemerald/src/berry_blender.c:3368
local RPM_CELLS = { 0x458 / 2, 0x45A / 2, 0x45C / 2, 0x460 / 2, 0x462 / 2 }

-- pokeemerald/src/berry_blender.c:112
local WIN_MSG, WIN_RESULTS = 4, 5

-- pokeemerald/src/berry_blender.c:3849
local TEXT_CASES = {
  [0] = { 2, 1, 3 }, [1] = { 2, nil, 3 }, [2] = { 4, nil, 5 }, [3] = { 2, 1, 3 },
}

function UI.new(opts)
  opts = opts or {}
  local self = setmetatable({}, UI)
  self.opts = opts
  self.session = opts.session
  self.man = opts.manifest or B.manifest()
  self.pack = opts.berries or B.berriesPack()
  self.random = opts.random or B.defaultRandom
  self.vblankRandom = opts.vblankRandom
  self.headless = opts.headless or Kit.headless()
  self.sound = opts.sound or Kit.sound({ muted = opts.headless })
  self.var8004 = opts.opponents or 1
  self.linkSession = opts.linkSession
  self.linked = self.linkSession ~= nil
  self.linkBerryWait = false
  self.linkBerryItems = nil
  self.linkPendingPressed = nil
  self.onDone = opts.onDone
  self.frames = 0
  self.done = false
  self.texts = self.man.texts
  self.irs = self.man.irs or {}
  self:begin()
  return self
end

function UI:rand() return band(self.random(), 0xFFFF) end
function UI:joyNew(mask) return Kit.joyNew(self.m, mask) end

-- pokeemerald/src/berry_blender.c:1047
function UI:begin()
  self.m = Kit.newMachine()
  self.wins = {}
  self.printer = nil
  self.yesNo = nil
  self.fastFade = nil
  self.game = nil
  self.state = 0
  self.loadGfxState = 0
  self.cb = "load"
end

-- pokeemerald/src/berry_blender.c:1016
function UI:initBgs()
  local p = self.m.ppu
  local tiles = self:readCache(self.man.outerTiles)
  self.outer = Kit.layer(tiles, 32, 32, { headless = self.headless })
  for i, e in ipairs(self.man.outerMap) do self.outer:putIndex(i - 1, e) end
  p:setBg(0, 0, nil)
  p:setBg(1, 1, nil)
  p:setBg(2, 0, nil)
  if not self.headless then
    self.centerLayer = Machine.layer(self.man.center)
  end
  -- pokeemerald/src/berry_blender.c:1073
  p:set("DISPCNT", Ppu.DISPCNT_MODE_1)
  self.bgShown = { [0] = false, false, false }
  self.msgKeep, self.printer = nil, nil
  self.bg2Priority = 0
end

function UI:readCache(path)
  local data = self.opts.cache and self.opts.cache.read and self.opts.cache:read(path)
  if not data then
    local ok, Dataset = pcall(require, "src.core.game3.dataset")
    if ok and Dataset and Dataset.cache then data = Dataset.cache():read(path) end
  end
  if not data and love and love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(path) then
    data = CacheBlob.readFs(path)
  end
  return assert(data, "berry_blender: missing " .. tostring(path))
end

function UI:showBg(i)
  local p = self.m.ppu
  self.bgShown[i] = true
  if i == 1 then p:setBg(1, 1, self.outer.layer) end
  if i == 2 then p:setBg(2, self.bg2Priority or 0, self.centerLayer, false) end
  p:set("DISPCNT", bor(p:get("DISPCNT"), Ppu.DISPCNT_OBJ_ON, Ppu.DISPCNT_OBJ_1D_MAP,
    i == 1 and Ppu.DISPCNT_BG1_ON or 0, i == 2 and Ppu.DISPCNT_BG2_ON or 0, i == 0 and Ppu.DISPCNT_BG0_ON or 0))
end

-- pokeemerald/src/berry_blender.c:957
function UI:loadGfx()
  local s = self.loadGfxState
  local p = self.m.ppu
  if s == 1 then
    p.palette:load(self.man.palettes.center, 0, 128)
  elseif s == 7 then
    p.palette:load(self.man.palettes.outer, 8 * 16, 16)
  elseif s == 9 then
    for _, pal in ipairs(self.man.palettes.sprites) do p.sprites:loadPalette(pal.tag, pal.colors) end
    self.loadGfxState = 0
    return true
  end
  self.loadGfxState = s + 1
  return false
end

function UI:createSprite(entry, x, y, sub, callback)
  local id, s = Kit.createSprite(self.m, { entry = entry, paletteTag = entry.paletteTag, priority = entry.priority,
    affineMode = entry.affineMode, objMode = entry.objMode, affineAnims = entry.affineAnims, callback = callback }, x, y, sub)
  return id, s
end

function UI:sprite(id) return self.m.ppu.sprites.sprites[id] end

function UI:destroySprite(s) Kit.destroySprite(self.m, s) end

-- pokeemerald/src/berry_blender.c:3443
function UI:arrowCb()
  return function(s)
    local g = self.game
    s.x2 = -(g and g.bg_X or 0)
    s.y2 = -(g and g.bg_Y or 0)
  end
end

function UI:createArrows(key)
  local T = self.man.tables
  self[key] = {}
  for i = 0, B.MAX_PLAYERS - 1 do
    local pos = T.playerArrowPos[i + 1]
    local id = self:createSprite(self.man.sprites.arrow, pos[1], pos[2], 1, self:arrowCb())
    Sprites.startAnim(self:sprite(id), i + 8)
    self[key][i] = id
  end
end

-- pokeemerald/src/berry_blender.c:3097
function UI:drawCenter()
  local g = self.game
  local bx, by = g and g.bg_X or 0, g and g.bg_Y or 0
  self.affine = {
    texX = (W / 2) * 256, texY = (H / 2) * 256,
    scrX = W / 2 - bx, scrY = H / 2 - by,
    sx = g and g.centerScale or 80, sy = g and g.centerScale or 80,
    alpha = g and g.arrowPos or 0,
  }
end

-- pokeemerald/src/berry_blender.c:945
function UI:vblank()
  local p = self.m.ppu
  local g = self.game
  local bx, by = g and g.bg_X or 0, g and g.bg_Y or 0
  p:set("BG1HOFS", band(bx, 0xFFFF))
  p:set("BG1VOFS", band(by, 0xFFFF))
  p:set("BG0HOFS", band(bx, 0xFFFF))
  p:set("BG0VOFS", band(by, 0xFFFF))
  if self.affine then p:setAffine(2, Affine.bgAffineSet(self.affine)) end
  p:vblank()
end

function UI:animate()
  local sp = self.m.ppu.sprites
  sp:animateAll()
  if self.berryPicId then
    for i = 0, Sprites.MAX - 1 do
      local s = sp.sprites[i]
      if s.inUse and s.berryPic then s.frame = self.berryPicId end
    end
  end
  Kit.buildOam(self.m)
end

function UI:updatePaletteFade()
  local ff = self.fastFade
  if ff then
    if ff.steps > 0 then
      local pal = self.m.ppu.palette
      for i = 0, 511 do
        local c = pal.faded[i] or 0
        local r, gg, b = band(c, 31), band(bit.rshift(c, 5), 31), band(bit.rshift(c, 10), 31)
        r, gg, b = math.max(0, r - 2), math.max(0, gg - 2), math.max(0, b - 2)
        pal.faded[i] = bor(r, bit.lshift(gg, 5), bit.lshift(b, 10))
      end
      ff.steps = ff.steps - 1
      ff.level = math.min(16, ff.level + 1)
    else
      ff.active = false
    end
    return
  end
  self.m.ppu.palette:update()
end

function UI:fadeActive()
  if self.fastFade then return self.fastFade.active end
  return self.m.ppu.palette:fadeActive()
end

function UI:beginFade(from, to)
  self.fastFade = nil
  self.m.ppu.palette:beginFade(0xFFFFFFFF, 0, from, to, 0)
end

function UI:fadeLevel()
  if self.fastFade then return self.fastFade.level end
  return self.m.ppu.palette.y or 0
end

-- pokeemerald/src/berry_blender.c:1601
function UI:measure(text)
  if self.headless then return 0 end
  local ok, w = pcall(Kit.measure, text)
  return ok and w or 0
end

function UI:addTextPrinter(win, text, x, y, caseId)
  local w = self.wins[win]
  if not w then return end
  if caseId ~= 3 then w.prints = {} end
  w.fill = TEXT_CASES[caseId][2] ~= nil
  w.prints[#w.prints + 1] = { text = text, x = x, y = y, caseId = caseId }
end

function UI:openWindow(win)
  local t = self.man.windows[win + 1]
  self.wins[win] = { left = t.left, top = t.top, width = t.width, height = t.height, prints = {}, shown = false }
  return self.wins[win]
end

function UI:putWindow(win)
  if self.wins[win] then self.wins[win].shown = true end
end

-- pokeemerald/src/berry_blender.c:1601
function UI:printPlayerNames()
  local g = self.game
  for i = 0, B.MAX_PLAYERS - 1 do
    local pid = g.arrowIdToPlayerId[i]
    if pid ~= B.NO_PLAYER then
      self.arrowIds[pid] = self.arrowIds2[i]
      Sprites.startAnim(self:sprite(self.arrowIds[pid]), i)
      local text = g.playerNames[pid] or ""
      local x = math.floor((0x38 - self:measure(text)) / 2)
      self:openWindow(i)
      self:addTextPrinter(i, text, x, 1, pid == g.localPlayerId and 2 or 1)
      self:putWindow(i)
    end
  end
end

-- pokeemerald/src/berry_blender.c:3883
function UI:printMessage(key, ir)
  if not self.printer then
    local SceneKit = require("src.ui.game3.rse.scene_kit")
    local Options = require("src.core.game3.options")
    local okS, speed = pcall(Options.textSpeed, self.session)
    local opt = okS and tonumber(speed) or 1
    self.printer = SceneKit.printer(ir or self.irs[key], { speed = SceneKit.textSpeedDelay(opt), textSpeedOption = opt,
      linePitch = UI.linePitch() })
    self.msgKeep = nil
    self.printer:run({ new = {}, held = {} })
    return false
  end
  self.printer:run(self.inp or { new = {}, held = {} })
  if not self.printer:isActive() then
    self.msgKeep = self.printer
    self.printer = nil
    return true
  end
  return false
end

-- pokeemerald/src/berry_blender.c:3880
function UI.linePitch()
  if UI._pitch then return UI._pitch end
  local m = B.loadLua("data/generated/gba/chrome/fonts/metrics.lua")
  local f = m and m[1]
  UI._pitch = f and ((f.maxLetterHeight or 16) + 1) or nil
  return UI._pitch
end

local function frameCall(self)
  local fn = self["cb_" .. self.cb]
  if fn then fn(self) end
end

-- pokeemerald/src/berry_blender.c:1061
function UI:cb_load()
  local st = self.state
  if st == 0 then
    self.m.ppu.sprites:resetData()
    self.m.ppu.sprites:freeAllPalettes()
    self:initBgs()
    self.game = B.new({ tables = self.man.tables, berries = self.pack.berries, opponents = self.var8004,
      blendMaster = self.opts.blendMaster, playerName = self.opts.playerName, opponentNames = self.man.opponentNames,
      random = self.linkSession and function() return self.linkSession:random() end or function() return self:rand() end,
      itemIds = self.opts.itemIds, version = self.opts.version, linked = self.linked,
      localPlayerId = self.linkSession and self.linkSession.localSeat or 0,
      numPlayers = self.opts.numPlayers, playerNames = self.opts.playerNames })
    self.wins = {}
    self.state = 1
    self:drawCenter()
  elseif st == 1 then
    if self:loadGfx() then
      self.arrowIds = {}
      self:createArrows("arrowIds")
      self.state = 2
    end
  elseif st == 2 then
    self:beginFade(16, 0)
    self:drawCenter()
    self.state = 3
  elseif st == 3 then
    self:showBg(0)
    self:showBg(1)
    if not self:fadeActive() then self.state = 4 end
  elseif st == 4 then
    if self:printMessage("berryBlenderStart") then self.state = 5 end
  elseif st == 5 then
    self:beginFade(0, 16)
    self.state = 6
  elseif st == 6 then
    if not self:fadeActive() then
      self.state = 7
      self.msgShown = false
      self:chooseBerry()
    end
  end
  self:animate()
  self:updatePaletteFade()
end

-- pokeemerald/src/item_menu.c:580
function UI:chooseBerry()
  self.hidden = true
  local function picked(itemId)
    self.hidden = false
    self.itemId = tonumber(itemId) or 0
    if self.itemId == 0 then
      if self.linkSession then self.linkSession:abort("berry_selection_cancelled") end
      self:exitToField()
      return
    end
    if self.linkSession then
      self.linkBerryWait = true
      return
    end
    self:startBlender()
  end
  if self.opts.chooseBerry then return self.opts.chooseBerry(picked) end
  local okR, Rse = pcall(require, "src.core.game3.rse.init")
  local bag = okR and Rse.system("bag", "ChooseBerryForMachine") or nil
  if bag and bag.chooseBerry then return bag.chooseBerry(nil, picked, "blender") end
  picked(UI.firstBerry(self.session))
end

function UI.firstBerry(session)
  session = B.session(session)
  local okB, Bag = pcall(require, "src.core.game3.bag")
  if not (okB and session and session.bag) then return 0 end
  local okI, ids = pcall(B.itemIds)
  if not okI then return 0 end
  local pocket = require("src.core.game3.items_data").pocketOf(ids.first)
  local ok, rows = pcall(Bag.listPocket, session.bag, pocket)
  if not ok or type(rows) ~= "table" then return 0 end
  for _, r in ipairs(rows) do
    local id = type(r) == "table" and (r.id or r.item) or r
    if tonumber(id) then return tonumber(id) end
  end
  return 0
end

-- pokeemerald/src/berry_blender.c:1271
function UI:startBlender()
  self.state = 0
  self.cb = "startLocal"
end

-- pokeemerald/src/berry_blender.c:1156
function UI:berryCb()
  return function(s)
    local d = s.data
    d[1] = d[1] + d[6]
    d[2] = d[2] - d[4]
    d[2] = d[2] + d[7]
    d[0] = d[0] + d[7]
    d[4] = d[4] - 1
    if d[0] < d[2] then
      d[4] = d[3] - 1
      d[3] = d[4]
      d[5] = d[5] + 1
      if d[5] > 3 then
        self:destroySprite(s)
        return
      end
      self.sound:se("SE_BALL_TRAY_EXIT")
    end
    s.x = d[1]
    s.y = d[2]
  end
end

-- pokeemerald/src/berry_blender.c:1199
function UI:createBerrySprite(itemId, slot)
  local berryId = itemId - self.game.ids.first
  local sp = self.m.ppu.sprites
  local tag = self.man.berry.paletteTag
  local idx = sp:indexOfPaletteTag(tag)
  if idx ~= 0xFF then sp.paletteTags[idx] = Sprites.TAG_NONE end
  sp:loadPalette(tag, self.man.palettes.berries[berryId + 1])
  self.berryPicId = berryId
  local id, s = self:createSprite(self.man.berry, 0, 80, 0)
  if not s then return end
  s.berryPic = true
  if band(slot, 1) == 1 then sp:startAffineAnim(s, 1) end
  local D = self.man.tables.berrySpriteData[slot + 1]
  local d = s.data
  d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7] = D[2], D[1], D[2], D[3], 10, 0, D[4], D[5]
  s.callback = self:berryCb()
end

-- pokeemerald/src/berry_blender.c:3225
function UI:countdownCb()
  return function(s)
    local d = s.data
    if d[0] == 0 then
      d[1] = d[1] + 8
      if d[1] > H / 2 + 8 then
        d[1] = H / 2 + 8
        d[0] = 1
        self.sound:se("SE_BALL_BOUNCE_1")
      end
    elseif d[0] == 1 then
      d[2] = d[2] + 1
      if d[2] > 20 then
        d[0] = 2
        d[2] = 0
      end
    elseif d[0] == 2 then
      d[1] = d[1] + 4
      if d[1] > H + 16 then
        d[3] = d[3] + 1
        if d[3] == 3 then
          self:destroySprite(s)
          self:createSprite(self.man.sprites.start, 120, -20, 2, self:startCb())
          return
        end
        d[0] = 0
        d[1] = -16
        Sprites.startAnim(s, d[3])
      end
    end
    s.y2 = d[1]
  end
end

-- pokeemerald/src/berry_blender.c:3272
function UI:startCb()
  return function(s)
    local d = s.data
    if d[0] == 0 then
      d[1] = d[1] + 8
      if d[1] > 92 then
        d[1] = 92
        d[0] = 1
        self.sound:se("SE_PIN")
      end
    elseif d[0] == 1 then
      d[2] = d[2] + 1
      if d[2] > 20 then d[0] = 2 end
    elseif d[0] == 2 then
      d[1] = d[1] + 4
      if d[1] > H + 16 then
        self.state = self.state + 1
        self:destroySprite(s)
        return
      end
    end
    s.y2 = d[1]
  end
end

-- pokeemerald/src/berry_blender.c:1632
function UI:cb_startLocal()
  local st = self.state
  local g = self.game
  local T = self.man.tables
  if st == 0 then
    self.m.ppu.sprites:resetData()
    self.m.ppu.sprites:freeAllPalettes()
    self.m.tasks:reset()
    self:initBgs()
    self.wins = {}
    g.speed, g.arrowPos, g.maxRPM, g.bg_X, g.bg_Y = 0, 0, 0, 0, 0
    if self.linkSession then
      if not g:setLinkBerries(self.linkBerryItems) then
        self:exitToField()
        return
      end
    else
      g:setBerries(self.itemId)
    end
    g.playAgainState = 0
    self.loadGfxState = 0
    self.state = 1
  elseif st == 1 then
    if self:loadGfx() then
      self.state = 2
      self:drawCenter()
    end
  elseif st == 2 then
    self.arrowIds, self.arrowIds2 = {}, nil
    self:createArrows("arrowIds2")
    self.state = 3
  elseif st == 3 then
    self:beginFade(16, 0)
    self.state = 4
    g.framesToWait = 0
  elseif st == 4 then
    g.framesToWait = g.framesToWait + 1
    if g.framesToWait == 2 then
      self:showBg(0)
      self:showBg(1)
    end
    if not self:fadeActive() then self.state = 8 end
  elseif st == 8 then
    self.state = 11
    self.playerToThrowBerry = 0
  elseif st == 11 then
    local map = T.playerIdMap[g.numPlayers - 1]
    for i = 0, B.MAX_PLAYERS - 1 do
      if self.playerToThrowBerry == map[i + 1] then
        self:createBerrySprite(g.chosenItemId[self.playerToThrowBerry], i)
        break
      end
    end
    g.framesToWait = 0
    self.state = 12
    self.playerToThrowBerry = self.playerToThrowBerry + 1
  elseif st == 12 then
    g.framesToWait = g.framesToWait + 1
    if g.framesToWait > 60 then
      if self.playerToThrowBerry >= g.numPlayers then
        g:beginFall()
        self.state = 13
      else
        self.state = 11
      end
      g.framesToWait = 0
    end
  elseif st == 13 then
    self.state = 14
    g:setPlayerIdMaps()
    self.sound:se("SE_FALL")
    self:drawCenter()
    self:showBg(2)
  elseif st == 14 then
    if g:fallFrame() then
      self.state = 15
      self.bg2Priority = 2
      self.m.ppu:setBg(2, 2, self.centerLayer, false)
      self.sound:se("SE_TRUCK_DOOR")
      self:printPlayerNames()
    end
    self:drawCenter()
  elseif st == 15 then
    if g:landShakeFrame() then self.state = 16 end
    self:drawCenter()
  elseif st == 16 then
    self:createSprite(self.man.sprites.countdown, 120, -16, 3, self:countdownCb())
    self.state = 17
  elseif st >= 18 and st <= 20 then
    self.state = st + 1
  elseif st == 21 then
    g:startPlay()
    self:handleEvents()
    self.cb = "play"
    self.state = 0
    local cur = self.sound:mapMusic()
    local cycling = self.sound:id("MUS_CYCLING")
    if cur ~= cycling then self.savedMusic = cur end
    self.sound:playMapMusic("MUS_CYCLING")
    self.sound:se("SE_BERRY_BLENDER")
  end
  self.m.tasks:run(self)
  self:animate()
  self:updatePaletteFade()
end

-- pokeemerald/src/berry_blender.c:3313
function UI:updateProgressBar(value)
  local L = self.outer
  local filled = math.floor(value * 64 / B.MAX_PROGRESS_BAR)
  local full = math.floor(filled / 8)
  local i = 0
  while i < full do
    L:putIndex(11 + i, PROGRESS_BAR_FILLED_TOP)
    L:putIndex(43 + i, PROGRESS_BAR_FILLED_BOTTOM)
    i = i + 1
  end
  local sub = filled % 8
  if sub ~= 0 then
    L:putIndex(11 + i, sub + PROGRESS_BAR_EMPTY_TOP)
    L:putIndex(43 + i, sub + PROGRESS_BAR_EMPTY_BOTTOM)
    i = i + 1
  end
  while i < 8 do
    L:putIndex(11 + i, PROGRESS_BAR_EMPTY_TOP)
    L:putIndex(43 + i, PROGRESS_BAR_EMPTY_BOTTOM)
    i = i + 1
  end
end

-- pokeemerald/src/berry_blender.c:3352
function UI:drawRPM()
  local rpm = self.game.currentRPM or 0
  local digits = {}
  for i = 0, 4 do
    digits[i] = rpm % 10
    rpm = math.floor(rpm / 10)
  end
  local L = self.outer
  L:putIndex(RPM_CELLS[1], digits[4] + RPM_DIGIT)
  L:putIndex(RPM_CELLS[2], digits[3] + RPM_DIGIT)
  L:putIndex(RPM_CELLS[3], digits[2] + RPM_DIGIT)
  L:putIndex(RPM_CELLS[4], digits[1] + RPM_DIGIT)
  L:putIndex(RPM_CELLS[5], digits[0] + RPM_DIGIT)
end

-- pokeemerald/src/berry_blender.c:3194
function UI:scoreSymbolCb(best)
  return function(s)
    local d = s.data
    d[0] = d[0] + 1
    if best then
      s.y2 = -(d[0] * 2)
      if s.y2 < -12 then s.y2 = -12 end
    else
      s.y2 = -math.floor(d[0] / 3)
    end
    if s.animEnded then self:destroySprite(s) end
  end
end

-- pokeemerald/src/berry_blender.c:3159
function UI:particleCb()
  return function(s)
    local d = s.data
    d[2] = d[2] + d[0]
    d[3] = d[3] + d[1]
    s.x2 = B.cdiv(d[2], 8)
    s.y2 = B.cdiv(d[3], 8)
    if s.animEnded then self:destroySprite(s) end
  end
end

-- pokeemerald/src/berry_blender.c:2011
function UI:scoreSprite(ev)
  local T = self.man.tables
  local pos, q = T.playerArrowPos[ev.arrowId + 1], T.playerArrowQuadrant[ev.arrowId + 1]
  local best = ev.cmd == CMD.BEST
  local id, s = self:createSprite(self.man.sprites.score, pos[1] - 10 * q[1], pos[2] - 10 * q[2], 1,
    self:scoreSymbolCb(best))
  if s then
    if best then
      Sprites.startAnim(s, B.SCOREANIM.BEST_FLASH)
      self.sound:se("SE_ICE_STAIRS")
    elseif ev.cmd == CMD.GOOD then
      Sprites.startAnim(s, B.SCOREANIM.GOOD)
      self.sound:se("SE_SUCCESS")
    else
      Sprites.startAnim(s, B.SCOREANIM.MISS)
      self.sound:se("SE_FAILURE")
    end
  end
  for _, p in ipairs(ev.particles or {}) do
    local _, ps = self:createSprite(self.man.sprites.particles, p.x, p.y, 1, self:particleCb())
    if ps then ps.data[0], ps.data[1] = p.dx, p.dy end
  end
  return id
end

function UI:handleEvents()
  local g = self.game
  for _, ev in ipairs(g:takeEvents()) do
    if ev.kind == "score" then
      self:scoreSprite(ev)
    elseif ev.kind == "flash" then
      local sid = self.arrowIds[g.arrowIdToPlayerId[ev.arrowId]]
      if sid then Sprites.startAnim(self:sprite(sid), ev.arrowId + 4) end
    elseif ev.kind == "progress" then
      self:updateProgressBar(ev.value)
    elseif ev.kind == "pitch" then
      self.sePitch = ev.value
      if self.sound.setSePitch then self.sound:setSePitch("SE_BERRY_BLENDER", ev.value) end
    elseif ev.kind == "tempo" then
      self.bgmTempo = ev.value
      if self.sound.setBgmTempo then self.sound:setBgmTempo(ev.value) end
    elseif ev.kind == "stopSe" then
      self.sound:stopSe("SE_BERRY_BLENDER")
    end
  end
end

-- pokeemerald/src/berry_blender.c:2212
function UI:cb_play()
  local g = self.game
  local pressed = self:joyNew(Kit.A)
  local remoteScores
  if self.linkSession then
    if self.linkPendingPressed == nil then self.linkPendingPressed = pressed end
    local waitError
    remoteScores, waitError = self.linkSession:exchangeFrame(g.gameFrameTime, g:previewInputScore(self.linkPendingPressed))
    if not remoteScores then
      if waitError == "timeout" then self.linkSession:abort(waitError) end
      if waitError == "abort" or waitError == "timeout" or not self.linkSession:isOpen() then self:exitToField() end
      return
    end
    pressed = self.linkPendingPressed
    self.linkPendingPressed = nil
  end
  local ended = g:playFrame(pressed, function() self:drawCenter() end, remoteScores)
  self:handleEvents()
  self:drawRPM()
  if ended then
    self.cb = "end"
    self.state = 0
  end
  self.m.tasks:run(self)
  self:animate()
  self:updatePaletteFade()
end

-- pokeemerald/src/berry_blender.c:3665
function UI:printRanking()
  local g = self.game
  local st = self.rankState or 0
  if st == 0 then
    self.rankState = 1
    g.framesToWait = 255
  elseif st == 1 then
    g.framesToWait = g.framesToWait - 10
    if g.framesToWait < 0 then
      g.framesToWait = 0
      self.rankState = 2
    end
  elseif st == 2 then
    g.framesToWait = g.framesToWait + 1
    if g.framesToWait > 20 then
      g.framesToWait = 0
      self.rankState = 3
    end
  elseif st == 3 then
    local w = self:openWindow(WIN_RESULTS)
    w.frame = true
    local t = self.texts
    self:addTextPrinter(WIN_RESULTS, t.ranking, math.floor((168 - self:measure(t.ranking)) / 2), 1, 0)
    self.scoreIcons = {}
    local _, best = self:createSprite(self.man.sprites.score, 128, 52, 0)
    Sprites.startAnim(best, B.SCOREANIM.BEST_STATIC)
    local _, good = self:createSprite(self.man.sprites.score, 160, 52, 0)
    local _, miss = self:createSprite(self.man.sprites.score, 192, 52, 0)
    Sprites.startAnim(miss, B.SCOREANIM.MISS)
    self.scoreIcons = { best, good, miss }
    local places = g:sortScores()
    local y = 41
    for i = 0, g.numPlayers - 1 do
      local place = places[i]
      self:addTextPrinter(WIN_RESULTS, tostring(i + 1) .. t.dot .. t.space .. (g.playerNames[place] or ""), 0, y, 3)
      self:addTextPrinter(WIN_RESULTS, B.rightAlign(g.scores[place][SC.BEST], 3), 78, y, 3)
      self:addTextPrinter(WIN_RESULTS, B.rightAlign(g.scores[place][SC.GOOD], 3), 78 + 32, y, 3)
      self:addTextPrinter(WIN_RESULTS, B.rightAlign(g.scores[place][SC.MISS], 3), 78 + 64, y, 3)
      y = y + 16
    end
    self:putWindow(WIN_RESULTS)
    g.framesToWait = 0
    self.rankState = 4
  elseif st == 4 then
    g.framesToWait = g.framesToWait + 1
    if g.framesToWait > 20 then self.rankState = 5 end
  elseif st == 5 then
    if self:joyNew(Kit.A) then
      self.sound:se("SE_SELECT")
      self.rankState = 6
    end
  elseif st == 6 then
    self.rankState = 0
    return true
  end
  return false
end

-- pokeemerald/src/berry_blender.c:3791
function UI:fanfareTask()
  local started = false
  self.m.tasks:create(function(tid)
    if not started then
      self.sound:fanfare("MUS_LEVEL_UP")
      started = true
    end
    local A = not self.headless and package.loaded["src.core.game3.audio"] or nil
    local finished = true
    if A and A.isFanfareFinished then
      local ok, r = pcall(A.isFanfareFinished)
      finished = not ok or r ~= false
    end
    if finished then
      if self.savedMusic and self.savedMusic ~= 0 then self.sound:playMapMusic(self.savedMusic) end
      self.m.tasks:destroy(tid)
    end
  end, 6)
end

-- pokeemerald/src/berry_blender.c:3455
function UI:printResults()
  local g = self.game
  local st = self.resState or 0
  local t = self.texts
  if st == 0 then
    self.resState = 1
    g.framesToWait = 17
  elseif st == 1 then
    g.framesToWait = g.framesToWait - 10
    if g.framesToWait < 0 then
      g.framesToWait = 0
      self.resState = 2
    end
  elseif st == 2 then
    g.framesToWait = g.framesToWait + 1
    if g.framesToWait > 20 then
      for _, s in ipairs(self.scoreIcons or {}) do self:destroySprite(s) end
      self.scoreIcons = nil
      g.framesToWait = 0
      self.resState = 3
    end
  elseif st == 3 then
    self:addTextPrinter(WIN_RESULTS, t.blendingResults, math.floor((0xA8 - self:measure(t.blendingResults)) / 2), 1, 0)
    local y = g.numPlayers == B.MAX_PLAYERS and 17 or 21
    for i = 0, g.numPlayers - 1 do
      local place = g.playerPlaces[i]
      self:addTextPrinter(WIN_RESULTS, tostring(i + 1) .. t.dot .. t.space .. (g.playerNames[place] or ""), 8, y, 3)
      self:addTextPrinter(WIN_RESULTS, (g.blendedBerries[place].name or "") .. t.spaceBerry, 0x54, y, 3)
      y = y + 16
    end
    self:addTextPrinter(WIN_RESULTS, t.maximumSpeed, 0, 0x51, 3)
    local speed = B.maxSpeedText(g.maxRPM, t)
    self:addTextPrinter(WIN_RESULTS, speed, 0xA8 - self:measure(speed), 0x51, 3)
    self:addTextPrinter(WIN_RESULTS, t.time, 0, 0x61, 3)
    local time = B.timeText(g.gameFrameTime, t)
    self:addTextPrinter(WIN_RESULTS, time, 0xA8 - self:measure(time), 0x61, 3)
    g.framesToWait = 0
    self.resState = 4
  elseif st == 4 then
    if self:joyNew(Kit.A) then self.resState = 5 end
  elseif st == 5 then
    self.wins[WIN_RESULTS] = nil
    local block = g:calculate()
    self.madeText = B.madeText(block, t, self.pack.pokeblockNames or {}):gsub("POKéBLOCK", "{POKEBLOCK}")
    self:fanfareTask()
    g:finishBlend(self.session)
    self.resState = 6
  elseif st == 6 then
    if self:printMessage(nil, self:madeIr()) then
      g:tryUpdateRecord(self.session)
      self.resState = 0
      return true
    end
  end
  return false
end

function UI:madeIr()
  local ir = {}
  local first = true
  for line in (self.madeText .. "\n"):gmatch("([^\n]*)\n") do
    if not first then ir[#ir + 1] = { t = "nl" } end
    ir[#ir + 1] = { t = "text", s = line }
    first = false
  end
  local nl = self.irs.newParagraph or {}
  for _, seg in ipairs(nl) do
    if seg.t ~= "eos" then ir[#ir + 1] = seg end
  end
  return ir
end

-- pokeemerald/src/berry_blender.c:2554
function UI:cb_end()
  local g = self.game
  local st = g.gameEndState
  if st < 5 then
    g:endFrame(function() self:drawCenter() end)
    self:handleEvents()
    self:drawRPM()
    self:animate()
    self:updatePaletteFade()
    return
  end
  if st < 3 then self:drawCenter() end
  if st == 5 then
    if self:printRanking() then g.gameEndState = 6 end
  elseif st == 6 then
    if self:printResults() then
      B.incrementGameStat(self.session, self.opts.nativeRS and self.linked and B.GAME_STAT_POKEBLOCKS_WITH_FRIENDS or B.GAME_STAT_POKEBLOCKS)
      g.gameEndState = 7
    end
  elseif st == 7 then
    if self:printMessage("wouldLikeToBlendAnotherBerry") then g.gameEndState = 8 end
  elseif st == 8 then
    g.gameEndState = 9
  elseif st == 9 then
    local SceneKit = require("src.ui.game3.rse.scene_kit")
    local yw = self.man.yesNoWindow
    self.yesNo = SceneKit.yesNo(yw.left, yw.top, { frameType = self.opts.frameType or 0 })
    g.gameEndState = 10
  elseif st == 10 then
    local r = self.yesNo:input(self.inp or { new = {} })
    if r ~= nil then
      if r ~= -1 then self.sound:se("SE_SELECT") end
      self.yesNo = nil
      self.yesNoAnswer = (r == 0) and 0 or 1
      g.gameEndState = 11
    end
  elseif st == 11 then
    local P = B.PLAY_AGAIN
    if self.yesNoAnswer == 0 then
      if not UI.hasBerries(self.session) then
        g.playAgainState = P.CANT_PLAY_NO_BERRIES
      elseif require("src.core.game3.rse.pokeblock").firstFreeSlot(self.session) == -1 then
        g.playAgainState = P.CANT_PLAY_NO_PKBLCK_SPACE
      else
        g.playAgainState = P.YES
      end
    else
      g.playAgainState = P.NO
    end
    g.gameEndState = 12
  elseif st == 12 then
    self.cb = "again"
    g.gameEndState = 0
    self.state = 0
  end
  g:restoreBgCoords()
  g:updateRPM()
  self:drawRPM()
  self.m.tasks:run(self)
  self:animate()
  self:updatePaletteFade()
end

function UI.hasBerries(session)
  return UI.firstBerry(session) ~= 0
end

-- pokeemerald/src/berry_blender.c:2942
function UI:cb_again()
  local g = self.game
  local P = B.PLAY_AGAIN
  local st = g.gameEndState
  if st == 0 then
    if self.linkSession then
      local decision, waitError = self.linkSession:exchangeContinue(g.playAgainState)
      if not decision then
        if waitError == "timeout" then self.linkSession:abort(waitError) end
        if waitError == "abort" or waitError == "timeout" or not self.linkSession:isOpen() then self:exitToField() end
        return
      end
      if not decision.continue then
        self.linkEndReason = decision
        g.playAgainState = P.NO
        if decision.reason == P.CANT_PLAY_NO_BERRIES or decision.reason == P.CANT_PLAY_NO_PKBLCK_SPACE then
          local who = tostring(self.opts.playerNames and self.opts.playerNames[(decision.seat or 0) + 1] or "")
          local source
          if decision.reason == P.CANT_PLAY_NO_BERRIES then
            source = who .. " has no BERRIES to put in\nthe BERRY BLENDER."
          else
            source = who .. "'s POKEBLOCK CASE is full.\\p"
          end
          self.linkEndMessage = require("src.core.game3.scripting.text_ir").fromAscii(source)
          g.gameEndState = 3
          return
        end
      else
        g.playAgainState = P.YES
      end
    end
    if g.playAgainState == P.YES or g.playAgainState == P.NO then g.gameEndState = 9 end
    if g.playAgainState == P.CANT_PLAY_NO_BERRIES then g.gameEndState = 2 end
    if g.playAgainState == P.CANT_PLAY_NO_PKBLCK_SPACE then g.gameEndState = 1 end
  elseif st == 1 then
    g.gameEndState = 3
    self.againKey = "yourPokeblockCaseIsFull"
  elseif st == 2 then
    g.gameEndState = 3
    self.againKey = "runOutOfBerriesForBlending"
  elseif st == 3 then
    local shown = self.linkEndMessage and self:printMessage(nil, self.linkEndMessage) or self:printMessage(self.againKey)
    if shown then self.linkEndMessage = nil; g.gameEndState = 9 end
  elseif st == 9 then
    self.fastFade = { active = true, steps = 16, level = 0 }
    g.gameEndState = 10
  elseif st == 10 then
    if not self:fadeActive() then
      if g.playAgainState == P.YES then
        if self.linkSession then self.linkSession:nextRound() end
        self:begin()
        return
      end
      self:exitToField()
      return
    end
  end
  self.m.tasks:run(self)
  self:animate()
  self:updatePaletteFade()
end

-- pokeemerald/src/overworld.c:1684
function UI:exitToField()
  self.done = true
  self.result = { pokeblock = self.game and self.game.pokeblock, maxRPM = self.game and self.game.maxRPM }
  if self.onDone then self.onDone(self) end
end

function UI:frame(inp)
  if self.done then return end
  self.frames = self.frames + 1
  self.inp = inp or { new = {}, held = {} }
  if self.vblankRandom then self.random() end
  self:vblank()
  Kit.readKeys(self.m, self.inp)
  if self.linkBerryWait then
    local berries, waitError = self.linkSession:submitBerry(self.itemId)
    if berries then
      self.linkBerryItems = berries
      self.linkBerryWait = false
      self:startBlender()
    elseif waitError == "timeout" then
      self.linkSession:abort(waitError)
      self.linkBerryWait = false
      self:exitToField()
    elseif waitError == "abort" or not self.linkSession:isOpen() then
      self.linkBerryWait = false
      self:exitToField()
    end
  end
  if self.hidden then return end
  frameCall(self)
  if self.outer then self.outer:flush() end
end

local function textColors(caseId)
  local SceneKit = require("src.ui.game3.rse.scene_kit")
  local c = TEXT_CASES[caseId] or TEXT_CASES[0]
  local colors = SceneKit.messageColors("std_menu", c[1], c[2] or 1, c[3])
  if not c[2] then colors.bg = nil end
  return colors
end

function UI:drawWindows()
  local FrlgFont = require("src.ui.game3.frlg_font")
  local Chrome = require("src.ui.game3.chrome")
  local g = self.game
  local ox, oy = -(g and g.bg_X or 0), -(g and g.bg_Y or 0)
  love.graphics.push()
  love.graphics.translate(ox, oy)
  for win = 0, WIN_RESULTS do
    local w = self.wins[win]
    if w and w.shown then
      if w.frame then
        Chrome.stdFrame(w.left, w.top, w.width, w.height)
      end
      if w.fill then
        local c = textColors(0).bg
        love.graphics.setColor(c)
        love.graphics.rectangle("fill", w.left * 8, w.top * 8, w.width * 8, w.height * 8)
        love.graphics.setColor(1, 1, 1, 1)
      end
      for _, p in ipairs(w.prints) do
        FrlgFont.draw(p.text, w.left * 8 + p.x, w.top * 8 + p.y, { colors = textColors(p.caseId), maxWidth = 240 })
      end
    end
  end
  if self.printer or self.msgKeep then
    Chrome.dialogueFrame()
    local SceneKit = require("src.ui.game3.rse.scene_kit")
    local pr = self.printer or self.msgKeep
    pr:draw(2 * 8, 15 * 8 + 1, { colors = SceneKit.messageColors("message_box") })
  end
  love.graphics.pop()
  if self.yesNo then self.yesNo:draw() end
end

function UI:draw()
  if self.headless then return end
  if self.hidden then
    love.graphics.clear(0, 0, 0, 1)
    return
  end
  local p = self.m.ppu
  if self.fastFade then
    p.palette.pltt = p.palette.pltt or {}
    for i = 0, 511 do p.palette.pltt[i] = p.palette.faded[i] end
  end
  local all = p.sprites.oamShown or {}
  local low, top = {}, {}
  for _, e in ipairs(all) do
    if (e.priority or 0) == 0 then top[#top + 1] = e else low[#low + 1] = e end
  end
  p.sprites.oamShown = low
  p:draw(0, 0)
  p.sprites.oamShown = all
  local level = self:fadeLevel()
  if not self.overlay then
    self.overlay = love.graphics.newCanvas(W, H, { dpiscale = 1 })
    self.overlay:setFilter("nearest", "nearest")
  end
  local prev = love.graphics.getCanvas()
  love.graphics.push("all")
  love.graphics.setCanvas(self.overlay)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.origin()
  self:drawWindows()
  love.graphics.pop()
  love.graphics.setCanvas(prev)
  local k = math.max(0, math.min(1, (16 - level) / 16))
  love.graphics.setColor(k, k, k, 1)
  love.graphics.draw(self.overlay, 0, 0)
  love.graphics.setColor(1, 1, 1, 1)
  if #top > 0 then self:drawTopObjs(top) end
end

local OBJ_MASK = [[
extern Image objTex;
vec4 effect(vec4 color, Image t, vec2 tc, vec2 sc) {
  float ov = floor(Texel(objTex, tc).a * 255.0 + 0.5);
  if (ov < 16.0) discard;
  return Texel(t, tc);
}
]]

-- pokeemerald/src/berry_blender.c:309
function UI:drawTopObjs(list)
  local p = self.m.ppu
  local saved, dispcnt = p.sprites.oamShown, p:get("DISPCNT")
  p.sprites.oamShown = list
  p:set("DISPCNT", band(dispcnt, bit.bnot(Ppu.DISPCNT_BG_ALL_ON)))
  local out = p:render()
  p:set("DISPCNT", dispcnt)
  p.sprites.oamShown = saved
  UI._mask = UI._mask or love.graphics.newShader(OBJ_MASK)
  love.graphics.push("all")
  love.graphics.setShader(UI._mask)
  UI._mask:send("objTex", p.gpu.obj)
  love.graphics.draw(out, 0, 0)
  love.graphics.pop()
end

local Host = {}
UI.Host = Host

function UI.open(opts)
  local Stack = require("src.ui.game3.stack")
  local SceneKit = require("src.ui.game3.rse.scene_kit")
  opts = opts or {}
  local userDone = opts.onDone
  local screen
  opts.onDone = function(s)
    Host._screen = nil
    Stack.pop(UI.STACK_ID)
    if userDone then userDone(s) end
  end
  screen = UI.new(opts)
  Host._screen = screen
  Host._step = SceneKit.stepper()
  Stack.push(UI.STACK_ID, Host, { hideBelow = true, fullscreen = true })
  return screen
end

function UI.active() return Host._screen end

function UI.isOpen() return Host._screen ~= nil end

function UI.reset()
  if Host._screen then
    Host._screen = nil
    require("src.ui.game3.stack").pop(UI.STACK_ID)
  end
  Host._step = nil
end

function Host.handleInput(input)
  local s = Host._screen
  if s and s.hidden then return end
  if Host._step then Host._step:collect(input) end
end

function Host.update(dt)
  local screen = Host._screen
  if not screen or screen.hidden then return end
  Host._step:run(dt, function(inp)
    if screen.done then return true end
    screen:frame(inp)
    if screen.hidden then return true end
    return screen.done or nil
  end)
end

function Host.draw()
  local screen = Host._screen
  if screen then screen:draw() else love.graphics.clear(0, 0, 0, 1) end
end

return UI
