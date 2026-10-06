local Structs = require("src.save_convert.gen3_port.structs")
local OldMan = {}
local SIZE = 64
local function f(name, off, t, n, len)
  return { name = name, off = off, t = t, n = n, len = len, pad = t == "text" and 0 or nil }
end
-- pokeruby/include/global.h:471
local VARIANT = {
  [0] = { f("songLyrics", 2, "u16", 6), f("newSongLyrics", 14, "u16", 6), f("playerName", 26, "text", nil, 8),
    f("playerTrainerIdBytes", 37, "u8", 4), f("hasChangedSong", 41, "bool8") },
  [1] = { f("taughtWord", 1, "bool8") },
  [2] = { f("decorations", 1, "u8", 4), f("playerNames", 5, "text", 4, 11), f("alreadyTraded", 49, "bool8") },
  [3] = { f("alreadyRecorded", 1, "bool8"), f("gameStatIDs", 4, "u8", 4),
    f("trainerNames", 8, "text", 4, 7), f("statValues", 36, "u32", 4) },
  [4] = { f("taleCounter", 1, "u8"), f("questionNum", 2, "u8"), f("randomWords", 4, "u16", 10),
    f("questionList", 24, "u8", 12) },
}
local function bytes(s)
  local out = {}
  for i = 1, #s do out[i] = s:byte(i) end
  return out
end
local function byteString(t)
  if type(t) ~= "table" or #t ~= SIZE then return nil end
  local out = {}
  for i = 1, SIZE do
    local v = tonumber(t[i])
    if not v or v % 1 ~= 0 or v < 0 or v > 255 then return nil end
    out[i] = string.char(v)
  end
  return table.concat(out)
end
function OldMan.read(s, codec)
  local id = s:byte(1)
  local out = Structs.read(s, 0, VARIANT[id] or {}, codec)
  out.id, out.nativeBytes = id, bytes(s)
  if out.playerTrainerIdBytes then
    out.playerTrainerId = out.playerTrainerIdBytes[1] + out.playerTrainerIdBytes[2] * 256
  end
  return out
end
function OldMan.render(codec, template, state, same)
  local id = math.floor(tonumber(state.id) or 0) % 256
  local own = byteString(state.nativeBytes)
  local tmpl = own and own:byte(1) == id and own or template
  local fresh = tmpl:byte(1) ~= id
  local spec = VARIANT[id]
  if not spec then
    local w = codec.newBuf(SIZE, own or template)
    w:w8(0, id)
    return w:str()
  end
  local w = codec.newBuf(SIZE, fresh and string.rep("\0", SIZE) or tmpl)
  w:w8(0, id)
  local src = {}
  for k, v in pairs(state) do src[k] = v end
  if id == 0 then
    local prior = not fresh and OldMan.read(tmpl, codec)
    local tid = math.floor(tonumber(state.playerTrainerId) or 0) % 65536
    if not state.playerTrainerIdBytes then src.playerTrainerIdBytes = { tid % 256, math.floor(tid / 256), 0, 0 }
    elseif prior and state.playerTrainerId ~= nil and tid ~= prior.playerTrainerId then
      src.playerTrainerIdBytes = { tid % 256, math.floor(tid / 256), state.playerTrainerIdBytes[3], state.playerTrainerIdBytes[4] }
    end
  end
  Structs.write(w, 0, spec, src, codec)
  local out = w:str()
  if fresh then return out end
  local keep = {}
  for o = 0, SIZE - 1 do keep[o] = true end
  keep[0] = false
  for _, field in ipairs(spec) do
    for i = 1, field.n or 1 do
      local part = {}
      for k, v in pairs(field) do part[k] = v end
      part.n = nil
      part.off = field.off + (i - 1) * (field.len or Structs.SIZE[field.t])
      if not same(Structs.read(out, 0, { part }, codec), Structs.read(tmpl, 0, { part }, codec)) then
        for o = part.off, part.off + Structs.fieldSize(part) - 1 do keep[o] = false end
      end
    end
  end
  local result = {}
  for o = 0, SIZE - 1 do result[o + 1] = (keep[o] and tmpl or out):sub(o + 1, o + 1) end
  return table.concat(result)
end
function OldMan.section(same)
  return { name = "oldMan", fields = { "oldMan" },
    read = function(x)
      local b = x.L.RSE.sb1.oldMan
      return { oldMan = OldMan.read(x.sb1:sub(b + 1, b + SIZE), x.codec) }
    end,
    write = function(x, v)
      if type(v.oldMan) ~= "table" then return end
      local b = x.L.RSE.sb1.oldMan
      x.w1:bytes(b, OldMan.render(x.codec, x.sb1:sub(b + 1, b + SIZE), v.oldMan, same))
    end,
  }
end
return OldMan
