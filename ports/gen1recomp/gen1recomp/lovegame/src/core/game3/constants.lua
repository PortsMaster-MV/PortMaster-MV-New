local GameVersion = require("src.core.GameVersion")

local Constants = {}

Constants.GAMES = {
  firered = "firered",
  leafgreen = "firered",
  emerald = "emerald",
  ruby = "ruby",
  sapphire = "ruby",
}

Constants.KINDS = {
  "abilities", "battle", "battle_string_ids", "decorations", "easy_chat", "field_effects",
  "flags", "items", "map_groups", "metatile_behaviors", "moves", "movement", "script_cmds",
  "songs", "specials", "species", "trainer_classes", "trainers", "vars", "weather",
  "event_objects", "metatile_labels", "region_map_sections", "heal_locations",
}

local KIND_SET = {}
for _, k in ipairs(Constants.KINDS) do KIND_SET[k] = true end

local sets = {}

function Constants.gameKey(id)
  local key = Constants.GAMES[id]
  if not key then
    error("game3 constants: no tables for game " .. tostring(id), 2)
  end
  return key
end

local Methods = {}

function Methods:raw(kind)
  return self[kind]
end

function Methods:id(kind, name)
  return self[kind].byName[name]
end

function Methods:require(kind, name)
  local v = self:id(kind, name)
  if v == nil then
    error(string.format("game3 constants: %s has no %s %s", self.game, kind, tostring(name)), 2)
  end
  return v
end

function Methods:name(kind, id, prefix)
  local t = self[kind]
  if kind == "specials" then return t.byId[id] end
  if kind == "script_cmds" then
    local e = t.byId[id]
    return e and e.name or nil
  end
  local rev = t.byId
  if not rev then return nil end
  if prefix then
    return rev[prefix] and rev[prefix][id] or nil
  end
  for _, sub in pairs(rev) do
    if type(sub) == "table" and sub[id] then return sub[id] end
  end
  return nil
end

function Methods:special(name)
  return self.specials.byName[name]
end

function Methods:specialName(id)
  return self.specials.byId[id]
end

function Methods:opcode(op)
  return self.script_cmds.byId[op]
end

function Methods:flag(name)
  return self.flags.byName[name]
end

function Methods:var(name)
  return self.vars.byName[name]
end

function Methods:song(name)
  return self.songs.byName[name]
end

function Methods:map(name)
  return self.map_groups.byName[name]
end

local SetMT = {
  __index = function(self, k)
    local m = Methods[k]
    if m then return m end
    if not KIND_SET[k] then return nil end
    local t = require("src.core.game3.constants." .. rawget(self, "game") .. "." .. k)
    rawset(self, k, t)
    return t
  end,
}

function Constants.of(gameOrVersion)
  local key = Constants.gameKey(gameOrVersion)
  local s = sets[key]
  if not s then
    s = setmetatable({ game = key }, SetMT)
    sets[key] = s
  end
  return s
end

function Constants.versionOf(session)
  if type(session) == "table" and type(session.version) == "string" then
    return session.version
  end
  return require("src.core.game3.profile").resolveId(GameVersion.get())
end

function Constants.active(session)
  return Constants.of(Constants.versionOf(session))
end

return Constants
