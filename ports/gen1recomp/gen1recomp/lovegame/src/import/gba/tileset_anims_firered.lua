local M = {}

local TILE_BYTES = 32

-- pokefirered/src/tileset_anims.c:223
M.COUNTER_MAX = 640

M.KINDS = { "water", "sand", "flower" }

M.TILES = {
  water = { tile = 416, count = 48 },
  sand = { tile = 464, count = 18 },
  flower = { tile = 508, count = 4 },
}

M.SCHEDULE = {
  sand = { period = 8, phase = 0, frames = 8 },
  water = { period = 16, phase = 1, frames = 8 },
  flower = { period = 16, phase = 2, frames = 5 },
}

M.DEFAULT_FRAMES = {
  flower = {
    base = 0x3A73E0,
    stride = 0x80,
    count = 5,
    bytes = 4 * TILE_BYTES,
  },
  water = {
    base = 0x3A7674,
    stride = 0x600,
    count = 8,
    bytes = 48 * TILE_BYTES,
  },
  sand = {
    base = 0x3AA674,
    stride = 0x240,
    count = 8,
    bytes = 18 * TILE_BYTES,
  },
}

return M
