local bit = require("bit")
local Base = require("src.ui.game3.rse.contest")
local Vram = require("src.ui.game3.rse.contest_vram")
local Ppu = require("src.core.game3.gba_ppu")
local Kit = require("src.ui.game3.rse.scene_kit")
local FastFade = require("src.ui.game3.rs.contest_fast_fade")
local UI = setmetatable({SUB = "rse/rs_contest_gfx", ID = Base.ID}, {__index = Base})
UI.__index = UI

function UI.new(opts)
  local own = {}; for k, v in pairs(opts or {}) do own[k] = v end
  own.manifest = own.manifest or Vram.manifest(UI.SUB)
  assert(own.manifest.assetLayout == "rs", "native RS contest graphics missing")
  local self = setmetatable(Base.new(own), UI)
  FastFade.install(self:pal())
  self.setupState = 0
  return self
end
function UI.open(opts)
  local own = {}; for k, v in pairs(opts or {}) do own[k] = v end
  own.sceneClass = UI
  return Base.open(own)
end

-- pokeruby/src/contest.c:113
function UI:loadVram()
  local tiles = Vram.decodeTiles(self:bytes("gfx", "interface"), {}, 0)
  local audience = self:bytes("gfx", "audience")
  Vram.decodeTiles(audience, tiles, 256)
  local alternate = {}; for k, v in pairs(tiles) do alternate[k] = v end
  -- contest_2.c:3576
  Vram.decodeTiles(audience:sub(0x1000 + 1, 0x2000), alternate, 256)
  self.tilesA, self.tilesB = tiles, alternate
  self.bg = {
    [0] = Vram.layer(tiles, 32, 64, self.headless),
    [1] = Vram.layer(tiles, 32, 64, self.headless),
    [2] = Vram.layer(tiles, 32, 64, self.headless),
    [3] = Vram.layer(tiles, 32, 32, self.headless),
  }
  self.bg2B = Vram.layer(alternate, 32, 64, self.headless)
  local map = Vram.u16s(self:bytes("maps", "audience"))
  self.bg[2]:load(map, 32 * 64)
  self.bg2B:load(map, 32 * 64)
  self.bg[3]:load(Vram.u16s(self:bytes("maps", "interface")), 32 * 32)
  self.audienceFrame = 0
end

function UI:attachBgs()
  for i = 0, 3 do
    local layer = i == 2 and self.audienceFrame == 1 and self.bg2B or self.bg[i]
    self.m.ppu:setBg(i, self.bgPrio[i], layer.layer, i == 3)
  end
end

function UI:setAudienceFrame(frame)
  self.audienceFrame = frame
  if not self.headless then
    self.m.ppu:setBg(2, self.bgPrio[2], (frame == 1 and self.bg2B or self.bg[2]).layer, false)
  end
end

function UI:setBgPriority(i, priority)
  self.bgPrio[i] = priority
  if not self.headless then
    local layer = i == 2 and self.audienceFrame == 1 and self.bg2B or self.bg[i]
    self.m.ppu:setBg(i, priority, layer.layer, i == 3)
  end
end

-- pokeruby/src/contest.c:419
function UI:vblankCb()
  local p = self.m.ppu
  for i = 0, 3 do
    p:set("BG" .. i .. "HOFS", bit.band(self.bgX[i], 0x1FF))
    p:set("BG" .. i .. "VOFS", bit.band(self.bgY[i], 0x1FF))
  end
  p:vblank()
  if not self.headless then
    for i = 0, 3 do self.bg[i]:flush() end
    self.bg2B:flush()
  end
end

-- contest_2.c:1076
function UI:swapMoveDescAndContestTilemaps()
  Base.swapMoveDescAndContestTilemaps(self)
  for y = 0, 9 do
    for x = 0, 31 do self.bg2B:put(x, y + 20, self.bg[2]:get(x, y + 20)) end
  end
end

function UI:loadContestPalettes()
  Base.loadContestPalettes(self)
  self:pal():fill(0, 0, 1)
end

-- pokeruby/src/contest.c:204
function UI:startCb()
  local m, st = self.m, self.m.state
  if st == 0 then
    self:pal():resetFade()
    self:pal().bufferTransferDisabled = true
    self:sprites():resetData(); self:sprites():freeAllPalettes()
    self:sprites():setReservedPalettes(4)
    m.tasks:reset(); self.c:init()
    for i = 0, 3 do m.ppu:set("BG" .. i .. "CNT", self.man.stageBgControl[i + 1]) end
  elseif st == 1 then
    self:loadContestPalettes()
  elseif st == 2 then
    local setup = self.setupState
    if setup == 1 then self:loadVram(); self:loadSheets()
    elseif setup == 5 then self:loadPalettes()
    elseif setup == 6 then
      self:drawContestantWindows(); self:fillContestantWindowBgs(); self:swapMoveDescAndContestTilemaps()
      self.e.judgeSpeechBubbleSpriteId = self:createJudgeSpeechBubbleSprite()
      self:createSliderHeartSprites(); self:createNextTurnSprites(); self:createApplauseMeterSprite()
      self:createJudgeAttentionEyeTask()
      self.judgeSpriteId = self:createJudgeSprite()
    end
    self.setupState = setup + 1
    if setup < 7 then return end
    self.setupState = 0
  elseif st == 3 then
    self:setBgForCurtainDrop()
    self.bgX[1], self.bgY[1] = 0, 0
    m.ppu:set("BG0CNT", 0x9801); m.ppu:set("BG1CNT", 0x9E00)
    m.ppu:set("BG2CNT", 0x9C01)
    m.ppu:set("DISPCNT", Ppu.DISPCNT_OBJ_1D_MAP + Ppu.DISPCNT_BG_ALL_ON + Ppu.DISPCNT_OBJ_ON +
      Ppu.DISPCNT_WIN0_ON + Ppu.DISPCNT_WIN1_ON)
    m.ppu:set("WININ", 0x3F3F); m.ppu:set("WINOUT", 0x3F3F)
    self:attachBgs()
    FastFade.begin(self:pal())
    self:pal().bufferTransferDisabled = false
    m:setVBlank(function() self:vblankCb() end)
    self.mainTaskId = self:createTask("taskStartContestWaitFade", 10)
    m:setCb2(function() self:mainCb() end)
    return
  end
  m.state = st + 1
end

function UI:taskStartContestWaitFade(tid)
  if not self:pal():fadeActive() then self:setFunc(tid, "taskTryStartLinkContest") end
end
function UI:taskTryStartLinkContest(tid)
  self:setFunc(tid, "taskWaitToRaiseCurtainAtStart")
end

-- pokeruby/src/contest_2.c:872
function UI:drawContestantWindowText()
  for i = 0, 3 do
    self.win[self:turnOrder(i)] = {font = "native_4", shadow = 8, parts = {
      {text = self:monName(i), x = 149, y = 0, fg = i + 10},
      {text = Base.plain("gText_Slash") .. self:trainerName(i), x = 200, y = 0, fg = i + 10},
    }}
  end
end
function UI:trainerName(i) return require("src.core.game3.rs.contest_util").trainerNameAt(self.c, i) end
function UI:startText(key, vars, speedy)
  Base.startText(self, key, vars, speedy)
  self.win[4].y = 0
end
function UI:taskShowMoveSelectScreen(tid, d)
  Base.taskShowMoveSelectScreen(self, tid, d)
  for i = 0, 3 do
    local w = self.win[5 + i]
    if w then w.x, w.y, w.font = 4, 0, "native_4" end
  end
end
function UI:printContestMoveDescription(move)
  Base.printContestMoveDescription(self, move)
  local cm = self.c.data.moves[move] or {}
  local eff = self.c.data.effects[cm.effect or 0] or {}
  self.win[10].text = eff.description or ""
  for _, id in ipairs({9, 10}) do self.win[id].y, self.win[id].font = 0, "native_3" end
end

function UI:drawMoveSelectArrow(i)
  if self.moveCursor == nil then
    local colors = {}; for k = 1, 16 do colors[k] = 0 end
    colors[13] = 0x2D9F
    self.cursorPal = self:sprites():loadPalette(0xFFF0, colors)
    if self.cursorPal == 255 then self.cursorPal = 0 end
  end
  self.moveCursor = i
end
function UI:eraseMoveSelectArrow() end
function UI:taskHandleMoveSelectInput(tid)
  local inp = self.inp or {new = {}, rep = {}}
  local rep, count, key = inp.rep or inp.new or {}, 0
  for k, v in pairs(rep) do if v then count, key = count + 1, k end end
  if not self:joyNew(require("src.ui.game3.rse.gc_kit").A) and
      not (count == 1 and (key == "up" or key == "down" or key == "b")) then return end
  Base.taskHandleMoveSelectInput(self, tid)
  if (inp.new and inp.new.a) or key == "b" then
    self.moveCursor = nil
    local sp = self:sprites()
    local index = sp:indexOfPaletteTag(0xFFF0)
    if index ~= 255 then sp.paletteTags[index] = 0xFFFF end
  end
end

function UI:draw()
  if self.headless or not self.bg then return end
  Base.draw(self)
  if self.moveCursor == nil then return end
  local Cursor = require("src.ui.game3.rs.menu_cursor")
  local man = assert(Kit.manifest("rse/common_ui"))
  local parts = man.menuCursor.parts or man.menuCursor
  local c = self:pal().pltt[256 + self.cursorPal * 16 + 12] or 0
  local r, g, b = Kit.rgb555(c)
  local segments = Cursor.segments(72)
  for i = #segments, 1, -1 do
    local seg = segments[i]
    love.graphics.setColor(r, g, b, 1)
    love.graphics.draw(assert(Kit.image(parts[seg.part].mask)), 4 + seg.x, 88 + self.moveCursor * 16)
  end
  love.graphics.setColor(1, 1, 1, 1)
end
return UI
