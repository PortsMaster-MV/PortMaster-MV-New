local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local IR = require("src.core.game3.scripting.text_ir")
local bit = require("bit")
local M = {SUB = "rse/berry_blender", FILES = {"center_idx.png","outer.4bpp","berries.png","arrow.png","score.png","particles.png","countdown.png","start.png"}}
M.REQUIRED = K.required(M.SUB,M.FILES)
local BB = "berry_blender.o:"
local function values(c,name,stride,signed)
  local off,n,out = c:off(name),c.S.size(name)/stride,{}
  for i=0,n-1 do out[i+1] = stride == 2 and (signed and c:s16(off+i*2) or c:u16(off+i*2)) or (signed and c:s8(off+i) or c:u8(off+i)) end
  return out
end
local function rows(list,n)
  local out = {}; for i=0,#list/n-1 do local row = {}; for j=1,n do row[j] = list[i*n+j] end; out[i+1] = row end; return out
end
local function text(c,off)
  local bytes = {}
  for i=0,1023 do local b=c:u8(off+i); bytes[#bytes+1]=b
    if b == 255 then local ir=IR.decode(bytes,{dialect="rs"}); return IR.toAscii(ir),ir end
  end
  error("native RS Blender text is unterminated")
end
local function window(c,name)
  local off,out = c:off(name),{}
  for i,key in ipairs({"bgNum","charBaseBlock","screenBaseBlock","priority","paletteNum","foregroundColor","backgroundColor","shadowColor","fontNum","textMode","spacing","tilemapLeft","tilemapTop","width","height"}) do out[key]=c:u8(off+i-1) end
  return out
end
local TEXTS = {
  berryBlenderStart="gOtherText_BlenderChooseBerry", wasMade="gOtherText_PokeBlockMade", pressAToStart="gOtherText_PressAToStart",
  pleaseWaitAWhile="gOtherText_PleaseWait", communicationStandby="gOtherText_LinkStandby3", wouldLikeToBlendAnotherBerry="gOtherText_BlendAnotherBerryPrompt",
  runOutOfBerriesForBlending="gOtherText_OutOfBerries", yourPokeblockCaseIsFull="gOtherText_CaseIsFull", hasNoBerriesToPut="gOtherText_NoBerriesForBlend",
  apostropheSPokeblockCaseIsFull="gOtherText_OtherCaseIsFull", blendingResults="gOtherText_ResultsOfBlending", spaceBerry="gOtherText_Berry",
  time="gOtherText_RequiredTime", min="gOtherText_Min", sec="gOtherText_Sec", maximumSpeed="gOtherText_MaxSpeed", rpm="gOtherText_RPM",
  ranking="gOtherText_Ranking", theLevelIs="gOtherText_BlockLevelIs", theFeelIs="gOtherText_BlockFeelIs", dot2="gOtherText_Period",
  blenderMaxSpeedRecord="gMultiText_BerryBlenderMaxSpeedRecord", players234="gMultiText_2P3P4P", yesNo="gOtherText_YesNoTerminating",
  newParagraph=BB.."gUnknown_08216249", space=BB.."sSpaceString_0",
}
function M.run(rom,cache,opts)
  local c=A.context(rom,cache,opts,M.SUB)
  local gfx=c:lz("gUnknown_08E6C100")
  local idx,w,h=K.bakeAffine(gfx,c:raw(BB.."sBlenderCenterMap"),32)
  local man={screen="berry_blender",center={index=c:gray("center_idx.png",w,h,idx),w=w,h=h,bpp=8},
    outerTiles=c:write("outer.4bpp",string.rep("\0",0x2000)..c:lz("gUnknown_08E6C920")),outerMap={},sprites={},texts={},irs={},palettes={},tables={},opponentNames={},blendMaster=false}
  local map=c:lz("gUnknown_08E6D354")
  for i=0,1023 do man.outerMap[i+1]=i<640 and bit.bor(map:byte(i*2+1)+map:byte(i*2+2)*256,0x100) or 0 end
  man.palettes.center=K.palList(c:palAt(c:off(BB.."sBlenderCenterPal"),128),0,128)
  man.palettes.outer=K.palList(c:palAt(c:off(BB.."sBlenderOuterPal"),16),0,16)
  man.palettes.font=K.palList(c:pal("gFontDefaultPalette",16),0,16)
  for _,spec in ipairs({{"arrow","sBlenderSyncArrow_SpriteTemplate","gBerryBlenderArrowTiles"},
    {"score","sSpriteTemplate_821645C","gBerryBlenderMarubatsuTiles"},
    {"particles","sSpriteTemplate_82164FC","gBerryBlenderParticlesTiles"},
    {"countdown","sSpriteTemplate_8216548","gBerryBlenderCountdownNumbersTiles"},
    {"start","sSpriteTemplate_821657C","gBerryBlenderStartTiles"}}) do
    local entry=c:spriteFrames(spec[1],c:raw(spec[3]),c:readTemplate(BB..spec[2]),{})
    entry.paletteTag=c:u16(c:off(BB..spec[2])+2); man.sprites[spec[1]]=entry
  end
  man.palettes.sprites={{tag=man.sprites.arrow.paletteTag,colors=K.palList(c:pal("gBerryBlenderArrowPalette",16),0,16)},
    {tag=man.sprites.score.paletteTag,colors=K.palList(c:pal("gBerryBlenderMiscPalette",16),0,16)}}
  local frames,pals={},{}
  local bp=c:off("item_menu.o:sBerryGraphicsTable")
  local count=c.S.count("item_menu.o:sBerryGraphicsTable",8)
  for i=0,count-1 do
    local pic=K.bakeSprite(c:lzAt(assert(c:ptr(bp+i*8))),48,48,0,4)
    local frame=K.blank(64,64)
    for y=0,47 do for x=0,47 do frame[(y+8)*64+x+9]=pic[y*48+x+1] end end
    frames[i+1]=frame; pals[i+1]=K.palList(c:palFrom(c:lzAt(assert(c:ptr(bp+i*8+4))),16),0,16)
  end
  local berry=c:readTemplate("item_menu.o:gSpriteTemplate_83C1E04")
  man.berry={png=c:png("berries.png",64,64*count,K.stack(frames,64,64),{},true),w=64,h=64,frames=count,
    anims={{{op="frame",frame=0,duration=0},{op="end"}}},affineAnims={A.affine(c,"item_menu.o:gSpriteAffineAnim_83C1D8C"),A.affine(c,"item_menu.o:gSpriteAffineAnim_83C1DC4")},
    priority=berry.oam.priority,affineMode=berry.oam.affineMode,objMode=berry.oam.objMode,paletteTag=berry.paletteTag}
  man.palettes.berries=pals
  for key,name in pairs(TEXTS) do man.texts[key],man.irs[key]=text(c,c:off(name)) end
  local off=c:off("gOtherText_ResultsOfBlending"); local _,irs=text(c,off)
  local bytes=0; repeat bytes=bytes+1 until c:u8(off+bytes-1)==255
  man.texts.berryUsed,man.irs.berryUsed=text(c,off+bytes)
  off=c:off("gOtherText_RPM"); bytes=0; repeat bytes=bytes+1 until c:u8(off+bytes-1)==255
  man.texts.dot,man.irs.dot=text(c,off+bytes)
  local names=c:off(BB.."sBlenderOpponentsNames")
  for i=0,2 do man.opponentNames[i+1]=text(c,assert(c:ptr(names+i*4))) end
  local T=man.tables
  T.playerArrowQuadrant=rows(values(c,BB.."gUnknown_082162CC",1,true),2)
  T.playerArrowPos=rows(values(c,BB.."sBlenderSyncArrowsPos",1),2)
  T.playerIdMap=rows(values(c,BB.."gUnknown_082162EC",1),4)
  T.arrowStartPos=values(c,BB.."gUnknown_082162F8",2)
  T.arrowStartPosIds=values(c,BB.."gUnknown_08216300",1)
  T.arrowHitRangeStart=values(c,BB.."gUnknown_08216303",1)
  T.berrySpriteData=rows(values(c,BB.."gUnknown_08216594",2,true),5)
  T.opponentBerrySets=rows(values(c,BB.."gUnknown_082165BC",1),3)
  T.numPlayersToSpeedDivisor=values(c,BB.."gUnknown_082165DA",1)
  T.blackPokeblockFlavorFlags=values(c,BB.."gUnknown_082165DF",1)
  T.berryMasterBerries={}
  T.sine=values(c,"gSineTable",2,true)
  T.namePositions=rows(values(c,BB.."gUnknown_082162D4",1),2)
  T.resultFirstRow=values(c,BB.."gUnknown_082165E9",1)
  T.resultRowPitch=values(c,BB.."gUnknown_082165EE",1)
  T.rankRowPitch=values(c,BB.."gUnknown_082165F3",1)
  man.nativeWindow=window(c,"gWindowTemplate_81E6F68")
  man.windows={}
  for i=1,4 do local p=T.namePositions[i]; man.windows[i]={left=p[1],top=p[2],width=7,height=2} end
  man.windows[5]={left=1,top=15,width=28,height=4}
  man.windows[6]={left=5,top=3,width=20,height=14}
  man.geometry={messageFrame={0,14,29,19},messageOrigin={1,15},resultsFrame={4,2,25,17},titleWidth=160,
    scoreCenters={140,164,188},recordFrame={6,3,23,16},recordTitle={8,4},recordPlayers={8,9},recordNumbers={15,9}}
  man.yesNoWindow={left=24,top=9,width=4,height=4,frame={23,8,28,13},cursorWidth=32}
  man.recordWindow={left=7,top=4,width=16,height=12}
  man.tiles={filledTop=0x81E9,filledBottom=0x81F9,emptyTop=0x81E1,emptyBottom=0x81F1,rpmDigit=0x8172,rpmCells={0x458/2,0x45A/2,0x45C/2,0x460/2,0x462/2}}
  return A.finish(c,man)
end
function M.ready(cache,root) return A.ready(M.SUB,cache,root) end
return M
