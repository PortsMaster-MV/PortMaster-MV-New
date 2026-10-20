local M = {}
local B = require("src.core.game3.link.rs_record_cross_bytes")
-- pokeemerald/src/string_util.c:657
-- src/international_string_util.c:122
local LENGTH = {1,2,2,2,4,2,2,1,2,1,1,3,2,2,2,1,3,2,2,2,2,1,1,1,1}
function M.length(s)
  return (s:find(string.char(255),1,true) or (#s+1))-1
end
function M.strip(s)
  local chars,i={},1
  while i<=#s and s:byte(i)~=255 do
    if s:byte(i)==252 then i=i+1+(LENGTH[(s:byte(i+1) or 255)+1] or 0)
    else chars[#chars+1]=s:sub(i,i); i=i+1 end
  end
  local out=table.concat(chars)..string.char(255)
  return out..s:sub(#out+1)
end
function M.japanese(s)
  for i=1,M.length(s) do local n=s:byte(i); if n>0 and n<=160 then return true end end
  return false
end
function M.prefixJapanese(s) return s:byte(1)==252 and s:byte(2)==21 end
function M.international(s, language)
  if language~=1 then return s end
  s=M.strip(s)
  local out=string.char(252,21)..s:sub(1,M.length(s))..string.char(252,22,255)
  assert(#out<=#s,"native international name exceeds its field")
  return out..s:sub(#out+1)
end
function M.pad(s)
  s=M.strip(s)
  local chars=s:sub(1,M.length(s))
  while #chars<6 do chars=chars..string.char(252,7) end
  local out=chars..string.char(255)
  return out..s:sub(#out+1)
end
function M.field(raw, off, size, fn)
  local text=fn(raw:sub(off+1,off+size))
  assert(#text==size,"native text conversion changed its field size")
  return raw:sub(1,off)..text..raw:sub(off+size+1)
end
-- pokeemerald/src/mauville_old_man.c:753
function M.oldForRuby(raw, codec)
  local id=raw:byte(1)
  for i=0,3 do
    if id==2 and raw:byte(51+i)==1 then
      raw=M.field(raw,5+i*11,11,function(s) return M.international(s,1) end)
    elseif id==3 and raw:byte(5+i)~=0 and M.japanese(raw:sub(9+i*7,15+i*7)..string.char(255)) then
      local friend=codec.encodeString("Friend",7,0) -- gText_Friend, strings.c:1404
      raw=raw:sub(1,8+i*7)..friend..raw:sub(16+i*7)
      raw=B.put(raw,52+i,2)
    end
  end
  return raw
end
function M.oldReceived(raw, ruby, language)
  local id=raw:byte(1)
  if id==2 then
    for i=0,3 do
      local name=raw:sub(6+i*11,16+i*11)
      if ruby then
        if M.prefixJapanese(name) then raw=M.field(raw,5+i*11,11,M.strip); raw=B.put(raw,50+i,1)
        else raw=B.put(raw,50+i,language) end
      elseif raw:byte(51+i)==1 then raw=M.field(raw,5+i*11,11,M.strip) end
    end
  elseif id==3 and ruby then
    for i=0,3 do if raw:byte(5+i)~=0 then raw=B.put(raw,52+i,language) end end
  elseif ruby then
    local off=({[0]=42,[1]=2,[4]=32})[id]
    if off then raw=B.put(raw,off,language) end
  end
  return raw
end
return M
