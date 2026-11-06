local Base = require("src.ui.game3.rse.berry_blender")
local B = require("src.core.game3.rse.berry_blender")
local Kit = require("src.ui.game3.rse.gc_kit")
local SceneKit = require("src.ui.game3.rse.scene_kit")
local Font = require("src.ui.game3.frlg_font")
local Chrome = require("src.ui.game3.chrome")
local Sprites = require("src.core.game3.gba_sprites")
local UI = {}; UI.__index=UI; setmetatable(UI,{__index=Base})
UI.STACK_ID="rs_berry_blender"
local Host={}; UI.Host=Host
function UI.new(opts)
  local options={}; for k,v in pairs(opts or {}) do options[k]=v end
  options.nativeRS,options.blendMaster=true,false
  options.version=options.version or require("src.core.game3.profile").forSession(options.session).id
  options.manifest=options.manifest or B.manifest()
  assert(options.manifest.assetLayout == "rs","native RS Blender requires its native pack")
  options.sound=options.sound or Kit.sound({muted=options.headless,version=options.version})
  return setmetatable(Base.new(options),UI)
end
function UI:textOptions(foreground)
  local w,pal=self.man.nativeWindow,self.man.palettes.font
  local function color(index) local r,g,b=SceneKit.rgb555(pal[index+1]); return {r,g,b,1} end
  return {font="native_"..w.fontNum,linePitch=16,maxWidth=240,
    colors={fg=color(foreground or w.foregroundColor),bg=color(w.backgroundColor),shadow=color(w.shadowColor)}}
end
function UI:measure(text) if self.headless then return 0 end; return Font.measure(text,self:textOptions()) end
-- pokeruby/src/berry_blender.c:1354
function UI:printPlayerNames()
  local g=self.game
  for i=0,3 do local pid=g.arrowIdToPlayerId[i]
    if pid ~= B.NO_PLAYER then
      self.arrowIds[pid]=self.arrowIds2[i]; Sprites.startAnim(self:sprite(self.arrowIds[pid]),i)
      local w=self:openWindow(i); w.fill=false
      w.prints={{text=(pid == g.localPlayerId and "{COLOR RED}" or "")..(g.playerNames[pid] or ""),x=1,y=0,caseId=1}}
      self:putWindow(i)
    end
  end
end
function UI:printMessage(key,ir)
  if not self.printer then
    local speed=require("src.core.game3.options").textSpeed(self.session)
    self.printer=SceneKit.printer(ir or self.irs[key],{speed=SceneKit.textSpeedDelay(speed),textSpeedOption=speed,linePitch=16})
    self.msgKeep=nil; self.printer:run({new={},held={}}); return false
  end
  self.printer:run(self.inp or {new={},held={}})
  if not self.printer:isActive() then self.msgKeep,self.printer=self.printer,nil; return true end
  return false
end
function UI:updateProgressBar(value)
  local tiles,L=self.man.tiles,self.outer
  local pixels=math.floor(value*64/B.MAX_PROGRESS_BAR); local full=math.floor(pixels/8); local i=0
  while i<full do L:putIndex(11+i,tiles.filledTop); L:putIndex(43+i,tiles.filledBottom); i=i+1 end
  local sub=pixels%8
  if sub~=0 then L:putIndex(11+i,tiles.emptyTop+sub); L:putIndex(43+i,tiles.emptyBottom+sub); i=i+1 end
  while i<8 do L:putIndex(11+i,tiles.emptyTop); L:putIndex(43+i,tiles.emptyBottom); i=i+1 end
end
function UI:drawRPM()
  local rpm=self.game.currentRPM or 0; local digits={}
  for i=0,4 do digits[i]=rpm%10; rpm=math.floor(rpm/10) end
  for i,cell in ipairs(self.man.tiles.rpmCells) do self.outer:putIndex(cell,digits[5-i]+self.man.tiles.rpmDigit) end
end
-- pokeruby/src/berry_blender.c:3171
function UI:printRanking()
  if self.rankState ~= 3 then return Base.printRanking(self) end
  local g,t=self.game,self.texts
  local w=self:openWindow(5); w.frame=true
  self:addTextPrinter(5,t.ranking,80-math.floor(self:measure(t.ranking)/2),0,0)
  self.scoreIcons={}
  for i,x in ipairs(self.man.geometry.scoreCenters) do
    local _,sprite=self:createSprite(self.man.sprites.score,x,52,0)
    Sprites.startAnim(sprite,({3,0,1})[i]); self.scoreIcons[i]=sprite
  end
  local places=g:sortScores(); local pitch=self.man.tables.rankRowPitch[g.numPlayers+1]
  for i=0,g.numPlayers-1 do
    local place,y=places[i],(8+i*pitch-3)*8
    self:addTextPrinter(5,tostring(i+1).." . "..(g.playerNames[place] or ""),4,y,3)
    for score=0,2 do local str=tostring(g.scores[place][score]); self:addTextPrinter(5,str,108+24*score-self:measure(str),y,3) end
  end
  self:putWindow(5); g.framesToWait=0; self.rankState=4; return false
end
-- pokeruby/src/berry_blender.c:2966
function UI:printResults()
  if self.resState ~= 3 then return Base.printResults(self) end
  local g,t=self.game,self.texts
  self:addTextPrinter(5,t.blendingResults,80-math.floor(self:measure(t.blendingResults)/2),0,0)
  local first,pitch=self.man.tables.resultFirstRow[g.numPlayers+1],self.man.tables.resultRowPitch[g.numPlayers+1]
  for i=0,g.numPlayers-1 do
    local place,y=g.playerPlaces[i],(first+i*pitch-3)*8
    self:addTextPrinter(5,tostring(i+1).." . "..(g.playerNames[place] or ""),0,y,3)
    self:addTextPrinter(5,(g.blendedBerries[place].name or "")..t.spaceBerry,88,y,3)
  end
  self:addTextPrinter(5,t.maximumSpeed,0,80,3)
  local integer=tostring(math.floor(g.maxRPM/100))
  self:addTextPrinter(5,integer,121-self:measure(integer),80,3)
  local dot=" . "; self:addTextPrinter(5,dot,121,80,3)
  local fraction=string.format("%02d",g.maxRPM%100)
  self:addTextPrinter(5,fraction..t.rpm,142-self:measure(fraction),80,3)
  self:addTextPrinter(5,t.time,0,96,3)
  local mins,secs=string.format("%02d",math.floor(g.gameFrameTime/3600)),string.format("%02d",math.floor(g.gameFrameTime/60)%60)
  self:addTextPrinter(5,mins..t.min,102-self:measure(mins),96,3)
  self:addTextPrinter(5,secs..t.sec,136-self:measure(secs),96,3)
  g.framesToWait=0; self.resState=4; return false
end
local function nativeYesNo(self)
  local select=0
  return {input=function(_,inp)
    local new=inp.new or {}
    if new.up or new.down then select=1-select; self.sound:se("SE_SELECT") end
    if new.b then return -1 end
    if new.a then return select end
  end,draw=function()
    Chrome.stdFrame(24,9,4,4)
    Font.draw(self.texts.yesNo,192,72,self:textOptions())
    require("src.ui.game3.rs.menu_cursor").draw(192,72+select*16,32)
  end}
end
function UI:cb_end()
  if self.game.gameEndState ~= 9 then return Base.cb_end(self) end
  self.yesNo=nativeYesNo(self); self.game.gameEndState=10
  self.game:restoreBgCoords(); self.game:updateRPM(); self:drawRPM()
  self.m.tasks:run(self); self:animate(); self:updatePaletteFade()
end
function UI:drawWindows()
  local g=self.game
  love.graphics.push(); love.graphics.translate(-(g and g.bg_X or 0),-(g and g.bg_Y or 0))
  for id=0,5 do local w=self.wins[id]
    if w and w.shown then
      if w.frame then Chrome.stdFrame(w.left,w.top,w.width,w.height) end
      for _,p in ipairs(w.prints) do Font.draw(p.text,w.left*8+p.x,w.top*8+p.y,self:textOptions()) end
    end
  end
  if self.printer or self.msgKeep then
    Chrome.stdFrame(1,15,28,4)
    local printer=self.printer or self.msgKeep
    printer:draw(8,120,self:textOptions())
  end
  love.graphics.pop()
  if self.yesNo then self.yesNo:draw() end
end
function UI.open(opts)
  opts=opts or {}; local options={}; for k,v in pairs(opts) do options[k]=v end
  local done=options.onDone
  options.onDone=function(screen) Host.screen=nil; require("src.ui.game3.stack").pop(UI.STACK_ID); if done then done(screen) end end
  local screen=UI.new(options); Host.screen=screen; Host.stepper=SceneKit.stepper()
  require("src.ui.game3.stack").push(UI.STACK_ID,Host,{hideBelow=true,fullscreen=true}); return screen
end
function UI.active() return Host.screen end
function UI.isOpen() return Host.screen ~= nil end
function UI.reset() if Host.screen then require("src.ui.game3.stack").pop(UI.STACK_ID) end; Host.screen,Host.stepper=nil,nil end
function Host.handleInput(input) if Host.stepper and not (Host.screen and Host.screen.hidden) then Host.stepper:collect(input) end end
function Host.update(dt) if Host.screen and not Host.screen.hidden then Host.stepper:run(dt,function(inp) Host.screen:frame(inp); return Host.screen.done or Host.screen.hidden or nil end) end end
function Host.draw() if Host.screen then Host.screen:draw() end end
return UI
