-- Switch OTA wire format (host-testable, no love.*).
-- The native DEVKITPRO launcher (libnx + switch-curl) must implement the
-- same decisions. LÖVE on NX never runs this path — Platform.networkValidated
-- stays false and src/update/Check.lua remains gated off on NX.
--
-- Asset: gen1recomp-<X.Y.Z>-switch.zip (same SD zip used for install).

local SwitchOta = {}

SwitchOta.RELEASES_API =
  "https://api.github.com/repos/bryanthaboi/gen1recomp/releases/latest"
SwitchOta.OTA_ASSET_PATTERN = "^gen1recomp%-(%d+%.%d+%.%d+)%-switch%.zip$"
SwitchOta.CHECK_TIMEOUT_SEC = 6
SwitchOta.GAME_NRO_NAME = "gen1recomp-game.nro"
SwitchOta.LAUNCHER_NRO_NAME = "gen1recomp.nro"
SwitchOta.SAVE_DIR_NAME = "pokemon-love2d"
SwitchOta.INSTALL_DIR = "switch/gen1recomp"

local function parseSemver(s)
  if type(s) ~= "string" then return nil end
  local body = s:match("^v?(.+)$")
  if not body then return nil end
  local maj, min, pat = body:match("^(%d+)%.(%d+)%.(%d+)$")
  if not maj then return nil end
  return { major = tonumber(maj), minor = tonumber(min), patch = tonumber(pat) }
end

function SwitchOta.compareSemver(a, b)
  local pa, pb = parseSemver(a), parseSemver(b)
  if not pa and not pb then return 0 end
  if not pa then return -1 end
  if not pb then return 1 end
  for _, field in ipairs({ "major", "minor", "patch" }) do
    if pa[field] < pb[field] then return -1 end
    if pa[field] > pb[field] then return 1 end
  end
  return 0
end

function SwitchOta.isOtaAssetName(name)
  if type(name) ~= "string" then return false end
  return name:match(SwitchOta.OTA_ASSET_PATTERN) ~= nil
end

function SwitchOta.versionFromOtaAsset(name)
  if type(name) ~= "string" then return nil end
  return name:match(SwitchOta.OTA_ASSET_PATTERN)
end

local function findJsonObjectStart(jsonText, pos)
  if type(jsonText) ~= "string" or not pos or pos < 1 then return nil end
  local depth = 0
  local p = pos
  while p >= 1 do
    local c = jsonText:sub(p, p)
    if c == "}" then
      depth = depth + 1
    elseif c == "{" then
      if depth == 0 then return p end
      depth = depth - 1
    end
    p = p - 1
  end
  return nil
end

local function findJsonObjectEnd(jsonText, objectStart)
  if type(jsonText) ~= "string" or not objectStart then return nil end
  if jsonText:sub(objectStart, objectStart) ~= "{" then return nil end
  local depth = 1
  local p = objectStart + 1
  local len = #jsonText
  while p <= len do
    local c = jsonText:sub(p, p)
    if c == "{" then
      depth = depth + 1
    elseif c == "}" then
      depth = depth - 1
      if depth == 0 then return p + 1 end
    end
    p = p + 1
  end
  return nil
end

-- Parse GitHub releases/latest JSON (tag_name + assets[].name/browser_download_url).
-- Returns { tag, version, assetName, downloadUrl } or nil + reason.
function SwitchOta.parseRelease(jsonText)
  if type(jsonText) ~= "string" or jsonText == "" then
    return nil, "empty_json"
  end
  local tag = jsonText:match('"tag_name"%s*:%s*"(.-)"')
  if not tag then return nil, "missing_tag" end
  local version = tag:match("^v?(%d+%.%d+%.%d+)$")
  if not version then return nil, "bad_tag" end

  local cursor = 1
  while true do
    local nameKeyPos = jsonText:find('"name"', cursor, true)
    if not nameKeyPos then break end
    local tail = jsonText:sub(nameKeyPos)
    local name = tail:match('"name"%s*:%s*"(.-)"')
    if name and SwitchOta.isOtaAssetName(name) then
      local assetStart = findJsonObjectStart(jsonText, nameKeyPos)
      local assetEnd = assetStart and findJsonObjectEnd(jsonText, assetStart)
      if assetStart and assetEnd and assetEnd > nameKeyPos then
        local assetBlock = jsonText:sub(assetStart, assetEnd - 1)
        local downloadUrl = assetBlock:match('"browser_download_url"%s*:%s*"(.-)"')
        if downloadUrl and downloadUrl ~= "" then
          return {
            tag = tag,
            version = version,
            assetName = name,
            downloadUrl = downloadUrl,
          }
        end
      end
    end
    cursor = nameKeyPos + 6
  end
  return nil, "missing_ota_asset"
end

-- Decide check outcome given installed version and parsed release.
-- Returns status: uptodate | available | error
function SwitchOta.decideUpdate(installedVersion, release)
  if type(installedVersion) ~= "string" or not parseSemver(installedVersion) then
    return { status = "error", reason = "bad_installed_version" }
  end
  if type(release) ~= "table" or not release.version then
    return { status = "error", reason = "bad_release" }
  end
  local cmp = SwitchOta.compareSemver(release.version, installedVersion)
  if cmp <= 0 then
    return { status = "uptodate", version = installedVersion }
  end
  return {
    status = "available",
    version = release.version,
    assetName = release.assetName,
    downloadUrl = release.downloadUrl,
  }
end

-- Parse sha256sums.txt lines: "<hex>  <filename>" or "<hex> *<filename>"
function SwitchOta.parseSums(text)
  local sums = {}
  if type(text) ~= "string" then return sums end
  for line in (text .. "\n"):gmatch("(.-)\n") do
    local hex, name = line:match("^(%x+)%s+%*?%./?(.-)%s*$")
    if hex and name and name ~= "" then
      sums[name] = hex:lower()
    end
  end
  return sums
end

-- Require a matching sha256. Missing sum is ALWAYS reject (no silent accept).
function SwitchOta.verifySha256(assetName, actualHex, sums)
  if type(assetName) ~= "string" or assetName == "" then
    return false, "bad_asset_name"
  end
  if type(sums) ~= "table" then
    return false, "missing_sums"
  end
  local expected = sums[assetName]
  if type(expected) ~= "string" or expected == "" then
    return false, "sum_not_found"
  end
  if type(actualHex) ~= "string" or actualHex == "" then
    return false, "missing_actual_hash"
  end
  if actualHex:lower() ~= expected:lower() then
    return false, "hash_mismatch"
  end
  return true, nil
end

-- Atomic apply plan: never writes live NROs directly; never touches saves.
-- Replaces game + launcher so NACP versions stay in sync (hbmenu / Sphaira).
function SwitchOta.planAtomicApply(installDir, verifiedTempPath)
  installDir = installDir or SwitchOta.INSTALL_DIR
  local gameNro = installDir .. "/" .. SwitchOta.GAME_NRO_NAME
  local launcherNro = installDir .. "/" .. SwitchOta.LAUNCHER_NRO_NAME
  local partPath = gameNro .. ".part"
  local launcherPart = launcherNro .. ".part"
  return {
    steps = {
      { op = "copy_to_part", from = verifiedTempPath, to = partPath },
      { op = "rename", from = partPath, to = gameNro },
      { op = "copy_to_part", from = "launcher", to = launcherPart },
      { op = "rename", from = launcherPart, to = launcherNro },
      { op = "env_set_next_load", target = gameNro },
    },
    preserve = { installDir .. "/" .. SwitchOta.SAVE_DIR_NAME },
    forbidden = {
      "delete:" .. installDir .. "/" .. SwitchOta.SAVE_DIR_NAME,
      "write_direct:" .. gameNro,
    },
  }
end

-- Offline / skip / timeout policy. Never blocks forever.
-- elapsedSec: time spent on the network check so far
-- events: { networkOk=bool, userSkip=bool, apiError=bool }
function SwitchOta.offlinePolicy(elapsedSec, events)
  events = events or {}
  if events.userSkip then
    return { action = "play_installed", reason = "user_skip", message = "update skipped" }
  end
  if events.apiError or events.networkOk == false then
    return {
      action = "play_installed",
      reason = "offline_or_error",
      message = "offline or update check failed — play installed version",
    }
  end
  local timeout = SwitchOta.CHECK_TIMEOUT_SEC
  if type(elapsedSec) == "number" and elapsedSec >= timeout then
    return {
      action = "play_installed",
      reason = "timeout",
      message = "update check timed out after " .. tostring(timeout) .. "s",
    }
  end
  return { action = "keep_checking", reason = "in_flight" }
end

return SwitchOta
