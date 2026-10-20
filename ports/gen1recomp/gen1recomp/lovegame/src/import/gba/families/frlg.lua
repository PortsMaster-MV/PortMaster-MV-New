local F = {}

F.name = "frlg"

-- pokefirered/include/fieldmap.h:6
F.numPrimaryTiles = 640
F.numTilesTotal = 1024
F.numPrimaryMetatiles = 640
F.numMetatilesTotal = 1024
F.numPalsInPrimary = 7
F.numPalsTotal = 13
F.metatileBytes = 16

-- pokefirered/include/global.fieldmap.h:91
F.layoutSize = 28

-- pokefirered/include/global.fieldmap.h:80
F.tilesetOffsets = { tiles = 4, palettes = 8, metatiles = 12, callback = 16, attributes = 20 }

F.attrBytes = 4

F.cloneObjects = true

F.secretBaseBgKind = nil

F.hiddenItemBgKind = 7

F.encounterSource = "attr"

F.aliases = true

F.groupsModule = "src.import.gba.map_groups_firered"

-- pokefirered/include/constants/global.h:121
F.connDirs = { [1] = "south", [2] = "north", [3] = "west", [4] = "east", [5] = "dive", [6] = "emerge" }

function F.behaviorOf(w)
  return w % 512
end

function F.layerOf(w)
  return math.floor((tonumber(w) or 0) / 0x20000000) % 4
end

function F.encounterOf(w)
  return math.floor((tonumber(w) or 0) / 0x1000000) % 8
end

function F:borderDims(rom, layoutOff)
  return rom:get(layoutOff + 24) or 2, rom:get(layoutOff + 25) or 2
end

-- pokefirered/include/global.fieldmap.h:204
function F:decodeHeaderFlags(rom, headerOff, out)
  out.bikingAllowed = rom:get(headerOff + 24)
  local flags = rom:get(headerOff + 25) or 0
  out.allowEscaping = flags % 2
  out.allowRunning = math.floor(flags / 2) % 2
  out.showMapName = math.floor(flags / 4) % 64
  local floor = rom:get(headerOff + 26) or 0
  if floor >= 0x80 then floor = floor - 0x100 end
  out.floorNum = floor
  out.battleType = rom:get(headerOff + 27)
  return out
end

-- pokefirered/asm/macros/map.inc:109
function F:hiddenItem(rom, base)
  local info = rom:u16(base + 10)
  local quantity = math.floor(info / 256) % 128
  if quantity == 0 then quantity = 1 end
  return {
    item = rom:u16(base + 8),
    hiddenItemId = info % 256,
    quantity = quantity,
    underfoot = info >= 32768,
  }
end

function F:groups()
  return require(self.groupsModule)
end

function F.mapConstAt()
  return nil
end

function F.tilesetName()
  return nil
end

function F:uncompressedTileBytes(_, tilesOff, palsOff)
  if palsOff and tilesOff and palsOff > tilesOff then
    return palsOff - tilesOff
  end
  return nil
end

return F
