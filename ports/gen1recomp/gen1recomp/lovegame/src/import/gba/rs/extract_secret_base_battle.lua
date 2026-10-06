local A = require("src.import.gba.rs.assets")
local M = {SUB = "rse/secret_base_battle", FILES = {}, REQUIRED = {"rse/secret_base_battle/manifest.lua"}}

function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local classes, pic, names = c:off("gSecretBaseTrainerClasses"), c:off("gTrainerClassToPicIndex"), c:off("gTrainerClassToNameIndex")
  local classNames = c:off("gTrainerClassNames")
  -- battle_ai_script_commands.c:337
  local aiOff = c:off("gTrainers") + 1024 * 40 + 28
  local man = {classes = {}, loseText = {}, decorations = {}, roomDecorationVersion = 1,
    aiFlags = c:u32(aiOff), aiRomOffset = aiOff}
  local decor = c:off("gDecorations")
  for i = 0, c.S.count("gDecorations", 32) - 1 do
    local b = decor + i * 32
    assert(c:u8(b) == i, "RS decoration row ID mismatch")
    man.decorations[i] = {permission = c:u8(b + 17), tiles = {c:u16(c:ptr(b + 28))}}
  end
  assert(c.S.size("gSecretBaseTrainerClasses") == 10, "RS secret-base class table differs")
  for i = 0, 9 do
    local facilityClass = c:u8(classes + i)
    local nameId = c:u8(names + facilityClass)
    man.classes[i] = {facilityClass = facilityClass, pic = c:u8(pic + facilityClass),
      nameId = nameId, name = A.text(c, classNames + nameId * 13)}
  end
  for i, symbol in ipairs({"UnknownString_81A1BB2", "UnknownString_81A1F67", "UnknownString_81A2254",
    "UnknownString_81A25C3", "UnknownString_81A2925", "UnknownString_81A1D74", "UnknownString_81A20C9",
    "UnknownString_81A2439", "UnknownString_81A2754", "UnknownString_81A2B2A"}) do
    man.loseText[i - 1] = A.text(c, c:off(symbol))
  end
  return A.finish(c, man)
end
function M.ready(cache, root)
  if not A.ready(M.SUB, cache, root) then return false end
  local body = cache:read((root or "data/generated/gba") .. "/" .. M.SUB .. "/manifest.lua")
  return body:find("roomDecorationVersion = 1", 1, true) ~= nil
end
return M
