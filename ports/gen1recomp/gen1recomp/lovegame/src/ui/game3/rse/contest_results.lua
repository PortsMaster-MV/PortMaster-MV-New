local bit = require("bit")
local band, rshift = bit.band, bit.rshift

local Vram = require("src.ui.game3.rse.contest_vram")
local Ppu = require("src.core.game3.gba_ppu")
local Sprites = require("src.core.game3.gba_sprites")
local GcKit = require("src.ui.game3.rse.gc_kit")
local Contest = require("src.core.game3.rse.contest")

local UI = {}
UI.__index = UI

UI.ID = "rse_contest_results"
UI.SUB = "rse/contest_gfx"

local N = Contest.CONTESTANT_COUNT
local DISPLAY_WIDTH, DISPLAY_HEIGHT = 240, 160
-- pokeemerald/src/contest_util.c:81
local NUM_BAR_SEGMENTS, BAR_SEGMENT_LENGTH = 11, 8
local MAX_BAR_LENGTH = NUM_BAR_SEGMENTS * BAR_SEGMENT_LENGTH
-- pokeemerald/src/contest_util.c:86
local TEXT_BOX_X, TEXT_BOX_Y = DISPLAY_WIDTH + 32, DISPLAY_HEIGHT - 16
-- pokeemerald/src/contest_util.c:50
local SLIDING_TEXT_OFFSCREEN, SLIDING_TEXT_ENTERING, SLIDING_TEXT_ARRIVED, SLIDING_TEXT_EXITING = 0, 1, 2, 3
local SLIDING_MON_ENTERED, SLIDING_MON_EXITED = 1, 2
-- pokeemerald/src/contest_util.c:66
local TAG_TEXT_WINDOW_BASE, TAG_CONFETTI = 3009, 3017
-- pokeemerald/include/constants/game_stat.h:40
local GAME_STAT_ENTERED_CONTEST, GAME_STAT_WON_CONTEST = 36, 37
-- pokeemerald/include/constants/game_stat.h:39
local GAME_STAT_WON_LINK_CONTEST = 35
-- pokeemerald/include/constants/field_specials.h:80
local FANCOUNTER_FINISHED_CONTEST = 2

local function rgb(r, g, b) return r + g * 32 + b * 1024 end
local function winRange(a, b) return a * 256 + b end

local function s16(v)
  v = band(v, 0xFFFF)
  return v >= 0x8000 and v - 0x10000 or v
end

function UI.new(opts)
  opts = opts or {}
  local self = setmetatable({}, UI)
  self.opts = opts
  self.c = assert(opts.contest, "contest results need a contest")
  self.session = opts.session
  self.headless = opts.headless or Vram.headless()
  self.sound = opts.sound or GcKit.sound({ muted = self.headless })
  self.man = opts.manifest or Vram.manifest(UI.SUB)
  self.m = GcKit.newMachine()
  self.fn = {}
  self.frames = 0
  self.done = false
  self.onDone = opts.onDone
  self.bgX, self.bgY = { [0] = 0, 0, 0, 0 }, { [0] = 0, 0, 0, 0 }
  self.win0h, self.win0v, self.win1h, self.win1v = 0, 0, 0, 0
  self.d = { slidingTextBoxState = SLIDING_TEXT_OFFSCREEN, numStandingsPrinted = 0, winnerMonSlidingState = 0,
    confettiCount = 0, destroyConfetti = false, pointsFlashing = false, barLength = { [0] = 0, 0, 0, 0 },
    numBarsUpdating = 0 }
  self.m:setCb2(function() self:startCb() end)
  return self
end

function UI:func(name)
  local f = self.fn[name]
  if not f then
    f = function(tid, data) return self[name](self, tid, data) end
    self.fn[name] = f
  end
  return f
end

function UI:task(id) return self.m.tasks:get(id) end
function UI:setFunc(tid, name) self.m.tasks:setFunc(tid, self:func(name)) end
function UI:createTask(name, prio) return self.m.tasks:create(self:func(name), prio) end
function UI:destroyTask(tid) self.m.tasks:destroy(tid) end
function UI:sprites() return self.m.ppu.sprites end
function UI:sprite(id) return self.m.ppu.sprites.sprites[id] end
function UI:pal() return self.m.ppu.palette end
function UI:bytes(kind, key) return Vram.bytes(self.man, kind, key) end

local function Util() return require("src.core.game3.rse.contest_util") end
local function Stage() return require("src.ui.game3.rse.contest") end

function UI:rand() return require("src.core.game3.rng").Random() % 65536 end

-- pokeemerald/src/contest_util.c:1107
function UI:iconTiles(i, frame)
  local Pokemon = require("src.core.game3.pokemon")
  local CachePaths = require("src.core.game3.cache_paths")
  local m = self.c.mons[i]
  local species = Pokemon.picSpecies(tonumber(m.species) or 0, m.personality)
  local rgba = Vram.readCache((CachePaths.CACHE_ROOT or "data/generated/gba") .. "/pokemon/icons/" .. species .. ".rgba")
  local pal = self.iconPal[i]
  local out = {}
  for ty = 0, 2 do
    for tx = 0, 3 do
      local px = {}
      for y = 0, 7 do
        for x = 0, 7 do
          local gx, gy = tx * 8 + x, frame * 32 + 8 + ty * 8 + y
          local o = (gy * 32 + gx) * 4
          local r, g, b, a = 0, 0, 0, 0
          if rgba then r, g, b, a = rgba:byte(o + 1, o + 4) end
          local v = 0
          if (a or 0) ~= 0 then
            local c = math.floor(r * 31 / 255 + 0.5) + math.floor(g * 31 / 255 + 0.5) * 32
              + math.floor(b * 31 / 255 + 0.5) * 1024
            v = pal.index[c]
            if not v then
              v = #pal.colors + 1
              if v > 15 then v = 15 end
              pal.index[c] = v
              pal.colors[v] = c
            end
          end
          px[y * 8 + x] = v
        end
      end
      out[ty * 4 + tx] = px
    end
  end
  return out
end

-- pokeemerald/src/contest_util.c:1107
function UI:loadContestMonIcon(i, srcOffset, useDmaNow)
  local list = self:iconTiles(i, srcOffset)
  for k = 0, 11 do self.tiles[0x200 + i * 16 + k] = list[k] end
  if useDmaNow then
    self.bg[1]:writeSequence(bit.bor(i * 0x10 + 0x200, (i + 10) * 4096), 3, i * 3 + 4, 4, 3, 17, 1)
  else
    for y = i * 3 + 4, i * 3 + 6 do
      for x = 3, 6 do self.bg[1]:_paint(self.bg[1]:cellOf(x, y)) end
    end
  end
end

-- pokeemerald/src/contest_util.c:1140
function UI:loadAllContestMonIconPalettes()
  self.iconPal = {}
  for i = 0, N - 1 do
    self.iconPal[i] = { index = {}, colors = {} }
    self:iconTiles(i, 0)
    self:iconTiles(i, 1)
    local t = {}
    for k = 0, 15 do t[k + 1] = self.iconPal[i].colors[k] or 0 end
    self:pal():load(t, (10 + i) * 16, 16)
  end
end

-- pokeemerald/src/contest_util.c:448
function UI:loadBgGfx()
  local tiles = Vram.decodeTiles(self:bytes("gfx", "results"), {}, 0)
  self.tiles = tiles
  local h = self.headless
  self.bg = {}
  for i = 0, 3 do self.bg[i] = Vram.layer(tiles, 32, 32, h) end
  self.bg[3]:load(Vram.u16s(self:bytes("maps", "results_bg")), 32 * 32)
  self.bg[2]:load(Vram.u16s(self:bytes("maps", "results_interface")), 32 * 32)
  self.bg[0]:load(Vram.u16s(self:bytes("maps", "results_banner")), 32 * 32)
  self:loadTitleBarTilemaps()
  local pal = self:pal()
  pal:load(self.man.palettes.results, 0, 256)
  pal:load(self.man.palettes.results_text_window, 15 * 16, 16)
  local U = Util()
  for i = 0, N - 1 do
    local numStars = U.preliminaryStars(self.c, i, true)
    local round2 = U.round2Hearts(self.c, i, true)
    for j = 0, 9 do
      local tile1 = 0x60B2
      if j < numStars then tile1 = tile1 + 2 end
      local tile2
      if j < math.abs(round2) then
        tile2 = 0x60A4
        if round2 < 0 then tile2 = tile2 + 2 end
      else
        tile2 = 0x60A2
      end
      self.bg[1]:put(j + 19, i * 3 + 5, tile1)
      self.bg[1]:put(j + 19, i * 3 + 6, tile2)
    end
  end
end

-- pokeemerald/src/contest_util.c:1405
function UI:loadTitleBarTilemaps()
  local c = self.c
  local L = self.bg[2]
  local function map(key) return Vram.u16s(self:bytes("maps", key)) end
  local x, y = 5, 1
  if c:isLink() then
    L:copyRect(map("title_link"), 5, 1, 5, 2)
    x = 10
  else
    local key = ({ [0] = "title_normal", "title_super", "title_hyper" })[c.rank] or "title_master"
    L:copyRect(map(key), 5, 1, 10, 2)
    x = 15
  end
  local palette = c.category
  local catKey = ({ [0] = "title_cool", "title_beauty", "title_cute", "title_smart" })[c.category] or "title_tough"
  if palette > 4 then palette = 4 end
  L:copyRect(map(catKey), x, y, 5, 2)
  x = x + 5
  L:copyRect(map("title"), x, y, 6, 2)
  local cur = {}
  for yy = 0, 3 do
    for xx = 0, 31 do cur[yy * 32 + xx] = L:get(xx, yy) end
  end
  L:copyRect(cur, 0, 0, 32, 4, palette)
end

-- pokeemerald/src/contest_util.c:513
function UI:loadAllContestMonNames()
  self.names = {}
  for i = 0, N - 1 do
    local nick = Util().monName(self.c.mons[i])
    local slash = Stage().plain("gText_Slash") .. Util().trainerName(self.c.mons[i])
    self.names[i] = { nick = nick, trainer = slash, player = i == self.c.playerIndex }
  end
end

function UI:newSprite(template, x, y, sub)
  local sp = self:sprites()
  local id = sp:create(template, x, y, sub)
  local s = sp.sprites[id]
  s.callback = template.callback
  return id, s
end

-- pokeemerald/src/contest_util.c:1232
function UI:createResultsTextWindowSprites()
  local sp = self:sprites()
  local palNum = sp:loadPalette(TAG_TEXT_WINDOW_BASE, self.man.palettes.misc_blank)
  local ids = {}
  for i = 0, 7 do
    local id, s = self:newSprite({ w = 64, h = 32, priority = 3 }, TEXT_BOX_X, TEXT_BOX_Y, 10)
    s.oam.paletteNum = palNum
    s.oam.priority = 3
    ids[i] = id
  end
  local s0, s4 = self:sprite(ids[0]), self:sprite(ids[4])
  s0.data[0], s0.data[1], s0.data[2] = ids[1], ids[2], ids[3]
  s4.data[0], s4.data[1], s4.data[2] = ids[5], ids[6], ids[7]
  self.d.slidingTextBoxSpriteId = ids[0]
  self.d.linkTextBoxSpriteId = ids[4]
  for k = 4, 7 do self:sprite(ids[k]).invisible = true end
  self.textWindowTiles = Vram.decodeTiles(self:bytes("gfx", "results_text_window"), {}, 0)
end

-- pokeemerald/src/contest_util.c:1168
function UI:drawResultsTextWindow(text, spriteId)
  local FrlgFont = require("src.ui.game3.frlg_font")
  local strWidth = FrlgFont.measure(text)
  local tileWidth = math.floor((strWidth + 9) / 8)
  if tileWidth > 30 then tileWidth = 30 end
  local src = self.textWindowTiles
  local fill = {}
  for k = 0, 63 do fill[k] = 1 end
  local sprTiles = { [0] = {}, {}, {}, {} }
  local function put(col, row, px)
    local spr = math.floor(col / 8)
    if spr <= 3 then sprTiles[spr][row * 8 + col % 8] = px end
  end
  put(0, 0, src[0]); put(0, 1, src[4]); put(0, 2, src[4]); put(0, 3, src[2])
  for i = 0, tileWidth - 1 do
    put(i + 1, 0, src[6]); put(i + 1, 1, fill); put(i + 1, 2, fill); put(i + 1, 3, src[7])
  end
  put(tileWidth + 1, 0, src[1]); put(tileWidth + 1, 1, src[5]); put(tileWidth + 1, 2, src[5])
  put(tileWidth + 1, 3, src[3])
  local s0 = self:sprite(spriteId)
  local ids = { [0] = spriteId, s0.data[0], s0.data[1], s0.data[2] }
  for k = 0, 3 do
    self:sprite(ids[k]).sheet = Vram.sheetFromTileList(sprTiles[k], 64, 32, self.headless)
  end
  self.boxTexts = self.boxTexts or {}
  self.boxTexts[spriteId] = { text = text, x = math.floor((tileWidth * 8 - strWidth) / 2) + 8, spriteId = spriteId }
  return math.floor((DISPLAY_WIDTH - (tileWidth + 2) * 8) / 2)
end

-- pokeemerald/src/contest_util.c:1363
function UI:showLinkResultsTextBox(text)
  local x = self:drawResultsTextWindow(text, self.d.linkTextBoxSpriteId)
  local s = self:sprite(self.d.linkTextBoxSpriteId)
  s.x, s.y, s.invisible = x + 32, 80, false
  for i = 0, 2 do
    local s2 = self:sprite(s.data[i])
    s2.x = s.x + s.x2 + (i + 1) * 64
    s2.y = s.y
    s2.invisible = false
  end
  self.win0h = winRange(0, DISPLAY_WIDTH)
  self.win0v = winRange(s.y - 16, s.y + 16)
  self.m.ppu:set("WININ", Ppu.WININ_WIN1_BG_ALL + Ppu.WININ_WIN1_OBJ + 0x2000 + 0xE + Ppu.WININ_WIN0_OBJ
    + Ppu.WININ_WIN0_CLR)
  self.linkBoxShown = true
end

-- pokeemerald/src/contest_util.c:1387
function UI:hideLinkResultsTextBox()
  local s = self:sprite(self.d.linkTextBoxSpriteId)
  s.invisible = true
  for i = 0, 2 do self:sprite(s.data[i]).invisible = true end
  self.win0h, self.win0v = 0, 0
  self.m.ppu:set("WININ", Ppu.WININ_WIN0_ALL + Ppu.WININ_WIN1_BG_ALL + Ppu.WININ_WIN1_OBJ + 0x2000)
  self.linkBoxShown = false
end

-- pokeemerald/src/contest_util.c:1273
function UI:startTextBoxSlideIn(x, y, slideOutTimer, inc)
  local s = self:sprite(self.d.slidingTextBoxSpriteId)
  s.x, s.y, s.x2, s.y2 = TEXT_BOX_X, y, 0, 0
  s.data[4] = x + 32
  s.data[5] = slideOutTimer
  s.data[6] = inc
  s.data[7] = 0
  s.callback = function(sp) self:spriteCBTextBoxSlideIn(sp) end
  self.d.slidingTextBoxState = SLIDING_TEXT_ENTERING
end

function UI:positionTextBoxParts(s)
  for i = 0, 2 do
    local s2 = self:sprite(s.data[i])
    s2.x = s.x + s.x2 + (i + 1) * 64
    s2.y = s.y
  end
end

-- pokeemerald/src/contest_util.c:1311
function UI:spriteCBTextBoxSlideIn(s)
  local delta = s16(s.data[7] + s.data[6])
  s.x = s.x - rshift(band(delta, 0xFFFF), 8) % 256
  s.data[7] = band(s.data[7] + s.data[6], 0xFF)
  if s.x < s.data[4] then s.x = s.data[4] end
  self:positionTextBoxParts(s)
  if s.x == s.data[4] then
    s.callback = function(sp) self:spriteCBEndTextBoxSlideIn(sp) end
  end
end

-- pokeemerald/src/contest_util.c:1334
function UI:spriteCBEndTextBoxSlideIn(s)
  self.d.slidingTextBoxState = SLIDING_TEXT_ARRIVED
  if band(s.data[5], 0xFFFF) ~= 0xFFFF then
    s.data[5] = s.data[5] - 1
    if s.data[5] == -1 then self:startTextBoxSlideOut(s.data[6]) end
  end
end

-- pokeemerald/src/contest_util.c:1288
function UI:startTextBoxSlideOut(inc)
  local s = self:sprite(self.d.slidingTextBoxSpriteId)
  s.x = s.x + s.x2
  s.y = s.y + s.y2
  s.x2, s.y2 = 0, 0
  s.data[6] = inc
  s.data[7] = 0
  s.callback = function(sp) self:spriteCBTextBoxSlideOut(sp) end
  self.d.slidingTextBoxState = SLIDING_TEXT_EXITING
end

-- pokeemerald/src/contest_util.c:1344
function UI:spriteCBTextBoxSlideOut(s)
  local delta = s16(s.data[7] + s.data[6])
  s.x = s.x - rshift(band(delta, 0xFFFF), 8) % 256
  s.data[7] = band(s.data[7] + s.data[6], 0xFF)
  self:positionTextBoxParts(s)
  if s.x + s.x2 < -224 then
    s.x, s.y, s.x2, s.y2 = TEXT_BOX_X, TEXT_BOX_Y, 0, 0
    self:positionTextBoxParts(s)
    s.callback = nil
    self.d.slidingTextBoxState = SLIDING_TEXT_OFFSCREEN
  end
end

-- pokeemerald/src/contest_util.c:523
function UI:startCb()
  local m = self.m
  local p = m.ppu
  local st = m.state
  if st == 0 then
    m.ppu.sprites:resetData()
    m.ppu.sprites:freeAllPalettes()
    m.tasks:reset()
    self:loadBgGfx()
    self:loadAllContestMonIconPalettes()
    for i = 0, N - 1 do self:loadContestMonIcon(i, 0, true) end
    self:loadAllContestMonNames()
    self:createResultsTextWindowSprites()
    -- pokeemerald/src/contest_util.c:403
    p:set("DISPCNT", Ppu.DISPCNT_OBJ_1D_MAP + Ppu.DISPCNT_BG_ALL_ON + Ppu.DISPCNT_OBJ_ON + Ppu.DISPCNT_WIN0_ON
      + Ppu.DISPCNT_WIN1_ON + Ppu.DISPCNT_OBJWIN_ON)
    p:set("WININ", Ppu.WININ_WIN0_ALL + 0x3F00)
    p:set("WINOUT", 0x2 + 0x4 + 0x8 + 0x20 + Ppu.WINOUT_WINOBJ_ALL)
    if not self.headless then
      p:setBg(0, 0, self.bg[0].layer)
      for i = 1, 3 do p:setBg(i, 3, self.bg[i].layer) end
    end
    self:pal():beginFade(0xFFFFFFFF, 0, 16, 0, 0)
    self.d.showResultsTaskId = self:createTask("taskShowContestResults", 5)
    self.win1h = winRange(0, DISPLAY_WIDTH)
    self.win1v = winRange(DISPLAY_HEIGHT - 32, DISPLAY_HEIGHT)
    self:createTask("taskSlideContestResultsBg", 20)
    self.results = Util().resultsData(self.c)
    self.sound:playMapMusic("MUS_CONTEST_RESULTS")
    m:setVBlank(function() self:vblankCb() end)
    m:setCb2(function() self:mainCb() end)
    return
  end
  m.state = st + 1
end

-- pokeemerald/src/contest_util.c:558
function UI:mainCb()
  local sp = self:sprites()
  sp:animateAll()
  sp:buildOam()
  self.m.tasks:run(self)
  self:pal():update()
end

-- pokeemerald/src/contest_util.c:568
function UI:vblankCb()
  local p = self.m.ppu
  for i = 0, 3 do
    p:set("BG" .. i .. "HOFS", band(self.bgX[i], 0x1FF))
    p:set("BG" .. i .. "VOFS", band(self.bgY[i], 0x1FF))
  end
  p:set("WIN0H", self.win0h)
  p:set("WIN0V", self.win0v)
  p:set("WIN1H", self.win1h)
  p:set("WIN1V", self.win1v)
  p:vblank()
  if not self.headless then for i = 0, 3 do self.bg[i]:flush() end end
end

local function incrementGameStat(session, id)
  if not session then return end
  if type(session.gameStats) ~= "table" then session.gameStats = {} end
  session.gameStats[id] = math.min(0xFFFFFF, math.floor(tonumber(session.gameStats[id]) or 0) + 1)
end

-- pokeemerald/src/contest.c:3635
local function saveLinkContestResults(sess, c)
  if not sess then return end
  local rows = type(sess.contestLinkResults) == "table" and sess.contestLinkResults or {}
  sess.contestLinkResults = rows
  local cat = (tonumber(c.category) or 0) + 1
  local place = (tonumber(c.standings[c.playerIndex]) or 0) + 1
  rows[cat] = type(rows[cat]) == "table" and rows[cat] or { 0, 0, 0, 0 }
  rows[cat][place] = math.min(9999, (tonumber(rows[cat][place]) or 0) + 1)
end
UI.saveLinkContestResults = saveLinkContestResults

-- pokeemerald/src/contest_util.c:592
function UI:taskShowContestResults(tid, d)
  local c, sess = self.c, self.session
  if c:isLink() and c.link then
    if not self.linkResultsSaved then
      self.linkResultsSaved = true
      -- pokeemerald/src/contest_util.c:601
      saveLinkContestResults(sess, c)
      if c.standings[c.playerIndex] == 0 then incrementGameStat(sess, GAME_STAT_WON_LINK_CONTEST) end
      local okF, FieldRse = pcall(require, "src.core.game3.scripting.natives_field_rse")
      local id = require("src.core.game3.profile").forSession(sess).id
      local nativeRs = id == "ruby" or id == "sapphire"
      if not nativeRs and okF and FieldRse and FieldRse.tryGainNewFanFromCounter and sess and not self.opts.noFieldHooks then
        pcall(FieldRse.tryGainNewFanFromCounter, FANCOUNTER_FINISHED_CONTEST)
      end
      local okN, NC = pcall(require, "src.core.game3.scripting.natives_contest")
      if not nativeRs and okN and NC and NC.onResultsShown and sess then NC.onResultsShown(c, sess) end
    end
    if self:pal():fadeActive() then return end
    if not self.linkResultsPersisted and not self.opts.noFieldHooks then
      if self.linkSaveError then
        if not (self.inp and self.inp.new and self.inp.new.a) then return end
        self:hideLinkResultsTextBox()
        self.linkSaveError = nil
      end
      local ok, err = require("src.core.game3.rse.contest_util").persistLinkResults(sess, c)
      if not ok then
        self.linkSaveError = err
        self:showLinkResultsTextBox("Save failed. A: retry")
        return
      end
      self.linkResultsPersisted = true
    end
    -- pokeemerald/src/contest_util.c:653
    if not self.standbyBeforeResults then
      self.standbyBeforeResults = true
      self:showLinkResultsTextBox(Stage().plain("gText_CommunicationStandby"))
    end
    -- pokeemerald/src/contest_util.c:681
    local row, err = c.link:exchange("results", c.playerIndex)
    if not (row or err) then return end
    -- pokeemerald/src/contest_util.c:692
    self:hideLinkResultsTextBox()
    d[0] = 0
    self:setFunc(tid, "taskAnnouncePreliminaryResults")
    return
  end
  if self:pal():fadeActive() then return end
  d[0] = 0
  local id = require("src.core.game3.profile").forSession(sess).id
  local nativeRs = id == "ruby" or id == "sapphire"
  if not nativeRs then
    incrementGameStat(sess, GAME_STAT_ENTERED_CONTEST)
    if c.standings[c.playerIndex] == 0 then incrementGameStat(sess, GAME_STAT_WON_CONTEST) end
  end
  local okN, NC = pcall(require, "src.core.game3.scripting.natives_contest")
  if not nativeRs and okN and NC and NC.onResultsShown and sess then NC.onResultsShown(c, sess) end
  local okF, FieldRse = pcall(require, "src.core.game3.scripting.natives_field_rse")
  if not nativeRs and okF and FieldRse and FieldRse.tryGainNewFanFromCounter and sess and not self.opts.noFieldHooks then
    pcall(FieldRse.tryGainNewFanFromCounter, FANCOUNTER_FINISHED_CONTEST)
  end
  self:setFunc(tid, "taskAnnouncePreliminaryResults")
end

-- pokeemerald/src/contest_util.c:696
function UI:taskAnnouncePreliminaryResults(tid, d)
  if d[0] == 0 then
    self:createTask("taskFlashStarsAndHearts", 20)
    local x = self:drawResultsTextWindow(Stage().plain("gText_AnnouncingResults"), self.d.slidingTextBoxSpriteId)
    self:startTextBoxSlideIn(x, TEXT_BOX_Y, 120, 1088)
    d[0] = 1
  elseif d[0] == 1 then
    if self.d.slidingTextBoxState == SLIDING_TEXT_OFFSCREEN then
      d[1] = 0
      d[0] = 2
    end
  elseif d[0] == 2 then
    d[1] = d[1] + 1
    if d[1] == 21 then
      d[1] = 0
      d[0] = 3
    end
  elseif d[0] == 3 then
    local x = self:drawResultsTextWindow(Stage().plain("gText_PreliminaryResults"), self.d.slidingTextBoxSpriteId)
    self:startTextBoxSlideIn(x, TEXT_BOX_Y, -1, 1088)
    d[0] = 4
  elseif d[0] == 4 then
    if self.d.slidingTextBoxState == SLIDING_TEXT_ARRIVED then
      d[0] = 0
      self:setFunc(tid, "taskShowPreliminaryResults")
    end
  end
end

-- pokeemerald/src/contest_util.c:740
function UI:taskShowPreliminaryResults(tid, d)
  if d[0] == 0 then
    if not self.d.pointsFlashing then
      self:updateContestResultBars(false, d[2])
      d[2] = d[2] + 1
      if self.d.numBarsUpdating == 0 then d[0] = 2 else d[0] = 1 end
    end
  elseif d[0] == 1 then
    if self.d.numBarsUpdating == 0 then d[0] = 0 end
  else
    self:startTextBoxSlideOut(1088)
    d[0], d[2] = 0, 0
    self:setFunc(tid, "taskAnnounceRound2Results")
  end
end

-- pokeemerald/src/contest_util.c:767
function UI:taskAnnounceRound2Results(tid, d)
  if self.d.slidingTextBoxState == SLIDING_TEXT_OFFSCREEN then
    d[1] = d[1] + 1
    if d[1] == 21 then
      d[1] = 0
      local x = self:drawResultsTextWindow(Stage().plain("gText_Round2Results"), self.d.slidingTextBoxSpriteId)
      self:startTextBoxSlideIn(x, TEXT_BOX_Y, -1, 1088)
    end
  elseif self.d.slidingTextBoxState == SLIDING_TEXT_ARRIVED then
    self:setFunc(tid, "taskShowRound2Results")
  end
end

-- pokeemerald/src/contest_util.c:786
function UI:taskShowRound2Results(tid, d)
  if d[0] == 0 then
    if not self.d.pointsFlashing then
      self:updateContestResultBars(true, d[2])
      d[2] = d[2] + 1
      if self.d.numBarsUpdating == 0 then d[0] = 2 else d[0] = 1 end
    end
  elseif d[0] == 1 then
    if self.d.numBarsUpdating == 0 then d[0] = 0 end
  else
    self:startTextBoxSlideOut(1088)
    d[0] = 0
    self:setFunc(tid, "taskAnnounceWinner")
  end
end

function UI:winnerId()
  return Util().winnerId(self.c)
end

-- pokeemerald/src/contest_util.c:816
function UI:taskAnnounceWinner(tid, d)
  local st = d[0]
  if st == 0 then
    if self.d.slidingTextBoxState == SLIDING_TEXT_OFFSCREEN then d[0] = 1 end
  elseif st == 1 then
    d[1] = d[1] + 1
    if d[1] == 31 then d[1] = 0; d[0] = 2 end
  elseif st == 2 then
    for i = 0, N - 1 do
      local nt = self:createTask("taskDrawFinalStandingNumber", 10)
      local nd = self:task(nt).data
      nd[0] = self.c.standings[i]
      nd[1] = i
    end
    d[0] = 3
  elseif st == 3 then
    if self.d.numStandingsPrinted == N then
      d[1] = d[1] + 1
      if d[1] == 31 then
        d[1] = 0
        self:createTask("taskStartHighlightWinnersBox", 10)
        d[0] = 4
        self:bounceMonIconInBox(self:winnerId(), 14)
      end
    end
  elseif st == 4 then
    d[1] = d[1] + 1
    if d[1] == 21 then
      d[1] = 0
      local i = self:winnerId()
      local text = Stage().plain("gText_ContestantsMonWon",
        { Util().trainerName(self.c.mons[i]), Util().monName(self.c.mons[i]) })
      local x = self:drawResultsTextWindow(text, self.d.slidingTextBoxSpriteId)
      self:startTextBoxSlideIn(x, TEXT_BOX_Y, -1, 1088)
      d[0] = 5
    end
  else
    d[0] = 0
    self:setFunc(tid, "taskShowWinnerMonBanner")
  end
end

-- pokeemerald/src/contest_util.c:877
function UI:taskShowWinnerMonBanner(tid, d)
  local st = d[0]
  if st == 0 then
    self.win0h = winRange(0, DISPLAY_WIDTH)
    self.win0v = winRange(DISPLAY_HEIGHT / 2, DISPLAY_HEIGHT / 2)
    local i = self:winnerId()
    local m = self.c.mons[i]
    local Pokemon = require("src.core.game3.pokemon")
    local CachePaths = require("src.core.game3.cache_paths")
    local species = tonumber(m.species) or 0
    local p = (tonumber(m.personality) or 0) % 4294967296
    local ot = tonumber(m.otId) or 0
    local shiny = Pokemon.isShiny({ personality = p, otId = ot % 65536, otSecretId = math.floor(ot / 65536) % 65536 })
    local picSpecies = Pokemon.picSpecies(species, p)
    local rgba = Vram.readCache((CachePaths.CACHE_ROOT or "data/generated/gba") .. "/pokemon/"
      .. (shiny and "front_shiny" or "front") .. "/" .. picSpecies .. ".rgba")
    local sheet, pal = Vram.indexedPic(rgba, self.headless)
    local sp = self:sprites()
    local palNum = sp:loadPalette(0x7000 + species, pal)
    local id, s = self:newSprite({ w = 64, h = 64, sheet = sheet }, DISPLAY_WIDTH + 32, DISPLAY_HEIGHT / 2, 10)
    s.oam.paletteNum = palNum
    s.oam.priority = 0
    s.data[1] = species
    s.callback = function(sp2) self:spriteCBWinnerMonSlideIn(sp2) end
    self.d.winnerMonSpriteId = id
    self.confettiPal = sp:loadPalette(TAG_CONFETTI, self.man.palettes.confetti)
    self.confettiSheets = self.confettiSheets or {}
    self:createTask("taskCreateConfetti", 10)
    d[0] = 1
  elseif st == 1 then
    d[3] = d[3] + 1
    if d[3] == 1 then
      d[3] = 0
      d[2] = d[2] + 2
      if d[2] > 32 then d[2] = 32 end
      local counter = d[2]
      self.win0v = winRange(DISPLAY_HEIGHT / 2 - counter, DISPLAY_HEIGHT / 2 + counter)
      if counter == 32 then d[0] = 2 end
    end
  elseif st == 2 then
    if self.d.winnerMonSlidingState == SLIDING_MON_ENTERED then d[0] = 3 end
  elseif st == 3 then
    d[1] = d[1] + 1
    if d[1] == 121 then
      d[1] = 0
      self:sprite(self.d.winnerMonSpriteId).callback = function(sp2) self:spriteCBWinnerMonSlideOut(sp2) end
      d[0] = 4
    end
  elseif st == 4 then
    if self.d.winnerMonSlidingState == SLIDING_MON_EXITED then
      local top = rshift(self.win0v, 8) + 2
      if top > DISPLAY_HEIGHT / 2 then top = DISPLAY_HEIGHT / 2 end
      self.win0v = winRange(top, DISPLAY_HEIGHT - top)
      if top == DISPLAY_HEIGHT / 2 then d[0] = 5 end
    end
  else
    if self.d.winnerMonSlidingState == SLIDING_MON_EXITED then
      self.d.destroyConfetti = true
      d[0] = 0
      self:setFunc(tid, "taskSetSeenWinnerMon")
    end
  end
end

-- pokeemerald/src/contest_util.c:978
function UI:taskSetSeenWinnerMon(tid, d)
  if GcKit.joyNew(self.m, GcKit.A) then
    local sess = self.session
    if sess and not self.c:isLink() then
      local Dex = require("src.core.game3.dex")
      sess.dex = sess.dex or {}
      for i = 0, N - 1 do Dex.setSeen(sess.dex, tonumber(self.c.mons[i].species) or 0) end
    end
    d[10] = 0
    self:setFunc(tid, "taskTryDisconnectLinkPartners")
  end
end

-- pokeemerald/src/contest_util.c:998
function UI:taskTryDisconnectLinkPartners(tid)
  local c = self.c
  if c:isLink() and c.link then
    if not self.standbyBeforeBye then
      self.standbyBeforeBye = true
      -- pokeemerald/src/contest_util.c:1004
      self:showLinkResultsTextBox(Stage().plain("gText_CommunicationStandby"))
    end
    local row, err = c.link:exchange("bye", 1)
    if not (row or err) then return end
    -- pokeemerald/src/contest_util.c:1022
    self:hideLinkResultsTextBox()
    -- pokeemerald/src/contest_util.c:1005
    require("src.core.game3.link.contest_link").close("contest_results")
    c.link = nil
  end
  self:setFunc(tid, "taskTrySetContestInterviewData")
end

-- pokeemerald/src/contest_util.c:1027
function UI:taskTrySetContestInterviewData(tid, d)
  local c = self.c
  if not c:isLink() and self.session then
    local okR, Rse = pcall(require, "src.core.game3.rse.init")
    local okN, NC = pcall(require, "src.core.game3.scripting.natives_contest")
    local mon = okN and NC and self.session.party and self.session.party[(NC.partyIndex or 0) + 1] or nil
    if okR and Rse then
      Rse.call("tv", "bravoTrainerPokemonProfileBeforeInterview2", nil, nil, c.standings[c.playerIndex],
        c.category, c.rank, mon)
    end
  end
  local sess = self.session
  local id = require("src.core.game3.profile").forSession(sess).id
  if (id == "ruby" or id == "sapphire") and sess and not self.rsResultsSaved then
    self.rsResultsSaved = true
    if not self.opts.noFieldHooks then require("src.core.game3.rse.fan_club_lifecycle_rs").onContestResults(sess) end
    local NC = require("src.core.game3.scripting.natives_contest")
    NC.onResultsShown(c, sess)
  end
  self.hwFade = { y = 0 }
  d[1] = 0
  self:setFunc(tid, "taskEndShowContestResults")
end

-- pokeemerald/src/contest_util.c:1036
function UI:taskEndShowContestResults(tid, d)
  local hw = self.hwFade
  if hw.y < 16 then
    hw.y = hw.y + 1
    return
  end
  if d[1] == 0 then
    if self.d.highlightWinnerTaskId then self:destroyTask(self.d.highlightWinnerTaskId) end
    self:pal():blendMask(0x0000FFFF, 16, 0)
    d[1] = 1
  elseif d[1] == 1 then
    self:pal():blendMask(0xFFFF0000, 16, 0)
    d[1] = 2
  else
    self:destroyTask(tid)
    self.done = true
  end
end

-- pokeemerald/src/contest_util.c:1067
function UI:taskSlideContestResultsBg()
  self.bgX[3] = self.bgX[3] + 2
  self.bgY[3] = self.bgY[3] + 1
  if self.bgX[3] > 255 then self.bgX[3] = self.bgX[3] - 255 end
  if self.bgY[3] > 255 then self.bgY[3] = self.bgY[3] - 255 end
end

-- pokeemerald/src/contest_util.c:1081
function UI:taskFlashStarsAndHearts(tid, d)
  d[0] = d[0] + 1
  if d[0] == 2 then
    d[0] = 0
    if d[2] == 0 then d[1] = d[1] + 1 else d[1] = d[1] - 1 end
    if d[1] == 16 then d[2] = 1 elseif d[1] == 0 then d[2] = 0 end
    local pal = self:pal()
    pal:blend(6 * 16 + 11, 1, d[1], rgb(30, 22, 11))
    pal:blend(6 * 16 + 8, 1, d[1], 0x7FFF)
    pal:blend(6 * 16 + 14, 1, d[1], rgb(30, 29, 29))
  end
  self.d.pointsFlashing = d[1] ~= 0
end

-- pokeemerald/src/contest_util.c:1770
function UI:updateContestResultBars(isRound2, numUpdates)
  local numInc, numDec = 0, 0
  local R = self.results
  for i = 0, N - 1 do
    local r = R[i]
    if not isRound2 then
      if numUpdates < r.numStars then
        self.bg[1]:put(19 + r.numStars - numUpdates - 1, i * 3 + 5, 0x60B3)
        local target = math.floor(r.barLengthPreliminary * 65536 / r.numStars) * (numUpdates + 1)
        if target % 65536 > 0x7FFF then target = target + 0x10000 end
        self:startBarTask(i, math.floor(target / 65536), false)
        numInc = numInc + 1
      end
    else
      if numUpdates < r.numHearts then
        local tile = r.lostPoints and 0x60A5 or 0x60A3
        self.bg[1]:put(19 + r.numHearts - numUpdates - 1, i * 3 + 6, tile)
        local target = math.floor(r.barLengthRound2 * 65536 / r.numHearts) * (numUpdates + 1)
        if target % 65536 > 0x7FFF then target = target + 0x10000 end
        local t
        if r.lostPoints then
          t = -math.floor(target / 65536) + r.barLengthPreliminary
          numDec = numDec + 1
        else
          t = math.floor(target / 65536) + r.barLengthPreliminary
          numInc = numInc + 1
        end
        self:startBarTask(i, s16(t), r.lostPoints)
      end
    end
  end
  if numDec > 0 then self.sound:se("SE_BOO") end
  if numInc > 0 then self.sound:se("SE_PIN") end
end

function UI:startBarTask(i, target, decreasing)
  local tid = self:createTask("taskUpdateContestResultBar", 10)
  local d = self:task(tid).data
  d[0], d[1], d[2] = i, target, decreasing and 1 or 0
  self.d.numBarsUpdating = self.d.numBarsUpdating + 1
end

-- pokeemerald/src/contest_util.c:1839
function UI:taskUpdateContestResultBar(tid, d)
  local monId, target, decreasing = d[0], d[1], d[2] ~= 0
  local bars = self.d.barLength
  local minMax, reached = false, false
  if decreasing then
    if bars[monId] <= 0 then minMax = true end
  else
    if bars[monId] >= MAX_BAR_LENGTH then minMax = true end
  end
  if bars[monId] == target then reached = true end
  if not reached then
    if minMax then bars[monId] = target
    elseif decreasing then bars[monId] = bars[monId] - 1
    else bars[monId] = bars[monId] + 1 end
  end
  if not minMax and not reached then
    for i = 0, NUM_BAR_SEGMENTS - 1 do
      local off
      if bars[monId] >= (i + 1) * BAR_SEGMENT_LENGTH then off = 8
      elseif bars[monId] >= i * BAR_SEGMENT_LENGTH then off = bars[monId] % 8
      else off = 0 end
      local tile = off < 4 and (0x504C + off) or (0x5057 + off)
      self.bg[2]:put(i + 7, monId * 3 + 6, tile)
    end
  end
  if reached then
    self.d.numBarsUpdating = self.d.numBarsUpdating - 1
    self:destroyTask(tid)
  end
end

-- pokeemerald/src/contest_util.c:1522
function UI:taskDrawFinalStandingNumber(tid, d)
  if d[10] == 0 then
    d[11] = (3 - d[0]) * 40
    d[10] = 1
  else
    d[11] = d[11] - 1
    if d[11] == -1 then
      local first = d[0] * 2 + 0x5043
      self.bg[2]:writeSequence(first, 1, d[1] * 3 + 5, 2, 1, 17, 1)
      self.bg[2]:writeSequence(first + 0x10, 1, d[1] * 3 + 6, 2, 1, 17, 1)
      self.d.numStandingsPrinted = self.d.numStandingsPrinted + 1
      self:destroyTask(tid)
      self.sound:se("SE_CONTEST_PLACE")
    end
  end
end

-- pokeemerald/src/contest_util.c:1549
function UI:taskStartHighlightWinnersBox(tid, d)
  local i = self:winnerId()
  local L = self.bg[2]
  local src = {}
  for y = 0, 2 do
    for x = 0, 31 do src[y * 32 + x] = L:get(x, i * 3 + 4 + y) end
  end
  L:copyRect(src, 0, i * 3 + 4, 32, 3, 9)
  d[10] = i
  d[12] = 1
  self:setFunc(tid, "taskHighlightWinnersBox")
  self.d.highlightWinnerTaskId = tid
end

-- pokeemerald/src/contest_util.c:1560
function UI:taskHighlightWinnersBox(tid, d)
  d[11] = d[11] + 1
  if d[11] == 1 then
    d[11] = 0
    self:pal():blend(9 * 16 + 1, 1, d[12], rgb(13, 28, 27))
    if d[13] == 0 then
      d[12] = d[12] + 1
      if d[12] == 16 then d[13] = 1 end
    else
      d[12] = d[12] - 1
      if d[12] == 0 then d[13] = 0 end
    end
  end
end

-- pokeemerald/src/contest_util.c:1579
function UI:spriteCBWinnerMonSlideIn(s)
  if s.data[0] < 10 then
    s.data[0] = s.data[0] + 1
    if s.data[0] == 10 then
      self.sound:cry(s.data[1], 0)
      s.data[1] = 0
    end
  else
    local delta = s.data[1] + 0x600
    s.x = s.x - rshift(delta, 8)
    s.data[1] = band(s.data[1] + 0x600, 0xFF)
    if s.x < DISPLAY_WIDTH / 2 then s.x = DISPLAY_WIDTH / 2 end
    if s.x == DISPLAY_WIDTH / 2 then
      s.callback = nil
      s.data[1] = 0
      self.d.winnerMonSlidingState = SLIDING_MON_ENTERED
    end
  end
end

-- pokeemerald/src/contest_util.c:1607
function UI:spriteCBWinnerMonSlideOut(s)
  local delta = s.data[1] + 0x600
  s.x = s.x - rshift(delta, 8)
  s.data[1] = band(s.data[1] + 0x600, 0xFF)
  if s.x < -32 then
    s.callback = nil
    s.invisible = true
    self.d.winnerMonSlidingState = SLIDING_MON_EXITED
  end
end

function UI:confettiSheet(k)
  local hit = self.confettiSheets[k]
  if hit then return hit end
  self.confettiTiles = self.confettiTiles or Vram.decodeTiles(self:bytes("gfx", "confetti"), {}, 0)
  hit = Vram.sheet(self.confettiTiles, { k }, 8, 8, self.headless)
  self.confettiSheets[k] = hit
  return hit
end

-- pokeemerald/src/contest_util.c:1621
function UI:taskCreateConfetti(tid, d)
  d[0] = d[0] + 1
  if d[0] == 5 then
    d[0] = 0
    if self.d.confettiCount < 40 then
      local x = (self:rand() % DISPLAY_WIDTH) - 20
      local id, s = self:newSprite({ w = 8, h = 8 }, x, 44, 5)
      s.oam.paletteNum = self.confettiPal
      s.data[0] = self:rand() % 512
      s.data[1] = (self:rand() % 24) + 16
      s.data[2] = (self:rand() % 256) + 48
      s.sheet = self:confettiSheet(self:rand() % 17)
      s.data[3], s.data[4] = 0, 0
      s.callback = function(sp) self:spriteCBConfetti(sp) end
      self.d.confettiCount = self.d.confettiCount + 1
    end
  end
  if self.d.destroyConfetti then self:destroyTask(tid) end
end

-- pokeemerald/src/contest_util.c:1641
function UI:spriteCBConfetti(s)
  s.data[3] = s16(s.data[3] + s.data[0])
  -- pokeemerald/src/trig.c:515
  s.x2 = bit.arshift(s16(s.data[1]) * (self.man.sine[rshift(band(s.data[3], 0xFFFF), 8)] or 0), 8)
  local delta = s.data[4] + s.data[2]
  s.x = s.x + rshift(delta, 8)
  s.data[4] = band(s.data[4] + s.data[2], 0xFF)
  s.y = s.y + 1
  if self.d.destroyConfetti then s.invisible = true end
  if s.x > DISPLAY_WIDTH + 8 or s.y > 116 then
    self:sprites():destroy(s)
    self.d.confettiCount = self.d.confettiCount - 1
  end
end

-- pokeemerald/src/contest_util.c:1669
function UI:bounceMonIconInBox(i, numFrames)
  local tid = self:createTask("taskBounceMonIconInBox", 8)
  local d = self:task(tid).data
  d[0], d[1] = i, numFrames
end

-- pokeemerald/src/contest_util.c:1677
function UI:taskBounceMonIconInBox(tid, d)
  local v = d[10]
  d[10] = v + 1
  if v == d[1] then
    d[10] = 0
    self:loadContestMonIcon(d[0], d[11], false)
    d[11] = bit.bxor(d[11], 1)
  end
end

function UI:frame(inp)
  if self.done then return end
  self.frames = self.frames + 1
  self.inp = inp or { new = {}, held = {} }
  local m = self.m
  m.vblankCounter1 = m.vblankCounter1 + 1
  if m.vblankCb then m.vblankCb(m) end
  GcKit.readKeys(m, self.inp)
  if m.cb2 then m.cb2(m) end
end

local function color(c)
  return { band(c, 31) / 31, band(rshift(c, 5), 31) / 31, band(rshift(c, 10), 31) / 31, 1 }
end

function UI:draw()
  if self.headless then return end
  local lg = love.graphics
  self.m.ppu:draw(0, 0)
  local FrlgFont = require("src.ui.game3.frlg_font")
  local pltt = self.m.ppu.palette.pltt
  local fg, sh = color(pltt[15 * 16 + 1] or 0), color(pltt[15 * 16 + 8] or 0)
  local red = color(pltt[15 * 16 + 2] or 0)
  -- pokeemerald/src/contest_util.c:417
  local top, bottom = rshift(self.win0v, 8), band(self.win0v, 0xFF)
  if bottom <= top then top, bottom = DISPLAY_HEIGHT, DISPLAY_HEIGHT end
  for _, band_ in ipairs({ { 0, top }, { bottom, DISPLAY_HEIGHT } }) do
    if band_[2] > band_[1] then
      lg.setScissor(0, band_[1], DISPLAY_WIDTH, band_[2] - band_[1])
      for i = 0, N - 1 do
        local n = self.names and self.names[i]
        if n then
          local x, y = 7 * 8, (4 + i * 3) * 8 + 2
          FrlgFont.draw(n.nick, x, y, { font = "narrow", colors = { fg = n.player and red or fg, shadow = sh } })
          FrlgFont.draw(n.trainer, x + 50, y, { font = "narrow", colors = { fg = n.player and red or fg, shadow = sh } })
        end
      end
      lg.setScissor()
    end
  end
  for _, id in ipairs({ self.d.slidingTextBoxSpriteId, self.d.linkTextBoxSpriteId }) do
    local bt = self.boxTexts and self.boxTexts[id]
    local s = bt and self:sprite(bt.spriteId)
    if s and s.inUse and not s.invisible then
      local palNum = s.oam.paletteNum
      local tfg = color(pltt[256 + palNum * 16 + 15] or 0)
      local tsh = color(pltt[256 + palNum * 16 + 14] or 0)
      local x = s.x + s.x2 - 32 + bt.x
      local y = s.y + s.y2 - 16 + 8 + 1
      local clipTop = id == self.d.linkTextBoxSpriteId and (s.y + s.y2 - 16) or (DISPLAY_HEIGHT - 32)
      lg.setScissor(0, clipTop, DISPLAY_WIDTH, 32)
      FrlgFont.draw(bt.text, x, y, { colors = { fg = tfg, shadow = tsh } })
      lg.setScissor()
    end
  end
  if self.hwFade and self.hwFade.y > 0 then
    lg.setColor(0, 0, 0, self.hwFade.y / 16)
    lg.rectangle("fill", 0, 0, DISPLAY_WIDTH, DISPLAY_HEIGHT)
    lg.setColor(1, 1, 1, 1)
  end
end

local Host = {}
UI.Host = Host

function UI.open(opts)
  local Stack = require("src.ui.game3.stack")
  local SceneKit = require("src.ui.game3.rse.scene_kit")
  local screen = ((opts and opts.sceneClass) or UI).new(opts)
  Host._screen = screen
  Host._step = SceneKit.stepper()
  local userDone = opts and opts.onDone
  screen.onDone = function()
    Host._screen = nil
    Stack.pop(UI.ID)
    if userDone then userDone(screen) end
  end
  if screen.headless then
    for _ = 1, opts.maxFrames or 100000 do
      if screen.done then break end
      screen:frame({ new = { a = true }, held = {}, rep = {} })
    end
    screen.onDone()
    return screen
  end
  Stack.push(UI.ID, Host, { hideBelow = true, fullscreen = true })
  return screen
end

function UI.active() return Host._screen end

function UI.reset()
  if Host._screen then
    Host._screen = nil
    require("src.ui.game3.stack").pop(UI.ID)
  end
end

function Host.handleInput(input)
  if Host._step then Host._step:collect(input) end
end

function Host.update(dt)
  local screen = Host._screen
  if not screen then return end
  Host._step:run(dt, function(inp)
    if screen.done then return true end
    screen:frame(inp)
    return screen.done or nil
  end)
  if screen.done and Host._screen == screen then screen.onDone() end
end

function Host.draw()
  local screen = Host._screen
  if screen then screen:draw() else love.graphics.clear(0, 0, 0, 1) end
end

return UI
