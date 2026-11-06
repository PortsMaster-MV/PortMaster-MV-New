-- In-battle HUD tiles, shared by the battle screen and the status
-- screen: pokered overlays the $62-$7F font area with the HP bar /
-- status sheet (font_battle_extra -> $62) and the HUD line tiles
-- (battle_hud_1 -> $6D, battle_hud_2+3 -> $73).
--
-- The two screens do NOT use the same overlay: the status screen scatters
-- hud_2 and hud_3 instead of copying them contiguously, which is what keeps
-- its № and <ID> glyphs alive.  HudTiles.tile draws the battle layout,
-- HudTiles.statusTile the status one -- see STATUS_PAGES below. #280

local Assets = require("src.render.Assets")

local HudTiles = {}

-- The four HUD sheets are glyph pages like any other, so they resolve
-- through the font registry: mod.content.font:register("battle_hud_1",
-- { image = ..., base = 0x6D }) reskins the HP bar.  These are the
-- vanilla pages the importer's cache carries, in the order the asm
-- overlays them ($6D lands on top of font_battle_extra's tail).
local PAGES = {
  { id = "font_battle_extra",
    image = "assets/generated/battle/font_battle_extra.png", base = 0x62 },
  { id = "battle_hud_1",
    image = "assets/generated/battle/battle_hud_1.png", base = 0x6D },
  { id = "battle_hud_2",
    image = "assets/generated/battle/battle_hud_2.png", base = 0x73 },
  { id = "battle_hud_3",
    image = "assets/generated/battle/battle_hud_3.png", base = 0x76 },
}

-- The STATUS SCREEN overlays the SAME sheets differently, and the layout
-- above would break it: engine/pokemon/status_screen.asm:86-97 copies 3
-- tiles of hud_1 to $6D, ONE tile of hud_2 to $78 and 2 tiles of hud_3 to
-- $76, which leaves $70/$73/$74 as font_battle_extra's <to>, <ID> and № --
-- the glyphs the screen prints "№." and "<ID>№/" from
-- (constants/charmap.asm:69-73).  The battle overlay instead copies
-- hud_2+hud_3 contiguously over $73-$78 (engine/battle/core.asm:6520/6532),
-- burying № under a line tile, so the status screen needs its own table.
-- The line glyphs land identically either way -- $76 ─, $77 ┘, $6F the
-- halfarrow -- only the vertical bar moves ($73 in battle, $78 here). #280
local STATUS_PAGES = {
  { id = "font_battle_extra",
    image = "assets/generated/battle/font_battle_extra.png", base = 0x62 },
  { id = "battle_hud_1",
    image = "assets/generated/battle/battle_hud_1.png", base = 0x6D },
  { id = "battle_hud_3",
    image = "assets/generated/battle/battle_hud_3.png", base = 0x76, count = 2 },
  { id = "battle_hud_2",
    image = "assets/generated/battle/battle_hud_2.png", base = 0x78, count = 1 },
}

-- engine/menus/naming_screen.asm:93
local NAMING_PAGES = {
  { id = "font_battle_extra",
    image = "assets/generated/battle/font_battle_extra.png", base = 0x62 },
}

local tiles, statusTiles, namingTiles

-- Build one code -> {img, quad} map from a page list.  `count` caps a page
-- at the number of tiles the asm actually copies (the extracted sheets all
-- carry 3 tiles; the status overlay uses fewer).  A mod's registered page
-- swaps the image in either table, but only the battle table honors its
-- `base`: the status layout is the asm's own placement, and sliding hud_2
-- there would bury № again.
local function build(pages, fixedBase)
  local out = {}
  local registered = require("src.core.Data").font
  registered = registered and registered.pages or nil
  for _, page in ipairs(pages) do
    local override = registered and registered[page.id]
    local path, base = page.image, page.base
    if override and override.image then path = override.image end
    if not fixedBase and override and override.base then base = override.base end
    local ok, img = pcall(Assets.image, path)
    if ok then
      local iw, ih = img:getDimensions()
      local per = iw / 8
      local count = page.count or per * (ih / 8)
      for i = 0, count - 1 do
        out[base + i] = {
          img = img,
          quad = love.graphics.newQuad((i % per) * 8,
                                       math.floor(i / per) * 8, 8, 8, iw, ih),
        }
      end
    end
  end
  return out
end

local function put(t, x, y, tint)
  if not t then return end
  local r, g, b, a = love.graphics.getColor()
  if tint then
    love.graphics.setColor(tint)
  else
    love.graphics.setColor(1, 1, 1, 1)
  end
  love.graphics.draw(t.img, t.quad, x, y)
  love.graphics.setColor(r, g, b, a)
end

function HudTiles.tile(code, x, y, tint)
  if not tiles then tiles = build(PAGES) end
  put(tiles[code], x, y, tint)
end

-- The same sheets under the status screen's overlay (STATUS_PAGES).  The HP
-- bar codes $62-$6D are identical in both layouts, so drawHPBar below keeps
-- using the battle table. #280
function HudTiles.statusTile(code, x, y, tint)
  if not statusTiles then statusTiles = build(STATUS_PAGES, true) end
  put(statusTiles[code], x, y, tint)
end

-- engine/menus/naming_screen.asm:93
function HudTiles.namingTile(code, x, y, tint)
  if not namingTiles then namingTiles = build(NAMING_PAGES, true) end
  put(namingTiles[code], x, y, tint)
end

-- lazy: the next tile() rebuilds every page from the search path
function HudTiles.invalidate()
  tiles = nil
  statusTiles = nil
  namingTiles = nil
end

Assets.register(HudTiles.invalidate)

-- The bar's right-end tile follows wHPBarType (DrawHPBar's "Right"
-- branch): only type 1 -- the player's in-battle bar and the status
-- screen -- gets the double-bar $6D; the enemy bar (0) and the party
-- menu (2) close with the near-blank $6C nub.
function HudTiles.capTile(barType)
  return barType == 1 and 0x6D or 0x6C
end

-- Tile HP bar (home/pokemon.asm DrawHPBar): "HP" ($71) + ":[" ($62),
-- six 8px segments ($63 empty, +n partial, $6B full), then the
-- wHPBarType right cap.  A nonzero HP always shows at least a
-- one-pixel sliver.  The fill is tinted with the SGB bar palettes at
-- GetHealthBarColor's thresholds (>= 27 px green, >= 10 yellow, else
-- red).
--
-- segments: how many 8px cells the bar spans (6, the hardware width,
-- unless a caller asks for more -- the widescreen battle layout has room
-- for a longer bar in the same tiles).  The color thresholds scale with
-- it so a wider bar turns yellow and red at the same fractions of full.
--
-- grayFill (#229): when the caller will colorize this bar with an SGB
-- region palette (BattleState's zone pass, BATTLE_ZONES pal 0/1 =
-- GetHealthBarColor), leave the fill as its raw DMG shade-2 gray and skip
-- the per-pixel tint -- the DMG hardware bar is ONE gray shade recolored by
-- the region palette (engine/gfx/palettes.asm SetPal_Battle,
-- data/sgb/sgb_packets.asm BlkPacket_Battle), never a per-pixel repaint.
-- Tinting first would double-apply the color: GREENBAR's fill {0,189,0} has
-- red channel 0, so the tint zeroes the whole bar's red and the zone's
-- red-channel-keyed shade shader then maps every pixel to color 3 = black.
--
-- pixels: an explicit 0..48 bar length on GetHPBarLength's scale, for a
-- caller that is animating the bar between two HP values
-- (UpdateHPBar_AnimateHPBar); it scales with `segments` like the color
-- thresholds do.  Without it the length comes from mon.hp as before.
-- The fill tint for a bar colour, kept per colour table (the bar palettes
-- are a handful of fixed tables) and rebuilt if its values ever differ.
-- put() only reads it.
local fillTints = setmetatable({}, { __mode = "k" })
local function fillTint(c)
  local t = fillTints[c]
  if t and t.r == c[1] and t.g == c[2] and t.b == c[3] then return t end
  t = { math.min(1, c[1] / 170), math.min(1, c[2] / 170),
        math.min(1, c[3] / 170), 1, r = c[1], g = c[2], b = c[3] }
  fillTints[c] = t
  return t
end

function HudTiles.drawHPBar(data, tx, ty, mon, barType, grayFill, segments, pixels)
  local x, y = tx * 8, ty * 8
  segments = math.max(1, math.floor(segments or 6))
  HudTiles.tile(0x71, x, y)
  HudTiles.tile(0x62, x + 8, y)
  local px = 0
  if pixels then
    px = math.max(0, math.floor(pixels * segments / 6))
  elseif mon.stats.hp > 0 and mon.hp > 0 then
    px = math.max(1, math.floor(mon.hp * segments * 8 / mon.stats.hp))
  end
  local tint
  if not grayFill then
    local PaletteFX = require("src.render.PaletteFX")
    local green = math.ceil(27 * segments / 6)
    local yellow = math.ceil(10 * segments / 6)
    local name = px >= green and "GREENBAR"
                 or px >= yellow and "YELLOWBAR" or "REDBAR"
    local colors = PaletteFX.pal(data, name)
    if colors then
      local c = colors[3] -- GB color 2 is the fill shade
      -- the fill pixels are the 2/3-gray shade; divide so they land on
      -- the palette color exactly (the black outline stays black)
      tint = fillTint(c)
    end
  end
  for i = 0, segments - 1 do
    local seg = math.min(8, math.max(0, px - i * 8))
    HudTiles.tile(seg >= 8 and 0x6B or 0x63 + seg, x + 16 + i * 8, y, tint)
  end
  HudTiles.tile(HudTiles.capTile(barType), x + 16 + segments * 8, y)
end

return HudTiles
