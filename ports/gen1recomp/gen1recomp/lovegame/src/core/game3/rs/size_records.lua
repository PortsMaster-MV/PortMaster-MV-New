local bit = require("bit")
local M = {}

M.TABLE = {
  {290, 1, 0}, {300, 1, 10}, {400, 2, 110}, {500, 4, 310},
  {600, 20, 710}, {700, 50, 2710}, {800, 100, 7710}, {900, 150, 17710},
  {1000, 150, 32710}, {1100, 100, 47710}, {1200, 50, 57710}, {1300, 20, 62710},
  {1400, 5, 64710}, {1500, 2, 65210}, {1600, 1, 65410}, {1700, 1, 65510},
}

function M.hash(mon)
  local ivs = mon.ivs or {}
  local function iv(name, slot) return math.floor(tonumber(ivs[name] or ivs[slot]) or 0) % 16 end
  local pid = math.floor(tonumber(mon.personality) or 0) % 65536
  local hi = bit.bxor(bit.bxor(iv("atk", 2), iv("def", 3)) * iv("hp", 1), pid % 256)
  local lo = bit.bxor(bit.bxor(iv("spa", 5), iv("spd", 6)) * iv("spe", 4), math.floor(pid / 256))
  return hi * 256 + lo
end

function M.tableIndex(hash)
  hash = math.floor(tonumber(hash) or 0) % 65536
  for i = 1, 14 do if hash < M.TABLE[i + 1][3] then return i - 1 end end
  return 15
end

function M.sizeFromHeight(height, hash)
  hash = math.floor(tonumber(hash) or 0) % 65536
  local row = M.TABLE[M.tableIndex(hash) + 1]
  local scale = row[1] + math.floor((hash - row[3]) / row[2])
  return math.floor(height * scale / 10)
end

function M.size(species, hash)
  local entry = assert(require("src.core.game3.pokemon").dexEntry(species), "native RS dex height missing")
  return M.sizeFromHeight(assert(entry.height, "native RS dex entry has no height"), hash)
end

function M.format(size)
  local inchesTenths = math.floor((size * 10) / (2.54 * 10))
  return string.format("%d.%d", math.floor(inchesTenths / 10), inchesTenths % 10)
end

function M.compare(session, species, record, slot)
  if slot == 255 then return 0, record end
  local mon = session and session.party and session.party[slot + 1]
  local Pokemon = require("src.core.game3.pokemon")
  if not mon or Pokemon.isEgg(mon) or Pokemon.speciesOf(mon) ~= species then return 1, record end
  local hash = M.hash(mon)
  local size = M.size(species, hash)
  if size <= M.size(species, record) then return 2, record, size end
  return 3, hash, size
end

return M
