local Fingerprint = require("src.link.Fingerprint")

local HostRules = {}

HostRules.MAX_ROWS = 512

local function fields()
  return Fingerprint.GEN3_MOVE_FIELDS
end

local function sortedIds(map)
  local ids = {}
  for id in pairs(map or {}) do
    if type(id) == "number" then ids[#ids + 1] = id end
  end
  table.sort(ids)
  return ids
end

function HostRules.encodeRow(id, row)
  local parts = {}
  for i, f in ipairs(fields()) do
    local v = row[f]
    parts[i] = type(v) == "number" and ("%d"):format(v) or ""
  end
  return tostring(id) .. ":" .. table.concat(parts, ",")
end

function HostRules.decodeRow(text)
  if type(text) ~= "string" then return nil end
  local id, rest = text:match("^(%d+):(.*)$")
  id = tonumber(id)
  if not id then return nil end
  local row, i = {}, 0
  for cell in (rest .. ","):gmatch("([^,]*),") do
    i = i + 1
    local f = fields()[i]
    if not f then return nil end
    if cell ~= "" then
      local n = tonumber(cell)
      if not n then return nil end
      row[f] = n
    end
  end
  if i ~= #fields() then return nil end
  return id, row
end

-- pokeemerald/src/battle_controllers.c:397
function HostRules.block(version)
  local Moves = require("src.core.game3.battle.moves")
  local rom = Moves.romRows() or {}
  local rows = {}
  for _, id in ipairs(sortedIds(rom)) do
    if type(rom[id]) == "table" then rows[#rows + 1] = HostRules.encodeRow(id, rom[id]) end
  end
  return {
    version = version,
    rules = Fingerprint.rulesGen3(version),
    moves = Fingerprint.movesGen3Of(rom),
    rows = rows,
  }
end

function HostRules.decode(block, announced)
  if type(block) ~= "table" or type(block.rows) ~= "table" then return nil, "host_rules_missing" end
  local version = block.version
  local Profile = require("src.core.game3.profile")
  if type(version) ~= "string" or not Profile.isGame3Version(version) then return nil, "host_rules_version" end
  local okR, rules = pcall(Fingerprint.rulesGen3, version)
  if not okR or rules ~= block.rules then return nil, "host_rules_mismatch" end
  if #block.rows > HostRules.MAX_ROWS then return nil, "host_rules_rows" end
  local map = {}
  for _, text in ipairs(block.rows) do
    local id, row = HostRules.decodeRow(text)
    if not id or map[id] then return nil, "host_rules_rows" end
    map[id] = row
  end
  local digest = Fingerprint.movesGen3Of(map)
  if digest ~= block.moves then return nil, "host_rules_rows" end
  if announced ~= nil and announced ~= digest then return nil, "host_rules_rows" end
  return { version = version, rows = map }
end

function HostRules.apply(decoded)
  local Moves = require("src.core.game3.battle.moves")
  Moves.setLinkRows(decoded and decoded.rows or nil)
end

function HostRules.clear()
  local Moves = package.loaded["src.core.game3.battle.moves"]
  if Moves and Moves.setLinkRows then Moves.setLinkRows(nil) end
end

return HostRules
