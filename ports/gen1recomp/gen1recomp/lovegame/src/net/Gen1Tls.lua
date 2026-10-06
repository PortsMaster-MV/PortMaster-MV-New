-- Load gen1tls from next to the exe and put its poll API on love.system --
-- same tlsOpen / tlsSend / ... shape Android already exposes through JNI.
--
-- Mods can't require("ffi") under the sandbox, so they can't load the DLL
-- themselves even when it's sitting right there.  We do it here, before any
-- mod runs.  LegacyCompat's love.system shim forwards the tls* keys through
-- (clipboard / openURL stay stubbed).
--
-- true = tlsOpen is ready.  Already present (Android), no FFI, or no DLL:
-- just return false and move on; plain ws:// rooms don't care.

local Gen1Tls = {}

local function exeDir()
  if love and love.filesystem and love.filesystem.getSourceBaseDirectory then
    local base = love.filesystem.getSourceBaseDirectory()
    if type(base) == "string" and base ~= "" then return base end
  end
  if type(arg) == "table" and type(arg[0]) == "string" then
    local dir = arg[0]:match("^(.*)[/\\]")
    if dir and dir ~= "" then return dir end
  end
  return "."
end

local function fileReadable(path)
  local f = io.open(path, "rb")
  if not f then return false end
  f:close()
  return true
end

local function libNames()
  local osName = (love and love.system and love.system.getOS and love.system.getOS()) or ""
  if osName == "Windows" then return { "gen1tls.dll" } end
  if osName == "OS X" then return { "libgen1tls.dylib", "gen1tls.dylib" } end
  if osName == "Linux" then return { "libgen1tls.so", "gen1tls.so" } end
  return { "gen1tls.dll", "libgen1tls.so", "libgen1tls.dylib" }
end

function Gen1Tls.install()
  if not (love and love.system) then return false end
  if type(love.system.tlsOpen) == "function" then return true end

  local okFfi, ffi = pcall(require, "ffi")
  if not okFfi or type(ffi) ~= "table" then return false end

  ffi.cdef[[
    int gen1tls_open(const char *host, int port);
    int gen1tls_status(int handle);
    int gen1tls_send(int handle, const char *data, int length);
    int gen1tls_receive(int handle, char *buf, int max);
    int gen1tls_error(int handle, char *buf, int max);
    void gen1tls_close(int handle);
  ]]

  local dir = exeDir()
  local lib
  for _, name in ipairs(libNames()) do
    local path = dir .. "/" .. name
    if fileReadable(path) then
      local ok, loaded = pcall(ffi.load, path)
      if ok then lib = loaded; break end
    end
    local ok, loaded = pcall(ffi.load, name)
    if ok then lib = loaded; break end
  end
  if not lib then return false end

  local errBuf = ffi.new("char[512]")
  local recvBuf = ffi.new("char[65536]")

  love.system.tlsOpen = function(host, port)
    return lib.gen1tls_open(host, tonumber(port) or 0)
  end
  love.system.tlsStatus = function(handle)
    return lib.gen1tls_status(handle)
  end
  love.system.tlsSend = function(handle, data)
    data = data or ""
    return lib.gen1tls_send(handle, data, #data)
  end
  love.system.tlsReceive = function(handle, max)
    max = math.min(tonumber(max) or 8192, 65536)
    if max <= 0 then return "" end
    local n = lib.gen1tls_receive(handle, recvBuf, max)
    if n <= 0 then return "" end
    return ffi.string(recvBuf, n)
  end
  love.system.tlsError = function(handle)
    if lib.gen1tls_error(handle, errBuf, 512) == 0 then return nil end
    return ffi.string(errBuf)
  end
  love.system.tlsClose = function(handle)
    lib.gen1tls_close(handle)
  end
  return true
end

return Gen1Tls