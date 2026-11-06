local SaveSections = {}

local defs = {}

local function copy(v)
  if type(v) ~= "table" then return v end
  local out = {}
  for k, x in pairs(v) do out[k] = copy(x) end
  return out
end

function SaveSections.register(name, def)
  assert(type(name) == "string" and name ~= "", "save section needs a name")
  assert(type(def) == "table", "save section " .. name .. " needs a definition")
  defs[name] = def
  return def
end

function SaveSections.unregister(name)
  defs[name] = nil
end

function SaveSections.fields(list, newGame)
  return {
    fields = list,
    newGame = newGame,
    export = function(session, out)
      local names = type(list) == "function" and list() or list
      for _, f in ipairs(names) do
        if session[f] ~= nil then out[f] = copy(session[f]) end
      end
    end,
    restore = function(save, session)
      local names = type(list) == "function" and list() or list
      for _, f in ipairs(names) do
        if save[f] ~= nil then session[f] = copy(save[f]) end
      end
    end,
  }
end

local function resolve(entry)
  local name, module = entry, nil
  if type(entry) == "table" then name, module = entry.name, entry.module end
  if not defs[name] and module then require(module) end
  local def = defs[name]
  if not def then error("save section '" .. tostring(name) .. "' is not registered", 0) end
  return name, def
end

function SaveSections.of(version)
  local Profile = require("src.core.game3.profile")
  local save = Profile.of(version).save
  local out = {}
  for _, entry in ipairs(save and save.sections or {}) do
    local name, def = resolve(entry)
    out[#out + 1] = { name = name, def = def }
  end
  return out
end

function SaveSections.newGame(session, version)
  for _, s in ipairs(SaveSections.of(version)) do
    if s.def.newGame then s.def.newGame(session) end
  end
end

function SaveSections.export(session, out, version)
  for _, s in ipairs(SaveSections.of(version)) do
    if s.def.export then s.def.export(session, out) end
  end
  return out
end

function SaveSections.restore(save, session, version)
  for _, s in ipairs(SaveSections.of(version)) do
    if s.def.restore then s.def.restore(save, session) end
  end
  return session
end

-- pokeemerald/src/new_game.c:152
SaveSections.register("rtc", SaveSections.fields(function()
  return require("src.core.game3.rtc").SAVE_FIELDS
end, function(session)
  local Rtc = require("src.core.game3.rtc")
  session.localTimeOffset = Rtc.newTime(0, 0, 0, 0)
  session.lastBerryTreeUpdate = Rtc.newTime(0, 0, 0, 0)
  session.rtcSkew = 0
end))

-- pokeemerald/src/new_game.c:155
SaveSections.register("encryptionKey", SaveSections.fields({ "encryptionKey" }, function(session)
  session.encryptionKey = 0
end))

-- pokeemerald/include/global.h:1023
SaveSections.register("berryTrees", SaveSections.fields({ "berryTrees" }))

-- pokeemerald/include/global.h:1025
SaveSections.register("decorations", SaveSections.fields({ "playerRoomDecorations", "decorationInventory" }))

return SaveSections
