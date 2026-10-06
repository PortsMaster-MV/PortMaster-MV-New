local Logger = require("src.core.Logger")
local SafePath = require("src.mods.SafePath")

local okSave, SaveData = pcall(require, "src.core.SaveData")
if not okSave then SaveData = nil end
local okStorage, Storage = pcall(require, "src.mods.Storage")
if not okStorage then Storage = nil end

local LegacyCompat = {}

local ROOT = "mod_compat"
local OWN = "_own"
local MAX_SEGMENTS = 24

LegacyCompat.reports = {}

function LegacyCompat.reset()
  LegacyCompat.reports = {}
end

function LegacyCompat.report(modId)
  if modId then
    local entry = LegacyCompat.reports[modId]
    return entry and entry.order or {}
  end
  local out = {}
  for id, entry in pairs(LegacyCompat.reports) do
    out[id] = entry.order
  end
  return out
end

local function note(ctx, call, advice)
  local entry = LegacyCompat.reports[ctx.modId]
  if not entry then
    entry = { calls = {}, order = {} }
    LegacyCompat.reports[ctx.modId] = entry
  end
  local row = entry.calls[call]
  if row then
    row.count = row.count + 1
    return
  end
  row = { call = call, advice = advice, count = 1 }
  entry.calls[call] = row
  entry.order[#entry.order + 1] = row
  Logger.warn("[%s] %s was removed from the mod sandbox; %s", ctx.modId, call,
    advice)
end

local function refuse(ctx, call, advice)
  note(ctx, call, advice)
  return nil, ("%s is not available to mods; %s"):format(call, advice)
end

-- ------- path routing

local function normalize(path)
  if type(path) ~= "string" or path == "" then return nil end
  path = path:gsub("\\", "/")
  while path:find("//", 1, true) do path = (path:gsub("//", "/")) end
  if path ~= "/" then path = (path:gsub("/$", "")) end
  return path
end

local function flatten(path)
  local parts = {}
  for segment in path:gmatch("[^/]+") do
    if segment ~= "." and segment ~= ".." then
      parts[#parts + 1] = (segment:gsub("[^%w_%.%-]", "_"))
    end
  end
  if #parts == 0 then return nil end
  while #parts > MAX_SEGMENTS do table.remove(parts, 1) end
  return table.concat(parts, "/")
end

local function storageKey(key)
  local parts = {}
  for segment in key:gmatch("[^/]+") do parts[#parts + 1] = segment end
  if #parts == 0 then return nil end
  parts[#parts] = (parts[#parts]:gsub("%.[^%.]*$", ""))
  for i = 1, #parts do
    local cleaned = (parts[i]:gsub("[^%w_%-]", "_"))
    if cleaned == "" then return nil end
    parts[i] = cleaned
  end
  return table.concat(parts, "/")
end

local function ownRelative(ctx, path)
  if not ctx.modPath then return nil end
  if path == ctx.modPath then return "" end
  if path:sub(1, #ctx.modPath + 1) == ctx.modPath .. "/" then
    return path:sub(#ctx.modPath + 2)
  end
  return nil
end

local function ownFull(ctx, rel)
  if rel == "" then return ctx.modPath end
  local safe = SafePath.safe(rel)
  if not safe then return nil end
  return ctx.modPath .. "/" .. safe
end

local function ownExists(ctx, rel)
  local full = ownFull(ctx, rel)
  local fs = ctx.fs
  if not (full and fs and fs.getInfo) then return nil end
  return fs.getInfo(full)
end

local function classify(ctx, path)
  path = normalize(path)
  if not path then return nil end

  local root = ctx.virtualRoot
  if path == root then return { key = "", dir = true } end
  if path:sub(1, #root + 1) == root .. "/" then
    return { key = flatten(path:sub(#root + 2)) }
  end

  local rel = ownRelative(ctx, path)
  if not rel and path:sub(1, 1) ~= "/" and not path:match("^%a:")
      and ownExists(ctx, path) then
    rel = path
  end
  if rel then
    if rel == "" then return { key = OWN, rel = "", dir = true } end
    local flat = flatten(rel)
    return { key = flat and (OWN .. "/" .. flat) or nil, rel = rel }
  end

  return { key = flatten(path) }
end

-- ------- the overlay

local function persistFs(ctx)
  if SaveData and SaveData.persistenceFs then
    return SaveData.persistenceFs(ctx.fs)
  end
  return ctx.fs
end

local function overlayPath(ctx, key)
  if key == nil or key == "" then return ROOT .. "/" .. ctx.modId end
  return ROOT .. "/" .. ctx.modId .. "/" .. key
end

local function ensureParent(fs, path)
  if not fs.createDirectory then return end
  local dir = path:match("^(.*)/[^/]+$")
  if not dir then return end
  local built = nil
  for segment in dir:gmatch("[^/]+") do
    built = built and (built .. "/" .. segment) or segment
    fs.createDirectory(built)
  end
end

local function overlayRead(ctx, key)
  local fs = persistFs(ctx)
  if not (fs and fs.read and fs.getInfo) then return nil end
  local path = overlayPath(ctx, key)
  local info = fs.getInfo(path)
  if not info or info.type == "directory" then return nil end
  local body = fs.read(path)
  if type(body) ~= "string" then return nil end
  return body
end

local function overlayWrite(ctx, key, data)
  local fs = persistFs(ctx)
  if not (fs and fs.write) then
    return false, "no writable filesystem is available"
  end
  local path = overlayPath(ctx, key)
  ensureParent(fs, path)
  local ok, err = fs.write(path, data)
  if ok == false then return false, err or "write failed" end
  return true
end

local function overlayRemove(ctx, key)
  local fs = persistFs(ctx)
  if not (fs and fs.remove and fs.getInfo) then return false end
  local path = overlayPath(ctx, key)
  if not fs.getInfo(path) then return false end
  fs.remove(path)
  return true
end

local function overlayInfo(ctx, key)
  local fs = persistFs(ctx)
  if not (fs and fs.getInfo) then return nil end
  return fs.getInfo(overlayPath(ctx, key))
end

local function storageRead(ctx, key)
  if not (Storage and key and key ~= "") then return nil end
  if key:sub(1, #OWN + 1) == OWN .. "/" then return nil end
  local game = ctx.game and ctx.game()
  if not game then return nil end
  local sk = storageKey(key)
  if not sk then return nil end
  ctx.storage = ctx.storage or Storage.new(ctx.modId, ctx.fs)
  local ok, bytes = pcall(ctx.storage.readBytes, ctx.storage, game, sk)
  if ok and type(bytes) == "string" then return bytes end
  return nil
end

local function readPath(ctx, path)
  local at = classify(ctx, path)
  if not at then return nil, "invalid path" end
  local body = at.key and overlayRead(ctx, at.key)
  if body then return body end
  if at.rel then
    local full = ownFull(ctx, at.rel)
    local fs = ctx.fs
    if full and fs and fs.read then
      local packaged = fs.read(full)
      if type(packaged) == "string" then return packaged end
    end
  end
  body = at.key and storageRead(ctx, at.key)
  if body then return body end
  return nil, "could not open " .. tostring(path)
end

local function writePath(ctx, path, data)
  local at = classify(ctx, path)
  if not (at and at.key) then return false, "invalid path" end
  return overlayWrite(ctx, at.key, data)
end

local function infoPath(ctx, path)
  local at = classify(ctx, path)
  if not at then return nil end
  if at.key then
    local info = overlayInfo(ctx, at.key)
    if info then
      return { type = info.type, size = info.size, modtime = info.modtime }
    end
  end
  if at.rel then
    local info = ownExists(ctx, at.rel)
    if info then
      return { type = info.type, size = info.size, modtime = info.modtime }
    end
  end
  local stored = at.key and storageRead(ctx, at.key)
  if stored then return { type = "file", size = #stored } end
  return nil
end

local function listPath(ctx, path)
  local at = classify(ctx, path)
  local seen, out = {}, {}
  local function add(name)
    if name and name ~= "" and not seen[name] then
      seen[name] = true
      out[#out + 1] = name
    end
  end
  if at and at.rel then
    local full = ownFull(ctx, at.rel)
    local fs = ctx.fs
    if full and fs and fs.getDirectoryItems then
      for _, name in ipairs(fs.getDirectoryItems(full) or {}) do add(name) end
    end
  end
  if at and at.key then
    local fs = persistFs(ctx)
    if fs and fs.getDirectoryItems then
      for _, name in ipairs(fs.getDirectoryItems(overlayPath(ctx, at.key)) or {}) do
        add(name)
      end
    end
  end
  table.sort(out)
  return out
end

-- ------- buffered file handles

local function openBuffer(ctx, path, mode)
  mode = tostring(mode or "r"):gsub("b", "")
  local writable = mode:find("[wa+]") ~= nil
  local body
  if mode:sub(1, 1) == "w" then
    body = ""
  else
    body = readPath(ctx, path)
    if not body then
      if not writable then return nil, "could not open " .. tostring(path) end
      body = ""
    end
  end
  local state = {
    ctx = ctx, path = path, buf = body, pos = 1,
    writable = writable, closed = false, dirty = false,
  }
  if mode:sub(1, 1) == "a" then state.pos = #body + 1 end
  return state
end

local function bufferFlush(state)
  if not (state.writable and state.dirty) then return true end
  local ok, err = writePath(state.ctx, state.path, state.buf)
  if ok then state.dirty = false end
  return ok, err
end

local function bufferWrite(state, text)
  if not state.writable then return false, "file is not open for writing" end
  local head = state.buf:sub(1, state.pos - 1)
  if #head < state.pos - 1 then head = head .. string.rep("\0", state.pos - 1 - #head) end
  local tail = state.buf:sub(state.pos + #text)
  state.buf = head .. text .. tail
  state.pos = state.pos + #text
  state.dirty = true
  return true
end

local function bufferRead(state, fmt)
  if fmt == nil then fmt = "*l" end
  if type(fmt) == "number" then
    if fmt == 0 then return state.pos <= #state.buf and "" or nil end
    if state.pos > #state.buf then return nil end
    local chunk = state.buf:sub(state.pos, state.pos + fmt - 1)
    state.pos = state.pos + #chunk
    return chunk
  end
  fmt = tostring(fmt):gsub("^%*", "")
  if fmt == "a" then
    local rest = state.buf:sub(state.pos)
    state.pos = #state.buf + 1
    return rest
  end
  if fmt == "l" or fmt == "L" then
    if state.pos > #state.buf then return nil end
    local nl = state.buf:find("\n", state.pos, true)
    local line
    if nl then
      line = state.buf:sub(state.pos, fmt == "L" and nl or nl - 1)
      state.pos = nl + 1
    else
      line = state.buf:sub(state.pos)
      state.pos = #state.buf + 1
    end
    return line
  end
  if fmt == "n" then
    local rest = state.buf:sub(state.pos)
    local text, after = rest:match("^%s*(%-?%d+%.?%d*[eE]?[-+]?%d*)()")
    if not text then return nil end
    state.pos = state.pos + after - 1
    return tonumber(text)
  end
  return nil
end

local function bufferSeek(state, whence, offset)
  whence = whence or "cur"
  offset = offset or 0
  if whence == "set" then state.pos = offset + 1
  elseif whence == "cur" then state.pos = state.pos + offset
  elseif whence == "end" then state.pos = #state.buf + offset + 1
  else return nil, "bad seek base" end
  if state.pos < 1 then state.pos = 1 end
  return state.pos - 1
end

local function bufferClose(state)
  if state.closed then return true end
  local ok, err = bufferFlush(state)
  state.closed = true
  return ok, err
end

local function ioFile(ctx, path, mode)
  local state, err = openBuffer(ctx, path, mode)
  if not state then return nil, err end
  local file = {}
  function file:read(...)
    local count = select("#", ...)
    if count == 0 then return bufferRead(state, "*l") end
    local out = {}
    for i = 1, count do out[i] = bufferRead(state, (select(i, ...))) end
    return unpack(out, 1, count)
  end
  function file:write(...)
    for i = 1, select("#", ...) do
      local value = select(i, ...)
      local ok, writeErr = bufferWrite(state, tostring(value))
      if not ok then return nil, writeErr end
    end
    return file
  end
  function file:lines(fmt)
    return function() return bufferRead(state, fmt or "*l") end
  end
  function file:seek(whence, offset) return bufferSeek(state, whence, offset) end
  function file:flush() bufferFlush(state) return file end
  function file:close() return bufferClose(state) end
  function file:setvbuf() return true end
  return file
end

local function loveFile(ctx, path, mode)
  local state = nil
  local file = {}
  function file:open(openMode)
    local opened, err = openBuffer(ctx, path, openMode or mode or "r")
    if not opened then return false, err end
    state = opened
    return true
  end
  function file:isOpen() return state ~= nil and not state.closed end
  function file:read(bytes)
    if not state and not file:open("r") then return nil, 0 end
    local body = bytes and bufferRead(state, bytes) or bufferRead(state, "*a")
    if not body then return nil, 0 end
    return body, #body
  end
  function file:write(data, size)
    if not state and not file:open(mode or "w") then return false end
    data = tostring(data)
    if size then data = data:sub(1, size) end
    local ok, err = bufferWrite(state, data)
    if not ok then return false, err end
    bufferFlush(state)
    return true
  end
  function file:lines()
    if not state then file:open("r") end
    return function() return state and bufferRead(state, "*l") or nil end
  end
  function file:seek(offset)
    if not state then return false end
    bufferSeek(state, "set", offset or 0)
    return true
  end
  function file:tell() return state and (state.pos - 1) or 0 end
  function file:getSize()
    if state then return #state.buf end
    local body = readPath(ctx, path)
    return body and #body or 0
  end
  function file:flush() if state then bufferFlush(state) end return true end
  function file:close()
    if state then bufferClose(state) end
    state = nil
    return true
  end
  function file:getFilename() return path end
  function file:getMode() return mode or "c" end
  function file:setBuffer() return true end
  if mode and mode ~= "c" then file:open(mode) end
  return file
end

-- ------- the love.filesystem stand-in

local function realFilesystem()
  return _G.love and _G.love.filesystem or nil
end

local function filesystemShim(ctx)
  local fsShim = {}

  local function readAdvice() return "reads now come from mod:read and mod.storage" end

  function fsShim.read(a, b, c)
    local path, size = a, b
    if (a == "string" or a == "data") and type(b) == "string" then
      path, size = b, c
    end
    note(ctx, "love.filesystem.read", readAdvice())
    local body, err = readPath(ctx, path)
    if not body then return nil, err end
    if size and size >= 0 then body = body:sub(1, size) end
    return body, #body
  end

  function fsShim.write(path, data, size)
    note(ctx, "love.filesystem.write",
      "writes are rerouted to this mod's private compat storage; migrate to mod.storage")
    data = tostring(data)
    if size then data = data:sub(1, size) end
    local ok, err = writePath(ctx, path, data)
    if not ok then return false, err end
    return true
  end

  function fsShim.append(path, data, size)
    note(ctx, "love.filesystem.append",
      "writes are rerouted to this mod's private compat storage; migrate to mod.storage")
    data = tostring(data)
    if size then data = data:sub(1, size) end
    local existing = readPath(ctx, path) or ""
    local ok, err = writePath(ctx, path, existing .. data)
    if not ok then return false, err end
    return true
  end

  function fsShim.lines(path)
    note(ctx, "love.filesystem.lines", readAdvice())
    local body = readPath(ctx, path)
    if not body then error("could not open " .. tostring(path), 2) end
    local pos = 1
    return function()
      if pos > #body then return nil end
      local nl = body:find("\n", pos, true)
      local line
      if nl then
        line = body:sub(pos, nl - 1)
        pos = nl + 1
      else
        line = body:sub(pos)
        pos = #body + 1
      end
      return line
    end
  end

  function fsShim.load(path)
    note(ctx, "love.filesystem.load",
      "the chunk is compiled into this mod's sandbox; prefer require or mod:read plus load")
    local body = readPath(ctx, path)
    if not body then return nil, "could not open " .. tostring(path) end
    if not ctx.compile then return nil, "no sandbox is bound yet" end
    return ctx.compile(body, "@" .. tostring(path))
  end

  function fsShim.getInfo(path, a, b)
    local info = infoPath(ctx, path)
    local filter = type(a) == "string" and a or nil
    local into = type(a) == "table" and a or (type(b) == "table" and b or nil)
    if not info then return nil end
    if filter and info.type ~= filter then return nil end
    if into then
      into.type, into.size, into.modtime = info.type, info.size, info.modtime
      return into
    end
    return info
  end

  function fsShim.getDirectoryItems(path)
    note(ctx, "love.filesystem.getDirectoryItems", "use mod.assets:list")
    return listPath(ctx, path)
  end

  function fsShim.createDirectory(path)
    local at = classify(ctx, path)
    if not (at and at.key) then return false end
    local fs = persistFs(ctx)
    if not (fs and fs.createDirectory) then return false end
    ensureParent(fs, overlayPath(ctx, at.key) .. "/.")
    fs.createDirectory(overlayPath(ctx, at.key))
    return true
  end

  function fsShim.remove(path)
    local at = classify(ctx, path)
    if not (at and at.key) then return false end
    return overlayRemove(ctx, at.key)
  end

  function fsShim.exists(path) return infoPath(ctx, path) ~= nil end

  function fsShim.isFile(path)
    local info = infoPath(ctx, path)
    return info ~= nil and info.type == "file"
  end

  function fsShim.isDirectory(path)
    local info = infoPath(ctx, path)
    return info ~= nil and info.type == "directory"
  end

  function fsShim.getSize(path)
    local info = infoPath(ctx, path)
    if not info then return nil, "could not open " .. tostring(path) end
    return info.size or 0
  end

  function fsShim.getLastModified(path)
    local info = infoPath(ctx, path)
    if not info then return nil, "could not open " .. tostring(path) end
    return info.modtime or 0
  end

  local function virtual(call)
    note(ctx, call, "paths are virtual now; everything under the returned root "
      .. "lands in this mod's private compat storage")
    return ctx.virtualRoot
  end

  function fsShim.getSaveDirectory() return virtual("love.filesystem.getSaveDirectory") end
  function fsShim.getWorkingDirectory() return virtual("love.filesystem.getWorkingDirectory") end
  function fsShim.getUserDirectory() return virtual("love.filesystem.getUserDirectory") end
  function fsShim.getAppdataDirectory() return virtual("love.filesystem.getAppdataDirectory") end
  function fsShim.getSourceBaseDirectory() return virtual("love.filesystem.getSourceBaseDirectory") end
  function fsShim.getRealDirectory() return ctx.virtualRoot end

  function fsShim.getIdentity() return ctx.modId end

  function fsShim.setIdentity()
    note(ctx, "love.filesystem.setIdentity",
      "a mod cannot repoint the save directory; the call does nothing")
    return false
  end

  function fsShim.getRequirePath() return "" end
  function fsShim.setRequirePath() return false end
  function fsShim.getCRequirePath() return "" end
  function fsShim.setCRequirePath() return false end

  function fsShim.mount()
    note(ctx, "love.filesystem.mount",
      "mounting is refused; ship the files inside your mod and use mod:read")
    return false
  end
  fsShim.unmount = fsShim.mount

  function fsShim.newFile(path, mode) return loveFile(ctx, path, mode) end

  function fsShim.newFileData(a, b)
    local real = realFilesystem()
    if type(a) == "string" and b == nil then
      note(ctx, "love.filesystem.newFileData", readAdvice())
      local body = readPath(ctx, a)
      if not body then return nil, "could not open " .. tostring(a) end
      if real and real.newFileData then return real.newFileData(body, a) end
      return nil, "no filesystem"
    end
    if real and real.newFileData then return real.newFileData(a, b) end
    return nil, "no filesystem"
  end

  function fsShim.isFused()
    local real = realFilesystem()
    return real and real.isFused and real.isFused() or false
  end

  function fsShim.areSymlinksEnabled() return false end
  function fsShim.setSymlinksEnabled() return false end
  function fsShim.init() return false end
  function fsShim.setSource() return false end

  return setmetatable(fsShim, { __index = function(_, key)
    note(ctx, "love.filesystem." .. tostring(key),
      "there is no compat stand-in for it; use mod.storage or mod:read")
    return nil
  end })
end

-- ------- the rest of the removed surface

local function systemShim(ctx)
  local function real() return _G.love and _G.love.system or nil end
  -- tls* comes from the engine (Android JNI, or desktop gen1tls hung on
  -- love.system at boot).  Forward those; keep clipboard / openURL stubbed.
  local TLS = {
    tlsOpen = true, tlsStatus = true, tlsSend = true,
    tlsReceive = true, tlsError = true, tlsClose = true,
  }
  local shim = {
    getOS = function()
      local sys = real()
      return sys and sys.getOS and sys.getOS() or "Unknown"
    end,
    getPowerInfo = function()
      local sys = real()
      if not (sys and sys.getPowerInfo) then return "unknown", nil, nil end
      return sys.getPowerInfo()
    end,
    getProcessorCount = function()
      local sys = real()
      return sys and sys.getProcessorCount and sys.getProcessorCount() or 1
    end,
    getClipboardText = function()
      note(ctx, "love.system.getClipboardText",
        "clipboard access stays sandboxed; the call returns an empty string")
      return ""
    end,
    setClipboardText = function()
      note(ctx, "love.system.setClipboardText",
        "clipboard access stays sandboxed; the call does nothing")
      return false
    end,
    openURL = function()
      note(ctx, "love.system.openURL",
        "launching a URL stays sandboxed; the call does nothing")
      return false
    end,
    vibrate = function(...)
      local sys = real()
      if sys and sys.vibrate then return sys.vibrate(...) end
      return false
    end,
  }
  return setmetatable(shim, {
    __index = function(_, key)
      if not TLS[key] then return nil end
      local sys = real()
      return sys and sys[key]
    end,
  })
end

local function eventShim(ctx)
  local function real() return _G.love and _G.love.event or nil end
  local shim = {
    quit = function()
      note(ctx, "love.event.quit",
        "a mod cannot close the game out from under the player; the call does nothing")
      return false
    end,
  }
  shim.push = function(name, ...)
    if name == "quit" then return shim.quit() end
    local ev = real()
    if ev and ev.push then return ev.push(name, ...) end
    return false
  end
  return setmetatable(shim, { __index = function(_, key)
    local ev = real()
    return ev and ev[key] or nil
  end })
end

local function ioShim(ctx)
  local stream = {
    write = function(self, ...)
      for i = 1, select("#", ...) do io.write(tostring((select(i, ...)))) end
      return self
    end,
    flush = function(self) return self end,
    close = function() return true end,
    read = function() return nil end,
    lines = function() return function() return nil end end,
    seek = function() return 0 end,
    setvbuf = function() return true end,
  }
  local out = setmetatable({}, { __index = stream })
  local shim = {
    open = function(path, mode)
      note(ctx, "io.open",
        "the handle is backed by mod:read and this mod's private compat storage")
      local file, err = ioFile(ctx, path, mode)
      if not file then return nil, err, 2 end
      return file
    end,
    lines = function(path, fmt)
      if path == nil then return function() return nil end end
      note(ctx, "io.lines",
        "the handle is backed by mod:read and this mod's private compat storage")
      local file, err = ioFile(ctx, path, "r")
      if not file then error(err, 2) end
      return file:lines(fmt)
    end,
    close = function(file) if file and file.close then return file:close() end return true end,
    type = function(file)
      if type(file) == "table" and file.read and file.close then return "file" end
      return nil
    end,
    read = function() return nil end,
    write = function(...) return out:write(...) end,
    input = function() return out end,
    output = function() return out end,
    stdout = out,
    stderr = out,
    stdin = setmetatable({}, { __index = stream }),
    popen = function()
      return refuse(ctx, "io.popen", "spawning a process is refused")
    end,
    tmpfile = function()
      return ioFile(ctx, ctx.virtualRoot .. "/io_tmpfile", "w+")
    end,
  }
  return shim
end

local function osShim(ctx)
  local HOME = { HOME = true, APPDATA = true, LOCALAPPDATA = true,
                 USERPROFILE = true, XDG_DATA_HOME = true,
                 XDG_CONFIG_HOME = true, TMPDIR = true, TEMP = true, TMP = true }
  return {
    getenv = function(name)
      note(ctx, "os.getenv",
        "the environment is hidden; home-like names answer with this mod's virtual root")
      if type(name) == "string" and HOME[name:upper()] then
        return ctx.virtualRoot
      end
      return nil
    end,
    remove = function(path)
      note(ctx, "os.remove", "the delete lands in this mod's private compat storage")
      local at = classify(ctx, path)
      if not (at and at.key and overlayRemove(ctx, at.key)) then
        return nil, tostring(path) .. ": no such file"
      end
      return true
    end,
    rename = function(from, to)
      note(ctx, "os.rename", "the move lands in this mod's private compat storage")
      local body = readPath(ctx, from)
      if not body then return nil, tostring(from) .. ": no such file" end
      local ok, err = writePath(ctx, to, body)
      if not ok then return nil, err end
      local at = classify(ctx, from)
      if at and at.key then overlayRemove(ctx, at.key) end
      return true
    end,
    tmpname = function()
      return ctx.virtualRoot .. "/tmp/os_tmpname"
    end,
    execute = function()
      note(ctx, "os.execute", "running a command is refused")
      return false
    end,
    exit = function()
      note(ctx, "os.exit",
        "a mod cannot end the process; the call does nothing")
      return false
    end,
    setlocale = function() return "C" end,
  }
end

local function packageShim(ctx)
  local shim = { path = "", cpath = "", preload = {}, loaded = {}, loaders = {} }
  return setmetatable(shim, {
    __index = function(_, key)
      note(ctx, "package." .. tostring(key),
        "the module loader is sandboxed; use require for the supported engine modules")
      return nil
    end,
  })
end

-- ------- love callbacks

local CALLBACKS = {
  load = true, update = true, draw = true, quit = true, lowmemory = true,
  threaderror = true, keypressed = true, keyreleased = true,
  textinput = true, textedited = true, mousemoved = true,
  mousepressed = true, mousereleased = true, wheelmoved = true,
  mousefocus = true, touchpressed = true, touchreleased = true,
  touchmoved = true, joystickadded = true, joystickremoved = true,
  joystickpressed = true, joystickreleased = true, joystickaxis = true,
  joystickhat = true, gamepadpressed = true, gamepadreleased = true,
  gamepadaxis = true, focus = true, visible = true, resize = true,
  filedropped = true, directorydropped = true, displayrotated = true,
  audiodevicechanged = true, localechanged = true,
}

local REFUSED = {
  run = "love.run is the engine's fixed-step loop; use mod.hooks and mod.events",
  errorhandler = "love.errorhandler is how a crash reaches the player; "
    .. "use mod.events",
}

-- ------- assembly

function LegacyCompat.new(opts)
  opts = opts or {}
  local ctx = {
    modId = opts.modId or "mod",
    modPath = opts.modPath,
    fs = opts.fs,
    game = opts.game,
    compile = nil,
  }
  ctx.virtualRoot = "/pokeport/" .. ctx.modId

  local filesystem = filesystemShim(ctx)
  local io_ = ioShim(ctx)
  local system = systemShim(ctx)
  local event = eventShim(ctx)

  local compat = {
    ctx = ctx,
    love = { filesystem = filesystem, system = system, event = event },
    os = osShim(ctx),
    globals = {
      io = io_,
      package = packageShim(ctx),
      loadfile = function(path)
        note(ctx, "loadfile",
          "the chunk is compiled into this mod's sandbox; prefer require or mod:read")
        local body = readPath(ctx, path)
        if not body then return nil, "could not open " .. tostring(path) end
        if not ctx.compile then return nil, "no sandbox is bound yet" end
        return ctx.compile(body, "@" .. tostring(path))
      end,
    },
    modules = {
      io = io_,
      ["love.filesystem"] = filesystem,
      ["love.system"] = system,
      ["love.event"] = event,
    },
  }

  compat.globals.dofile = function(path)
    local chunk, err = compat.globals.loadfile(path)
    if not chunk then error(err or ("could not open " .. tostring(path)), 2) end
    return chunk()
  end

  function compat.module(name)
    if type(name) ~= "string" then return nil end
    local substitute = compat.modules[name]
    if substitute then
      note(ctx, ('require("%s")'):format(name),
        "it now answers with the compat stand-in, not the real module")
      return substitute
    end
    if name == "os" then
      note(ctx, 'require("os")',
        "it now answers with the compat stand-in, not the real module")
      return compat.osTable
    end
    return nil
  end

  -- true when the assignment is a callback chain, which is what a mod
  -- wrapping love.mousemoved did before the sandbox; false plus a reason for
  -- the two names the engine owns, false alone for a module table.
  function compat.assign(key, value)
    if REFUSED[key] then
      note(ctx, ("love.%s assignment"):format(key), REFUSED[key])
      return false, ("[%s] %s"):format(ctx.modId, REFUSED[key])
    end
    if not CALLBACKS[key] then return false end
    if value ~= nil and type(value) ~= "function" then return false end
    note(ctx, ("love.%s assignment"):format(key),
      "the callback lands on the real love table the way it did before the "
      .. "sandbox; prefer mod.hooks and mod.events")
    return true
  end

  function compat.bind(env, compile)
    ctx.compile = compile
    compat.osTable = env and env.os or nil
  end

  return compat
end

return LegacyCompat
