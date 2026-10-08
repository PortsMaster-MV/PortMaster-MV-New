local bit = require("bit")
local Base = require("src.ui.game3.rse.contest_results")
local Vram = require("src.ui.game3.rse.contest_vram")
local Ppu = require("src.core.game3.gba_ppu")
local Kit = require("src.ui.game3.rse.scene_kit")
local UI = setmetatable({SUB = "rse/rs_contest_gfx", ID = Base.ID}, {__index = Base})
UI.__index = UI

function UI.new(opts)
  local own = {}; for k, v in pairs(opts or {}) do own[k] = v end
  own.manifest = own.manifest or Vram.manifest(UI.SUB)
  assert(own.manifest.assetLayout == "rs", "native RS contest results graphics missing")
  return setmetatable(Base.new(own), UI)
end
function UI.open(opts)
  local own = {}; for k, v in pairs(opts or {}) do own[k] = v end
  own.sceneClass = UI
  return Base.open(own)
end

-- pokeruby/src/contest_link_util.c:363
function UI:taskShowContestResults(tid, d)
  if self.c:isLink() then self.linkResultsSaved, self.linkResultsPersisted = true, true end
  return Base.taskShowContestResults(self, tid, d)
end

-- pokeruby/src/contest_link_util.c:1410
function UI:loadTitleBarTilemaps()
  local src, L = Vram.u16s(self:bytes("maps", "title_sheet")), self.bg[2]
  local rank = ({[0] = {0, 0, 9}, {9, 0, 8}, {17, 0, 8}, {0, 2, 9}})[self.c.rank] or {0, 2, 9}
  if self.c:isLink() then rank = {9, 2, 8} end
  local category = math.min(4, math.max(0, self.c.category))
  local cat = ({[0] = {17, 2, 10}, {0, 4, 11}, {11, 4, 10}, {21, 4, 10}, {0, 6, 10}})[category]
  local function copy(spec, x)
    for yy = 0, 1 do for xx = 0, spec[3] - 1 do
      L:put(x + xx, 1 + yy, src[(spec[2] + yy) * 32 + spec[1] + xx])
    end end
  end
  copy(rank, 5); copy(cat, 5 + rank[3])
  for y = 0, 3 do for x = 0, 31 do
    L:put(x, y, bit.bor(bit.band(L:get(x, y), 0xFFF), category * 4096))
  end end
end
function UI:loadAllContestMonNames()
  Base.loadAllContestMonNames(self)
  local U = require("src.core.game3.rs.contest_util")
  for i = 0, 3 do self.names[i].trainer = "/" .. U.trainerNameAt(self.c, i) end
end
function UI:startCb()
  Base.startCb(self)
  local p = self.m.ppu
  for i = 0, 3 do p:set("BG" .. i .. "CNT", self.man.resultsBgControl[i + 1]) end
  p:set("DISPCNT", Ppu.DISPCNT_OBJ_1D_MAP + Ppu.DISPCNT_BG_ALL_ON + Ppu.DISPCNT_OBJ_ON +
    Ppu.DISPCNT_WIN0_ON + Ppu.DISPCNT_WIN1_ON)
  p:set("WINOUT", 0x3F2E)
  if not self.headless then
    p:setBg(0, 0, self.bg[0].layer, true)
    for i = 1, 3 do p:setBg(i, 3, self.bg[i].layer, i == 3) end
  end
end

function UI:drawResultsTextWindow(text, spriteId)
  local Font = require("src.ui.game3.frlg_font")
  local width = Font.measure(text, {font = "native_3"})
  local tiles = math.floor((width + 7) / 8)
  local src, fill = self.textWindowTiles, {}
  for k = 0, 63 do fill[k] = 1 end
  local lists = {[0] = {}, {}, {}, {}}
  local function put(x, y, data)
    local i = math.floor(x / 8)
    if i <= 3 then lists[i][y * 8 + x % 8] = data end
  end
  put(0, 0, src[0]); put(0, 1, src[2]); put(0, 2, src[2]); put(0, 3, src[1])
  for i = 0, tiles - 1 do
    put(i + 1, 0, src[6]); put(i + 1, 1, fill); put(i + 1, 2, fill); put(i + 1, 3, src[7])
  end
  put(tiles + 1, 0, src[1]); put(tiles + 1, 1, src[3]); put(tiles + 1, 2, src[3]); put(tiles + 1, 3, src[2])
  local s = self:sprite(spriteId)
  local ids = {[0] = spriteId, s.data[0], s.data[1], s.data[2]}
  for i = 0, 3 do self:sprite(ids[i]).sheet = Vram.sheetFromTileList(lists[i], 64, 32, self.headless) end
  self.boxTexts = self.boxTexts or {}
  self.boxTexts[spriteId] = {text = text, x = math.floor((tiles * 8 - width) / 2) + 8, spriteId = spriteId}
  return math.floor((240 - (tiles + 2) * 8) / 2)
end

function UI:draw()
  if self.headless then return end
  local lg, Font = love.graphics, require("src.ui.game3.frlg_font")
  self.m.ppu:draw(0, 0)
  local pltt = self:pal().pltt
  local function color(index)
    local r, g, b = Kit.rgb555(pltt[index] or 0); return {r, g, b, 1}
  end
  local top, bottom = bit.rshift(self.win0v, 8), bit.band(self.win0v, 255)
  if bottom <= top then top, bottom = 160, 160 end
  for _, clip in ipairs({{0, top}, {bottom, 160}}) do
    if clip[2] > clip[1] then
      lg.setScissor(0, clip[1], 240, clip[2] - clip[1])
      for i = 0, 3 do
        local n = self.names and self.names[i]
        if n then
          local opts = {font = "native_4", colors = {fg = color(240 + (n.player and 2 or 1)), shadow = color(248)}}
          Font.draw(n.nick, 56, 32 + i * 24, opts)
          Font.draw(n.trainer, 106, 32 + i * 24, opts)
        end
      end
      lg.setScissor()
    end
  end
  for _, id in ipairs({self.d.slidingTextBoxSpriteId, self.d.linkTextBoxSpriteId}) do
    local bt = self.boxTexts and self.boxTexts[id]
    local s = bt and self:sprite(bt.spriteId)
    if s and s.inUse and not s.invisible then
      local bank = 256 + s.oam.paletteNum * 16
      local clipTop = id == self.d.linkTextBoxSpriteId and s.y + s.y2 - 16 or 128
      lg.setScissor(0, clipTop, 240, 32)
      Font.draw(bt.text, s.x + s.x2 - 32 + bt.x, s.y + s.y2 - 8,
        {font = "native_3", colors = {fg = color(bank + 15), shadow = color(bank + 14)}})
      lg.setScissor()
    end
  end
  if self.hwFade and self.hwFade.y > 0 then
    lg.setColor(0, 0, 0, self.hwFade.y / 16); lg.rectangle("fill", 0, 0, 240, 160)
    lg.setColor(1, 1, 1, 1)
  end
end
return UI
