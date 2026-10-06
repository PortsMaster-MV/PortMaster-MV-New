local Native = require("src.ui.game3.rs.intro_credits_scenery")
local Machine = require("src.ui.game3.rse.gba_machine")
local Ppu = require("src.core.game3.gba_ppu")
local Sprites = require("src.core.game3.gba_sprites")
local bit = require("bit")
local S = { NORMAL=0, DESTROY=1, FROZEN=2, SCENE_OCEAN_MORNING=0, SCENE_OCEAN_SUNSET=1,
  SCENE_FOREST_RIVAL_ARRIVE=2, SCENE_FOREST_CATCH_RIVAL=3, SCENE_CITY_NIGHT=4,
  TAG_BRENDAN=1002, TAG_MAY=1003, TAG_FLYGON_LATIOS=1004, TAG_FLYGON_LATIAS=1005 }
function S.manifest(m)
  local intro = m:manifest(Native.MANIFEST)
  local credits = m:manifest("data/generated/gba/credits_rse/manifest.lua")
  assert(intro.layout == "rs" and credits.assetLayout == "rs", "native RS credits scenery required")
  local out = {}; for k,v in pairs(intro) do out[k]=v end
  out.credits = credits.credits
  out.palettes = {}; for k,v in pairs(intro.palettes) do out.palettes[k]=v end
  out.palettes.sBrendanCredits_Pal = intro.palettes.gIntro2BrendanPalette
  out.palettes.sMayCredits_Pal = intro.palettes.gIntro2MayPalette
  out.palettes.sLatios_Pal = intro.palettes.gIntro2LatiosPalette
  out.palettes.sLatias_Pal = intro.palettes.gIntro2LatiasPalette
  return out
end
local function signed(n) n=bit.band(n,65535); return n>=32768 and n-65536 or n end
local function moving(s,sp,m)
  local g=m.globals
  if g.movingSceneryState == S.FROZEN then return end
  if g.movingSceneryState ~= S.NORMAL then sp:destroy(s); return end
  local n=bit.tobit(s.x*65536+bit.band(s.data[2],65535)+bit.band(s.data[1],65535))
  s.x,s.data[2]=math.floor(n/65536),signed(n); if s.x>255 then s.x=-32 end
  s.y2=-(g.movingSceneryVBase+(s.data[0]~=0 and g.movingSceneryVOffset or 0))
end
local function createMoving(m,entry,vertical)
  local frameOf,anims={},{}
  for i,r in ipairs(entry.rects) do frameOf[r.tile]=i-1 end
  for ai,a in ipairs(entry.anims) do
    local list={}; for ci,cmd in ipairs(a) do
      local row={}; for k,v in pairs(cmd) do row[k]=v end
      if row.op=="frame" then row.frame=assert(frameOf[row.tile],"native credits scenery tile") end
      list[ci]=row
    end; anims[ai]=list
  end
  local sheet=Ppu.indexSheet(entry.variants.day or entry.variants.night,entry.w,entry.h,entry.rects)
  local sp=m.ppu.sprites
  for _,r in ipairs(entry.sprites) do
    local sprite=sp:get(sp:create({w=r.w,h=r.h,sheet=sheet,anims=anims,callback=function(a,b) moving(a,b,m) end},r.x,r.y,r.subpriority))
    Sprites.calcCenterToCornerVec(sprite,r.shape,r.size,0)
    sprite.oam.priority,sprite.oam.shape,sprite.oam.size,sprite.oam.paletteNum=3,r.shape,r.size,0
    Sprites.startAnim(sprite,r.animNum); sprite.data[0],sprite.data[1],sprite.data[2]=vertical and 1 or 0,signed(r.xOff),0
  end
end
-- pokeruby/intro_credits_graphics.c:363
function S.loadCreditsSceneGraphics(m,scene)
  local man=S.manifest(m)
  local function load(name,off) local p=assert(man.palettes[name],name); m.ppu.palette:load(p,off,#p) end
  if scene==1 then
    load("gUnknown_0841221C",240); load("gUnknown_08412878",0); load("gUnknown_084131A4",256)
    m.sceneryLayers={"clouds_bg3","clouds_bg2"}; createMoving(m,man.scenery.moving_clouds,false)
  elseif scene==2 or scene==3 then
    load("gUnknown_0841221C",240); load("gUnknown_08413320",0); load("gUnknown_08413320",256)
    m.sceneryLayers={"trees_bg3","trees_bg2"}; createMoving(m,man.scenery.moving_trees,true)
  elseif scene==4 then
    load("gUnknown_0841223C",240); load("gUnknown_08413E38",0); load("gUnknown_08414064",256)
    m.sceneryLayers={"houses_bg3","houses_bg2"}; createMoving(m,man.scenery.moving_houses,true)
  else
    load("gUnknown_084121FC",240); load("gUnknown_08412818",0); load("gUnknown_08413184",256)
    m.sceneryLayers={"clouds_bg3","clouds_bg2"}; createMoving(m,man.scenery.moving_clouds,false)
  end
  m.ppu.sprites:setReservedPalettes(8); m.globals.movingSceneryState=S.NORMAL
end
function S.setCreditsSceneBgCnt(m)
  local man=S.manifest(m)
  m.ppu:setBg(3,3,Machine.layer(man.layers[m.sceneryLayers[1]]))
  m.ppu:setBg(2,2,Machine.layer(man.layers[m.sceneryLayers[2]]))
  m.ppu:setBg(1,1,Machine.layer(man.layers.grass)); m.ppu:set("DISPCNT",0x1F40)
end
S.createBicycleBgAnimationTask=Native.createBgTask
S.cycleSceneryPalette=Native.cyclePalette
return S
