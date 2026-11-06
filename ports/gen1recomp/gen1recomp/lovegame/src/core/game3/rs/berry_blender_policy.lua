local M = {}
function M.matches(version) return version == "ruby" or version == "sapphire" end
-- pokeruby/src/berry_blender.c:1011
function M.initLocalPlayers(game,n)
  assert(n >= 1 and n <= 3,"native RS Blender opponent count must be1..3")
  game.numPlayers=n+1; game.playerNames[0]=game.playerName
  for i=1,n do game.playerNames[i]=assert(game.names[i],"native RS Blender NPC name missing") end
end
function M.recordWindow(session,man)
  local B=require("src.core.game3.rse.berry_blender")
  local Font=require("src.ui.game3.frlg_font")
  local function width(text) return Font.measure(text,{font="native_3"}) end
  local win={left=7,top=4,width=16,height=12,prints={}}
  local function put(text,x,y) win.prints[#win.prints+1]={s=text,x=x,y=y} end
  put(man.texts.blenderMaxSpeedRecord,8,0); put(man.texts.players234,8,40)
  for i,record in ipairs(B.records(session)) do
    local integer=tostring(math.floor(record/100))
    put(integer,64+math.max(0,18-width(integer)),40+(i-1)*16)
    local fraction=" . "..string.format("%02d",record%100)..man.texts.rpm
    put(fraction,64+math.max(18,width(integer)),40+(i-1)*16)
  end
  return win
end
return M
