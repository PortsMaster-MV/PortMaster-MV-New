-- Single source of every compatibility-relevant number: engine release,
-- mod API major, link protocol, save format and ROM cache generation.  Zero
-- requires so it loads during love.conf and under plain Lua for tools and
-- tests.

local Version = {
  engine = "0.3.54",   -- game/engine release (semver).  Repo default is the
                          -- "-dev" placeholder; CI stamps the real X.Y.Z into
                          -- the packed game.love only, never the working tree.
  shell = 2,              -- native-shell contract this build implements
  payloadHost = "love",   -- native host family for in-place Lua payloads.
                          -- A payload must name the same family; this prevents
                          -- mounting code packaged for a different native host.
  minShell = 1,           -- lowest shell contract that can RUN this payload.
                          -- Bump only when a payload needs a newer native
                          -- binary (e.g. a LOVE version bump); an older shell
                          -- refuses to chainload a payload whose minShell
                          -- exceeds the shell it provides.
  modApi = 2,             -- mod API major (manifest `api`)
  linkProtocol = 2,       -- link handshake wire version (Handshake.PROTOCOL)
  saveFormat = 5,         -- save.meta.format
  cache = "rom-cache-v5", -- ROM import cache generation (RomImporter marker)
}

local DEV_PLACEHOLDER = "0.0.0-dev"

local function readFile(path)
  local handle = io.open(path, "rb")
  if not handle then return nil end
  local text = handle:read("*a")
  handle:close()
  if type(text) ~= "string" or text == "" then return nil end
  return text
end

local function commitFromBuildInfo()
  local fs = rawget(_G, "love") and love.filesystem
  if not (fs and fs.read) then return nil end
  local ok, text = pcall(fs.read, "build-info.json")
  if not ok or type(text) ~= "string" then return nil end
  return text:match('"gitCommitFull"%s*:%s*"(%x+)"')
      or text:match('"gitCommit"%s*:%s*"(%x+)"')
end

local function commitFromGit(source, read)
  read = read or readFile
  if type(source) ~= "string" or source == "" then return nil end
  local gitDir = source .. "/.git"
  local head = read(gitDir .. "/HEAD")
  if not head then
    local pointer = read(gitDir)
    local target = pointer and pointer:match("^gitdir:%s*(%S+)")
    if not target then return nil end
    if not target:match("^/") then target = source .. "/" .. target end
    gitDir = target
    head = read(gitDir .. "/HEAD")
    if not head then return nil end
  end
  local ref = head:match("^ref:%s*(%S+)")
  if not ref then return head:match("^(%x+)") end
  local hash = read(gitDir .. "/" .. ref)
  if hash then return hash:match("^(%x+)") end
  local packed = read(gitDir .. "/packed-refs")
  if packed then
    return packed:match("(%x+)%s+" .. ref:gsub("%p", "%%%0"))
  end
  return nil
end

function Version.devEngine(engine, source, read)
  engine = tostring(engine or "")
  if engine ~= DEV_PLACEHOLDER then return engine end
  local commit = commitFromBuildInfo() or commitFromGit(source, read)
  if type(commit) ~= "string" or #commit < 7 then return engine end
  return engine .. "+" .. commit:sub(1, 12):lower()
end

do
  local ok, derived = pcall(function()
    local source
    local fs = rawget(_G, "love") and love.filesystem
    if fs and fs.getSource then source = fs.getSource() end
    return Version.devEngine(Version.engine, source)
  end)
  if ok and type(derived) == "string" and derived ~= "" then
    Version.engine = derived
  end
end

-- True for the working-tree placeholder and any stamped "-dev" pre-release.
-- Shipped builds get a bare X.Y.Z from CI and are not "dev" here.
function Version.isDev()
  local engine = tostring(Version.engine or "")
  return engine == "0.0.0-dev" or engine:find("%-dev", 1) ~= nil
end

-- Window / chrome title.  Dev builds keep the version visible
-- ("gen1recomp v0.0.0-dev"); release builds are just the base name so Linux
-- window chrome and taskbars do not read "gen1recomp 0.1.73".
function Version.title(base)
  base = base or "gen1recomp"
  if Version.isDev() then
    return base .. " v" .. Version.engine
  end
  return base
end

return Version
