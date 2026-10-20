local Base = require("src.ui.game3.rse.roulette")
local R = require("src.core.game3.rse.roulette")
local Kit = require("src.ui.game3.rse.gc_kit")
local Ppu = require("src.core.game3.gba_ppu")
local Font = require("src.ui.game3.frlg_font")
local SceneKit = require("src.ui.game3.rse.scene_kit")
local UI = setmetatable({}, {__index = Base})
UI.__index = UI

UI.TEXT_ALIASES = {
  Roulette_Text_PlayMinimumWagerIsX = "gUnknown_081C40DF",
  Roulette_Text_NotEnoughCoins = "gUnknown_081C411C",
  Roulette_Text_SpecialRateTable = "gUnknown_081C4139",
  Roulette_Text_ControlsInstruction = "gUnknown_081C4157",
  Roulette_Text_ItsAHit = "gUnknown_081C4199",
  Roulette_Text_Jackpot = "gUnknown_081C41A5",
  Roulette_Text_NothingDoing = "gUnknown_081C41AE",
  Roulette_Text_YouveWonXCoins = "gUnknown_081C41BD",
  Roulette_Text_NoCoinsLeft = "gUnknown_081C41D2",
  Roulette_Text_KeepPlaying = "gUnknown_081C41E3",
  Roulette_Text_BoardWillBeCleared = "gUnknown_081C41F1",
  Roulette_Text_CoinCaseIsFull = "gUnknown_081C4231",
}

local function text(key, vars)
  return require("src.core.game3.rom_text").plain(assert(UI.TEXT_ALIASES[key], "native RS Roulette text key missing: " .. tostring(key)),
    vars and {stringVars = vars} or nil)
end

local function drawYesNo(yn, fade)
  if not yn then return end
  require("src.ui.game3.chrome").stdFrame(21, 9, 5, 4)
  local colors = SceneKit.messageColors("std_menu")
  for i = 0, 1 do
    Font.draw(require("src.core.game3.rom_text").at("gMenuYesNoItems", i), 21 * 8, 9 * 8 + 16 * i,
      {font = "native_3", colors = colors})
  end
  require("src.ui.game3.rs.menu_cursor").draw(21 * 8, 9 * 8 + yn.cursor * 16, 40)
end

local function drawMessage(message, fade)
  if not message then return end
  -- roulette.c:496
  local colors = SceneKit.messageColors("std_menu")
  if fade and fade > 0 then
    local k = (16 - fade) / 16
    local faded = {}
    for key, c in pairs(colors) do
      faded[key] = type(c) == "table" and {c[1] * k, c[2] * k, c[3] * k, c[4]} or c
    end
    colors = faded
  end
  require("src.ui.game3.chrome").stdFrame(1, 15, 28, 4)
  Font.draw(message, 8, 120, {font = "native_3", colors = colors, maxWidth = 224})
end

function UI.new(opts)
  opts = opts or {}
  opts.constants = opts.constants or require("src.core.game3.constants").active(opts.session)
  local self = Base.new(opts, UI)
  assert(self.man.assetLayout == "rs", "native RS Roulette pack required")
  return self
end

-- roulette.c:436
function UI:loadCb()
  local m, p, state = self.m, self.m.ppu, self.m.state
  if state == 0 then
    m:setVBlank(nil)
    self:initBgs()
    p:set("BG0CNT", 0x1F08)
    p:set("BG1CNT", 0x4401)
    p:set("BG2CNT", 0x4686)
    p:set("BLDCNT", Ppu.BLDCNT_TGT2_BG2 + Ppu.BLDCNT_TGT2_BD)
    p:set("BLDALPHA", Ppu.blendAlpha(10, 6))
  elseif state == 1 then
    p.palette:resetFade()
    p.sprites:resetData()
    m.tasks:reset()
  elseif state == 2 then
    p.palette:load(self.man.palettes.wheel, 0, 14 * 16)
  elseif state == 3 then
    self:initTableData()
  elseif state == 4 then
    p.sprites:freeAllPalettes()
    for _, pal in ipairs(self.man.palettes.sprites) do p.sprites:loadPalette(pal.tag, pal.colors) end
    self:createWheelBallSprites()
    self:createWheelCenterSprite()
    self:createInterfaceSprites()
    self:createGridSprites()
    self:createGridBallSprites()
    self:createWheelIconSprites()
  elseif state == 5 then
    p.sprites:animateAll()
    Kit.buildOam(m)
    self:setCreditDigits(self.opts.coins or 0)
    self:setBallCounterNumLeft(R.BALLS_PER_ROUND)
    self:setMultiplierSprite(0)
    self:drawGridBackground(0)
    self:showText("Roulette_Text_ControlsInstruction")
    m.coordOffsetX, m.coordOffsetY = -60, 0
  elseif state == 6 then
    p:set("DISPCNT", Ppu.DISPCNT_MODE_1 + Ppu.DISPCNT_OBJ_1D_MAP + Ppu.DISPCNT_OBJ_ON
      + Ppu.DISPCNT_BG0_ON + Ppu.DISPCNT_BG1_ON + Ppu.DISPCNT_BG2_ON)
  elseif state == 7 then
    m:setVBlank(function() self:vblankCb() end)
    self:beginHwFade(0xFF, 0, 16, 0, 1)
    local tid = m.tasks:create(self:func("taskStartPlaying"), 0)
    self.st.playTaskId = tid
    self:task(tid).data[6], self:task(tid).data[13] = R.BALLS_PER_ROUND, self.opts.coins or 0
    self.st.spinTaskId = m.tasks:create(self:func("taskSpinWheel"), 1)
    m:setCb2(function() self:mainCb() end)
    return
  end
  m.state = state + 1
end

function UI:showText(key, vars) self.text = {key = key, text = text(key, vars)} end
function UI:tvHook() end
function UI:incrementDailyRouletteUses() end
function UI:taskAskKeepPlaying(tid)
  self.yesNo = {cursor = 0}
  self:showText("Roulette_Text_KeepPlaying")
  self.yesNoFuncs = {"taskContinuePlaying", "taskStopPlaying"}
  self:setFunc(tid, "taskCallYesOrNo")
end

function UI:draw()
  if self.headless then return end
  if self.hw then self.m.ppu:set("BLDCNT", self.hw.blendCnt % 0x10000); self.m.ppu:set("BLDY", self.hw.y) end
  self.m.ppu:draw(0, 0)
  local fade = self.hw and self.hw.active and self.hw.y or 0
  drawMessage(self.text and self.text.text, fade)
  drawYesNo(self.yesNo, fade)
end

local Entry = setmetatable({}, {__index = Base.Entry})
Entry.__index = Entry
function Entry.new(opts) return setmetatable(Base.Entry.new(opts), Entry) end
function Entry:showText(key, vars) self.text = text(key, vars) end
function Entry:frame(inp)
  if self.state == "notEnough" then
    -- roulette.c:1604
    self.notEnoughFrames = (self.notEnoughFrames or 0) + 1
    if self.notEnoughFrames >= 61 then
      if self.opts.setVar8004 then self.opts.setVar8004(1) end
      self.text, self.coinsWindow, self.state = nil, false, "declined"
      return "decline"
    end
  end
  return Base.Entry.frame(self, inp)
end
function Entry:draw() drawMessage(self.text); drawYesNo(self.yesNo) end
UI.Entry = Entry

function UI.open(opts) return Base.open(opts, UI.new) end
function UI.playEntry(opts)
  opts = opts or {}
  opts.constants = require("src.core.game3.constants").active(opts.session)
  opts.manifest = opts.manifest or R.loadTables(opts.cache)
  assert(opts.manifest.assetLayout == "rs", "native RS Roulette pack required")
  opts.entryConstructor, opts.openScreen = Entry.new, UI.open
  opts.partyFlagsFor = function(party) return R.partyFlags(party, nil, opts.constants) end
  return Base.playEntry(opts)
end
return UI
