local Versions = require("src.import.gba.versions")
local AssetPack = require("src.import.gba.asset_pack")

local M = {}

M.FORMAT_VERSION = 1
M.LINK_SUB = "link"

M.PARTS = {
  "src.import.gba.berry_crush_extract",
  "src.import.gba.dodrio_extract",
  "src.import.gba.pokemon_jump_extract",
  "src.import.gba.mystery_gift_extract",
}

M.LINK_FILES = {
  "manifest.lua", "countdown_321.pal", "countdown_321.rgba",
  "minigame_countdown.pal", "minigame_countdown_numbers.rgba", "minigame_countdown_start.rgba",
  "minigame_digits.pal", "minigame_digits.rgba",
}

M.FILES = {
  berry_crush = {
    "bg.bin", "bg.rgba", "container_cap.bin", "container_cap.rgba", "core.pal", "crusher.4bpp",
    "crusher.pal", "crusher.rgba", "crusher_base.rgba", "crusher_top.bin", "crusher_top.rgba",
    "effect.pal", "impact.rgba", "manifest.lua", "sparkle.rgba", "tables.lua", "text_windows.bin",
    "text_windows.rgba", "timer.pal", "timer_digits.rgba",
  },
  dodrio_berry_picking = {
    "berries.pal", "berries.rgba", "bg.bin", "bg.pal", "bg.rgba", "cloud.pal", "cloud.rgba",
    "dodrio.pal", "dodrio.rgba", "dodrio_shiny.pal", "dodrio_shiny.rgba", "manifest.lua",
    "scenery.4bpp", "status.pal", "status.rgba", "tables.lua", "tree_border.4bpp",
    "tree_border_left.bin", "tree_border_left.rgba", "tree_border_right.bin", "tree_border_right.rgba",
  },
  pokemon_jump = {
    "bg.4bpp", "bg.bin", "bg.pal", "bg.rgba", "bonuses.4bpp", "bonuses.bin", "bonuses.rgba",
    "manifest.lua", "pal1.pal", "pal2.pal", "star.rgba", "tables.lua", "venusaur.4bpp",
    "venusaur.bin", "venusaur.rgba", "vine1.rgba", "vine1_pal2.rgba", "vine2.rgba", "vine2_pal2.rgba",
    "vine3.rgba", "vine3_pal2.rgba", "vine4.rgba", "vine4_pal2.rgba",
  },
  mystery_gift = {
    "manifest.lua", "border.pal", "border_tiles.rgba", "menu_bg.rgba", "stamp_shadow.pal",
  },
}
for i = 0, 7 do
  local mg = M.FILES.mystery_gift
  mg[#mg + 1] = "stamp_shadow_" .. i .. ".rgba"
  mg[#mg + 1] = "card_bg" .. i .. ".rgba"
  mg[#mg + 1] = "news_bg" .. i .. ".rgba"
end

M.REQUIRED = {}
for _, f in ipairs(M.LINK_FILES) do M.REQUIRED[#M.REQUIRED + 1] = M.LINK_SUB .. "/" .. f end
for _, sub in ipairs({ "berry_crush", "dodrio_berry_picking", "pokemon_jump", "mystery_gift" }) do
  for _, f in ipairs(M.FILES[sub]) do M.REQUIRED[#M.REQUIRED + 1] = sub .. "/" .. f end
end

local function bindSyms()
  local V = Versions.module()
  if rawget(V, "PJ_MONS") == nil then
    require("src.import.gba.rse.minigame_syms")(V)
  end
  return V
end

local function need(buf, n, what)
  if AssetPack.len(buf) < n then
    error(string.format("lmg: %s decompressed to %d bytes, want %d", what, AssetPack.len(buf), n))
  end
  return buf
end

local function sprite(key, fw, fh, frames, extra)
  local row = {
    file = key .. ".rgba", kind = "sprite", width = fw, height = fh * frames,
    frame_w = fw, frame_h = fh, frames = frames,
  }
  for k, v in pairs(extra or {}) do row[k] = v end
  return row
end

-- pokeemerald/src/minigame_countdown.c:376
local function linkArt(rom, cache, root, V)
  local dir = root .. "/" .. M.LINK_SUB
  local cdBank = AssetPack.banks(rom, V.MG_COUNTDOWN_PAL, 1)[0]
  local cd = need(AssetPack.lz(rom, V.MG_COUNTDOWN_GFX), 0xE00, "minigame countdown")
  cache:write(dir .. "/minigame_countdown_numbers.rgba", AssetPack.strip(cd, cdBank, 0, 16, 32, 32, 3))
  cache:write(dir .. "/minigame_countdown_start.rgba", AssetPack.frames(cd, cdBank,
    { { tile = 48 }, { tile = 80 } }, 64, 32))
  cache:write(dir .. "/minigame_countdown.pal", AssetPack.palRgb({ [0] = cdBank }, 0, 1))

  local stBank = AssetPack.banks(rom, V.MG_321START_PAL, 1)[0]
  local st = need(AssetPack.lz(rom, V.MG_321START_GFX), 0xC00, "321start")
  cache:write(dir .. "/countdown_321.rgba", AssetPack.strip(st, stBank, 0, 16, 32, 32, 6))
  cache:write(dir .. "/countdown_321.pal", AssetPack.palRgb({ [0] = stBank }, 0, 1))

  local dgBank = AssetPack.banks(rom, V.MG_DIGITS_PAL, 1)[0]
  local dg = need(AssetPack.lz(rom, V.MG_DIGITS_GFX), 11 * 32, "minigame digits")
  cache:write(dir .. "/minigame_digits.rgba", AssetPack.strip(dg, dgBank, 0, 1, 8, 8, 11))
  cache:write(dir .. "/minigame_digits.pal", AssetPack.palRgb({ [0] = dgBank }, 0, 1))

  cache:write(dir .. "/manifest.lua", AssetPack.serialize({
    format_version = M.FORMAT_VERSION,
    minigame_countdown_numbers = sprite("minigame_countdown_numbers", 32, 32, 3, {
      order = { 3, 2, 1 }, palette = "minigame_countdown.pal",
    }),
    minigame_countdown_start = sprite("minigame_countdown_start", 64, 32, 2, {
      order = { "left", "right" }, palette = "minigame_countdown.pal",
    }),
    countdown_321 = sprite("countdown_321", 32, 32, 6, {
      order = { "three", "two", "one", "start_mid", "start_left", "start_right" }, palette = "countdown_321.pal",
    }),
    minigame_digits = sprite("minigame_digits", 8, 8, 11, { palette = "minigame_digits.pal" }),
  }))
end

function M.run(rom, cache, opts)
  opts = opts or {}
  local root = opts.cacheRoot or AssetPack.defaultRoot()
  local V = bindSyms()
  linkArt(rom, cache, root, V)
  local out = { root = root }
  for _, name in ipairs(M.PARTS) do
    out[name] = require(name).run(rom, cache, { cacheRoot = root })
  end
  print(string.format("[lmg_extract] countdowns, digits, 3 minigames, mystery gift -> %s", root))
  return out
end

function M.ready(cache, cacheRoot)
  local root = cacheRoot or AssetPack.defaultRoot()
  local man = AssetPack.loadManifest(cache, root .. "/" .. M.LINK_SUB .. "/manifest.lua")
  if not man or man.format_version ~= M.FORMAT_VERSION or not man.minigame_digits then return false end
  for _, name in ipairs(M.PARTS) do
    if not require(name).ready(cache, root) then return false end
  end
  for _, rel in ipairs(M.REQUIRED) do
    if not cache:exists(root .. "/" .. rel) then return false end
  end
  return true
end

return M
