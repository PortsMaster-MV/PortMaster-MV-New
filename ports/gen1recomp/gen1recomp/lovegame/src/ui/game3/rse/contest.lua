local bit = require("bit")
local band, bor, rshift = bit.band, bit.bor, bit.rshift

local Vram = require("src.ui.game3.rse.contest_vram")
local Machine = require("src.ui.game3.rse.gba_machine")
local Ppu = require("src.core.game3.gba_ppu")
local Sprites = require("src.core.game3.gba_sprites")
local GcKit = require("src.ui.game3.rse.gc_kit")
local Contest = require("src.core.game3.rse.contest")

local UI = {}
UI.__index = UI

UI.ID = "rse_contest"
UI.SUB = "rse/contest_gfx"

local N = Contest.CONTESTANT_COUNT
local STR_NONE = Contest.STRING.NONE
local JUDGE = Contest.JUDGE
local DISPLAY_WIDTH, DISPLAY_HEIGHT = 240, 160

-- pokeemerald/src/contest.c:198
local WIN_GENERAL_TEXT, WIN_MOVE0, WIN_SLASH, WIN_MOVE_DESCRIPTION = 4, 5, 9, 10
-- pokeemerald/src/contest.c:194
local CONTESTANT_TEXT_COLOR_START = 10
-- pokeemerald/src/contest.c:261
local TILE_FILLED_APPEAL_HEART, TILE_FILLED_JAM_HEART = 0x5012, 0x5014
local TILE_EMPTY_APPEAL_HEART, TILE_EMPTY_JAM_HEART = 0x5035, 0x5036
-- pokeemerald/include/constants/contest.h:7
local MAX_CONTEST_MOVE_HEARTS = 8
-- pokeemerald/src/contest.c:267
local SLIDER_HEART_ANIM_NORMAL, SLIDER_HEART_ANIM_DISAPPEAR, SLIDER_HEART_ANIM_APPEAR = 0, 1, 2
-- pokeemerald/src/contest.c:243
local TAG_CONTEST_SYMBOLS_PAL, TAG_APPLAUSE_METER, TAG_NEXT_TURN_PAL = 0xABE0, 0xABE2, 0x4E22
local TAG_BLINK_EFFECT_CONTESTANT0 = 0x80E8
-- pokeemerald/include/constants/rgb.h:15
local RGB_BLACK, RGB_WHITE, RGB_RED = 0, 0x7FFF, 0x001F

local function rgb(r, g, b) return r + g * 32 + b * 1024 end

local function s16(v)
  v = band(v, 0xFFFF)
  return v >= 0x8000 and v - 0x10000 or v
end

local function tdiv(a, b)
  local q = a / b
  return q >= 0 and math.floor(q) or -math.floor(-q)
end

function UI.new(opts)
  opts = opts or {}
  local self = setmetatable({}, UI)
  self.opts = opts
  self.c = assert(opts.contest, "contest screen needs a contest")
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
  self.bgPrio = { [0] = 0, 1, 0, 3 }
  self.win = {}
  self.gfxState = {}
  for i = 0, N - 1 do
    self.gfxState[i] = { sliderHeartSpriteId = 0, nextTurnSpriteIds = {}, updatingAppealHearts = false,
      sliderUpdating = false, boxBlinking = false }
  end
  self.e = {
    applauseMeterIsMoving = false, isShowingApplauseMeter = false, sliderHeartsAnimating = false,
    waitForJudgeSpeechBubble = false, animatingAudience = false, waitForAudienceBlend = false,
    moveAnimTurnCount = 0, turnNumber = 0,
  }
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
function UI:joyNew(mask) return GcKit.joyNew(self.m, mask) end

function UI:turnOrder(i) return self.c.turnOrder[i] end
function UI:status(i) return self.c.status[i] end

function UI:bytes(kind, key) return Vram.bytes(self.man, kind, key) end

-- pokeemerald/src/contest.c:1301
function UI:loadVram()
  local interface = self:bytes("gfx", "interface")
  local audience = self:bytes("gfx", "audience")
  local tilesA = Vram.decodeTiles(interface, {}, 0)
  Vram.decodeTiles(audience, tilesA, 256)
  local tilesB = {}
  for k, v in pairs(tilesA) do tilesB[k] = v end
  Vram.decodeTiles(audience:sub(0x1000 + 1, 0x2000), tilesB, 256)
  self.tilesA, self.tilesB = tilesA, tilesB
  local h = self.headless
  self.bg = {
    [0] = Vram.layer(tilesA, 32, 64, h),
    [1] = Vram.layer(tilesA, 32, 64, h),
    [2] = Vram.layer(tilesA, 32, 64, h),
    [3] = Vram.layer(tilesA, 32, 32, h),
  }
  self.bg3B = Vram.layer(tilesB, 32, 32, h)
  local aud = Vram.u16s(self:bytes("maps", "audience"))
  self.bg[3]:load(aud, 32 * 32)
  self.bg3B:load(aud, 32 * 32)
  self.bg[2]:load(Vram.u16s(self:bytes("maps", "interface")), 32 * 64)
  self.audienceFrame = 0
end

function UI:attachBgs()
  local p = self.m.ppu
  for i = 0, 3 do
    local L = self.bg[i]
    if i == 3 and self.audienceFrame == 1 then L = self.bg3B end
    p:setBg(i, self.bgPrio[i], L.layer, i == 3)
  end
end

-- pokeemerald/src/contest.c:1332
function UI:loadPalettes()
  local pal = self:pal()
  pal:load(self.man.palettes.interface_audience, 0, 256)
  -- pokeemerald/src/contest.c:1333
  local player = self.c.playerIndex
  local a, b = {}, {}
  for k = 0, 15 do
    a[k + 1] = pal.unfaded[8 * 16 + k]
    b[k + 1] = pal.unfaded[(5 + player) * 16 + k]
  end
  pal:load(b, 8 * 16, 16)
  pal:load(a, (5 + player) * 16, 16)
  self.cachedWindowPalettes = {}
  for bank = 0, 15 do
    local t = {}
    for k = 0, 15 do t[k + 1] = pal.unfaded[bank * 16 + k] end
    self.cachedWindowPalettes[bank] = t
  end
  self:loadContestPalettes()
end

-- pokeemerald/src/contest.c:1074
function UI:loadContestPalettes()
  local pal = self:pal()
  pal:load(self.man.palettes.text, 15 * 16, 16)
  for i = 10, 13 do pal:load({ pal.unfaded[15 * 16 + 1] }, 15 * 16 + i, 1) end
  pal:fill(rgb(31, 17, 31), 15 * 16 + 3, 1)
end

function UI:setAudienceFrame(f)
  self.audienceFrame = f
  if not self.headless then self.m.ppu:setBg(3, self.bgPrio[3], (f == 1 and self.bg3B or self.bg[3]).layer, true) end
end

function UI:setBgPriority(i, prio)
  self.bgPrio[i] = prio
  if not self.headless then
    local L = self.bg[i]
    if i == 3 and self.audienceFrame == 1 then L = self.bg3B end
    self.m.ppu:setBg(i, prio, L.layer, i == 3)
  end
end

-- pokeemerald/src/contest.c:5490
function UI:fillBoxInc(bg, first, x, y, w, h, slot, delta)
  self.bg[bg]:writeSequence(first, x, y, w, h, slot, delta)
end

function UI:fillBox(bg, first, x, y, w, h, slot)
  self.bg[bg]:writeSequence(first, x, y, w, h, slot, 0)
end

-- pokeemerald/src/contest.c:5431
function UI:setWindow(id, text, opts)
  opts = opts or {}
  self.win[id] = { text = text, x = opts.x or 0, y = opts.y or 1, font = opts.font, fg = opts.fg or 15,
    shadow = opts.shadow or 8, rightAlign = opts.rightAlign }
end

function UI:clearWindow(id)
  self.win[id] = nil
end

-- pokeemerald/src/contest.c:3381
function UI:clearGeneralText()
  self.printer = nil
  self.win[WIN_GENERAL_TEXT] = nil
end

-- pokeemerald/src/contest.c:5454
function UI:startText(key, vars, speedy)
  local Kit = require("src.ui.game3.rse.scene_kit")
  local ir = key
  if type(key) == "string" then ir = UI.ir(key) end
  local speed = 0
  if speedy then
    local ok, Options = pcall(require, "src.core.game3.options")
    speed = Kit.textSpeedDelay(ok and Options.textSpeed(self.session) or 1)
  end
  self.printer = Kit.printer(ir, { ctx = { stringVars = vars or {} }, speed = speed, canSpeedUp = true })
  self.win[WIN_GENERAL_TEXT] = { printer = self.printer, x = 0, y = 1, fg = 1, shadow = 8 }
end

-- pokeemerald/src/contest.c:5501
function UI:textActive()
  return self.printer ~= nil and self.printer:isActive()
end

function UI:runText(inp)
  if self.printer and self.printer:isActive() then self.printer:run(inp or { new = {}, held = {} }) end
end

local function RomText() return require("src.core.game3.rom_text") end
local function Util() return require("src.core.game3.rse.contest_util") end

local function nativeText(key)
  local p = require("src.core.game3.profile").forSession()
  if p.id ~= "ruby" and p.id ~= "sapphire" then return nil end
  local man = Vram.manifest("rse/rs_contest_gfx")
  local bytes = man.texts and man.texts[key]
  if not bytes then return nil end
  local list, i = {}, 1
  while i <= #bytes do
    if bytes[i] == 0xFC and bytes[i + 1] == 0 then
      list[#list + 1], list[#list + 2] = 0xFD, 1
      i = i + 2
    else list[#list + 1] = bytes[i]; i = i + 1 end
  end
  return require("src.core.game3.scripting.text_ir").decode(list, {dialect = "rs"})
end

function UI.ir(key)
  return nativeText(key) or RomText().ir(key)
end

function UI.has(key)
  return nativeText(key) ~= nil or RomText().has(key)
end

function UI.plain(key, vars)
  local TextIR = require("src.core.game3.scripting.text_ir")
  return TextIR.toPlain(UI.ir(key), { stringVars = vars or {} })
end

function UI:monName(i) return Util().monName(self.c.mons[i]) end
function UI:trainerName(i) return Util().trainerName(self.c.mons[i]) end

function UI:moveName(move)
  if self.opts.moveName then return self.opts.moveName(move) end
  return require("src.core.game3.pokemon").moveName(move)
end

function UI:manText(entry)
  if type(entry) ~= "table" then return entry end
  if entry.name and UI.has(entry.name) then return UI.ir(entry.name) end
  local TextIR = require("src.core.game3.scripting.text_ir")
  local list = {}
  for i = 1, #(entry.bytes or {}) do list[i] = entry.bytes[i] end
  if #list == 0 or list[#list] ~= 0xFF then list[#list + 1] = 0xFF end
  return TextIR.decode(list, { dialect = TextIR.dialectOf() })
end

-- pokeemerald/src/contest.c:3000
function UI:drawContestantWindowText()
  for i = 0, N - 1 do
    local wid = self:turnOrder(i)
    local color = i + CONTESTANT_TEXT_COLOR_START
    local FrlgFont = require("src.ui.game3.frlg_font")
    local slashName = UI.plain("gText_Slash") .. self:trainerName(i)
    local w = FrlgFont.measure(slashName, { font = "narrow" })
    local offset = 0x60 - w
    if offset > 55 then offset = 55 end
    self.win[wid] = {
      parts = {
        { text = self:monName(i), x = 5, y = 1, fg = color },
        { text = slashName, x = offset, y = 1, fg = color },
      },
      font = "narrow", shadow = 8,
    }
  end
end

-- pokeemerald/src/contest.c:3676
function UI:fillContestantWindowBgs()
  for i = 0, N - 1 do self:fillBox(0, 0, 0x16, 2 + i * 5, 8, 2, 0x11) end
end

-- pokeemerald/src/contest.c:3161
function UI:swapMoveDescAndContestTilemaps()
  for _, b in ipairs({ 0, 2 }) do
    local L = self.bg[b]
    for y = 0, 9 do
      for x = 0, 31 do L:put(x, y + 20, L:get(x, y)) end
    end
  end
end

-- pokeemerald/src/contest.c:4413
function UI:drawContestantWindows()
  local pal = self:pal()
  for i = 0, N - 1 do
    pal:load(self.cachedWindowPalettes[5 + i], (5 + self:turnOrder(i)) * 16, 16)
  end
  self:drawContestantWindowText()
end

function UI:loadSheets()
  local h = self.headless
  local tiles = {}
  local function t(key) return Vram.decodeTiles(self:bytes("gfx", key), {}, 0) end
  tiles.slider = t("slider_heart")
  tiles.nextTurn = t("next_turn")
  tiles.numbers = t("next_turn_numbers")
  tiles.random = t("next_turn_random")
  tiles.applause = t("applause")
  tiles.meter = t("applause_meter")
  tiles.judge = t("judge")
  tiles.symbols = t("judge_symbols")
  self.tileSets = tiles
  self.sheets = {
    slider = Vram.sheet(tiles.slider, { 0 }, 8, 8, h),
    judge = Vram.sheet(tiles.judge, { 0 }, 64, 64, h),
    symbols = Vram.sheet(tiles.symbols, { 0, 4, 8, 12, 16, 20, 24 }, 16, 16, h),
  }
  self.nextTurnSheets = {}
  self.applauseSheets = {}
end

-- pokeemerald/src/contest.c:5031
function UI:nextTurnSheet(key, numberTile)
  local hit = self.nextTurnSheets[key]
  if hit then return hit end
  local T = self.tileSets
  local list = {}
  for k = 0, 7 do list[k] = T.nextTurn[k] end
  if numberTile then list[6] = numberTile end
  local left, right = {}, {}
  for k = 0, 3 do left[k] = list[k]; right[k] = list[k + 4] end
  hit = { Vram.sheetFromTileList(left, 32, 8, self.headless), Vram.sheetFromTileList(right, 32, 8, self.headless) }
  self.nextTurnSheets[key] = hit
  return hit
end

-- pokeemerald/src/contest.c:4728
function UI:applauseSheet(level)
  local hit = self.applauseSheets[level]
  if hit then return hit end
  local T = self.tileSets
  local list = {}
  for k = 0, 31 do list[k] = T.applause[k] end
  if level ~= "base" then
    for i = 0, 4 do
      local src = i < level and 2 or 0
      list[17 + i] = T.meter[src]
      list[25 + i] = T.meter[src + 1]
    end
  end
  hit = Vram.sheetFromTileList(list, 64, 32, self.headless)
  self.applauseSheets[level] = hit
  return hit
end

local function affineList(t)
  local out = {}
  for i = 0, 15 do
    if t[i] == nil then break end
    out[i + 1] = t[i]
  end
  return out
end

function UI:newSprite(template, x, y, sub)
  local sp = self:sprites()
  local id = sp:create(template, x, y, sub)
  local s = sp.sprites[id]
  s.callback = template.callback
  return id, s
end

-- pokeemerald/src/sprite.c:1427
function UI:startAffine(s, animId)
  local sp = self:sprites()
  if band(s.oam.affineMode, 1) == 0 then
    local n = sp:allocMatrix()
    s.oam.matrixNum = n
    s.oam.affineMode = Sprites.AFFINE_NORMAL
    sp:affineStateReset(n)
  end
  sp:startAffineAnim(s, animId)
end

-- pokeemerald/src/sprite.c:884
function UI:freeMatrix(s)
  local sp = self:sprites()
  if band(s.oam.affineMode, 1) ~= 0 then
    sp.matrixBitmap = band(sp.matrixBitmap, bit.bnot(bit.lshift(1, s.oam.matrixNum)))
    s.oam.matrixNum = 0
    s.oam.affineMode = Sprites.AFFINE_OFF
  end
end

-- pokeemerald/src/contest.c:3839
function UI:createSliderHeartSprites()
  local sp = self:sprites()
  local palNum = sp:loadPalette(TAG_CONTEST_SYMBOLS_PAL, self.man.palettes.judge_symbols)
  for i = 0, N - 1 do
    local y = self.man.sliderHeartY[self:turnOrder(i)]
    local id, s = self:newSprite({ w = 8, h = 8, sheet = self.sheets.slider, paletteTag = TAG_CONTEST_SYMBOLS_PAL,
      affineAnims = affineList(self.man.affine.sliderHeart) }, 180, y, 1)
    s.oam.paletteNum = palNum
    self.gfxState[i].sliderHeartSpriteId = id
  end
end

-- pokeemerald/src/contest.c:3945
function UI:createNextTurnSprites()
  local sp = self:sprites()
  local palNum = sp:loadPalette(TAG_NEXT_TURN_PAL, self.man.palettes.contest)
  for i = 0, N - 1 do
    local y = self.man.nextTurnY[self:turnOrder(i)]
    local sheets = self:nextTurnSheet("blank")
    local ids = {}
    for k = 1, 2 do
      local id, s = self:newSprite({ w = 32, h = 8, sheet = sheets[k] }, 204 + (k == 1 and -12 or 20), y, 0)
      s.oam.paletteNum = palNum
      s.invisible = true
      ids[k] = id
    end
    self.gfxState[i].nextTurnSpriteIds = ids
  end
end

-- pokeemerald/src/contest.c:3962
function UI:createApplauseMeterSprite()
  local sp = self:sprites()
  local palNum = sp:loadPalette(TAG_APPLAUSE_METER, self.man.palettes.contest)
  local id, s = self:newSprite({ w = 64, h = 32, sheet = self:applauseSheet("base") }, 30, 44, 1)
  s.oam.paletteNum = palNum
  s.invisible = true
  self.e.applauseMeterSpriteId = id
  self.applausePalNum = palNum
end

-- pokeemerald/src/contest.c:3097
function UI:createJudgeSprite()
  local pal = self:pal()
  pal:load(self.man.palettes.judge, 256 + 16, 16)
  local sp = self:sprites()
  local id, s = self:newSprite({ w = 64, h = 64, sheet = self.sheets.judge, priority = 3 }, 112, 36, 30)
  s.oam.paletteNum = 1
  return id
end

-- pokeemerald/src/contest.c:3109
function UI:createJudgeSpeechBubbleSprite()
  local sp = self:sprites()
  local palNum = sp:loadPalette(TAG_CONTEST_SYMBOLS_PAL, self.man.palettes.judge_symbols)
  local id, s = self:newSprite({ w = 16, h = 16, sheet = self.sheets.symbols }, 96, 10, 29)
  s.oam.paletteNum = palNum
  s.invisible = true
  s.data[0] = 0
  return id
end

-- pokeemerald/src/contest.c:3973
function UI:createJudgeAttentionEyeTask()
  local tid = self:createTask("taskFlashJudgeAttentionEye", 30)
  self.e.judgeAttentionTaskId = tid
  local d = self:task(tid).data
  for i = 0, N - 1 do d[i * 4] = 0xFF end
end

-- pokeemerald/src/contest.c:1169
function UI:startCb()
  local m = self.m
  local st = m.state
  if st == 0 then
    self:loadVram()
    self:loadSheets()
    m.ppu.sprites:resetData()
    m.ppu.sprites:freeAllPalettes()
    m.ppu.sprites:setReservedPalettes(4)
    m.tasks:reset()
    self.c:init()
  elseif st == 1 then
    self:loadPalettes()
  elseif st == 2 then
    self:drawContestantWindows()
    self:fillContestantWindowBgs()
    self:swapMoveDescAndContestTilemaps()
    self.e.judgeSpeechBubbleSpriteId = self:createJudgeSpeechBubbleSprite()
    self:createSliderHeartSprites()
    self:createNextTurnSprites()
    self:createApplauseMeterSprite()
    self:createJudgeAttentionEyeTask()
    self.judgeSpriteId = self:createJudgeSprite()
  elseif st == 3 then
    -- pokeemerald/src/contest.c:1206
    self:setBgForCurtainDrop()
    self.bgX[1], self.bgY[1] = 0, 0
    m.ppu:set("DISPCNT", Ppu.DISPCNT_OBJ_1D_MAP + Ppu.DISPCNT_BG_ALL_ON + Ppu.DISPCNT_OBJ_ON)
    self:attachBgs()
    self:pal():beginFade(0xFFFFFFFF, 0, 16, 0, RGB_BLACK)
    m:setVBlank(function() self:vblankCb() end)
    self.mainTaskId = self:createTask("taskStartContestWaitFade", 10)
    m:setCb2(function() self:mainCb() end)
    return
  end
  m.state = st + 1
end

-- pokeemerald/src/contest.c:1433
function UI:mainCb()
  local sp = self:sprites()
  sp:animateAll()
  -- pokeruby/src/contest.c:407
  if self.man.assetLayout == "rs" then
    require("src.core.game3.battle.anim").update(1 / 60)
  end
  self.m.tasks:run(self)
  sp:buildOam()
  self:pal():update()
end

-- pokeemerald/src/contest.c:56
function UI:vblankCb()
  local p = self.m.ppu
  for i = 0, 3 do
    p:set("BG" .. i .. "HOFS", band(self.bgX[i], 0x1FF))
    p:set("BG" .. i .. "VOFS", band(self.bgY[i], 0x1FF))
  end
  p:vblank()
  if not self.headless then
    for i = 0, 3 do self.bg[i]:flush() end
    self.bg3B:flush()
  end
end

-- pokeemerald/src/contest.c:1223
function UI:taskStartContestWaitFade(tid, d)
  if not self:pal():fadeActive() then
    d[0] = 0
    self:setFunc(tid, "taskWaitToRaiseCurtainAtStart")
  end
end

-- pokeemerald/src/contest.c:1378
function UI:taskWaitToRaiseCurtainAtStart(tid, d)
  if not self:pal():fadeActive() then
    d[0], d[1] = 0, 0
    self:setFunc(tid, "taskRaiseCurtainAtStart")
  end
end

-- pokeemerald/src/contest.c:1389
function UI:taskRaiseCurtainAtStart(tid, d)
  local st = d[0]
  if st == 0 then
    local v = d[1]
    d[1] = v + 1
    if v <= 60 then return end
    d[1] = 0
    self.sound:se("SE_CONTEST_CURTAIN_RISE")
    d[0] = 1
  elseif st == 1 then
    self.bgY[1] = s16(self.bgY[1] + 7)
    if self.bgY[1] <= DISPLAY_HEIGHT then return end
    d[0] = 2
  elseif st == 2 then
    self:updateContestantBoxOrder()
    d[0] = 3
  elseif st == 3 then
    self:setBgPriority(0, 0)
    self:setBgPriority(2, 0)
    self:slideApplauseMeterIn()
    d[0] = 4
  else
    if self.e.applauseMeterIsMoving then return end
    d[0], d[1] = 0, 0
    self:setFunc(tid, "taskDisplayAppealNumberText")
  end
end

-- pokeemerald/src/contest.c:1470
function UI:taskDisplayAppealNumberText(tid, d)
  if d[0] == 0 then
    self.bgY[0], self.bgY[2] = 0, 0
    self.cachedUnfaded = {}
    local pal = self:pal()
    for i = 0, 511 do self.cachedUnfaded[i] = pal.unfaded[i] end
    local num = tostring(self.c.contest.appealNumber + 1)
    local key = self.c:isTurnDisabled(self.c.playerIndex) and "gText_AppealNumButItCantParticipate"
      or "gText_AppealNumWhichMoveWillBePlayed"
    self:clearGeneralText()
    self:startText(key, { num }, true)
    d[0] = 1
  else
    self:runText(self.inp)
    if not self:textActive() then
      d[0] = 0
      self:setFunc(tid, "taskTryShowMoveSelectScreen")
    end
  end
end

-- pokeemerald/src/contest.c:1498
function UI:taskTryShowMoveSelectScreen(tid)
  local inp = self.inp or { new = {} }
  local onlyB = inp.new.b and not (inp.new.a or inp.new.up or inp.new.down or inp.new.left or inp.new.right)
  if self:joyNew(GcKit.A) or onlyB then
    self.sound:se("SE_SELECT")
    if not self.c:isTurnDisabled(self.c.playerIndex) then
      self:setBottomSliderHeartsInvisibility(true)
      self:setFunc(tid, "taskShowMoveSelectScreen")
    else
      self:setFunc(tid, "taskSelectedMove")
    end
  end
end

-- pokeemerald/src/contest.c:1517
function UI:taskShowMoveSelectScreen(tid)
  self.bgY[0], self.bgY[2] = DISPLAY_HEIGHT, DISPLAY_HEIGHT
  local c = self.c
  local me = c.playerIndex
  local st = c.status[me]
  for i = 0, 3 do
    local move = c.mons[me].moves[i] or 0
    local colorFg
    if st.prevMove ~= 0 and c:isAllowedToCombo(me) and c:areMovesCombo(st.prevMove, move) ~= 0
        and st.hasJudgesAttention ~= 0 then
      colorFg = "combo"
    elseif move ~= 0 and st.prevMove == move
        and c.data.moves[move] and c.data.moves[move].effect ~= Contest.EFFECT.REPETITION_NOT_BORING then
      colorFg = "repeat"
    end
    local name = self:moveName(move)
    self.win[WIN_MOVE0 + i] = { text = name, x = 5, y = 1, font = "narrow", fg = 15, shadow = 8, colorKey = colorFg }
  end
  self:drawMoveSelectArrow(c.contest.playerMoveChoice)
  self:printContestMoveDescription(c.mons[me].moves[c.contest.playerMoveChoice] or 0)
  self:setFunc(tid, "taskHandleMoveSelectInput")
end

-- pokeemerald/src/contest.c:1556
function UI:taskHandleMoveSelectInput(tid)
  local c = self.c
  local me = c.playerIndex
  local numMoves = 0
  for i = 0, 3 do if (c.mons[me].moves[i] or 0) ~= 0 then numMoves = numMoves + 1 end end
  local inp = self.inp or { new = {}, rep = {} }
  local rep = inp.rep or inp.new
  if self:joyNew(GcKit.A) then
    self.sound:se("SE_SELECT")
    self:setFunc(tid, "taskSelectedMove")
  elseif rep.b and not (rep.up or rep.down or rep.left or rep.right) then
    self.sound:se("SE_SELECT")
    self:setBottomSliderHeartsInvisibility(false)
    local key = c:isTurnDisabled(me) and "gText_AppealNumButItCantParticipate" or "gText_AppealNumWhichMoveWillBePlayed"
    self:clearGeneralText()
    self:startText(key, { tostring(c.contest.appealNumber + 1) }, false)
    self.bgY[0], self.bgY[2] = 0, 0
    self:setFunc(tid, "taskTryShowMoveSelectScreen")
  elseif rep.up and not rep.down then
    self:eraseMoveSelectArrow(c.contest.playerMoveChoice)
    if c.contest.playerMoveChoice == 0 then c.contest.playerMoveChoice = numMoves - 1
    else c.contest.playerMoveChoice = c.contest.playerMoveChoice - 1 end
    self:drawMoveSelectArrow(c.contest.playerMoveChoice)
    self:printContestMoveDescription(c.mons[me].moves[c.contest.playerMoveChoice] or 0)
    if numMoves > 1 then self.sound:se("SE_SELECT") end
  elseif rep.down and not rep.up then
    self:eraseMoveSelectArrow(c.contest.playerMoveChoice)
    if c.contest.playerMoveChoice == numMoves - 1 then c.contest.playerMoveChoice = 0
    else c.contest.playerMoveChoice = c.contest.playerMoveChoice + 1 end
    self:drawMoveSelectArrow(c.contest.playerMoveChoice)
    self:printContestMoveDescription(c.mons[me].moves[c.contest.playerMoveChoice] or 0)
    if numMoves > 1 then self.sound:se("SE_SELECT") end
  end
end

-- pokeemerald/src/contest.c:62
function UI:drawMoveSelectArrow(i)
  self:fillBoxInc(2, 55, 0, 31 + i * 2, 2, 2, 17, 1)
end

-- pokeemerald/src/contest.c:63
function UI:eraseMoveSelectArrow(i)
  self:fillBoxInc(2, 11, 0, 31 + i * 2, 2, 1, 17, 1)
  self:fillBoxInc(2, 11, 0, 32 + i * 2, 2, 1, 17, 1)
end

-- pokeemerald/src/contest.c:3194
function UI:printContestMoveDescription(move)
  local cm = self.c.data.moves[move] or { category = 0, effect = 0 }
  local category = cm.category or 0
  local categoryTile
  if category == 0 then categoryTile = 0x4040
  elseif category == 1 then categoryTile = 0x4045
  elseif category == 2 then categoryTile = 0x404A
  elseif category == 3 then categoryTile = 0x406A
  else categoryTile = 0x408A end
  self:fillBoxInc(0, categoryTile, 0x0b, 0x1f, 0x05, 0x01, 0x11, 0x01)
  self:fillBoxInc(0, categoryTile + 0x10, 0x0b, 0x20, 0x05, 0x01, 0x11, 0x01)
  local eff = self.c.data.effects[cm.effect or 0] or { appeal = 0, jam = 0 }
  local hearts = eff.appeal == 0xFF and 0 or math.floor((eff.appeal or 0) / 10)
  if hearts > MAX_CONTEST_MOVE_HEARTS then hearts = MAX_CONTEST_MOVE_HEARTS end
  self:fillBox(0, TILE_EMPTY_APPEAL_HEART, 0x15, 0x1f, MAX_CONTEST_MOVE_HEARTS, 0x01, 0x11)
  self:fillBox(0, TILE_FILLED_APPEAL_HEART, 0x15, 0x1f, hearts, 0x01, 0x11)
  hearts = eff.jam == 0xFF and 0 or math.floor((eff.jam or 0) / 10)
  if hearts > MAX_CONTEST_MOVE_HEARTS then hearts = MAX_CONTEST_MOVE_HEARTS end
  self:fillBox(0, TILE_EMPTY_JAM_HEART, 0x15, 0x20, MAX_CONTEST_MOVE_HEARTS, 0x01, 0x11)
  self:fillBox(0, TILE_FILLED_JAM_HEART, 0x15, 0x20, hearts, 0x01, 0x11)
  local key = "gContestEffectDescriptionPointers[" .. (cm.effect or 0) .. "]"
  local desc = ""
  if UI.has(key) then
    desc = require("src.core.game3.summary_data").contestEffectDescription(UI.plain(key))
  end
  self.win[WIN_MOVE_DESCRIPTION] = { text = desc, x = 0, y = 1, fg = 15, shadow = 8 }
  self.win[WIN_SLASH] = { text = UI.plain("gText_Slash"), x = 0, y = 1, fg = 15, shadow = 8 }
end

-- pokeemerald/src/contest.c:1632
function UI:taskSelectedMove(tid)
  local c = self.c
  if c.link and c:isLink() then
    local me = c.playerIndex
    self.linkMove = c:isTurnDisabled(me) and 0 or (c.mons[me].moves[c.contest.playerMoveChoice] or 0)
    self:printLinkStandby()
    self:setBottomSliderHeartsInvisibility(false)
    self:setFunc(tid, "taskCommunicateMoveSelections")
    return
  end
  c:chooseMoves(c.contest.playerMoveChoice)
  self:setFunc(tid, "taskHideMoveSelectScreen")
end

-- pokeemerald/src/contest.c:3668
function UI:printLinkStandby()
  self.bgY[0], self.bgY[2] = 0, 0
  self:clearGeneralText()
  self:startText(UI.has("gText_LinkStandby4") and "gText_LinkStandby4" or "gText_LinkStandby", {}, false)
end

-- pokeemerald/src/contest_link.c:276
function UI:taskCommunicateMoveSelections(tid)
  local c = self.c
  local CL = require("src.core.game3.link.contest_link")
  self:runText(self.inp)
  local moves, err = CL.exchangeMoves(c, self.linkMove)
  if err then
    self.linkError = err
    moves = {}
  end
  if not moves then return end
  c.linkMoves = {}
  for i = 0, (c.linkPlayers or N) - 1 do c.linkMoves[i] = moves[i] or 0 end
  c.linkMoves[c.playerIndex] = self.linkMove or 0
  c:chooseMoves(c.contest.playerMoveChoice)
  c.linkMoves = nil
  -- pokeemerald/src/contest.c:1653
  self:setFunc(tid, "taskHideMoveSelectScreen")
end

-- pokeemerald/src/contest.c:1659
function UI:taskHideMoveSelectScreen(tid, d)
  self:clearGeneralText()
  self.bgY[0], self.bgY[2] = 0, 0
  self:setBottomSliderHeartsInvisibility(false)
  for i = 0, 3 do self.win[WIN_MOVE0 + i] = nil end
  self.win[WIN_MOVE_DESCRIPTION], self.win[WIN_SLASH] = nil, nil
  local pal = self:pal()
  for i = 0, 511 do pal.unfaded[i] = self.cachedUnfaded[i]; pal.faded[i] = self.cachedUnfaded[i] end
  d[0], d[1] = 0, 0
  self:setFunc(tid, "taskHideApplauseMeterForAppealStart")
end

-- pokeemerald/src/contest.c:1683
function UI:taskHideApplauseMeterForAppealStart(tid, d)
  d[0] = d[0] + 1
  if d[0] > 2 then
    d[0] = 0
    d[1] = d[1] + 1
    if d[1] == 2 then
      self:slideApplauseMeterOut()
      self:animateSliderHearts(SLIDER_HEART_ANIM_DISAPPEAR)
      self:setFunc(tid, "taskWaitHideApplauseMeterForAppealStart")
    end
  end
end

-- pokeemerald/src/contest.c:1697
function UI:taskWaitHideApplauseMeterForAppealStart(tid)
  if not self.e.applauseMeterIsMoving and not self.e.sliderHeartsAnimating then
    self:setFunc(tid, "taskAppealSetup")
  end
end

-- pokeemerald/src/contest.c:1707
function UI:taskAppealSetup(tid, d)
  d[0] = d[0] + 1
  if d[0] > 19 then
    self.e.turnNumber = 0
    d[0] = 0
    self.turn = nil
    self:setFunc(tid, "taskDoAppeals")
  end
end

function UI:taskDoAppeals(tid, d)
  local t = self.turn
  if not t then
    local c = self.c
    c.contest.turnNumber = self.e.turnNumber
    local events, who = c:runTurn()
    t = { events = events, i = 1, contestant = who, wait = 0, phase = "user" }
    self.turn = t
  end
  if self:playTurn(t) then
    self.turn = nil
    self.e.turnNumber = self.e.turnNumber + 1
    if self.e.turnNumber == N then
      d[0], d[1], d[2] = 0, 0, 0
      self:setFunc(tid, "taskFinishRoundOfAppeals")
    end
  end
end

local CONCURRENT_JUDGE = {
  gText_AppealComboWentOverWell = "combo", gText_AppealComboWentOverVeryWell = "combo",
  gText_AppealComboWentOverExcellently = "combo", gText_JudgeLookedAtMonExpectantly = "combo",
  gText_RepeatedAppeal = "repeat",
}

local CROWD_TEXT = {
  gText_MonsXDidntGoOverWell = true, gText_MonsXWentOverGreat = true, gText_MonsXGotTheCrowdGoing = true,
}

-- pokeemerald/src/contest.c:1727
function UI:playTurn(t)
  local c = self.c
  for _ = 1, 64 do
    if t.step then
      local r = t.step(t)
      if r ~= true then return false end
      t.step = nil
    end
    local ev = t.events[t.i]
    if not ev then
      if t.phase == "opponents" and not t.statusDrawn then
        self:beginOpponentsDone(t)
      elseif not t.ended then
        t.ended = true
        t.step = self:turnEndStep(t)
      else
        return true
      end
    else
      if t.phase == "opponents" and not t.statusDrawn and not self:isOpponentEvent(ev) then
        self:beginOpponentsDone(t)
      else
        t.i = t.i + 1
        self:startEvent(t, ev)
      end
    end
  end
  return false
end

function UI:isOpponentEvent(ev)
  if ev.kind == "result" and ev.attacker ~= nil then return true end
  if ev.kind == "hearts" or ev.kind == "stars" or ev.kind == "status" or ev.kind == "judgeEye" then
    return ev.contestant ~= self.turn.contestant
  end
  return false
end

-- pokeemerald/src/contest.c:2010
function UI:beginOpponentsDone(t)
  t.statusDrawn = true
  self:drawStatusSymbols()
  local n = 0
  t.step = function()
    n = n + 1
    return n > 10
  end
end

function UI:waitText()
  return function()
    self:runText(self.inp)
    return not self:textActive()
  end
end

function UI:waitFrames(n)
  local k = 0
  return function()
    k = k + 1
    return k > n
  end
end

function UI:chain(...)
  local steps = { ... }
  local i = 1
  return function(t)
    while steps[i] do
      local r = steps[i](t)
      if r ~= true then return false end
      i = i + 1
    end
    return true
  end
end

function UI:startEvent(t, ev)
  local c = self.c
  local k = ev.kind
  if k == "turn" then
    t.contestant = ev.contestant
  elseif k == "slideIn" then
    self:clearGeneralText()
    t.step = self:slideMonInStep(t)
  elseif k == "text" then
    self:textEvent(t, ev)
  elseif k == "moveAnim" then
    t.step = self:moveAnimStep(t, ev)
  elseif k == "result" then
    self:printAppealMoveResultText(ev.contestant, ev.stringId)
    t.step = self:waitText()
  elseif k == "judge" then
    self:doJudgeSpeechBubble(ev.symbol)
    local pending = t.pendingJudge
    t.pendingJudge = nil
    t.step = function()
      if pending == "combo" or pending == "repeat" then self:runText(self.inp) end
      return not self.e.waitForJudgeSpeechBubble
    end
  elseif k == "nextTurnGfx" then
    self:showHideNextTurnGfx(true)
  elseif k == "hearts" then
    t.step = self:heartsStep(t, ev)
  elseif k == "stars" then
    self:updateConditionStars(ev.contestant, ev)
    t.step = self:waitFrames(20)
  elseif k == "status" then
    if ev.contestant == t.contestant and t.phase == "user" then
      if self:drawStatusSymbol(ev.contestant) then self.sound:se("SE_CONTEST_ICON_CHANGE") end
      t.phase = "opponents"
    else
      if self:drawStatusSymbol(ev.contestant) then self.sound:se("SE_CONTEST_ICON_CHANGE")
      else self.sound:se("SE_CONTEST_ICON_CLEAR") end
    end
  elseif k == "judgeEye" then
    if ev.contestant == t.contestant then
      if ev.on then self:startFlashJudgeAttentionEye(ev.contestant) else self:stopFlashJudgeAttentionEye(ev.contestant) end
    else
      self:stopFlashJudgeAttentionEye(ev.contestant)
    end
  elseif k == "crowd" then
    t.step = self:crowdStep(t, ev)
  elseif k == "applause" then
    t.applauseReset = true
  elseif k == "slideOut" then
    t.step = self:slideOutStep(t)
  end
end

function UI:textVars(ev)
  local vars = { self:monName(ev.contestant or 0) }
  if ev.move then vars[2] = self:moveName(ev.move) end
  return vars
end

function UI:textEvent(t, ev)
  local c = self.c
  local key = ev.text
  if key == "gText_MonWasWatchingOthers" then
    self:clearGeneralText()
    self:startText(key, { self:monName(ev.contestant) }, true)
    t.step = self:waitText()
    t.skipped = true
  elseif key == "gText_MonWasTooNervousToMove" then
    local st = c.status[ev.contestant]
    self:startStopFlashJudgeAttentionEye(ev.contestant)
    self:startText(key, { self:monName(ev.contestant), self:moveName(st.currMove) }, true)
    t.step = self:waitText()
  elseif key == "gText_MonAppealedWithMove" then
    self:clearGeneralText()
    self:startText(key, { self:monName(ev.contestant), self:moveName(ev.move) }, true)
    t.step = self:waitText()
  elseif key == "gText_MonCantAppealNextTurn" then
    self:clearGeneralText()
    self:startText(key, { self:monName(ev.contestant) }, true)
    t.step = self:waitText()
  elseif CONCURRENT_JUDGE[key] then
    self:clearGeneralText()
    local vars = ev.contestant and { self:monName(ev.contestant) } or {}
    self:startText(key, vars, true)
    t.pendingJudge = CONCURRENT_JUDGE[key]
    t.afterText = CONCURRENT_JUDGE[key]
  elseif CROWD_TEXT[key] then
    self:clearGeneralText()
    local third
    if ev.move then third = self:moveName(ev.move)
    else
      local TextIR = require("src.core.game3.scripting.text_ir")
      third = TextIR.toPlain(self:manText(c.data.manifest.conditionTexts[ev.condition or 0]), {})
    end
    self:startText(key, { self:monName(ev.contestant), nil, third }, true)
  elseif key == "gText_CrowdContinuesToWatchMon" then
    self:clearGeneralText()
    self:startText(key, { self:monName(ev.contestant), self:moveName(ev.move), self:monName(ev.freezer) }, true)
    t.step = self:waitText()
  elseif key == "gText_MonsMoveIsIgnored" then
    self:clearGeneralText()
    self:startText(key, { self:monName(ev.contestant) }, true)
    t.step = self:chain(self:waitText(), function() self:clearGeneralText(); return true end)
  else
    self:clearGeneralText()
    self:startText(key, self:textVars(ev), true)
    t.step = self:waitText()
  end
end

-- pokeemerald/src/contest.c:4567
function UI:printAppealMoveResultText(contestant, stringId)
  local c = self.c
  local attackerMove = c.status[c.results.contestant].currMove
  local cat = (c.data.moves[attackerMove] or {}).category or 0
  local third = ({ [0] = "gText_Contest_Shyness", "gText_Contest_Anxiety", "gText_Contest_Laziness",
    "gText_Contest_Hesitancy", "gText_Contest_Fear" })[cat] or "gText_Contest_Fear"
  local vars = { self:monName(contestant), self:moveName(c.status[contestant].currMove), UI.plain(third) }
  local entry = c.data.manifest.appealResultTexts[stringId]
  self:clearGeneralText()
  self:startText(self:manText(entry), vars, true)
end

-- pokeemerald/src/contest.c:3121
function UI:createContestantSprite(i)
  local c = self.c
  local m = c.mons[i]
  local Pokemon = require("src.core.game3.pokemon")
  local CachePaths = require("src.core.game3.cache_paths")
  local species = tonumber(m.species) or 0
  local p = (tonumber(m.personality) or 0) % 4294967296
  local tid = tonumber(m.otId) or 0
  local shiny = Pokemon.isShiny({ personality = p, otId = tid % 65536, otSecretId = math.floor(tid / 65536) % 65536 })
  local picSpecies = Pokemon.picSpecies(species, p)
  local kind = shiny and "back_shiny" or "back"
  local rgba = Vram.readCache((CachePaths.CACHE_ROOT or "data/generated/gba") .. "/pokemon/" .. kind .. "/"
    .. picSpecies .. ".rgba")
  local sheet, pal = Vram.indexedPic(rgba, self.headless)
  self:pal():load(pal, 256 + 2 * 16, 16)
  local PicCoords = require("src.core.game3.battle.pic_coords")
  local okY, backY = pcall(function() return PicCoords.active().back[picSpecies] end)
  local y = (okY and tonumber(backY) or 0) + 80
  local id, s = self:newSprite({ w = 64, h = 64, sheet = sheet, priority = 2 }, 0x70, y, 30)
  s.oam.paletteNum = 2
  s.oam.priority = 2
  s.subpriority = 30
  s.data[2] = species
  -- pokeemerald/src/data.c:253
  if species ~= require("src.core.game3.constants").of("emerald"):id("species", "SPECIES_UNOWN") then
    s.oam.hFlip = true
  end
  return id, s
end

-- pokeemerald/src/contest.c:1779
function UI:slideMonInStep(t)
  local c = self.c
  local contestant = t.contestant
  local id, s = self:createContestantSprite(contestant)
  s.x2 = 120
  s.data[0] = 0
  s.callback = function(sp)
    if sp.x2 ~= 0 then
      sp.x2 = sp.x2 - 2
    else
      sp.data[0] = sp.data[0] + 1
      if sp.data[0] == 31 then
        sp.data[0] = 0
        sp.callback = nil
        sp.slidDone = true
      end
    end
  end
  t.monSpriteId = id
  self:blinkContestantBox(self:createContestantBoxBlinkSprites(contestant), false)
  return function()
    local sp = self:sprite(id)
    if sp.slidDone and not self.gfxState[contestant].boxBlinking then return true end
    return false
  end
end

-- pokeemerald/src/contest.c:1830
function UI:moveAnimStep(t, ev)
  local c = self.c
  local contestant = t.contestant
  local started, ended = false, false
  local mon = c.mons[contestant] or {}
  local Pokemon = require("src.core.game3.pokemon")
  local picSpecies = Pokemon.picSpecies(tonumber(mon.species) or 0, tonumber(mon.personality) or 0)
  local PicCoords = require("src.core.game3.battle.pic_coords")
  local backY = 0
  local okY, coords = pcall(PicCoords.active)
  if okY and coords and coords.back then backY = tonumber(coords.back[picSpecies]) or 0 end
  local sprite = self:sprite(t.monSpriteId)
  local originalX2, originalY2 = sprite and sprite.x2 or 0, sprite and sprite.y2 or 0
  local Anim = require("src.core.game3.battle.anim")
  local overrides = {
    [2] = { 112, 80 + backY, x = 112, y = 80 + backY },
    [3] = { 48, 40, x = 48, y = 40 },
  }
  local target = c.mons[ev.target] or {}
  local nativeRs = self.man.assetLayout == "rs"
  local presentation
  return function()
    if not started then
      started = true
      if nativeRs then presentation = Anim.beginContestPresentation({ headless = self.headless }) end
      local attackerPresent = Anim.present(2)
      attackerPresent.visible = true
      attackerPresent.ox, attackerPresent.oy = 0, 0
      -- pokeemerald/src/contest.c:1834-1838
      Anim.launchMove(ev.move, {
        attackerId = 2,
        targetId = 3,
        attackerSide = "player",
        targetSide = "enemy",
        attackerSpecies = mon.species,
        targetSpecies = target.species,
        turn = c.contest.moveAnimTurnCount,
        phase = nativeRs and "task" or nil,
        ctx = { isContest = true, contestant = contestant, target = ev.target },
        coordinateOverrides = overrides,
        headless = self.headless,
        onEnd = function()
          ended = true
          if presentation then Anim.endContestPresentation(presentation); presentation = nil end
          attackerPresent.ox, attackerPresent.oy = 0, 0
          attackerPresent.visible = false
          local current = self:sprite(t.monSpriteId)
          if current then current.x2, current.y2 = originalX2, originalY2 end
        end,
      })
    end
    local present = Anim.present(2)
    local current = self:sprite(t.monSpriteId)
    if current and not ended then
      current.x2 = originalX2 + (present and present.ox or 0)
      current.y2 = originalY2 + (present and present.oy or 0)
    end
    if not ended and Anim.busy() then return false end
    if not ended then
      ended = true
      if present then present.ox, present.oy, present.visible = 0, 0, false end
      if current then current.x2, current.y2 = originalX2, originalY2 end
      if presentation then Anim.endContestPresentation(presentation); presentation = nil end
    end
    if c.status[contestant].hasJudgesAttention == 0 then self:stopFlashJudgeAttentionEye(contestant) end
    self:drawUnnervedSymbols()
    return true
  end
end

-- pokeemerald/src/contest.c:1932
function UI:heartsStep(t, ev)
  local contestant = ev.contestant
  local pre
  if t.afterText == "combo" then
    local n = 0
    pre = function()
      self:runText(self.inp)
      if self:textActive() then return false end
      n = n + 1
      return n > 50
    end
  elseif t.afterText == "repeat" then
    pre = self:waitText()
  end
  local kind = t.afterText
  t.afterText = nil
  local started = false
  return function()
    if pre and not pre() then return false end
    pre = nil
    if not started then
      started = true
      self:updateAppealHearts(ev.from, ev.delta, contestant)
      return false
    end
    if self.gfxState[contestant].updatingAppealHearts then return false end
    if kind == "repeat" then self:clearGeneralText() end
    return true
  end
end

-- pokeemerald/src/contest.c:2198
function UI:crowdStep(t, ev)
  local c = self.c
  local contestant = t.contestant
  local phase, n11 = 0, 0
  local nextHearts
  if ev.delta > 0 then
    local nx = t.events[t.i]
    if nx and nx.kind == "hearts" and nx.contestant == contestant then
      nextHearts = nx
      t.i = t.i + 1
    end
  end
  if ev.delta < 0 then
    return function()
      if phase == 0 then
        self:blendAudienceBackground(-1, 1)
        self.sound:fanfare("MUS_TOO_BAD")
        phase = 1
        return false
      elseif phase == 1 then
        self:runText(self.inp)
        if not self.e.waitForAudienceBlend and not self:textActive() then
          self:showAndUpdateApplauseMeter(-1)
          phase = 2
        end
        return false
      elseif phase == 2 then
        if not self.e.isShowingApplauseMeter then
          n11 = n11 + 1
          if n11 > 30 then
            self:blendAudienceBackground(-1, -1)
            phase = 3
          end
        end
        return false
      end
      if self:pal():fadeActive() then return false end
      self:clearGeneralText()
      return true
    end
  end
  return function()
    if phase == 0 then
      self:runText(self.inp)
      if not self:textActive() then
        self:blendAudienceBackground(1, 1)
        phase = 1
      end
      return false
    elseif phase == 1 then
      if not self.e.waitForAudienceBlend then
        self:animateAudience()
        self.sound:se("SE_M_ENCORE2")
        self:showAndUpdateApplauseMeter(1)
        phase = 2
      end
      return false
    elseif phase == 2 then
      if not self.e.isShowingApplauseMeter then
        n11 = n11 + 1
        if n11 > 30 then
          if nextHearts then self:updateAppealHearts(nextHearts.from, nextHearts.delta, contestant) end
          phase = 3
        end
      end
      return false
    elseif phase == 3 then
      if not self.gfxState[contestant].updatingAppealHearts and not self.e.animatingAudience then
        self:blendAudienceBackground(1, -1)
        phase = 4
      end
      return false
    end
    if self:pal():fadeActive() then return false end
    if self.gfxState[contestant].updatingAppealHearts then return false end
    self:clearGeneralText()
    return true
  end
end

-- pokeemerald/src/contest.c:2379
function UI:slideOutStep(t)
  local phase = 0
  return function()
    if phase == 0 then
      self:slideApplauseMeterOut()
      phase = 1
      return false
    elseif phase == 1 then
      if self.e.applauseMeterIsMoving then return false end
      if t.applauseReset or self.c.contest.applauseLevel > 4 then
        self.c.contest.applauseLevel = 0
        self:updateApplauseMeter()
      end
      local s = self:sprite(t.monSpriteId)
      s.callback = function(sp)
        sp.x2 = sp.x2 - 6
        if sp.x + sp.x2 < -32 then
          sp.callback = nil
          sp.invisible = true
        end
      end
      phase = 2
      return false
    elseif phase == 2 then
      local s = self:sprite(t.monSpriteId)
      if not s.invisible then return false end
      self:sprites():destroy(s)
      t.monSpriteId = nil
      return true
    end
  end
end

-- pokeemerald/src/contest.c:2423
function UI:turnEndStep(t)
  if t.monSpriteId then
    local s = self:sprite(t.monSpriteId)
    if s and s.inUse then self:sprites():destroy(s) end
  end
  return self:waitFrames(29)
end

-- pokeemerald/src/contest.c:2478
function UI:taskFinishRoundOfAppeals(tid, d)
  self.c:finishRound()
  d[0] = 0
  self:setFunc(tid, "taskReadyUpdateHeartSliders")
end

-- pokeemerald/src/contest.c:2516
function UI:taskReadyUpdateHeartSliders(tid, d)
  self:showHideNextTurnGfx(false)
  d[0], d[1] = 0, 0
  self:setFunc(tid, "taskUpdateHeartSliders")
end

-- pokeemerald/src/contest.c:2524
function UI:taskUpdateHeartSliders(tid, d)
  if d[0] == 0 then
    d[1] = d[1] + 1
    if d[1] > 20 then
      self:animateSliderHearts(SLIDER_HEART_ANIM_APPEAR)
      d[1] = 0
      d[0] = 1
    end
  elseif d[0] == 1 then
    if not self.e.sliderHeartsAnimating then
      d[1] = d[1] + 1
      if d[1] > 20 then
        d[1] = 0
        d[0] = 2
      end
    end
  else
    self:updateHeartSliders()
    d[0], d[1] = 0, 0
    self:setFunc(tid, "taskWaitForHeartSliders")
  end
end

-- pokeemerald/src/contest.c:2555
function UI:taskWaitForHeartSliders(tid, d)
  if self:slidersDoneUpdating() then
    local pal = self:pal()
    for i = 0, 511 do pal.unfaded[i] = self.cachedUnfaded[i] end
    d[0], d[1] = 0, 2
    self:setFunc(tid, "taskWaitPrintRoundResult")
  end
end

-- pokeemerald/src/contest.c:2569
function UI:taskWaitPrintRoundResult(tid, d)
  d[0] = d[0] + 1
  if d[0] > 2 then
    d[0] = 0
    d[1] = d[1] - 1
    if d[1] == 0 then self:setFunc(tid, "taskPrintRoundResultText") end
  end
end

-- pokeemerald/src/contest.c:2579
function UI:taskPrintRoundResultText(tid, d)
  local c = self.c
  if d[0] == 0 then
    local attention = c.status[c.playerIndex].attentionLevel
    self:clearGeneralText()
    self:startText(self:manText(c.data.manifest.roundResultTexts[attention]), { self:monName(c.playerIndex) }, true)
    d[0] = 1
  else
    self:runText(self.inp)
    if not self:textActive() then
      d[0] = 0
      self:setFunc(tid, "taskReUpdateHeartSliders")
    end
  end
end

-- pokeemerald/src/contest.c:2602
function UI:taskReUpdateHeartSliders(tid, d)
  local v = d[0]
  d[0] = v + 1
  if v > 29 then
    d[0] = 0
    self:updateHeartSliders()
    self:setFunc(tid, "taskWaitForHeartSlidersAgain")
  end
end

-- pokeemerald/src/contest.c:2555
function UI:taskWaitForHeartSlidersAgain(tid, d)
  if self:slidersDoneUpdating() then
    d[0] = 0
    self:setBgForCurtainDrop()
    self.bgX[1], self.bgY[1] = 0, DISPLAY_HEIGHT
    self.sound:se("SE_CONTEST_CURTAIN_FALL")
    self:setFunc(tid, "taskUpdateCurtainDropAtRoundEnd")
  end
end

-- pokeemerald/src/contest.c:5137
function UI:taskUpdateCurtainDropAtRoundEnd(tid, d)
  self.bgY[1] = s16(self.bgY[1] - 7)
  if self.bgY[1] < 0 then self.bgY[1] = 0 end
  if self.bgY[1] == 0 then
    d[0], d[1], d[2] = 0, 0, 0
    self:setFunc(tid, "taskResetForNextRound")
  end
end

-- pokeemerald/src/contest.c:5150
function UI:taskResetForNextRound(tid, d)
  local c = self.c
  if d[0] == 0 then
    for i = 0, N - 1 do c.contest.prevTurnOrder[i] = c.turnOrder[i] end
    self:fillContestantWindowBgs()
    self:drawConditionStars()
    self:drawContestantWindows()
    self:showHideNextTurnGfx(true)
    self:updateSliderHeartSpriteYPositions()
    d[0] = 1
  elseif d[0] == 1 then
    c:setStatusesForNextRound()
    d[0] = 3
  elseif d[0] == 3 then
    self:drawStatusSymbols()
    self:swapMoveDescAndContestTilemaps()
    d[0] = 0
    self:setFunc(tid, "taskWaitRaiseCurtainAtRoundEnd")
  end
end

-- pokeemerald/src/contest.c:5205
function UI:taskWaitRaiseCurtainAtRoundEnd(tid, d)
  if d[2] < 10 then
    d[2] = d[2] + 1
  elseif d[1] == 0 then
    if d[0] == 16 then d[1] = d[1] + 1 else d[0] = d[0] + 1 end
  elseif d[0] == 0 then
    d[1], d[2] = 0, 0
    self:setFunc(tid, "taskStartRaiseCurtainAtRoundEnd")
  else
    d[0] = d[0] - 1
  end
end

-- pokeemerald/src/contest.c:5236
function UI:taskStartRaiseCurtainAtRoundEnd(tid, d)
  if d[2] < 10 then
    d[2] = d[2] + 1
  else
    d[2] = 0
    self.sound:se("SE_CONTEST_CURTAIN_RISE")
    self:setFunc(tid, "taskUpdateRaiseCurtainAtRoundEnd")
  end
end

-- pokeemerald/src/contest.c:5199
function UI:taskUpdateRaiseCurtainAtRoundEnd(tid)
  self.bgY[1] = s16(self.bgY[1] + 7)
  if self.bgY[1] > DISPLAY_HEIGHT then
    self:updateContestantBoxOrder()
    self:setFunc(tid, "taskTryStartNextRoundOfAppeals")
  end
end

-- pokeemerald/src/contest.c:2633
function UI:taskTryStartNextRoundOfAppeals(tid)
  self:setBgPriority(0, 0)
  self:setBgPriority(2, 0)
  if not self.c:nextRound() then
    self:setFunc(tid, "taskEndAppeals")
  else
    self:slideApplauseMeterIn()
    self:setFunc(tid, "taskStartNewRoundOfAppeals")
  end
end

-- pokeemerald/src/contest.c:2653
function UI:taskStartNewRoundOfAppeals(tid)
  if not self.e.applauseMeterIsMoving then self:setFunc(tid, "taskDisplayAppealNumberText") end
end

-- pokeemerald/src/contest.c:2659
function UI:taskEndAppeals(tid, d)
  local c = self.c
  self.bgY[0], self.bgY[2] = 0, 0
  c:endAppeals()
  self:clearGeneralText()
  local okR, Rse = pcall(require, "src.core.game3.rse.init")
  if okR and Rse then
    Rse.call("tv", "bravoTrainerPokemonProfileBeforeInterview1", nil, nil, c.status[c.playerIndex].prevMove)
  end
  self:startText("gText_AllOutOfAppealTime", {}, true)
  d[2] = 0
  self:setFunc(tid, "taskWaitForOutOfTimeMsg")
end

-- pokeemerald/src/contest.c:2686
function UI:taskWaitForOutOfTimeMsg(tid, d)
  self:runText(self.inp)
  if not self:textActive() then
    self:setBgForCurtainDrop()
    self.bgX[1], self.bgY[1] = 0, DISPLAY_HEIGHT
    self.sound:se("SE_CONTEST_CURTAIN_FALL")
    d[0] = 0
    self:setFunc(tid, "taskDropCurtainAtAppealsEnd")
  end
end

-- pokeemerald/src/contest.c:2699
function UI:taskDropCurtainAtAppealsEnd(tid, d)
  self.bgY[1] = s16(self.bgY[1] - 7)
  if self.bgY[1] < 0 then self.bgY[1] = 0 end
  if self.bgY[1] == 0 then
    d[0] = 0
    self:setFunc(tid, "taskTryCommunicateFinalStandings")
  end
end

-- pokeemerald/src/contest.c:2711
function UI:taskTryCommunicateFinalStandings(tid, d)
  local c = self.c
  if c.link and c:isLink() and not self.finalShared then
    local CL = require("src.core.game3.link.contest_link")
    local ok, err = CL.exchangeFinalStandings(c)
    if err then self.linkError = err end
    if not (ok or err) then return end
    self.finalShared = true
  end
  local v = d[0]
  d[0] = v + 1
  if v >= 50 then
    d[0] = 0
    self:pal():beginFade(0xFFFFFFFF, 0, 0, 16, RGB_BLACK)
    self:setFunc(tid, "taskContestReturnToField")
  end
end

-- pokeemerald/src/contest.c:2745
function UI:taskContestReturnToField(tid)
  if not self:pal():fadeActive() then
    self:destroyTask(tid)
    self.done = true
  end
end

-- pokeemerald/src/contest.c:5065
function UI:setBgForCurtainDrop()
  self.bgPrio[1] = 0
  self:setBgPriority(0, 1)
  self:setBgPriority(2, 1)
  self.bgX[1], self.bgY[1] = DISPLAY_WIDTH, DISPLAY_HEIGHT
  self.bg[1]:clear()
  self.bg[1]:load(Vram.u16s(self:bytes("maps", "curtain")), 32 * 32)
  self:setBgPriority(1, 0)
  for i = 0, N - 1 do
    local g = self.gfxState[i]
    self:sprite(g.sliderHeartSpriteId).oam.priority = 1
    for _, id in ipairs(g.nextTurnSpriteIds) do self:sprite(id).oam.priority = 1 end
  end
end

-- pokeemerald/src/contest.c:5103
function UI:updateContestantBoxOrder()
  self.bg[1]:clear()
  self:setBgPriority(1, 1)
  self.bgX[1], self.bgY[1] = 0, 0
  for i = 0, N - 1 do
    local g = self.gfxState[i]
    self:sprite(g.sliderHeartSpriteId).oam.priority = 0
    for _, id in ipairs(g.nextTurnSpriteIds) do self:sprite(id).oam.priority = 0 end
  end
end

-- pokeemerald/src/contest.c:3684
local function heartTile(contestant)
  local base = ({ [0] = 0x5011, 0x6011, 0x7011 })[contestant] or 0x8011
  return base + 1
end

-- pokeemerald/src/contest.c:3699
local function heartsFromAppeal(appeal)
  local h = tdiv(appeal, 10)
  if h > 16 then h = 16 elseif h < -16 then h = -16 end
  return h
end

-- pokeemerald/src/contest.c:3716
function UI:updateAppealHearts(startAppeal, delta, contestant)
  self.gfxState[contestant].updatingAppealHearts = true
  local tid = self:createTask("taskUpdateAppealHearts", 20)
  local d = self:task(tid).data
  local startHearts = heartsFromAppeal(startAppeal)
  local heartsDelta = heartsFromAppeal(startAppeal + delta) - startHearts
  d[0] = math.abs(startHearts)
  d[1] = heartsDelta
  if startHearts > 0 or (startHearts == 0 and heartsDelta > 0) then d[2] = 1 else d[2] = -1 end
  d[3] = contestant
  d[10] = 0
  return tid
end

-- pokeemerald/src/contest.c:3737
function UI:taskUpdateAppealHearts(tid, d)
  local contestant = d[3]
  local startHearts, heartsDelta = d[0], d[1]
  d[10] = d[10] + 1
  if d[10] <= 14 then return end
  d[10] = 0
  if d[1] == 0 then
    self:destroyTask(tid)
    self.gfxState[contestant].updatingAppealHearts = false
    return
  end
  local heartOffset, newNumHearts
  if startHearts == 0 then
    if heartsDelta < 0 then
      heartOffset = heartTile(contestant) + 2
      d[1] = d[1] + 1
    else
      heartOffset = heartTile(contestant)
      d[1] = d[1] - 1
    end
    newNumHearts = d[0]
    d[0] = d[0] + 1
  elseif d[2] < 0 then
    if heartsDelta < 0 then
      newNumHearts = d[0]
      d[0] = d[0] + 1
      d[1] = d[1] + 1
      heartOffset = heartTile(contestant) + 2
    else
      d[0] = d[0] - 1
      newNumHearts = d[0]
      heartOffset = 0
      d[1] = d[1] - 1
    end
  else
    if heartsDelta < 0 then
      d[0] = d[0] - 1
      newNumHearts = d[0]
      heartOffset = 0
      d[1] = d[1] + 1
    else
      newNumHearts = d[0]
      d[0] = d[0] + 1
      d[1] = d[1] - 1
      heartOffset = heartTile(contestant)
    end
  end
  newNumHearts = band(newNumHearts, 0xFF)
  local onSecondLine = false
  if newNumHearts > 7 then
    onSecondLine = true
    newNumHearts = newNumHearts - 8
  end
  self:fillBox(0, heartOffset, newNumHearts + 22, self:turnOrder(contestant) * 5 + 2 + (onSecondLine and 1 or 0), 1, 1, 17)
  if heartsDelta > 0 then
    self.sound:se("SE_CONTEST_HEART")
  else
    self.sound:se("SE_BOO")
  end
  if not onSecondLine and newNumHearts == 0 and heartOffset == 0 then d[2] = -d[2] end
end

-- pokeemerald/src/contest.c:3856
function UI:updateHeartSlider(contestant)
  local g = self.gfxState[contestant]
  g.sliderUpdating = true
  local s = self:sprite(g.sliderHeartSpriteId)
  local target = tdiv(self.c.status[contestant].pointTotal, 10) * 2
  if target > 56 then target = 56 elseif target < 0 then target = 0 end
  s.invisible = false
  local dir = target > s.x2 and 1 or -1
  s.callback = function(sp)
    if sp.x2 == target then
      g.sliderUpdating = false
      sp.callback = nil
    else
      sp.x2 = sp.x2 + dir
    end
  end
end

function UI:updateHeartSliders()
  for i = 0, N - 1 do self:updateHeartSlider(i) end
end

function UI:slidersDoneUpdating()
  for i = 0, N - 1 do
    if self.gfxState[i].sliderUpdating then return false end
  end
  return true
end

-- pokeemerald/src/contest.c:3919
function UI:updateSliderHeartSpriteYPositions()
  for i = 0, N - 1 do
    self:sprite(self.gfxState[i].sliderHeartSpriteId).y = self.man.sliderHeartY[self:turnOrder(i)]
  end
end

-- pokeemerald/src/contest.c:3928
function UI:setBottomSliderHeartsInvisibility(invisible)
  for i = 0, N - 1 do
    if self:turnOrder(i) > 1 then
      self:sprite(self.gfxState[i].sliderHeartSpriteId).x = invisible and 256 or 180
    end
  end
end

-- pokeemerald/src/contest.c:5252
function UI:animateSliderHearts(animId)
  for i = 0, N - 1 do
    local s = self:sprite(self.gfxState[i].sliderHeartSpriteId)
    self:startAffine(s, animId)
    if animId == SLIDER_HEART_ANIM_APPEAR then
      self:sprites():animate(s)
      s.invisible = false
    end
  end
  local tid = self:createTask("taskWaitForSliderHeartAnim", 5)
  self:task(tid).data[0] = animId
  self.e.sliderHeartsAnimating = true
end

-- pokeemerald/src/contest.c:5273
function UI:taskWaitForSliderHeartAnim(tid, d)
  local s0 = self:sprite(self.gfxState[0].sliderHeartSpriteId)
  if s0.affineAnimEnded then
    if d[0] == SLIDER_HEART_ANIM_DISAPPEAR then
      for i = 0, N - 1 do self:sprite(self.gfxState[i].sliderHeartSpriteId).invisible = true end
    end
    for i = 0, N - 1 do self:freeMatrix(self:sprite(self.gfxState[i].sliderHeartSpriteId)) end
    self.e.sliderHeartsAnimating = false
    self:destroyTask(tid)
  end
end

-- pokeemerald/src/contest.c:5012
function UI:showHideNextTurnGfx(show)
  local c = self.c
  for i = 0, N - 1 do
    local g = self.gfxState[i]
    local st = c.status[i]
    local visible = st.turnOrderMod ~= 0 and show
    local sheets
    if visible then
      -- pokeemerald/src/contest.c:5031
      if st.turnOrderMod ~= 1 then
        sheets = self:nextTurnSheet("random", self.tileSets.random[0])
      else
        sheets = self:nextTurnSheet("n" .. st.nextTurnOrder, self.tileSets.numbers[st.nextTurnOrder])
      end
    end
    for k, id in ipairs(g.nextTurnSpriteIds) do
      local s = self:sprite(id)
      if visible then
        s.sheet = sheets[k]
        s.y = self.man.nextTurnY[self:turnOrder(i)]
        s.invisible = false
      else
        s.invisible = true
      end
    end
  end
end

-- pokeemerald/src/contest.c:4681
function UI:doJudgeSpeechBubble(symbol)
  local s = self:sprite(self.e.judgeSpeechBubbleSpriteId)
  local frame, se
  if symbol == JUDGE.SWIRL or symbol == JUDGE.SWIRL_UNUSED then frame, se = 0, "SE_FAILURE"
  elseif symbol == JUDGE.ONE_EXCLAMATION then frame, se = 1, "SE_SUCCESS"
  elseif symbol == JUDGE.TWO_EXCLAMATIONS then frame, se = 2, "SE_SUCCESS"
  elseif symbol == JUDGE.NUMBER_ONE_UNUSED or symbol == JUDGE.NUMBER_ONE then frame, se = 3, "SE_WARP_IN"
  elseif symbol == JUDGE.NUMBER_FOUR then frame, se = 4, "SE_WARP_IN"
  elseif symbol == JUDGE.STAR then frame, se = 6, "SE_M_HEAL_BELL"
  else frame, se = 5, "SE_WARP_IN" end
  s.frame = frame
  self.sound:se(se)
  s.data[1] = 0
  s.invisible = false
  s.callback = function(sp)
    local v = sp.data[1]
    sp.data[1] = v + 1
    if v > 84 then
      sp.data[1] = 0
      sp.invisible = true
      sp.callback = nil
      self.e.waitForJudgeSpeechBubble = false
    end
  end
  self.e.waitForJudgeSpeechBubble = true
end

-- pokeemerald/src/contest.c:3983
function UI:startFlashJudgeAttentionEye(contestant)
  local d = self:task(self.e.judgeAttentionTaskId).data
  d[contestant * 4], d[contestant * 4 + 1] = 0, 0
end

-- pokeemerald/src/contest.c:3989
function UI:stopFlashJudgeAttentionEye(contestant)
  local tid = self:createTask("taskStopFlashJudgeAttentionEye", 31)
  self:task(tid).data[0] = contestant
end

-- pokeemerald/src/contest.c:4114
function UI:startStopFlashJudgeAttentionEye(contestant)
  if self.c.status[contestant].hasJudgesAttention ~= 0 then self:startFlashJudgeAttentionEye(contestant)
  else self:stopFlashJudgeAttentionEye(contestant) end
end

-- pokeemerald/src/contest.c:3995
function UI:taskStopFlashJudgeAttentionEye(tid, d)
  local contestant = d[0]
  local ed = self:task(self.e.judgeAttentionTaskId).data
  local v = ed[contestant * 4]
  if v == 0 or v == 0xFF then
    ed[contestant * 4], ed[contestant * 4 + 1] = 0xFF, 0
    self:pal():blend((5 + self.c.contest.prevTurnOrder[contestant]) * 16 + 6, 2, 0, rgb(31, 31, 18))
    self:destroyTask(tid)
  end
end

-- pokeemerald/src/contest.c:4009
function UI:taskFlashJudgeAttentionEye(tid, d)
  for i = 0, N - 1 do
    local o = i * 4
    if d[o] ~= 0xFF then
      if d[o + 1] == 0 then d[o] = d[o] + 1 else d[o] = d[o] - 1 end
      if d[o] == 16 or d[o] == 0 then d[o + 1] = bit.bxor(d[o + 1], 1) end
      self:pal():blend((5 + self.c.contest.prevTurnOrder[i]) * 16 + 6, 2, d[o], rgb(31, 31, 18))
    end
  end
end

-- pokeemerald/src/contest.c:4122
function UI:createContestantBoxBlinkSprites(contestant)
  local order = self:turnOrder(contestant)
  local x = order * 40 + 32
  local L = self.bg[2]
  local function tilesAt(col0)
    local list = {}
    for ty = 0, 7 do
      for tx = 0, 7 do
        local k = ty * 8 + tx
        if k < 40 then
          local lin = (order * 5 + ty) * 32 + col0 + tx
          local e = L.map[lin] or 0
          local px = self.tilesA[e % 1024]
          if px then
            list[k] = Vram.flipTile(px, math.floor(e / 1024) % 2 == 1, math.floor(e / 2048) % 2 == 1)
          end
        end
      end
    end
    return list
  end
  local sp = self:sprites()
  local tag = TAG_BLINK_EFFECT_CONTESTANT0 + contestant
  local palNum = sp:loadPalette(tag, self.cachedWindowPalettes[5 + contestant])
  local ids = {}
  for k, col in ipairs({ 19, 27 }) do
    local sheet = Vram.sheetFromTileList(tilesAt(col), 64, 64, self.headless)
    local id, s = self:newSprite({ w = 64, h = 64, sheet = sheet, affineMode = Sprites.AFFINE_DOUBLE,
      objMode = Sprites.OBJ_BLEND, affineAnims = affineList(self.man.affine.boxBlink) },
      k == 1 and 184 or 248, x, 29)
    s.oam.paletteNum = palNum
    s.data[1] = contestant
    ids[k] = id
  end
  self:sprite(ids[1]).data[0] = ids[2]
  self:sprite(ids[2]).data[0] = ids[1]
  self.blinkTag = tag
  return ids[1]
end

-- pokeemerald/src/contest.c:4188
function UI:blinkContestantBox(spriteId, b)
  local p = self.m.ppu
  p:set("BLDCNT", Ppu.BLDCNT_TGT2_ALL + Ppu.BLDCNT_EFFECT_BLEND)
  p:set("BLDALPHA", Ppu.blendAlpha(7, 9))
  local s1 = self:sprite(spriteId)
  local contestant = s1.data[1]
  self.gfxState[contestant].boxBlinking = true
  local s2 = self:sprite(s1.data[0])
  local sp = self:sprites()
  sp:startAffineAnim(s1, 1)
  sp:startAffineAnim(s2, 1)
  s2.callback = nil
  s1.callback = function(s)
    if s.affineAnimEnded and s2.affineAnimEnded then
      s.invisible = true
      s2.invisible = true
      s.callback = function()
        self.gfxState[contestant].boxBlinking = false
        self:freeMatrix(s2)
        sp:destroy(s2)
        self:freeMatrix(s)
        sp:destroy(s)
        local tag = TAG_BLINK_EFFECT_CONTESTANT0 + contestant
        for i = 0, 15 do if sp.paletteTags[i] == tag then sp.paletteTags[i] = Sprites.TAG_NONE end end
        p:set("BLDCNT", 0)
        p:set("BLDALPHA", 0)
      end
    end
  end
  self.sound:se(b and "SE_PC_LOGIN" or "SE_CONTEST_MONS_TURN")
end

-- pokeemerald/src/contest.c:144
function UI:updateConditionStars(i, ev)
  local offset = self:turnOrder(i) * 5 + 2
  local numStars = math.floor((ev.condition or self.c.status[i].condition) / 10)
  if ev.gain then
    self:fillBox(0, 0x2034, 19, offset, 1, numStars, 17)
    self.sound:se("SE_EXP_MAX")
  else
    self:fillBox(0, 0, 19, offset + numStars, 1, 3 - numStars, 17)
    self.sound:se("SE_CONTEST_CONDITION_LOSE")
  end
end

-- pokeemerald/src/contest.c:3301
function UI:drawConditionStars()
  for i = 0, N - 1 do
    local offset = self:turnOrder(i) * 5 + 2
    local numStars = math.floor(self.c.status[i].condition / 10)
    self:fillBox(0, 0x2034, 19, offset, 1, numStars, 17)
    self:fillBox(0, 0, 19, offset + numStars, 1, 3 - numStars, 17)
  end
end

-- pokeemerald/src/contest.c:3317
local function statusSymbolTile(kind)
  local off = ({ circle = 0x80, wave = 0x84, x = 0x86, swirl = 0x88, square = 0x82 })[kind] or 0
  return off + 0x9000
end

-- pokeemerald/src/contest.c:3343
function UI:drawStatusSymbol(contestant)
  local st = self.c.status[contestant]
  local offset = self:turnOrder(contestant) * 5 + 2
  local tile
  if st.resistant ~= 0 or st.immune ~= 0 or st.jamSafetyCount ~= 0 or st.jamReduction ~= 0 then
    tile = statusSymbolTile("circle")
  elseif st.nervous ~= 0 then
    tile = statusSymbolTile("wave")
  elseif st.numTurnsSkipped ~= 0 or st.noMoreTurns ~= 0 then
    tile = statusSymbolTile("x")
  end
  if tile then
    self:fillBoxInc(0, tile, 20, offset, 2, 1, 17, 1)
    self:fillBoxInc(0, tile + 16, 20, offset + 1, 2, 1, 17, 1)
    return true
  end
  self:fillBox(0, 0, 20, offset, 2, 2, 17)
  return false
end

function UI:drawStatusSymbols()
  for i = 0, N - 1 do self:drawStatusSymbol(i) end
end

-- pokeemerald/src/contest.c:5039
function UI:drawUnnervedSymbols()
  local c = self.c
  for i = 0, N - 1 do
    if (c.results.unnervedPokes[i] or 0) ~= 0 and not c:isTurnDisabled(i) then
      local offset = self:turnOrder(i) * 5 + 2
      local tile = statusSymbolTile("swirl")
      self:fillBoxInc(0, tile, 20, offset, 2, 1, 17, 1)
      self:fillBoxInc(0, tile + 16, 20, offset + 1, 2, 1, 17, 1)
      self.sound:se("SE_CONTEST_ICON_CHANGE")
    end
  end
end

-- pokeemerald/src/contest.c:4728
function UI:updateApplauseMeter()
  local s = self:sprite(self.e.applauseMeterSpriteId)
  local level = self.c.contest.applauseLevel
  s.sheet = self:applauseSheet(math.max(0, math.min(5, level)))
  if level > 4 then self:startApplauseOverflowAnimation() end
end

-- pokeemerald/src/contest.c:4753
function UI:startApplauseOverflowAnimation()
  local tid = self:createTask("taskApplauseOverflowAnimation", 10)
  local d = self:task(tid).data
  d[1] = 1
  d[2] = self.applausePalNum
end

-- pokeemerald/src/contest.c:4762
function UI:taskApplauseOverflowAnimation(tid, d)
  d[0] = d[0] + 1
  if d[0] ~= 1 then return end
  d[0] = 0
  if d[3] == 0 then d[4] = d[4] + 1 else d[4] = d[4] - 1 end
  self:pal():blend(256 + d[2] * 16 + 8, 1, d[4], RGB_WHITE)
  if d[4] == 0 or d[4] == 16 then
    d[3] = bit.bxor(d[3], 1)
    if self.c.contest.applauseLevel < 5 then
      self:pal():blend(256 + d[2] * 16 + 8, 1, 0, RGB_RED)
      self:destroyTask(tid)
    end
  end
end

-- pokeemerald/src/contest.c:4792
function UI:slideApplauseMeterIn()
  self:createTask("taskSlideApplauseMeterIn", 10)
  local s = self:sprite(self.e.applauseMeterSpriteId)
  s.x2 = -70
  s.invisible = false
  self.e.applauseMeterIsMoving = true
end

function UI:taskSlideApplauseMeterIn(tid, d)
  local s = self:sprite(self.e.applauseMeterSpriteId)
  d[10] = d[10] + 1664
  s.x2 = s.x2 + rshift(d[10], 8)
  d[10] = band(d[10], 0xFF)
  if s.x2 > 0 then s.x2 = 0 end
  if s.x2 == 0 then
    self.e.applauseMeterIsMoving = false
    self:destroyTask(tid)
  end
end

-- pokeemerald/src/contest.c:4816
function UI:slideApplauseMeterOut()
  local s = self:sprite(self.e.applauseMeterSpriteId)
  if s.invisible then
    self.e.applauseMeterIsMoving = false
  else
    self:createTask("taskSlideApplauseMeterOut", 10)
    s.x2 = 0
    self.e.applauseMeterIsMoving = true
  end
end

function UI:taskSlideApplauseMeterOut(tid, d)
  local s = self:sprite(self.e.applauseMeterSpriteId)
  d[10] = d[10] + 1664
  s.x2 = s.x2 - rshift(d[10], 8)
  d[10] = band(d[10], 0xFF)
  if s.x2 < -70 then s.x2 = -70 end
  if s.x2 == -70 then
    s.invisible = true
    self.e.applauseMeterIsMoving = false
    self:destroyTask(tid)
  end
end

-- pokeemerald/src/contest.c:4847
function UI:showAndUpdateApplauseMeter()
  self:createTask("taskShowAndUpdateApplauseMeter", 5)
  self.e.isShowingApplauseMeter = true
end

function UI:taskShowAndUpdateApplauseMeter(tid, d)
  if d[10] == 0 then
    self:slideApplauseMeterIn()
    d[10] = 1
  elseif d[10] == 1 then
    if not self.e.applauseMeterIsMoving then d[10] = 2 end
  else
    local v = d[11]
    d[11] = v + 1
    if v > 20 then
      d[11] = 0
      self:updateApplauseMeter()
      self.e.isShowingApplauseMeter = false
      self:destroyTask(tid)
    end
  end
end

-- pokeemerald/src/contest.c:4896
function UI:animateAudience()
  self:createTask("taskAnimateAudience", 15)
  self.e.animatingAudience = true
end

function UI:taskAnimateAudience(tid, d)
  local v = d[10]
  d[10] = v + 1
  if v > 6 then
    d[10] = 0
    if d[11] == 0 then
      self:setAudienceFrame(1)
    else
      self:setAudienceFrame(0)
      d[12] = d[12] + 1
    end
    d[11] = bit.bxor(d[11], 1)
    if d[12] == 9 then
      self.e.animatingAudience = false
      self:destroyTask(tid)
    end
  end
end

-- pokeemerald/src/contest.c:4937
function UI:blendAudienceBackground(excitementDir, blendDir)
  local tid = self:createTask("taskBlendAudienceBackground", 10)
  local d = self:task(tid).data
  local color, coeff, target
  local level = self.c.contest.applauseLevel
  if excitementDir > 0 then
    color = rgb(30, 27, 8)
    if blendDir > 0 then coeff, target = 0, level * 3 else coeff, target = level * 3, 0 end
  else
    color = RGB_BLACK
    if blendDir > 0 then coeff, target = 0, 12 else coeff, target = 12, 0 end
  end
  d[0], d[1], d[2], d[3] = color, coeff, blendDir, target
  self.e.waitForAudienceBlend = false
end

function UI:taskBlendAudienceBackground(tid, d)
  local v = d[10]
  d[10] = v + 1
  if v >= 0 then
    d[10] = 0
    if d[2] > 0 then d[1] = d[1] + 1 else d[1] = d[1] - 1 end
    self:pal():blend(16 + 1, 1, d[1], d[0])
    self:pal():blend(16 + 10, 1, d[1], d[0])
    if d[1] == d[3] then
      self:destroyTask(tid)
      self.e.waitForAudienceBlend = false
    end
  end
end

function UI:frame(inp)
  if self.done then return end
  self.frames = self.frames + 1
  self.inp = inp or { new = {}, held = {}, rep = {} }
  local m = self.m
  m.vblankCounter1 = m.vblankCounter1 + 1
  if m.vblankCb then m.vblankCb(m) end
  GcKit.readKeys(m, self.inp)
  if m.cb2 then m.cb2(m) end
end

local function colorOf(pltt, idx)
  local c = pltt[15 * 16 + idx] or 0
  return { band(c, 31) / 31, band(rshift(c, 5), 31) / 31, band(rshift(c, 10), 31) / 31, 1 }
end

function UI:drawWindows()
  local FrlgFont = require("src.ui.game3.frlg_font")
  local pltt = self.m.ppu.palette.pltt
  local wins = self.man.windows
  local by = band(self.m.ppu.regs.BG0VOFS or 0, 0x1FF)
  local list = {}
  for id, w in pairs(self.win) do
    local t = wins[id]
    if t then
      list[#list + 1] = { w = w, t = t, top = t.top }
      -- pokeemerald/src/contest.c:3161
      if id < WIN_GENERAL_TEXT and t.top < 10 then list[#list + 1] = { w = w, t = t, top = t.top + 20 } end
    end
  end
  for _, item in ipairs(list) do
    local w, t = item.w, item.t
    do
      local wx, wy = t.left * 8, item.top * 8 - by
      local wh = t.height * 8
      if wy + wh > 0 and wy < DISPLAY_HEIGHT then
        love.graphics.setScissor(wx, math.max(0, wy), t.width * 8, wh)
        local shadow = colorOf(pltt, w.shadow or 8)
        if w.parts then
          for _, part in ipairs(w.parts) do
            FrlgFont.draw(part.text, wx + part.x, wy + part.y,
              { font = w.font, colors = { fg = colorOf(pltt, part.fg), shadow = shadow } })
          end
        elseif w.printer then
          w.printer:draw(wx + (w.x or 0), wy + (w.y or 1),
            { colors = { fg = colorOf(pltt, w.fg or 1), shadow = shadow } })
        elseif w.text then
          local fg = colorOf(pltt, w.fg or 15)
          local sh = shadow
          -- pokeemerald/src/strings.c:1233
          if w.colorKey == "combo" then
            fg, sh = colorOf(pltt, 3), colorOf(pltt, 2)
          elseif w.colorKey == "repeat" then
            fg = colorOf(pltt, 8)
          end
          FrlgFont.draw(w.text, wx + (w.x or 0), wy + (w.y or 1), { font = w.font, colors = { fg = fg, shadow = sh } })
        end
        love.graphics.setScissor()
      end
    end
  end
end

function UI:draw()
  if self.headless then return end
  self.m.ppu:draw(0, 0)
  -- pokeemerald/src/contest.c:1834 draws the move's sprites during the contest appeal scene.
  require("src.core.game3.battle.anim").drawParticles()
  self:drawWindows()
end

local Host = {}
UI.Host = Host

function UI.open(opts)
  local Stack = require("src.ui.game3.stack")
  local SceneKit = require("src.ui.game3.rse.scene_kit")
  local screen = ((opts and opts.sceneClass) or UI).new(opts)
  require("src.core.game3.battle.anim").reset({ headless = screen.headless,
    double = screen.man.assetLayout ~= "rs" })
  Host._screen = screen
  Host._step = SceneKit.stepper()
  local userDone = opts and opts.onDone
  screen.onDone = function()
    Host._screen = nil
    require("src.core.game3.battle.anim").reset({ headless = false })
    Stack.pop(UI.ID)
    if userDone then userDone(screen) end
  end
  if screen.headless then
    for _ = 1, opts.maxFrames or 200000 do
      if screen.done then break end
      screen:frame(opts.autoInput and opts.autoInput(screen) or { new = { a = true }, held = {}, rep = { a = true } })
    end
    screen.onDone()
    return screen
  end
  Stack.push(UI.ID, Host, { hideBelow = true, fullscreen = true })
  return screen
end

function UI.active() return Host._screen end

function UI.reset()
  require("src.core.game3.battle.anim").reset({ headless = false })
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
  if screen.man.assetLayout ~= "rs" then
    require("src.core.game3.battle.anim").update(dt)
  end
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
