local M = {}
local B = require("src.core.game3.link.rs_record_cross_bytes")
local Text = require("src.core.game3.link.rs_record_cross_text")
local Tower = require("src.core.game3.link.rs_record_cross_tower")
local Util = require("src.core.game3.rse.record_mix_util")
local Codec = require("src.save_convert.Gen3Save")
local Rs = require("src.core.game3.link.rs")
local function n(v) return tonumber(v) or 0 end
local function deep(v) return Util.deep(v) end
local function emerald(v) return v=="emerald" end
function M.anyRS(players)
  for _,p in ipairs(players or {}) do if Rs.is(p.version) then return true end end
  return false
end
function M.mixed(s, players)
  s=type(s)=="table" and s or {}
  if Rs.is(s.version) then
    for _,p in ipairs(players or {}) do if emerald(p.version) then return true end end
  else return emerald(s.version) and M.anyRS(players) end
  return false
end
local function partner(players,mine) return players[Util.shuffle(players)[mine]] end
local function rawOld(c, value, template) return B.renderOld(c,value or {id=0},template) end
local function rawRsTower(c, record)
  local rc=Codec.forVersion("ruby")
  return rc.port.renderTowerRecord(rc,nil,record or {})
end
local function showRaw(c, p)
  local rows={}
  for i=0,24 do
    local show=(p.tvShows or {})[i] or {kind=0}
    rows[i]=B.raw(show.nativeBytes,36) or B.raw(show._recordMixNativeBytes,36)
    if not rows[i] then
      rows[i]=require("src.save_convert.gen3_port.sections.rs_tv_shows").render(c,string.rep("\0",36),show,
        require("src.save_convert.gen3_port.rse").same)
    end
  end
  return rows
end
local function daycareTemplate(c, blocks, i)
  local off=c.L.DAYCARE.off+(i-1)*c.L.DAYCARE.monSize+c.L.DAYCARE_MAIL.off
  return blocks.sb1:sub(off+1,off+56)
end
-- pokeemerald/src/record_mixing.c:201
function M.packet(s, playerId)
  assert(emerald(s.version),"cross-version compatibility exporter requires Emerald")
  local c=Codec.forVersion(s.version)
  local out={version=s.version,name=s.name or s.playerName,trainerId=n(s.trainerId or s.id)%65536,
    linkTrainerId=Util.sessionLinkTrainerId(s),language=2,recordLayout="rs"}
  local bases=require("src.core.game3.rse.secret_base").mixExport(s)
  local source=B.blocks(s,c)
  out.secretBases={}
  for i=1,20 do
    local off=c.L.RSE.sb1.secretBases+(i-1)*160
    local raw=B.render(c,160,B.BASE,bases[i] or {},source.sb1:sub(off+1,off+160))
    if raw:byte(14)==1 then raw=string.rep("\0",160) end -- ClearJapaneseSecretBases
    out.secretBases[i]=B.read(c,raw,B.BASE)
  end
  local Tv=require("src.core.game3.rse.tv")
  Tv.deactivateAllNormalShows(s)
  local state=Tv.state(s)
  local sb1=B.sectionRaw(s,"tvShows",{tvShows=state.tvShows})
  local rows={}
  for i=0,24 do
    local off=c.L.RSE.sb1.tvShows+i*36
    local raw=sb1:sub(off+1,off+36)
    if i<24 then
      local kind=raw:byte(1)
      if (kind==25 and raw:byte(11)>88) or (kind==23 and raw:byte(19)>88)
        or (kind==7 and ((raw:byte(30)==1)~=(raw:byte(31)==1))) then raw=string.rep("\0",36) end
    end
    rows[i]=raw
  end
  out.tvShows=B.readShows(c,rows); out.pokeNews=deep(state.pokeNews)
  local sum=0; local prefix=table.concat(rows,"",0,24):sub(1,256)
  for i=1,256 do sum=sum+prefix:byte(i) end
  out.tvShowByteSum=sum%256
  local old=rawOld(c,require("src.core.game3.rse.old_man").state(s),
    source.sb1:sub(c.L.RSE.sb1.oldMan+1,c.L.RSE.sb1.oldMan+64))
  out.oldMan=B.readOld(c,Text.oldForRuby(old,c))
  out.dewfordTrends=require("src.core.game3.rse.dewford_trend").mixExport(s)
  out.daycareMail=require("src.core.game3.rse.daycare_mail_mix").mixExport(s)
  local storedMail=require("src.core.game3.daycare").stateOf(s).mail or {}
  local dc=out.daycareMail; dc.itemsHeld={}
  for i=1,2 do
    local template=daycareTemplate(c,source,i)
    local raw=storedMail[i] and B.renderMail(c,storedMail[i],template,true) or template
    if i<=n(dc.numDaycareMons) and B.u16(raw,32)~=0 then
      if raw:byte(56)%16~=1 then raw=Text.field(raw,36,8,Text.pad) end
      local lang=math.floor(raw:byte(56)/16)
      raw=Text.field(raw,44,11,function(str) return Text.international(str,lang) end)
    end
    dc.mail[i]=B.readMail(c,raw,true)
    dc.itemsHeld[i]=(dc.cantHoldItem[i]==true or dc.cantHoldItem[i]==1) and 1 or 0
  end
  local _,sb2=B.sectionRaw(s,"frontierRecords",{frontier=s.frontier or {}})
  local off=c.L.RSE.sb2.frontier
  local tower=Tower.toRuby(c,sb2:sub(off+1,off+236))
  local rc=Codec.forVersion("ruby")
  out.battleTowerRecord=rc.port.readTowerRecord(tower,rc)
  out.giftItem=require("src.core.game3.rse.record_mixing_gift").mixExport(s,playerId) or 0
  return deep(out)
end

-- record_mixing.c:760
local function receiveMail(s, players, mine, sum)
  local c=Codec.forVersion(s.version)
  local Rng=require("src.core.game3.rng")
  local oldSeed=Rng.Random2(); Rng.SeedRng2(Util.linkTrainerId(players[1])%65536)
  local eligible={}
  for i,p in ipairs(players) do
    local r=p.daycareMail; r.mail=r.mail or {}; r.itemsHeld=r.itemsHeld or r.cantHoldItem or {}
    local slots={}
    for j=1,2 do
      local raw=B.renderMail(c,r.mail[j] or {},nil,true)
      if j<=n(r.numDaycareMons) and B.u16(raw,32)~=0 then
        local ot=raw:sub(37,44); local mon=raw:sub(45,55)
        local otLang,monLang=n(p.language),n(p.language)
        if Text.length(ot)<=5 then otLang=1 else raw=Text.field(raw,36,8,Text.strip) end
        if Text.prefixJapanese(mon) then raw=Text.field(raw,44,11,Text.strip); monLang=1 end
        if Rs.is(p.version) then raw=B.put(raw,55,otLang%16+monLang%16*16) end
      end
      r.mail[j]=B.readMail(c,raw,true)
      local held=r.itemsHeld[j]
      if j<=n(r.numDaycareMons) and not (held==true or held==1) then slots[#slots+1]=j end
    end
    if #slots==2 then
      local a,b=n(r.mail[1].message.itemId),n(r.mail[2].message.itemId)
      if (a==0)==(b==0) then slots={Rng.Random2()%2+1} else slots={a~=0 and 1 or 2} end
    end
    if #slots~=0 then eligible[#eligible+1]={i,slots[1]} end
  end
  local function swap(a,b)
    local l,r=eligible[a+1],eligible[b+1]
    local lm,rm=players[l[1]].daycareMail.mail,players[r[1]].daycareMail.mail
    lm[l[2]],rm[r[2]]=rm[r[2]],lm[l[2]]
  end
  local row=n(sum)%3+1
  if #eligible==2 then swap(0,1)
  elseif #eligible==3 then local pair=({{0,1},{1,2},{2,0}})[row]; swap(pair[1],pair[2])
  elseif #eligible==4 then local ids=({{0,1,2,3},{0,2,1,3},{0,3,2,1}})[row]; swap(ids[1],ids[2]); swap(ids[3],ids[4]) end
  require("src.core.game3.daycare").stateOf(s).mail=deep(players[mine].daycareMail.mail)
  Rng.SeedRng(oldSeed)
end

local function receiveTower(s, raw)
  local c=Codec.forVersion(s.version)
  s.frontier=s.frontier or {}; s.frontier.towerRecords=s.frontier.towerRecords or {}
  local list=s.frontier.towerRecords
  local _,sb2=B.sectionRaw(s,"frontierRecords",{frontier=s.frontier})
  local raws={}; local base=c.L.RSE.sb2.frontier+236
  for i=1,5 do raws[i]=sb2:sub(base+(i-1)*236+1,base+i*236) end
  local target
  for i=1,5 do
    if raws[i]:sub(13,16)==raw:sub(13,16) and raws[i]:byte(9)==raw:byte(9) then target=i; break end
  end
  if not target then for i=1,5 do if B.u16(raws[i],2)==0 then target=i; break end end end
  if not target then
    local min,slots=B.u16(raws[1],2),{1}
    for i=2,5 do local streak=B.u16(raws[i],2)
      if streak<min then min,slots=streak,{i} elseif streak==min then slots[#slots+1]=i end
    end
    target=slots[require("src.core.game3.rng").Random()%#slots+1]
  end
  list[target]=B.readTower(c,raw)
  return target
end

function M.receive(s, packets, mine)
  if #packets<2 or #packets>4 or mine<1 or mine>#packets then return {unsupportedReason="rs_record_mixing_invalid_players"} end
  local players=deep(packets)
  for _,p in ipairs(players) do
    if not (Rs.is(p.version) or emerald(p.version)) or (emerald(p.version) and p.recordLayout~="rs") then
      return {unsupportedReason="rs_record_mixing_requires_native_compatibility_packet"}
    end
    if type(p.oldMan)~="table" or type(p.daycareMail)~="table" or type(p.battleTowerRecord)~="table"
      or type(p.dewfordTrends)~="table" then return {unsupportedReason="rs_record_mixing_invalid_packet"} end
  end
  if Rs.is(s.version) then
    local c=Codec.forVersion(s.version)
    local Old=require("src.save_convert.gen3_port.sections.rs_old_man")
    local Tv=require("src.save_convert.gen3_port.sections.rs_tv_shows")
    local Mail=require("src.save_convert.gen3_port.sections.rs_daycare_mail")
    for _,p in ipairs(players) do
      p.version=s.version
      p.oldMan=Old.read(rawOld(c,p.oldMan),c)
      local rows=showRaw(c,p)
      p.tvShows=p.tvShows or {}
      for i=0,24 do p.tvShows[i]=Tv.readSlot(rows[i],c) end
      p.daycareMail.mail=p.daycareMail.mail or {}
      for i=1,2 do p.daycareMail.mail[i]=Mail.read(B.renderMail(c,p.daycareMail.mail[i] or {},nil,false),c) end
    end
    return require("src.core.game3.link.rs_record_mix").receive(s,players,mine)
  end
  local c=Codec.forVersion(s.version)
  local applied={}
  local bases={}
  for i,p in ipairs(players) do
    bases[i]=p.secretBases or {}
    for _,base in ipairs(bases[i]) do
      if Rs.is(p.version) or (n(p.language)==1 and #c.encodeString(base.trainerName or "",7):match("^[^\255]*")>5) then base.language=2 end
    end
  end
  require("src.core.game3.rse.secret_base").mixImport(s,bases,mine); applied.secretBases=true
  receiveMail(s,players,mine,players[1].tvShowByteSum); applied.daycareMail=true
  local peer=partner(players,mine)
  local own=players[mine]
  local filler=B.raw(own._recordMixPacketFiller,102) or string.rep("\0",102)
  local gift=n(own.giftItem)
  local destination=(rawRsTower(c,own.battleTowerRecord)..string.char(gift%256,math.floor(gift/256)%256)..filler):sub(1,236)
  local tower=Tower.toEmerald(c,rawRsTower(c,peer.battleTowerRecord),n(peer.language),destination)
  applied.towerSlot=receiveTower(s,tower); applied.battleTower=true
  for i,p in ipairs(players) do
    local rows=showRaw(c,p)
    if Rs.is(p.version) then
      for slot=0,23 do if rows[slot]:byte(1)==7 then
        rows[slot]=B.put(rows[slot],30,Text.japanese(rows[slot]:sub(13,20)) and 1 or 2)
      end end
    end
    p.tvShows=B.readShows(c,rows)
  end
  local Tv=require("src.core.game3.rse.tv")
  Tv.receiveShows(s,players,mine); Tv.receivePokeNews(s,players,mine)
  applied.tvShows,applied.pokeNews=true,true
  peer=partner(players,mine)
  s.oldMan=B.readOld(c,Text.oldReceived(rawOld(c,peer.oldMan),Rs.is(peer.version),n(peer.language)))
  require("src.core.game3.rse.old_man").resetFlag(s)
  local C=require("src.core.game3.constants").of(s.version)
  local store=s.store or s; store.vars=store.vars or {}
  store.vars[C:require("vars","VAR_OBJ_GFX_ID_0")]=C:require("event_objects","OBJ_EVENT_GFX_BARD")
  applied.oldMan=true
  local trends={}; for i,p in ipairs(players) do trends[i]=p.dewfordTrends end
  require("src.core.game3.rse.dewford_trend").mixImport(trends,s); applied.dewfordTrends=true
  applied.gift=require("src.core.game3.rse.record_mixing_gift").mixImport(players,s,mine); applied.giftItem=true
  return applied
end
return M
