local Rse = require("src.save_convert.gen3_port.rse")

local Frlg = {}

Frlg.SECTIONS = Rse.FRLG_SECTIONS
for _, name in ipairs({ "linkBattleRecords", "trainerNameRecords" }) do
  Frlg.SECTIONS[#Frlg.SECTIONS + 1] = Rse.SECTIONS[name]
  Frlg.SECTIONS[name] = Rse.SECTIONS[name]
end
Frlg.finishImport = Rse.finishImport

local IV_NAMES = { "hp", "attack", "defense", "speed", "spAtk", "spDef" }

-- include/global.h:417
function Frlg.portRoamer(r)
  if type(r) ~= "table" or (r.species or 0) == 0 then return nil end
  local ivs = {}
  for i, k in ipairs(IV_NAMES) do ivs[k] = math.floor(r.ivs / 2 ^ ((i - 1) * 5)) % 32 end
  return { active = r.active ~= 0, species = r.species, speciesId = r.species, level = r.level, hp = r.hp,
    status = r.status, statusNum = r.status, pid = r.personality, personality = r.personality, ivs = ivs,
    ivWord = r.ivs }
end

function Frlg.install(codec)
  local toPortSave = codec.toPortSave

  function codec.importPort(bytes, version)
    if type(bytes) ~= "string" then return nil, codec.message("size", 0) end
    local cart, blocks = codec.decode(bytes)
    if not cart then return nil, codec.message(blocks, #bytes) end
    if not codec.mapFor(cart.location.group, cart.location.num) then return nil, codec.MSG.corrupt end
    local save = toPortSave(cart, version)
    save.roamer = Frlg.portRoamer(cart.roamer)
    Rse.readSections(codec, blocks, save, Frlg.SECTIONS)
    local stamped, note = codec.stampImport(save, bytes, cart, version)
    return stamped, nil, note
  end

  function codec.exportPort(save, opts)
    local c, blocks = codec.fromPortSave(save, opts)
    if not c then return nil, blocks end
    local encoded = Rse.writeSections(codec, codec.encodeBlocks(c, blocks), blocks, save, Frlg.SECTIONS)
    for _, n in ipairs(c.notes or {}) do encoded.notes[#encoded.notes + 1] = n end
    return codec.finishFlash(c, blocks, encoded), #encoded.notes > 0 and table.concat(encoded.notes, " ") or nil
  end

  codec.port = Frlg
  return codec
end

return Frlg
