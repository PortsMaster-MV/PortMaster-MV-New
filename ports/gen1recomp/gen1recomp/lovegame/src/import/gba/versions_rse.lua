local Syms = require("src.import.gba.syms")

local VersionsRse = {}

VersionsRse.FAMILY = "rse"

-- pokeemerald/include/fieldmap.h:4
VersionsRse.FIELDMAP = {
  NUM_TILES_IN_PRIMARY = 512,
  NUM_TILES_TOTAL = 1024,
  NUM_METATILES_IN_PRIMARY = 512,
  NUM_METATILES_TOTAL = 1024,
  NUM_PALS_IN_PRIMARY = 6,
  NUM_PALS_TOTAL = 13,
  MAX_MAP_DATA_SIZE = 10240,
  NUM_TILES_PER_METATILE = 8,
  METATILE_ATTR_BYTES = 2,
}

function VersionsRse.new(game, build)
  local S = Syms.of(build or game)
  local V = {}

  V.GAME = game
  V.BUILD = build or game
  V.FAMILY = VersionsRse.FAMILY
  V.FIELDMAP = VersionsRse.FIELDMAP
  V.ROM_SIZE = 16777216
  V.SYMS = S
  V.BY_SHA1 = {}
  V.BY_MD5 = {}

  function V.sym(name) return S.off(name) end

  function V.count(name, stride) return S.count(name, stride) end

  function V.gbaToFile(addr)
    addr = tonumber(addr)
    if not addr or addr < 0x08000000 or addr >= 0x0A000000 then return nil end
    return addr - 0x08000000
  end

  function V.normalizeSha1(sha1)
    if type(sha1) ~= "string" then return nil end
    return (sha1:lower():gsub("%s+", ""))
  end
  V.normalizeMd5 = V.normalizeSha1

  function V.identitySha1(hash)
    local key = V.normalizeSha1(hash)
    if not key or key == "" then return nil end
    return key
  end

  function V.lookup(sha1)
    local key = V.identitySha1(sha1)
    if not key then return nil, "missing sha1" end
    local row = V.BY_SHA1[key]
    if not row then return nil, "unsupported or unknown " .. game .. " dump SHA-1" end
    return row
  end
  V.lookupSha1 = V.lookup

  function V.address(base) return base end

  function V.select(identity)
    if identity == game then return end
    local key = V.identitySha1(identity)
    if not (key and V.BY_SHA1[key]) then
      error("versions(" .. game .. "): unknown identity " .. tostring(identity), 2)
    end
  end

  function V.mapIdFor(group, num)
    return require("src.import.gba.map_catalog").mapIdFor(group, num)
  end
  V.frMapFor = V.mapIdFor

  function V.seviiMapFor() return nil end

  function V.game(id)
    return require("src.import.gba.versions_game").game(id)
  end

  return V
end

return VersionsRse
