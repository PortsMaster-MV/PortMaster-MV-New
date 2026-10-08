-- Background HTTP for sandboxed mods, behind the "network" permission.
--
-- The sandbox blocks love.thread because newThread boots a Lua state with a
-- full standard library that none of the sandbox's rules reach -- one call and
-- a mod has io back.  That is correct, but it left mods with no way to do
-- anything off the main thread at all: the only reachable transports
-- (socket, http) block, so a mod that wanted to fetch something had to hang
-- the game to do it.
--
-- This is the narrow replacement.  src/net/Fetch.lua already runs a pool of
-- engine-owned worker threads, and those workers run OUR code, not the mod's,
-- so handing a mod a job in that pool grants no new reach.  A mod submits a
-- URL and polls for the body; it never gets a thread, a path, or a raw handle
-- into the shared job table.
--
-- WHAT THIS FILE HAS TO GET RIGHT, because Fetch itself is shared with the
-- launcher:
--   * Handles are opaque tables owned per mod.  Fetch keys jobs by integer,
--     and the launcher's own ROM download and index fetches live in the same
--     table; an integer handed to a mod would let it poll (or cancel) work
--     that is not its own.  A forged table simply misses the lookup.
--   * Only http and https.  The transport is curl, which also speaks file://,
--     scp:// and ftp://; without this check mod.fetch would be a filesystem
--     read and the sandbox would be back to square one.
--   * A per-mod ceiling on jobs in flight, so one mod cannot fill the shared
--     three-worker pool and starve the launcher's own fetches.

local Net = {}

-- Per mod, not global: the pool is shared with the launcher and a mod should
-- never be able to monopolise it.
Net.MAX_INFLIGHT = 4
-- Clamp on the caller's timeout, so a mod cannot pin a worker indefinitely.
Net.MAX_SECONDS = 30
-- A log body ceiling.  A diagnostic ring (boot evidence + recent lines +
-- status) routinely exceeds 64 KiB on a long session, so the ceiling is
-- 512 KiB: generous for real support logs, still far under the 5 MiB the
-- reference loghook endpoint accepts, and small enough that a misbehaving
-- mod cannot upload arbitrary megabytes.  The body is staged to a file and
-- streamed by the transport, so the ceiling is a budget, not a memory
-- spike; callers that stay under it never notice it.
Net.MAX_BODY = 512 * 1024

local function fetch()
  return require("src.net.Fetch")
end

-- http/https only, and a host must actually be present -- "http://" alone
-- reaches curl as a malformed URL rather than being refused here.
function Net.urlDenial(url)
  if type(url) ~= "string" or url == "" then return "url must be a string" end
  local scheme, rest = url:match("^(%a[%w+.-]*)://(.*)$")
  if not scheme then return "url must start with http:// or https://" end
  scheme = scheme:lower()
  if scheme ~= "http" and scheme ~= "https" then
    return ("%s:// is not allowed; mod.fetch speaks http and https only")
      :format(scheme)
  end
  if rest == "" or rest:match("^/") then return "url has no host" end
  return nil
end

local function bucket(loader, modId)
  loader.netJobs = loader.netJobs or {}
  local b = loader.netJobs[modId]
  if not b then b = {}; loader.netJobs[modId] = b end
  return b
end

local function inflight(b)
  local n = 0
  for _, id in pairs(b) do
    if fetch().isPending(id) then n = n + 1 end
  end
  return n
end

function Net.available()
  local ok, F = pcall(fetch)
  if not ok then return false end
  local okAvail, avail = pcall(F.available)
  return okAvail and avail and true or false
end

-- Returns an opaque handle, or nil plus a reason.
function Net.get(loader, modId, url, opts)
  local denial = Net.urlDenial(url)
  if denial then return nil, denial end
  opts = type(opts) == "table" and opts or {}
  local b = bucket(loader, modId)
  if inflight(b) >= Net.MAX_INFLIGHT then
    return nil, ("too many requests in flight (limit %d); poll and release "
      .. "the ones you have"):format(Net.MAX_INFLIGHT)
  end
  local maxSeconds = tonumber(opts.maxSeconds) or Net.MAX_SECONDS
  if maxSeconds > Net.MAX_SECONDS then maxSeconds = Net.MAX_SECONDS end
  if maxSeconds < 1 then maxSeconds = 1 end
  -- The mod is named in the agent string so a server operator can see which
  -- mod is calling them, and a mod cannot pretend to be the launcher.
  local id = fetch().get(url, {
    userAgent = "gen1recomp-mod/" .. tostring(modId),
    accept = type(opts.accept) == "string" and opts.accept or nil,
    maxSeconds = maxSeconds,
  })
  local handle = {}
  b[handle] = id
  return handle
end

-- The closed list of postLog format switches.  Anything outside it is a
-- caller bug, rejected before a job is submitted, so the surface stays
-- exactly two shapes on the wire.
local POST_FORMATS = { text = true, json = true }

-- A one-way log POST to the mod's manifest-declared log_url (https only,
-- validated in Manifest.lua).  Same shape as get(): opaque handle, per-mod
-- in-flight ceiling, user agent naming the mod.  The response body is never
-- returned -- a postLog is fire-and-forget reporting, and the engine has no
-- reason to hand a mod a server's reply.
function Net.postLog(loader, modId, logUrl, body, opts)
  if type(body) ~= "string" or body == "" then
    return nil, "log body must be a non-empty string"
  end
  if #body > Net.MAX_BODY then
    return nil, ("log body too large (%d bytes, limit %d)"):format(#body, Net.MAX_BODY)
  end
  opts = type(opts) == "table" and opts or {}
  for key in pairs(opts) do
    if key ~= "format" then
      return nil, ("unknown log option %q (format is the only switch)"):format(tostring(key))
    end
  end
  local format = opts.format or "text"
  if not POST_FORMATS[format] then
    return nil, ("unknown log format %q (text and json only)"):format(tostring(format))
  end
  local denial = Net.urlDenial(logUrl)
  if denial then return nil, denial end
  local b = bucket(loader, modId)
  if inflight(b) >= Net.MAX_INFLIGHT then
    return nil, ("too many requests in flight (limit %d); poll and release "
      .. "the ones you have"):format(Net.MAX_INFLIGHT)
  end
  local payload = body
  local contentType = "text/plain"
  if format == "json" then
    local Json = require("src.link.Json")
    payload = Json.encode({
      ts = os.time(),
      mod = modId,
      format = "json",
      body = body,
    })
    contentType = "application/json"
  end
  local id = fetch().post(logUrl, payload, {
    userAgent = "gen1recomp-mod/" .. tostring(modId),
    contentType = contentType,
    maxSeconds = Net.MAX_SECONDS,
  })
  local handle = {}
  b[handle] = id
  return handle
end

-- A copy of the job's state, never the engine's own table.  An unknown or
-- forged handle reads as an error rather than nil, so a mod that lost track of
-- one cannot spin waiting on it forever.
function Net.poll(loader, modId, handle)
  local id = bucket(loader, modId)[handle]
  if not id then return { status = "error", err = "unknown request" } end
  local st = fetch().poll(id)
  return { status = st.status, body = st.body, err = st.err,
           progress = st.progress }
end

function Net.release(loader, modId, handle)
  local b = bucket(loader, modId)
  local id = b[handle]
  if not id then return false end
  fetch().release(id)
  b[handle] = nil
  return true
end

function Net.cancel(loader, modId, handle)
  local id = bucket(loader, modId)[handle]
  if not id then return false end
  fetch().cancel(id)
  return true
end

-- Drop everything this mod still holds.  Called when a mod unloads, so a
-- disabled mod cannot leave jobs accumulating in the shared table.
function Net.releaseAll(loader, modId)
  local b = loader.netJobs and loader.netJobs[modId]
  if not b then return end
  local F = fetch()
  for handle, id in pairs(b) do
    pcall(F.cancel, id)
    pcall(F.release, id)
    b[handle] = nil
  end
  loader.netJobs[modId] = nil
end

return Net
