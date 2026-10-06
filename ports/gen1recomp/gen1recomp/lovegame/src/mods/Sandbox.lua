-- The environment a mod's own code runs in.  Every chunk a mod authors -- the
-- entry file, an options_schema, anything it hands to load() -- runs against
-- this table instead of _G, so the only paths it can name are the ones the
-- engine hands it (mod:read, mod.storage, mod.assets).
--
-- What this is and is not: raw io/os/ffi are the only way to name a file
-- outside the game tree at all, and they are absent here, so the reported
-- "any mod can rewrite anything in your home directory" hole closes by
-- construction.  Inside the LÖVE tree this is defense in depth, not a security
-- boundary: an engine module reached through require, or ImageData:encode,
-- still writes in the save directory.
--
-- Lua 5.1/LuaJIT is the target, so setfenv is the mechanism; the 5.2+ arm
-- exists because AssetTransform's sandbox needed it and getting this wrong
-- silently hands the chunk the real globals.

local Runtime = require("src.mods.Runtime")
local SafePath = require("src.mods.SafePath")

local Sandbox = {}

-- Modules that hand a mod the disk, a raw socket or a fresh Lua state no
-- matter what this file removes from the environment.  package.loaded.io is
-- the one call that would undo every other rule here.
local DENIED = {
  io = "the filesystem", os = "the filesystem", debug = "the debug library",
  package = "the module loader", ffi = "arbitrary C calls",
}

-- Same idea one level up: love.filesystem is reachable by name, and
-- love.thread starts a Lua state this sandbox has no say over.  jit.util
-- is the LuaJIT-specific equal of the debug library above -- funcbc,
-- funck and friends read the bytecode and constants of any function a
-- chunk can reach, which is enough to walk back to upvalues (the real
-- _G, love, io) the rest of this file exists to keep out of reach.  The
-- bare `jit` table stays -- env.jit above hands it over directly for
-- jit.on/off/flush -- so only the submodule require is denied.
local DENIED_PREFIX = { ["love"] = true, ["ffi"] = true, ["jit"] = true }

-- The wire, which is what the network permission governs.
local NETWORK = { socket = true, enet = true, http = true, https = true,
                  ssl = true, mime = true, ltn12 = true }

local function head(name)
  return (name:match("^([^%.]+)")) or name
end

-- The verdict for a name never changes (the tables above are fixed), and the
-- Loader's require shim asks for every require the engine makes while a mod
-- is enabled, so it is worked out once per name: false for allowed, the
-- denial message, or NETWORK_ONLY with the message kept alongside.
local verdicts, verdictCount = {}, 0
local VERDICT_MAX = 4096

local function verdictFor(name)
  local root = head(name)
  local reason = DENIED[root]
  if reason then
    return ("%s is not available to mods (it grants %s); use mod.storage, "
      .. "mod:read, mod:list and the engine API instead"):format(name, reason)
  end
  if DENIED_PREFIX[root] and name ~= root then
    return ("%s is not available to mods; use mod.storage, mod:read, mod:list "
      .. "and the engine API instead"):format(name)
  end
  if NETWORK[root] then
    return { network = ("%s needs the \"network\" permission in manifest.json")
      :format(name) }
  end
  return false
end

-- nil when the require is allowed, else the message to fail it with.
function Sandbox.moduleDenial(name, permissionSet)
  if type(name) ~= "string" then return nil end
  local verdict = verdicts[name]
  if verdict == nil then
    verdict = verdictFor(name)
    if verdictCount >= VERDICT_MAX then verdicts, verdictCount = {}, 0 end
    verdicts[name] = verdict
    verdictCount = verdictCount + 1
  end
  if not verdict then return nil end
  if type(verdict) == "table" then
    if (permissionSet or {}).network then return nil end
    return verdict.network
  end
  return verdict
end

-- ------- the love facade

-- Dropped, not narrowed: filesystem writes anywhere in the save directory
-- (including another mod's storage), thread opens a Lua state with a full
-- standard library, system.openURL launches whatever it is handed, and event
-- lets a mod quit the game out from under the player.  Everything else LÖVE
-- exposes passes through, so a new module in a future LÖVE is available
-- without an edit here.
-- value is the replacement to name in the error, or true when there is none
local BLOCKED_LOVE = {
  filesystem = "mod.storage, mod:read and mod:list",
  -- newThread's state has a full standard library and none of this file's
  -- rules, so it stays blocked -- but the reason mods reached for it was
  -- background work, and mod.fetch is that without the escape.
  thread = 'mod.fetch for background HTTP (needs the "network" permission)',
  system = "mod.device:powerInfo() for battery information, mod.steps for "
    .. "the step bridge", event = true,
}

-- Per-mod, because the compat overrides (src/mods/LegacyCompat.lua) are backed
-- by that mod's own overlay and must not be shared.
local function loveFacade(compat, permissions)
  if not _G.love then return nil end
  local overrides = compat and compat.love
  return setmetatable({}, {
    __index = function(_, key)
      local override = overrides and overrides[key]
      if override ~= nil then return override end
      if key == "thread" then
        -- Threads open a fresh Lua state with a full standard library, so
        -- they stay blocked unless the mod declares the `compute`
        -- permission (the mod's own source runs in the worker, and the
        -- worker ships source-only like every other mod file). The mod
        -- must never receive arbitrary code from elsewhere: channels
        -- carry data only.
        if not (permissions or {}).compute then
          error('love.thread needs the "compute" permission in manifest.json', 2)
        end
        return _G.love.thread
      end
      local hint = BLOCKED_LOVE[key]
      if hint then
        error(("love.%s is not available to mods%s"):format(key,
          type(hint) == "string" and (", use " .. hint) or ""), 2)
      end
      return _G.love[key]
    end,
    -- a callback chain lands on the real table (compat.assign decides which
    -- names qualify); a module table never does
    __newindex = function(_, key, value)
      if compat then
        local allowed, reason = compat.assign(key, value)
        if allowed then
          _G.love[key] = value
          return
        end
        if reason then error(reason, 2) end
      end
      error(("mods cannot assign love.%s"):format(tostring(key)), 2)
    end,
  })
end

-- ------- the environment

-- Absent on purpose: io, package, dofile, loadfile, getfenv, setfenv, debug,
-- newproxy, module.  os keeps only the clock -- getenv is how the reported
-- exploit found the user's home directory.
local SAFE_OS = { time = true, date = true, clock = true, difftime = true }

-- Per-mod copies, not the shared tables: a mod that assigns string.trim or
-- replaces table.insert changes its own view and nobody else's.  The functions
-- are the same objects, so state behind them (math.randomseed's RNG) is
-- unaffected -- only the namespace is private.
local function copy(source)
  if type(source) ~= "table" then return source end
  local out = {}
  for key, value in pairs(source) do out[key] = value end
  return out
end

local function baseGlobals()
  local safeOs = {}
  for key in pairs(SAFE_OS) do safeOs[key] = os[key] end
  return {
    assert = assert, error = error, ipairs = ipairs, next = next,
    pairs = pairs, pcall = pcall, xpcall = xpcall, select = select,
    tonumber = tonumber, tostring = tostring, type = type, unpack = unpack,
    rawequal = rawequal, rawget = rawget, rawset = rawset, rawlen = rawlen,
    setmetatable = setmetatable, getmetatable = getmetatable, print = print,
    collectgarbage = collectgarbage, _VERSION = _VERSION,
    coroutine = copy(coroutine), math = copy(math), string = copy(string),
    table = copy(table), bit = copy(bit), jit = jit, os = safeOs,
  }
end

-- setfenv on 5.1/LuaJIT; on 5.2+ the env has to be handed to load itself, so
-- a caller there compiles through Sandbox.compile instead.
function Sandbox.bind(chunk, env)
  if setfenv then setfenv(chunk, env) end
  return chunk
end

-- Bytecode is unreviewable and, on LuaJIT, a way out of any sandbox built out
-- of environments.  Mods ship source.
local function rejectBytecode(source, what)
  if type(source) == "string" and source:sub(1, 1) == "\27" then
    return nil, (what or "chunk") .. ": mods must ship Lua source, not bytecode"
  end
  return true
end

function Sandbox.compile(source, chunkname, env)
  local ok, err = rejectBytecode(source, chunkname)
  if not ok then return nil, err end
  if setfenv then
    local chunk, compileErr = loadstring(source, chunkname)
    if not chunk then return nil, compileErr end
    return setfenv(chunk, env)
  end
  return load(source, chunkname, "t", env)
end

-- The load() a mod sees.  Lua 5.1 gives a loaded chunk the GLOBAL environment
-- rather than the caller's, so without this every sandboxed mod is one
-- load(mod:read(...)) away from the real _G -- which is exactly how the
-- multi-file mods in mods/ are written.
local function sandboxedLoad(env)
  return function(chunk, chunkname)
    if type(chunk) == "function" then
      local parts = {}
      while true do
        local piece = chunk()
        if piece == nil or piece == "" then break end
        parts[#parts + 1] = piece
      end
      chunk = table.concat(parts)
    end
    if type(chunk) ~= "string" then return nil, "load expects a string or reader" end
    return Sandbox.compile(chunk, chunkname or "=(load)", env)
  end
end

-- The require a mod sees: the deny list lives here rather than on a stack
-- walk, because pcall(require, "io") puts a C frame where the walk would look.
-- Runtime.modRequire is how the loader's gate identifies the caller for the
-- Gen 2 facade once Runtime.currentMod has gone back to nil (a mod requiring
-- lazily from an event handler).
local function sandboxedRequire(modId, permissionSet, compat)
  return function(name, ...)
    -- the compat stand-in answers first, so a legacy require("io") gets the
    -- rerouted table instead of the denial below (src/mods/LegacyCompat.lua)
    local substitute = compat and compat.module(name)
    if substitute ~= nil then return substitute end
    local denial = Sandbox.moduleDenial(name, permissionSet)
    if denial then error(("[%s] %s"):format(modId or "mod", denial), 2) end
    local previous = Runtime.modRequire
    Runtime.modRequire = modId or true
    local ok, result = pcall(_G.require, name, ...)
    Runtime.modRequire = previous
    if not ok then error(result, 0) end
    return result
  end
end

function Sandbox.envFor(opts)
  opts = opts or {}
  local compat = opts.compat
  local env = baseGlobals()
  env.love = loveFacade(compat, opts.permissions)
  env.require = sandboxedRequire(opts.modId, opts.permissions, compat)
  local loader = sandboxedLoad(env)
  env.load = loader
  env.loadstring = loader
  -- a mod's globals are its own: two mods no longer share a namespace, and
  -- neither can reach the engine's
  env._G = env
  if compat then
    for key, value in pairs(compat.globals) do env[key] = value end
    for key, value in pairs(compat.os) do env.os[key] = value end
    compat.bind(env, function(source, chunkname)
      return Sandbox.compile(source, chunkname, env)
    end)
  end
  return env
end

-- fs.load keeps the real filesystem's handling of the file; the environment is
-- swapped after the fact.  The 5.2+ arm has to go back to source, which is the
-- only reason fs.read is touched here.
function Sandbox.loadFile(fs, path, env)
  if fs.read then
    local ok, err = rejectBytecode(fs.read(path), path)
    if not ok then return nil, err end
  end
  if setfenv then
    local chunk, err = fs.load(path)
    if not chunk then return nil, err end
    return setfenv(chunk, env)
  end
  local source = fs.read and fs.read(path)
  if not source then return nil, "unable to read " .. path end
  return Sandbox.compile(source, "@" .. path, env)
end

Sandbox.safePath = SafePath.safe
Sandbox.requirePath = SafePath.require

return Sandbox
