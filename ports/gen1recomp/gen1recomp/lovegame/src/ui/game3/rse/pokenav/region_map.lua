local Kit = require("src.ui.game3.rse.scene_kit")
local Gfx = require("src.ui.game3.rse.pokenav.gfx")
local RegionMap = require("src.ui.game3.rse.region_map")

local NavMap = {}
NavMap.__index = NavMap

-- pokeemerald/include/pokenav.h:293
NavMap.FUNC = { NONE = 0, CURSOR_MOVED = 1, ZOOM_OUT = 2, ZOOM_IN = 3, EXIT = 4 }
local FUNC = NavMap.FUNC
local INPUT, TYPE = RegionMap.INPUT, RegionMap.TYPE

local function Pokenav()
  return require("src.ui.game3.rse.pokenav.init")
end

local function pause() coroutine.yield() end
local function wait(pred) while pred() do coroutine.yield() end end

local function isEventIsland(sec)
  for _, v in ipairs(RegionMap.manifest().offMap) do
    if v == sec then return true end
  end
  return false
end

-- pokeemerald/src/pokenav_region_map.c:174
function NavMap.new(shell)
  local s = RegionMap.newState({ session = shell.session, mode = "wall" })
  local self = setmetatable({ shell = shell, session = shell.session, rm = s, bg1Y = 0, zoomTextSprites = {} }, NavMap)
  local cur = require("src.core.game3.rse.match_call").currentMapsec()
  self.zoomDisabled = isEventIsland(cur or -1)
  self.zoomed = (not self.zoomDisabled) and shell.session and shell.session.regionMapZoom == true or false
  -- pokeemerald/src/region_map.c:544
  self.scrollX, self.scrollY = 0, 0
  self.scale = 0x100
  self.c, self.d = 0, 0
  if self.zoomed then
    self.scrollX = s.cursorX * 8 - 0x34
    self.scrollY = s.cursorY * 8 - 0x44
    self.zoomedX, self.zoomedY = s.cursorX, s.cursorY
    self.scale, self.c, self.d = 0x80, 0x38, 0x48
  end
  self.cursorSx, self.cursorSy = 8 * s.cursorX + 4, 8 * s.cursorY + 4
  self.moveCounter = 0
  self.inputFn = self.zoomed and "zoomed" or "full"
  self.cursorVisible = not self.zoomDisabled
  self.iconVisible = not self.zoomDisabled
  self.iconTimer, self.iconBlinkOn = 0, true
  self.cursorAnim = 0
  self.bg1Y = self.zoomed and 0 or 96
  -- pokeemerald/src/pokenav_region_map.c:665
  for i = 0, 2 do
    self.zoomTextSprites[i + 1] = { data0 = 0, data1 = i * 4, data3 = 150, data4 = i * 4, data5 = 0 }
  end
  return self
end

function NavMap:positionWithinMapSec(x, y)
  local sec = self.rm.mapSecId
  if sec == RegionMap.mapsec("NONE") then return 0 end
  local pos = 0
  while true do
    if x <= RegionMap.CURSOR_X_MIN then
      local found = false
      if y ~= 0 then
        for xx = RegionMap.CURSOR_X_MIN, RegionMap.CURSOR_X_MAX do
          if RegionMap.mapSecAt(xx, y - 1) == sec then found = true break end
        end
      end
      if found then
        y = y - 1
        x = RegionMap.CURSOR_X_MAX + 1
      else
        break
      end
    else
      x = x - 1
      if RegionMap.mapSecAt(x, y) == sec then pos = pos + 1 end
    end
  end
  return pos
end

function NavMap:moveTo(x, y)
  local s = self.rm
  local id = RegionMap.mapSecAt(x, y)
  s.mapSecType = RegionMap.mapSecType(s, id)
  if id ~= s.mapSecId then
    s.mapSecId = id
    s.mapSecName = RegionMap.mapName(id)
  end
  s.posWithinMapSec = self:positionWithinMapSec(x, y)
end

-- pokeemerald/src/region_map.c:648
function NavMap:processInput(inp)
  local s = self.rm
  local held, new = inp.held or {}, inp.new or {}
  if self.inputFn == "full_move" then
    if self.moveCounter ~= 0 then return INPUT.MOVE_CONT end
    s.cursorX = s.cursorX + self.dx
    s.cursorY = s.cursorY + self.dy
    self:moveTo(s.cursorX, s.cursorY)
    self.inputFn = "full"
    return INPUT.MOVE_END
  elseif self.inputFn == "zoomed_move" then
    -- pokeemerald/src/region_map.c:770
    self.scrollY = self.scrollY + self.dy
    self.scrollX = self.scrollX + self.dx
    self.moveFrames = self.moveFrames + 1
    if self.moveFrames == 8 then
      local x = math.floor((self.scrollX + 0x2c) / 8) + 1
      local y = math.floor((self.scrollY + 0x34) / 8) + 2
      if x ~= self.zoomedX or y ~= self.zoomedY then
        self.zoomedX, self.zoomedY = x, y
        self:moveTo(x, y)
      end
      self.moveFrames = 0
      self.inputFn = "zoomed"
      return INPUT.MOVE_END
    end
    return INPUT.MOVE_CONT
  end
  local input = INPUT.NONE
  self.dx, self.dy = 0, 0
  if self.inputFn == "full" then
    if held.up and s.cursorY > RegionMap.CURSOR_Y_MIN then self.dy = -1; input = INPUT.MOVE_START end
    if held.down and s.cursorY < RegionMap.CURSOR_Y_MAX then self.dy = 1; input = INPUT.MOVE_START end
    if held.left and s.cursorX > RegionMap.CURSOR_X_MIN then self.dx = -1; input = INPUT.MOVE_START end
    if held.right and s.cursorX < RegionMap.CURSOR_X_MAX then self.dx = 1; input = INPUT.MOVE_START end
  else
    -- pokeemerald/src/region_map.c:727
    if held.up and self.scrollY > -0x34 then self.dy = -1; input = INPUT.MOVE_START end
    if held.down and self.scrollY < 0x3c then self.dy = 1; input = INPUT.MOVE_START end
    if held.left and self.scrollX > -0x2c then self.dx = -1; input = INPUT.MOVE_START end
    if held.right and self.scrollX < 0xac then self.dx = 1; input = INPUT.MOVE_START end
  end
  if new.a then input = INPUT.A end
  if new.b then input = INPUT.B end
  if input == INPUT.MOVE_START then
    if self.inputFn == "full" then
      self.moveCounter = 4
      self.inputFn = "full_move"
    else
      self.moveFrames = 0
      self.inputFn = "zoomed_move"
    end
  end
  return input
end

-- pokeemerald/src/pokenav_region_map.c:205
function NavMap:callback(inp)
  if self.exitReady then return Pokenav().MENU.MAIN_MENU_CURSOR_ON_MAP end
  if self.zoomDisabled then
    if (inp.new or {}).b then return FUNC.EXIT end
    return FUNC.NONE
  end
  local r = self:processInput(inp)
  if r == INPUT.MOVE_END then return FUNC.CURSOR_MOVED end
  if r == INPUT.A then return self.zoomed and FUNC.ZOOM_OUT or FUNC.ZOOM_IN end
  if r == INPUT.B then return FUNC.EXIT end
  return FUNC.NONE
end

-- pokeemerald/src/pokenav_region_map.c:303
function NavMap:open()
  local shell = self.shell
  shell.spinVisible = true
  for _ = 1, 8 do pause() end
  self:updateInfoWindow()
  shell.pal:blend(require("src.core.game3.pal_fade").mask({ 1 }), 16, { 0, 0, 0 })
  pause()
  self.visible = true
  pause()
  local key = "hoenn_map"
  shell.leftMain:show(key, true, true)
  shell.leftMain.frame1 = self.zoomed and 2 or 1
  shell:setHelpBar(self.zoomed and 2 or 1)
  shell:fade("from_black")
  pause()
  wait(function() return shell:fadeActive() or shell:leftHeadersBusy() end)
end

-- pokeemerald/src/region_map.c:804
function NavMap:setZoomData()
  local s = self.rm
  if not self.zoomed then
    self.scrollX, self.scrollY = 0, 0
    self.acc3c, self.acc40 = 0, 0
    self.target60 = s.cursorX * 8 - 0x34
    self.target62 = s.cursorY * 8 - 0x44
    self.step44 = math.floor(self.target60 * 256 / 16)
    self.step48 = math.floor(self.target62 * 256 / 16)
    self.zoomedX, self.zoomedY = s.cursorX, s.cursorY
    self.zoomAcc = 0x10000
    self.zoomStep = -0x800
  else
    self.acc3c = self.scrollX * 0x100
    self.acc40 = self.scrollY * 0x100
    self.target60, self.target62 = 0, 0
    local function trunc(v) return v >= 0 and math.floor(v) or -math.floor(-v) end
    self.step44 = -trunc(self.acc3c / 16)
    self.step48 = -trunc(self.acc40 / 16)
    s.cursorX, s.cursorY = self.zoomedX, self.zoomedY
    self.zoomAcc = 0x8000
    self.zoomStep = 0x800
  end
  self.c, self.d = 0x38, 0x48
  self.zoomFrame = 0
  self.cursorVisible = false
  self.iconVisible = false
end

-- pokeemerald/src/region_map.c:839
function NavMap:updateZoom()
  if self.zoomFrame >= 16 then return false end
  self.zoomFrame = self.zoomFrame + 1
  local ret
  if self.zoomFrame == 16 then
    self.step44, self.step48 = 0, 0
    self.scrollX, self.scrollY = self.target60, self.target62
    self.zoomAcc = self.zoomed and 0x10000 or 0x8000
    self.zoomed = not self.zoomed
    self.inputFn = self.zoomed and "zoomed" or "full"
    local s = self.rm
    self.cursorSx, self.cursorSy = 8 * s.cursorX + 4, 8 * s.cursorY + 4
    self.cursorVisible = true
    self.iconVisible = true
    ret = false
  else
    self.acc3c = self.acc3c + self.step44
    self.acc40 = self.acc40 + self.step48
    self.scrollX = math.floor(self.acc3c / 256)
    self.scrollY = math.floor(self.acc40 / 256)
    self.zoomAcc = self.zoomAcc + self.zoomStep
    if (self.step44 < 0 and self.scrollX < self.target60) or (self.step44 > 0 and self.scrollX > self.target60) then
      self.scrollX, self.step44 = self.target60, 0
    end
    if (self.step48 < 0 and self.scrollY < self.target62) or (self.step48 > 0 and self.scrollY > self.target62) then
      self.scrollY, self.step48 = self.target62, 0
    end
    if not self.zoomed then
      if self.zoomAcc < 0x8000 then self.zoomAcc, self.zoomStep = 0x8000, 0 end
    else
      if self.zoomAcc > 0x10000 then self.zoomAcc, self.zoomStep = 0x10000, 0 end
    end
    ret = true
  end
  self.scale = math.floor(self.zoomAcc / 256)
  return ret
end

-- pokeemerald/src/pokenav_region_map.c:533
function NavMap:updateInfoWindow()
  local s = self.rm
  self.info = { type = s.mapSecType, name = s.mapSecName, sec = s.mapSecId, pos = s.posWithinMapSec }
end

-- pokeemerald/src/pokenav_region_map.c:589
function NavMap:bgZoomTask(zoomIn)
  self.bgTask = self.shell:run(function()
    while true do
      if zoomIn then
        self.bg1Y = self.bg1Y - 4.5
        if self.bg1Y <= 0 then self.bg1Y = 0 return end
      else
        self.bg1Y = self.bg1Y + 4.5
        if self.bg1Y >= 96 then self.bg1Y = 96 return end
      end
      coroutine.yield()
    end
  end)
end

function NavMap:loopTask(func)
  local shell = self.shell
  if func == FUNC.CURSOR_MOVED then
    self:updateInfoWindow()
    pause()
  elseif func == FUNC.ZOOM_OUT then
    -- pokeemerald/src/pokenav_region_map.c:398
    Kit.playSe("SE_SELECT")
    self:bgZoomTask(false)
    self:setZoomData()
    pause()
    wait(function() return self:updateZoom() or shell:busy(self.bgTask) end)
    shell:setHelpBar(1)
    pause()
    shell.leftMain.frame1 = 1
  elseif func == FUNC.ZOOM_IN then
    -- pokeemerald/src/pokenav_region_map.c:424
    Kit.playSe("SE_SELECT")
    self:updateInfoWindow()
    pause()
    self:bgZoomTask(true)
    self:setZoomData()
    pause()
    wait(function() return self:updateZoom() or shell:busy(self.bgTask) end)
    shell:setHelpBar(2)
    pause()
    shell.leftMain.frame1 = 2
  elseif func == FUNC.EXIT then
    -- pokeemerald/src/pokenav_region_map.c:457
    Kit.playSe("SE_SELECT")
    shell:fade("to_black")
    pause()
    wait(function() return shell:fadeActive() end)
    shell:hideLeftHeaders()
    local slide = shell:slideHeader(false)
    pause()
    wait(function() return shell:busy(slide) end)
    self.visible = false
    pause()
    self.exitReady = true
  end
end

-- pokeemerald/src/pokenav_region_map.c:192
function NavMap:free()
  if self.session then self.session.regionMapZoom = self.zoomed == true end
end

function NavMap:frame()
  local s = self.rm
  -- pokeemerald/src/region_map.c:1360
  if self.moveCounter ~= 0 then
    self.cursorSx = self.cursorSx + 2 * self.dx
    self.cursorSy = self.cursorSy + 2 * self.dy
    self.moveCounter = self.moveCounter - 1
  end
  self.cursorAnim = self.cursorAnim + 1
  -- pokeemerald/src/region_map.c:1541
  if s.blinkPlayerIcon then
    self.iconTimer = self.iconTimer + 1
    if self.iconTimer > 16 then
      self.iconTimer = 0
      self.iconBlinkOn = not self.iconBlinkOn
    end
  else
    self.iconBlinkOn = true
  end
  -- pokeemerald/src/pokenav_region_map.c:693
  for _, sp in ipairs(self.zoomTextSprites) do
    if sp.data3 > 0 then
      sp.data3 = sp.data3 - 1
    else
      sp.data0 = sp.data0 + 1
      if sp.data0 > 11 then sp.data0 = 0 end
      sp.data1 = sp.data1 + 1
      if sp.data1 > 60 then sp.data1 = 0 end
      if sp.data5 < 4 then
        if sp.data0 == 0 then
          sp.data5 = sp.data5 + 1
          sp.data3 = 120
        end
      elseif sp.data1 == sp.data4 then
        sp.data5, sp.data0, sp.data3 = 0, 0, 120
      end
    end
  end
end

-- pokeemerald/src/region_map.c:900
function NavMap:drawMap()
  local man = RegionMap.manifest()
  local sDisp = 0x100 / math.max(1, self.scale)
  local c, d = self.c, self.d
  local x0 = c - (self.scrollX + c) * sDisp
  local y0 = d - (self.scrollY + d) * sDisp
  local k = 1 - Gfx.dim
  local img = Kit.image(man.layers.map.png)
  if img then
    love.graphics.setColor(k, k, k, 1)
    local span = 512 * sDisp
    -- pokeemerald/src/region_map.c:609
    for ty = -1, 1 do
      for tx = -1, 1 do
        local dx, dy = math.floor(x0 + tx * span), math.floor(y0 + ty * span)
        if dx < 240 and dy < 160 and dx + span > 0 and dy + span > 0 then
          love.graphics.draw(img, dx, dy, 0, sDisp, sDisp)
        end
      end
    end
    love.graphics.setColor(1, 1, 1, 1)
  end
  if self.zoomDisabled then
    -- pokeemerald/src/pokenav_region_map.c:335
    love.graphics.setColor(0, 0, 0, 6 / 16)
    love.graphics.rectangle("fill", 0, 0, 240, 160)
    love.graphics.setColor(1, 1, 1, 1)
    return
  end
  local s = self.rm
  if self.iconVisible and self.iconBlinkOn then
    local who = s.female and man.sprites.may or man.sprites.brendan
    local ix, iy
    if self.zoomed then
      ix = s.playerIconX * 16 - 0x30 - 2 * self.scrollX
      iy = s.playerIconY * 16 - 0x42 - 2 * self.scrollY
    else
      ix, iy = s.playerIconX * 8 + 4, s.playerIconY * 8 + 4
    end
    Gfx.drawImage(who, 0, 0, 16, 16, ix - 8, iy - 8)
  end
  if self.cursorVisible then
    if self.zoomed then
      local seq = { 0, 1, 2, 1 }
      local f = seq[math.floor(self.cursorAnim / 10) % 4 + 1]
      Gfx.drawFrame(Gfx.manifest().sprites.cursorLarge, f, 48 - 16, 64 - 16, 32, 32)
    else
      local f = math.floor(self.cursorAnim / 20) % 2
      Gfx.drawImage(man.sprites.cursor, 0, f * 16, 16, 16, self.cursorSx - 8, self.cursorSy - 8)
    end
  end
end

local function landmarkNames(sec, pos)
  local out = {}
  local lists = Gfx.manifest().landmarks
  local i = 1
  while lists[i] and lists[i].mapSec ~= RegionMap.mapsec("NONE") do
    if lists[i].mapSec > sec then return out end
    if lists[i].mapSec == sec then break end
    i = i + 1
  end
  local row
  while lists[i] and lists[i].mapSec == sec do
    if lists[i].id == pos then row = lists[i] break end
    i = i + 1
  end
  if not row then return out end
  local Rematch = require("src.core.game3.rse.rematch")
  for _, l in ipairs(row.landmarks) do
    if l.flag == 0xFFFF or Rematch.flag(nil, l.flag) then out[#out + 1] = Gfx.plain(l.name) end
  end
  return out
end
NavMap.landmarkNames = landmarkNames

local function frameType(session)
  local ok, v = pcall(function() return require("src.core.game3.scripting.natives_region_map_rse").frameType(session) end)
  return ok and tonumber(v) or 0
end

-- pokeemerald/src/pokenav_region_map.c:533
function NavMap:drawInfo()
  local info = self.info
  if not info then return end
  local man = Gfx.manifest()
  local pal = man.palettes.infoWindow
  local y0 = 4 * 8 + math.floor(self.bg1Y)
  love.graphics.push()
  love.graphics.translate(0, math.floor(self.bg1Y))
  Kit.userFrame(17, 4, 12, 13, frameType(self.session), Gfx.color(pal, 1))
  love.graphics.pop()
  local colors = Gfx.colors(pal, Gfx.TEXT.WHITE, Gfx.TEXT.DARK_GRAY, Gfx.TEXT.LIGHT_GRAY)
  if info.type == TYPE.NONE then return end
  Gfx.text(info.name or "", 17 * 8, y0 + 1, colors, "narrow")
  if info.type == TYPE.CITY_CANFLY then
    for i, e in ipairs(man.cityMaps) do
      if e.mapSec == info.sec and e.index == info.pos then
        Gfx.drawImage(man.sprites.cityMaps, 0, (i - 1) * 80, 80, 80, 18 * 8, 6 * 8 + math.floor(self.bg1Y))
        break
      end
    end
    local ty = 132 + math.floor(self.bg1Y)
    for i, sp in ipairs(self.zoomTextSprites) do
      Gfx.drawImage(man.sprites.zoomText, sp.data1 * 8, 0, 32, 8, 152 + (i - 1) * 32 - 16, ty - 4)
    end
  elseif info.type == TYPE.ROUTE or info.type == TYPE.BATTLE_FRONTIER then
    for i, name in ipairs(landmarkNames(info.sec, info.pos)) do
      Gfx.text(name, 17 * 8, y0 + (i - 1) * 16 + 17, colors, "narrow")
    end
  end
end

function NavMap:draw()
  if not self.visible then return end
  self:drawMap()
  self:drawInfo()
end

return NavMap
