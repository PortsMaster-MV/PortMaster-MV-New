local Init = {}
-- pokeruby/src/mauville_man.c:190
function Init.set(session)
  local state = require("src.core.game3.rse.old_man").set(session)
  local codec = require("src.save_convert.Gen3Save").forVersion(session.version)
  local w = codec.newBuf(64)
  w:w8(0, state.id)
  if state.id == 0 then
    for i = 1, 6 do w:w16(2 + (i - 1) * 2, state.songLyrics[i]) end
  elseif state.id == 2 then
    -- pokeruby/src/trader.c:60
    for i = 1, 4 do
      w:w8(i, state.decorations[i])
      w:bytes(5 + (i - 1) * 11, codec.encodeString(state.playerNames[i], 11, 0))
    end
  elseif state.id == 3 then
    -- pokeruby/src/mauville_man.c:862
    for i = 0, 3 do w:w8(8 + i, 255) end
  end
  session.oldMan = require("src.save_convert.gen3_port.sections.rs_old_man").read(w:str(), codec)
  -- pokeruby/src/mauville_man.c:807
  local C = require("src.core.game3.constants").of(session.version)
  session.vars[C:require("vars", "VAR_OBJ_GFX_ID_0")] = C:require("event_objects", "OBJ_EVENT_GFX_BARD") + state.id
  return session.oldMan
end
return Init
