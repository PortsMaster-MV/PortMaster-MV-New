local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local M = {SUB = "rse/party", FILES = {"bg.png", "misc.gfx", "held_items.png", "status.png", "order.png", "order.gfx",
  "hp_green.png", "hp_yellow.png", "hp_red.png", "hp_caps.png"}}
local N = "party_menu.o:"
local panels = {{"large", "gUnknown_083769D8", 11, 7}, {"small", "gUnknown_08376A25", 19, 3},
  {"empty", "gUnknown_08376A5E", 19, 3}}
for _, p in ipairs(panels) do for bank = 3, 10 do M.FILES[#M.FILES + 1] = p[1] .. "_" .. bank .. ".png" end end
M.REQUIRED = K.required(M.SUB, M.FILES)
local function rows(c, name, count, stride, fields, recordSize)
  local out, off = {}, c:off(N .. name)
  recordSize = recordSize or fields
  assert(c.S.size(N .. name) == count * stride * recordSize, "native party coordinate table size: " .. name)
  for r = 0, count - 1 do
    local row = {}
    for j = 0, stride - 1 do
      local a = {}; for k = 0, fields - 1 do a[k + 1] = c:u8(off + (r * stride + j) * recordSize + k) end
      row[j + 1] = a
    end
    out[r + 1] = row
  end
  return out
end
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local man = {screen = "party", coverage = "native_panel_tiles_palettes_coordinates_and_icons", panels = {}, sprites = {}, palettes = {}, prompts = {}}
  local gfx = c:lz("gPartyMenuMisc_Gfx")
  man.gfx = c:write("misc.gfx", gfx)
  -- party_menu.c:2198
  local pal = c:pal("gPartyMenuMisc_Pal", 176, nil, 0, true)
  pal[0] = 0x7FFF
  c:pal("gFontDefaultPalette", 16, pal, 240)
  c:pal("gStatusPal_Icons", 16, pal, 176, true)
  man.palettes.bg = K.palList(pal, 0, 256)
  local idx, w, h = K.bakeText(gfx, c:lz("gPartyMenuMisc_Tilemap"), 30, 20)
  man.bg = c:layer({key = "bg", opaque = true}, idx, w, h, pal)
  man.bg.backdrop = pal[0]
  for _, p in ipairs(panels) do
    local bytes = c:raw(N .. p[2])
    assert(#bytes == p[3] * p[4], "native party panel table size")
    local entry = {w = p[3] * 8, h = p[4] * 8, tiles = {}, variants = {}}
    for i = 1, #bytes do entry.tiles[i] = bytes:byte(i) end
    for bank = 3, 10 do
      local map = {}; for i = 1, #bytes do map[i] = string.char(bytes:byte(i), bank * 16) end
      local pi = K.bakeText(gfx, table.concat(map), p[3], p[4], {linear = true, mapWidth = p[3]})
      entry.variants[bank] = c:png(p[1] .. "_" .. bank .. ".png", entry.w, entry.h, pi, pal, true)
    end
    man.panels[p[1]] = entry
  end
  man.panelPalettes = {normal = 3, alternate = 4, fainted = 5, switching = 6, selectedOffset = 4}
  local hp = c:lz("gPartyMenuHpBar_Gfx")
  local hpPals = {}; for _, p in ipairs({{"green", 4}, {"yellow", 5}, {"red", 6}, {"caps", 3}}) do hpPals[#hpPals + 1] = {name = p[1], pal = {}}
    for i = 0, 15 do hpPals[#hpPals].pal[i] = pal[p[2] * 16 + i] end end
  man.hpTiles = c:strip("hp", hp, 8, 8, #hp / 32, K.variants(hpPals))
  local order = c:lz("gPartyMenuOrderText_Gfx")
  man.orderGfx = c:write("order.gfx", order)
  local orderIdx, ow, oh = K.bakeText(order, c:raw("gUnknown_08E9A300"), 32, math.floor(c.S.size("gUnknown_08E9A300") / 64))
  man.order = c:layer({key = "order"}, orderIdx, ow, oh, pal)
  man.sprites.status = c:strip("status", c:lz("gStatusGfx_Icons"), 32, 8, 7, c:pal("gStatusPal_Icons", 16, nil, nil, true))
  man.sprites.heldItems = c:spriteFrames("held_items", c:raw(N .. "MenuGfx_HoldIcons"), c:readTemplate(N .. "gSpriteTemplate_837660C"), c:pal(N .. "MenuPal_HoldIcons", 16))
  man.coordinates = {monIcons = rows(c, "gUnknown_08376678", 8, 6, 2, 4), text = rows(c, "gUnknown_08376738", 12, 6, 2, 4),
    heldItems = rows(c, "gUnknown_083768B8", 3, 8, 2, 4), panels = rows(c, "gUnknown_083769A8", 2, 6, 2),
    linkPanels = rows(c, "gUnknown_083769C0", 2, 6, 2), windows = rows(c, "gUnknown_08376948", 2, 6, 4),
    moveWindows = rows(c, "gUnknown_08376978", 2, 6, 4), hpBars = {}}
  man.coordinates.cursor = man.coordinates.heldItems
  man.cursor = {visible = false}
  man.heldItemOffset = {4, 10}
  man.coordinates.descriptors = {}
  local descriptor = c:off(N .. "gUnknown_08376918")
  for layout = 0, 1 do
    local row = {}
    for i = 0, 5 do
      local tile = (c:u32(descriptor + (layout * 6 + i) * 4) - 0x0600F000) / 2
      row[i + 1] = {tile % 32, math.floor(tile / 32)}
    end
    man.coordinates.descriptors[layout + 1] = row
  end
  man.textSettings = {}
  local tso = c:off(N .. "PartyMonTextSettings")
  for layout = 0, 3 do
    local settings = {}
    for slot = 0, 5 do
      local o = tso + (layout * 6 + slot) * 8
      local row = {x = c:u8(o) * 8, y = c:u8(o + 1) * 8, oam = {}}
      local p = assert(c:ptr(o + 4))
      for i = 0, 15 do
        if c:u16(p + i * 6) == 65535 then break end
        row.oam[#row.oam + 1] = {c:u16(p + i * 6), c:u16(p + i * 6 + 2), c:u16(p + i * 6 + 4)}
      end
      settings[slot + 1] = row
    end
    man.textSettings[layout + 1] = settings
  end
  man.windows = {}
  for key, name in pairs({bg = "gWindowTemplate_81E6C90", monText = "gWindowTemplate_81E6CAC", menu = "gWindowTemplate_81E6CC8"}) do
    local o, win = c:off(name), {}
    for i, field in ipairs({"bgNum", "charBaseBlock", "screenBaseBlock", "priority", "paletteNum", "foregroundColor", "backgroundColor", "shadowColor",
      "fontNum", "textMode", "spacing", "tilemapLeft", "tilemapTop", "width", "height"}) do win[field] = c:u8(o + i - 1) end
    man.windows[key] = win
  end
  man.buttons = {confirm = {x = 24, y = 16, tiles = {0x2A,0x2B,0x2C,0x2D,0x2E,0x2F,0x3A,0x3B,0x3C,0x3D,0x3E,0x3F}},
    cancel = {x = 24, y = 18, tiles = {0x2A,0x0B,0x0C,0x0D,0x0E,0x2F,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F}}}
  man.monIconAnims = {}
  for i = 0, 4 do man.monIconAnims[i + 1] = c:readAnim(c:off("pokemon_icon.o:sAnim_" .. i)) end
  man.bgControls = {0x1E05, 0x703, 0xF08, 0x602}
  man.bgOffsets = {{0,0}, {0,0}, {0,0}, {0,-1}}
  local ho = c:off(N .. "gUnknown_08376858")
  for layout = 0, 3 do
    local row = {}; for i = 0, 5 do
      local p = c:u32(ho + (layout * 6 + i) * 4)
      local tile = (p - 0x0600F000) / 2
      row[i + 1] = {tile % 32, math.floor(tile / 32)}
    end
    man.coordinates.hpBars[layout + 1] = row
  end
  local po = c:off(N .. "PartyMenuPromptTexts")
  for i = 0, c.S.count(N .. "PartyMenuPromptTexts", 4) - 1 do man.prompts[i + 1] = A.text(c, assert(c:ptr(po + i * 4))) end
  man.nativeTiles = {hpBase = 256, orderBase = 268, statusBase = 396, statusPalette = 11,
    hpCaps = {0x3109, 0x310A, 0x310B}, promptX = 1, promptY = 17}
  return A.finish(c, man)
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
