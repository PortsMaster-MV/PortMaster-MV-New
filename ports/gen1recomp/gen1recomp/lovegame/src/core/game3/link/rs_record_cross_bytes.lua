local M = {}
local Structs = require("src.save_convert.gen3_port.structs")
local Port = require("src.save_convert.gen3_port.rse")
local Records = Port.Records
local Codec = require("src.save_convert.Gen3Save")
local function f(name, off, t, n, len) return {name=name, off=off, t=t, n=n, len=len, pad=t=="text" and 0 or nil} end
local function b(name, off, shift, width) return {name=name, off=off, t="bits", of="u8", shift=shift, width=width} end
local PARTY = {f("personality",0,"u32",6), f("moves",24,"u16",24), f("species",72,"u16",6),
  f("heldItems",84,"u16",6), f("levels",96,"u8",6), f("EVs",102,"u8",6)}
M.BASE = {f("secretBaseId",0,"u8"), b("toRegister",1,0,4), b("gender",1,4,1), b("battledOwnerToday",1,5,1),
  b("registryStatus",1,6,2), f("trainerName",2,"text",nil,7), f("trainerId",9,"u8",4), f("language",13,"u8"),
  f("numSecretBasesReceived",14,"u16"), f("numTimesEntered",16,"u8"), f("decorations",18,"u8",16),
  f("decorationPositions",34,"u8",16), {name="party",off=52,t="struct",spec=PARTY,size=108}}
-- pokeemerald/include/global.h:651
M.OLD = {
  [0]={f("songLyrics",2,"u16",6),f("newSongLyrics",14,"u16",6),f("playerName",26,"text",nil,8),
    f("playerTrainerIdBytes",37,"u8",4),f("hasChangedSong",41,"bool8"),f("language",42,"u8")},
  [1]={f("taughtWord",1,"bool8"),f("language",2,"u8")},
  [2]={f("decorations",1,"u8",4),f("playerNames",5,"text",4,11),f("alreadyTraded",49,"bool8"),f("language",50,"u8",4)},
  [3]={f("alreadyRecorded",1,"bool8"),f("gameStatIDs",4,"u8",4),f("trainerNames",8,"text",4,7),
    f("statValues",36,"u32",4),f("language",52,"u8",4)},
  [4]={f("taleCounter",1,"u8"),f("questionNum",2,"u8"),f("randomWords",4,"u16",10),
    f("questionList",24,"u8",8),f("language",32,"u8")},
}
M.TOWER = {}
for _, field in ipairs(Records.TOWER) do M.TOWER[#M.TOWER+1]=field end
M.TOWER[#M.TOWER+1]={name="party",off=52,t="struct",spec=Records.MON,size=44,n=4}
M.MAIL = {f("words",0,"u16",9), f("playerName",18,"text",nil,8), f("trainerIdRaw",26,"u32"),
  f("species",30,"u16"),f("itemId",32,"u16")}

function M.bytes(raw)
  local out={}; for i=1,#raw do out[i]=raw:byte(i) end; return out
end
function M.raw(bytes, size)
  if type(bytes)~="table" or #bytes~=size then return end
  local out={}
  for i=1,size do
    local n=tonumber(bytes[i]); if not n or n<0 or n>255 or n%1~=0 then return end
    out[i]=string.char(n)
  end
  return table.concat(out)
end
function M.put(raw, off, value)
  return raw:sub(1,off)..string.char(value%256)..raw:sub(off+2)
end
function M.u16(raw, off) return raw:byte(off+1)+raw:byte(off+2)*256 end
local function patch(w, base, spec, value, codec)
  for _, field in ipairs(spec) do
    local given=value[field.name]
    if given~=nil then
      if field.t=="struct" then
        if field.n then for i=1,field.n do patch(w,base+field.off+(i-1)*field.size,field.spec,given[i] or {},codec) end
        else patch(w,base+field.off,field.spec,given,codec) end
      elseif field.n then
        for i=1,field.n do
          local part={}; for k,v in pairs(field) do part[k]=v end
          part.n=nil; part.off=field.off+(i-1)*(field.len or Structs.SIZE[field.t])
          local want=given[i]
          if want~=nil and not Port.same(Structs.read(w:str(),base,{part},codec)[field.name],want) then
            Structs.write(w,base,{part},{[field.name]=want},codec)
          end
        end
      elseif not Port.same(Structs.read(w:str(),base,{field},codec)[field.name],given) then
        Structs.write(w,base,{field},value,codec)
      end
    end
  end
end
function M.render(codec, size, spec, value, template)
  local raw=M.raw(value and value._recordMixNativeBytes,size) or template or string.rep("\0",size)
  local w=codec.newBuf(size,raw); patch(w,0,spec,value or {},codec); return w:str()
end
function M.read(codec, raw, spec)
  local value=Structs.read(raw,0,spec,codec); value._recordMixNativeBytes=M.bytes(raw); return value
end
function M.readOld(codec, raw)
  local out=M.read(codec,raw,M.OLD[raw:byte(1)] or {}); out.id=raw:byte(1)
  if out.playerTrainerIdBytes then out.playerTrainerId=out.playerTrainerIdBytes[1]+out.playerTrainerIdBytes[2]*256 end
  return out
end
function M.renderOld(codec, value, template)
  local raw=M.raw(value._recordMixNativeBytes,64) or M.raw(value.nativeBytes,64) or template or string.rep("\0",64)
  local src={}; for k,v in pairs(value) do src[k]=v end
  if value.id==0 and src.playerTrainerIdBytes==nil then
    local id=tonumber(src.playerTrainerId) or 0
    src.playerTrainerIdBytes={id%256,math.floor(id/256)%256,raw:byte(40),raw:byte(41)}
  end
  local result=M.render(codec,64,M.OLD[value.id] or {},src,raw)
  return M.put(result,0,value.id or 0)
end
function M.readTower(codec, raw)
  local out=M.read(codec,raw,M.TOWER)
  out.checksumValid=codec.u32(raw,232)==Records.wordSum(raw,0,58)
  return out
end
function M.renderTower(codec, value, template)
  local raw=M.render(codec,236,M.TOWER,value,template)
  local w=codec.newBuf(236,raw); w:w32(232,Records.wordSum(raw,0,58)); return w:str()
end
function M.readMail(codec, raw, emerald)
  local message=M.read(codec,raw:sub(1,36),M.MAIL)
  message.playerName=message.playerName:gsub(" +$","")
  message.trainerId=emerald and message.trainerIdRaw or message.trainerIdRaw%65536
  message._rsNativeBytes=M.bytes(raw:sub(1,36))
  local out={message=message,otName=codec.decodeString(raw,36,8),monName=codec.decodeString(raw,44,11),
    _recordMixNativeBytes=M.bytes(raw),_rsNativeBytes=M.bytes(raw)}
  if emerald then out.gameLanguage=raw:byte(56)%16; out.monLanguage=math.floor(raw:byte(56)/16) end
  return out
end
function M.renderMessage(codec, value, template)
  local raw=template or M.raw(value._recordMixNativeBytes,36) or M.raw(value._rsNativeBytes,36) or string.rep("\0",36)
  local message={}; for k,v in pairs(value) do message[k]=v end
  message._recordMixNativeBytes=M.bytes(raw)
  local id=tonumber(message.trainerId)
  if message.trainerIdRaw==nil or (id and id~=message.trainerIdRaw and id~=message.trainerIdRaw%65536) then
    id=id or 0
    local old=codec.u32(raw,26)
    message.trainerIdRaw=(id<65536 and id==old%65536) and old or id
  end
  local name=codec.decodeString(raw,18,8):gsub(" +$","")
  if name==tostring(message.playerName or "") then message.playerName=nil end
  return M.render(codec,36,M.MAIL,message,raw)
end
function M.renderMail(codec, value, template, emerald)
  local raw=M.raw(value._recordMixNativeBytes,56) or M.raw(value._rsNativeBytes,56) or template or string.rep("\0",56)
  raw=M.renderMessage(codec,value.message or {},raw:sub(1,36))..raw:sub(37)
  raw=M.render(codec,56,{f("otName",36,"text",nil,8),f("monName",44,"text",nil,11)},
    {otName=value.otName,monName=value.monName},raw)
  if emerald and value.gameLanguage~=nil and value.monLanguage~=nil then
    raw=M.put(raw,55,value.gameLanguage%16+(value.monLanguage%16)*16)
  end
  return raw
end

local function blocks(s, codec)
  local image=codec.slotTemplate(s)
  if image then local _,out=codec.decode(image); if type(out)=="table" then return out end end
  return {sb1=string.rep("\0",codec.L.BLOCKS[2].size),sb2=string.rep("\0",codec.L.BLOCKS[1].size)}
end
M.blocks=blocks
function M.sectionRaw(s, name, value)
  local c=Codec.forVersion(s.version); local source=blocks(s,c)
  local w1,w2=c.newBuf(#source.sb1,source.sb1),c.newBuf(#source.sb2,source.sb2)
  local x={L=c.L,codec=c,sb1=source.sb1,sb2=source.sb2,w1=w1,w2=w2}
  M.beforeSection(x,name,value)
  c.port.SECTIONS[name].write(x,value)
  M.afterSection(x,name,value)
  return w1:str(),w2:str(),c
end
function M.readShows(codec, raws)
  local off=codec.L.RSE.sb1.tvShows
  local sb1=string.rep("\0",off)..table.concat(raws,"",0,24)
  local out=codec.port.SECTIONS.tvShows.read({L=codec.L,codec=codec,sb1=sb1}).tvShows
  for i=0,24 do out[i]._recordMixNativeBytes=M.bytes(raws[i]) end
  return out
end
local function renderShow(codec, show, raw)
  local w=codec.newBuf(36,raw)
  codec.port.SECTIONS.tvShows.write({L={RSE={sb1={tvShows=0,tvShowCount=1}}},codec=codec,sb1=raw,w1=w},
    {tvShows={[0]=show}})
  return w:str()
end
function M.hasMetadata(value)
  if type(value)~="table" then return false end
  if value._recordMixNativeBytes then return true end
  for _,child in pairs(value) do if type(child)=="table" and M.hasMetadata(child) then return true end end
  return false
end

function M.beforeSection(x, name, value)
  if name=="tvShows" then
    for i=0,24 do
      local raw=M.raw((value.tvShows or {})[i] and value.tvShows[i]._recordMixNativeBytes,36)
      if raw then x.w1:bytes(x.L.RSE.sb1.tvShows+i*36,raw) end
    end
    x.sb1=x.w1:str()
  end
end
function M.afterSection(x, name, value)
  if name=="tvShows" then
    for i=0,24 do
      local show=(value.tvShows or {})[i]
      local raw=type(show)=="table" and M.raw(show._recordMixNativeBytes,36)
      if raw then x.w1:bytes(x.L.RSE.sb1.tvShows+i*36,renderShow(x.codec,show,raw)) end
    end
  elseif name=="secretBases" then
    for i=1,20 do
      local base=(value.secretBases or {})[i]
      if type(base)=="table" and M.raw(base._recordMixNativeBytes,160) then
        x.w1:bytes(x.L.RSE.sb1.secretBases+(i-1)*160,M.render(x.codec,160,M.BASE,base))
      end
    end
  elseif name=="oldMan" and x.L.FAMILY=="emerald" then
    local old=value.oldMan
    if type(old)=="table" and M.raw(old._recordMixNativeBytes,64) then
      x.w1:bytes(x.L.RSE.sb1.oldMan,M.renderOld(x.codec,old))
    end
  end
end
return M
