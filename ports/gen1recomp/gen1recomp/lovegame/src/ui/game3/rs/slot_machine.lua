local Base = require("src.ui.game3.rse.slot_machine")
local Kit = require("src.ui.game3.rse.gc_kit")
local SceneKit = require("src.ui.game3.rse.scene_kit")
local Ppu = require("src.core.game3.gba_ppu")
local Font = require("src.ui.game3.frlg_font")

local UI = setmetatable({}, {__index = Base})
UI.__index = UI

function UI.new(opts)
  local self = Base.new(opts, UI)
  assert(self.man.assetLayout == "rs", "native RS slot-machine pack required")
  return self
end

-- pokeruby/src/slot_machine.c:361
function UI:setupCb()
  local m, p = self.m, self.m.ppu
  local st = m.state
  if st == 0 then
    m:setVBlank(nil)
    p:set("DISPCNT", 0)
    self:initSlotMachine()
  elseif st == 1 then
  elseif st == 2 then
    self:initBgs()
    for _, r in ipairs({"BG0HOFS", "BG0VOFS", "BG1HOFS", "BG1VOFS",
      "BG2HOFS", "BG2VOFS", "BG3HOFS", "BG3VOFS"}) do p:set(r, 0) end
    p:set("BG0CNT", 0x1F08)
    p:set("BG1CNT", 0x1C01)
    p:set("BG2CNT", 0x1D02)
    p:set("BG3CNT", 0x1E02)
    p:set("WININ", 0x3F)
    p:set("WINOUT", 0x3F)
    p:set("BLDCNT", Ppu.BLDCNT_TGT1_BG3 + Ppu.BLDCNT_EFFECT_BLEND + Ppu.BLDCNT_TGT2_OBJ)
    p:set("BLDALPHA", Ppu.blendAlpha(9, 8))
  elseif st == 3 then
  elseif st == 4 then
    p.palette:resetFade()
    p.sprites:resetData()
    p.sprites.oamLimit = 0x80
    p.sprites:freeAllPalettes()
    m.tasks:reset()
    self.reelButtonPress = {0, 0, 0, 0}
  elseif st == 5 then
    self:loadGfxAndTilemaps()
  elseif st == 6 then
    self:createSlotMachineSprites()
    self:createGameplayTasks()
    m:setVBlank(function() self:vblankCb() end)
    p:set("DISPCNT", Ppu.DISPCNT_OBJ_1D_MAP + Ppu.DISPCNT_BG_ALL_ON
      + Ppu.DISPCNT_OBJ_ON + Ppu.DISPCNT_WIN0_ON)
    m:setCb2(function() self:mainCb() end)
    return
  end
  m.state = st + 1
end

-- pokeruby/src/slot_machine.c:481
function UI:initBgs()
  Base.initBgs(self)
  self.m.ppu:setBg(3, 2, self.bg[3].layer)
end

function UI:tvHook() end

local function color(value, fade, transparent)
  local c = Kit.color555(value)
  local k = (16 - fade) / 16
  c[1], c[2], c[3] = c[1] * k, c[2] * k, c[3] * k
  if transparent then c[4] = 0 end
  return c
end

-- pokeruby/src/text.c:1462
-- slot_machine.c:3031
function UI:drawOverlay()
  if self.infoWindow and self.infoWindow.text then
    local pal = self.m.ppu.palette
    local fade = pal.active and pal.y or 0
    local u = self.man.palettes.unk
    local colors = {fg = color(u[2], fade), bg = color(u[1], fade, true),
      shadow = color(u[9], fade)}
    Font.draw(Kit.text("gText_ReelTimeHelp"), 10, 32,
      {font = "native_3", colors = colors, maxWidth = 230})
  end
  if self.message then
    SceneKit.birchDialogueFrame(2, 15, 27, 4)
    Font.draw(self.message.text, 16, 121,
      {font = "native_3", colors = SceneKit.messageColors(), maxWidth = 240})
  end
  if self.yesNo then
    -- pokeruby/src/slot_machine.c:1057
    local x, y = self.yesNo.tx + 1, self.yesNo.ty + 1
    require("src.ui.game3.chrome").stdFrame(x, y, 5, 4)
    local colors = SceneKit.messageColors("std_menu")
    for i = 0, 1 do
      Font.draw(require("src.core.game3.rom_text").at("gMenuYesNoItems", i),
        x * 8 + 8, y * 8 + i * 16, {font = "native_3", colors = colors})
    end
    require("src.ui.game3.rs.menu_cursor").draw(x * 8 + 8, y * 8 + self.yesNo.cursor * 16, 40)
  end
end

function UI.open(opts) return Base.open(opts, UI.new) end

return UI
