local Profile = require("src.core.game3.profile")

local Sem = {}

Sem.FRLG_VARS = {
  -- pokefirered/include/constants/vars.h:52
  happinessSteps = 0x4021,
  -- pokefirered/include/constants/vars.h:75
  massageSteps = 0x4025,
  poisonSteps = 0x4040,
  -- pokefirered/include/constants/vars.h:47
  repelSteps = 0x4020,
}

Sem.FRLG_FLAGS = {
  -- pokefirered/include/constants/flags.h:1333
  flashActive = 0x806,
}

local resolved = {}

local function block(session)
  local row = Profile.forSession(session)
  local map = row and row.map
  return row, map and map.semantics or nil
end

local function resolve(session, kind, name)
  local row, sem = block(session)
  if not sem then
    return (kind == "vars" and Sem.FRLG_VARS or Sem.FRLG_FLAGS)[name]
  end
  local key = row.id .. ":" .. kind .. ":" .. name
  local hit = resolved[key]
  if hit ~= nil then return hit or nil end
  local pret = sem[kind] and sem[kind][name]
  local id = false
  if pret then
    local Flags = require("src.core.game3.scripting.flags")
    local t = Flags.forVersion(row.id)
    id = (kind == "vars" and t.VAR_IDS or t.IDS)[pret]
    if not id then error("field semantics: " .. row.id .. " has no " .. pret, 3) end
  end
  resolved[key] = id
  return id or nil
end

function Sem.var(session, name)
  return resolve(session, "vars", name)
end

local function live_store(session)
  local Runtime = package.loaded["src.core.game3.runtime"]
  local Space = package.loaded["src.core.game3.scripting.space"]
  if Runtime and Runtime.getSession and Runtime.getSession() == session and Space and Space.active then
    return Space.store
  end
end

function Sem.getVar(session, name)
  return require("src.core.game3.scripting.flags").getVar(live_store(session) or session, nil, Sem.var(session, name))
end

function Sem.setVar(session, name, value)
  local Flags, id = require("src.core.game3.scripting.flags"), Sem.var(session, name)
  Flags.setVar(session, nil, id, value)
  local store = live_store(session)
  if store then Flags.setVar(store, nil, id, value) end
end

function Sem.flag(session, name)
  return resolve(session, "flags", name)
end

function Sem.reset()
  resolved = {}
end

return Sem
