local M = {}
local B = require("src.core.game3.link.rs_record_cross_bytes")
local Records = require("src.save_convert.gen3_port.rse").Records
-- battle_tower.c:3073
local CLASSES={0,11,1,1,2,6,3,13,4,14,5,15,6,16,7,17,8,3,9,18,10,12,11,19,12,20,13,21,14,23,15,7,
 16,10,17,25,18,26,19,27,20,29,21,30,22,31,23,32,24,33,25,34,26,35,27,36,28,37,29,38,30,39,31,40,
 32,41,33,42,34,9,35,22,36,43,37,44,38,45,39,46,40,47,41,48,42,49,43,50,44,51,45,52,46,4,
 47,53,48,54,49,55,50,56,51,28,52,57,53,58,56,5,57,59,58,60,59,61,60,62,61,63,62,64,63,65,64,66,65,2,
 66,68,67,69,68,70,69,8,70,24,71,71,72,67,73,0,74,72,75,73,76,74,0,0,131,67,36,8,231,67,36,8,19,68,36,8}
local function class(value, toRuby)
  local src,dst=toRuby and 2 or 1,toRuby and 1 or 2
  for i=0,81 do if CLASSES[i*2+src]==value then return CLASSES[i*2+dst] end end
  return toRuby and 36 or 43
end
local function valid(raw, off)
  for i=0,2 do if B.u16(raw,off+i*44)==0 then return false end end
  return true
end
function M.toRuby(codec, raw)
  if not valid(raw,52) then return string.rep("\0",164),false end
  local result=raw:sub(1,28)..raw:sub(53,184)..string.rep("\0",4)
  result=B.put(result,1,class(raw:byte(2),true))
  local w=codec.newBuf(164,result); w:w32(160,Records.wordSum(result,0,40))
  return w:str(),true
end
function M.toEmerald(codec, raw, language, destination)
  if not valid(raw,28) then return string.rep("\0",236),false end
  local w=codec.newBuf(236,destination or string.rep("\0",236))
  w:bytes(0,raw:sub(1,28)); w:w8(1,class(raw:byte(2),false)); w:bytes(52,raw:sub(29,160))
  w:fill(184,44,0)
  local won={3130,3130,3073,2602,1543,3073}
  local lost={4153,4654,3076,2621,1584,3076}
  for i=1,6 do w:w16(28+(i-1)*2,won[i]); w:w16(40+(i-1)*2,lost[i]) end
  w:w8(228,language or 2); w:w32(232,Records.wordSum(w:str(),0,58))
  return w:str(),true
end
return M
