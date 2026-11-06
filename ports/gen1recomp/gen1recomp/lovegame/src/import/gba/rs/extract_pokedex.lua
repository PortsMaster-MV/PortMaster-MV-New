local K = require("src.import.gba.rse.boot_gfx")
local A = require("src.import.gba.rs.assets")
local M = {SUB = "rse/pokedex"}
local N = "pokedex.o:"
local maps = {{"list", "gUnknown_08E96738"}, {"list_underlay", "gUnknown_08E9C6DC"},
  {"start_menu_main", "gPokedexStartMenuMain_Tilemap"}, {"start_menu_search", "gPokedexStartMenuSearchResults_Tilemap"},
  {"info", "gUnknown_08E96BD4"}, {"cry", N .. "gUnknown_0839F8A0"}, {"size", N .. "gUnknown_0839F988"},
  {"select_main", "gPokedexScreenSelectBarMain_Tilemap"}, {"select_sub", "gPokedexScreenSelectBarSubmenu_Tilemap"},
  {"search", "gPokedexMenuSearch_Tilemap"}}
M.FILES = {"menu.gfx", "interface.gfx", "search.gfx", "orders.lua"}
for _, m in ipairs(maps) do
  M.FILES[#M.FILES + 1] = m[1] .. ".map"
  for _, p in ipairs(m[1] == "search" and {"search"} or {"hoenn", "national", "searchResults"}) do M.FILES[#M.FILES + 1] = m[1] .. "_" .. p .. ".png" end
end
M.REQUIRED = K.required(M.SUB, M.FILES)
local function bytes(c, name, stride)
  local out, off = {}, c:off(name)
  for i = 0, c.S.count(name, stride or 1) - 1 do out[i + 1] = stride == 2 and c:u16(off + i * 2) or c:u8(off + i) end
  return out
end
local function options(c, name)
  local out, off = {}, c:off(N .. name)
  for i = 0, c.S.count(N .. name, 8) - 1 do
    local a, b = c:ptr(off + i * 8), c:ptr(off + i * 8 + 4)
    if not b then break end
    out[#out + 1] = {description = a and A.text(c, a) or "", title = A.text(c, b)}
  end
  return out
end
function M.run(rom, cache, opts)
  local c = A.context(rom, cache, opts, M.SUB)
  local man = {screen = "pokedex", coverage = "native_list_detail_search_backgrounds_and_search_tables", gfx = {}, maps = {}, layers = {}, palettes = {}}
  local pals = {hoenn = c:pal("gPokedexMenu_Pal", 96), national = c:pal(N .. "sNationalPokedexPalette", 96),
    searchResults = c:pal(N .. "sPokedexSearchPalette", 96), search = c:pal("gPokedexMenuSearch_Pal", 64)}
  for k, p in pairs(pals) do man.palettes[k] = K.palList(p, 0, k == "search" and 64 or 96) end
  local gs = {}
  for _, g in ipairs({{"menu", "gPokedexMenu_Gfx"}, {"interface", "gPokedexMenu2_Gfx"}, {"search", "gPokedexMenuSearch_Gfx"}}) do
    gs[g[1]] = c:lz(g[2]); man.gfx[g[1]] = {path = c:write(g[1] .. ".gfx", gs[g[1]]), bytes = #gs[g[1]]}
  end
  for _, m in ipairs(maps) do
    local map = c:lz(m[2]); man.maps[m[1]] = {path = c:write(m[1] .. ".map", map), entries = #map / 2}
    local h = math.min(32, math.floor(#map / 64))
    local idx, w, height = K.bakeText(m[1] == "search" and gs.search or gs.menu, map, 32, h)
    local variants = {}
    for _, p in ipairs(m[1] == "search" and {"search"} or {"hoenn", "national", "searchResults"}) do variants[#variants + 1] = {name = p, pal = pals[p]} end
    man.layers[m[1]] = c:layer({key = m[1], variants = variants}, idx, w, height, pals.hoenn)
  end
  local search = {modes = options(c, "sDexModeOptions"), orders = options(c, "sDexOrderOptions"), names = options(c, "sDexSearchNameOptions"),
    colors = options(c, "sDexSearchColorOptions"), types = options(c, "sDexSearchTypeOptions"), typeIds = bytes(c, N .. "sDexSearchTypeIds"),
    orderIds = bytes(c, N .. "sOrderOptions"), modeIds = bytes(c, N .. "sPokedexModes"), letterRanges = {}, topBar = {}, items = {}, movement = {}}
  local lo = c:off(N .. "sLetterSearchRanges")
  for i = 0, c.S.count(N .. "sLetterSearchRanges", 4) - 1 do search.letterRanges[i] = {c:u8(lo + i * 4), c:u8(lo + i * 4 + 1), c:u8(lo + i * 4 + 2), c:u8(lo + i * 4 + 3)} end
  local top = c:off(N .. "sSearchMenuTopBarItems")
  for i = 0, c.S.count(N .. "sSearchMenuTopBarItems", 8) - 1 do
    local o = top + i * 8
    search.topBar[i + 1] = {description = A.text(c, assert(c:ptr(o))), x = c:u8(o + 4), y = c:u8(o + 5), width = c:u8(o + 6)}
  end
  local io = c:off(N .. "sSearchMenuItems")
  for i = 0, c.S.count(N .. "sSearchMenuItems", 12) - 1 do
    local o = io + i * 12
    search.items[i + 1] = {description = A.text(c, assert(c:ptr(o))), titleX = c:u8(o + 4), titleY = c:u8(o + 5), titleWidth = c:u8(o + 6),
      selX = c:u8(o + 7), selY = c:u8(o + 8), selWidth = c:u8(o + 9)}
  end
  for _, k in ipairs({"SearchNatDex", "ShiftNatDex", "SearchHoennDex", "ShiftHoennDex"}) do
    local name, rows = N .. "sSearchMovementMap_" .. k, {}
    local o = c:off(name)
    for i = 0, c.S.count(name, 4) - 1 do rows[i + 1] = {c:u8(o + i * 4), c:u8(o + i * 4 + 1), c:u8(o + i * 4 + 2), c:u8(o + i * 4 + 3)} end
    search.movement[k] = rows
  end
  man.search = search
  man.scrollMonIncrements, man.scrollTimers = bytes(c, N .. "gUnknown_083A05EC"), bytes(c, N .. "gUnknown_083A05F1")
  require("src.import.gba.pokedex_chrome_extract").extractOrders(rom, cache, c.root)
  c.files[#c.files + 1] = "orders.lua"
  return A.finish(c, man)
end
function M.ready(cache, root) return A.ready(M.SUB, cache, root) end
return M
