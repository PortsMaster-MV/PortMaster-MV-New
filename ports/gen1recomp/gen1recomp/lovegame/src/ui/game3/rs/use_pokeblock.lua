local Base = require("src.ui.game3.rse.use_pokeblock")
local Text = require("src.core.game3.rom_text")
local Kit = require("src.ui.game3.rse.scene_kit")
local Gfx = require("src.ui.game3.rse.pokeblock_gfx")
local Font = require("src.ui.game3.frlg_font")
local Chrome = require("src.ui.game3.chrome")
local Graph = require("src.ui.game3.rse.condition_graph")
local UI = {}

-- use_pokeblock.c:44
UI.TEXT_ALIASES = {
  gText_GetsAPokeBlockQuestion = "gOtherText_GetsAPokeBlock",
  gText_WontEatAnymore = "gOtherText_WontEat",
  gText_WasEnhanced = "gOtherText_WasEnhanced",
  gText_NothingChanged = "gOtherText_NothingChanged",
  gText_Coolness = "OtherText_Coolness", gText_Toughness = "OtherText_Toughness",
  gText_Smartness = "OtherText_Smartness", gText_Cuteness = "OtherText_Cuteness",
  gText_Beauty3 = "OtherText_Beauty",
  gText_Var1AteTheVar2 = "gContestStatsText_NormallyAte",
  gText_Var1HappilyAteVar2 = "gContestStatsText_HappilyAte",
  gText_Var1DisdainfullyAteVar2 = "gContestStatsText_DisdainfullyAte",
}

local function layers(st, m, gfx)
  if st.rsLayers then return st.rsLayers end
  local map, patch = gfx:map("graph"), gfx:map("nature_win")
  for y = 0, 3 do for x = 0, 11 do map[(13 + y) * 32 + x] = patch[y * 12 + x] end end
  local graph = gfx:renderMap(map, "graph", Gfx.palette(m.palettes.graph, {}, 2),
    {rows = 32, tileBase = m.graphTileBase})
  local frame = gfx:renderMap(gfx:map("mon_frame"), "mon_frame", Gfx.palette(m.palettes.mon_frame, {}, 13),
    {rows = 32, tileBase = m.monFrameTileBase})
  local data = gfx:renderMap(gfx:map("graph_data"), "graph", Gfx.palette(m.palettes.graph_data, {}, 3),
    {rows = 32, tileBase = m.graphTileBase})
  local shifted = love.graphics.newCanvas(256, 256)
  love.graphics.push("all")
  love.graphics.setCanvas(shifted); love.graphics.clear(0, 0, 0, 0)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(data, 0, -6); love.graphics.draw(data, 0, 250)
  love.graphics.pop()
  st.rsLayers = {graph = graph, frame = frame, data = shifted}
  return st.rsLayers
end

-- use_pokeblock.c:281
function UI.draw(st, host)
  local gfx = Gfx.of("rse/pokeblock")
  local m, L = gfx:manifest(), nil
  L = layers(st, m, gfx)
  love.graphics.setColor(0, 0, 0, 1); love.graphics.rectangle("fill", 0, 0, 240, 160)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(L.graph, 0, -6)
  love.graphics.push("all"); love.graphics.setScissor(0, 50, 240, 65)
  st.graph:draw(L.data, 11, 4); love.graphics.pop()
  love.graphics.draw(L.frame, 0, -40)
  host.drawIcons()
  if st.monPic and not host.isCancel(st.sel) then
    local w, h = st.monPic:getDimensions()
    love.graphics.draw(st.monPic, 38 + st.monX - w / 2, 64 - h / 2)
  end
  local title = assert(Kit.manifest("rse/pokenav").leftHeaders.condition, "native RS Condition header missing")
  local image = assert(Kit.image(title.png))
  local iw, ih = image:getDimensions()
  for i, t in ipairs(st.titles) do
    local r = title.rects[i]
    local q = love.graphics.newQuad(r.x, r.y, r.w, r.h, iw, ih)
    love.graphics.draw(image, q, t.x - r.w / 2, 17 - r.h / 2)
  end
  local function colors(fg, shadow)
    return {fg = Gfx.color(m.palettes.condition_text[fg + 1]),
      shadow = Gfx.color(m.palettes.condition_text[shadow + 1]), bg = {0, 0, 0, 0}}
  end
  local function print(text, x, y, c)
    Font.draw(text, x, y, {font = "native_3", colors = c, maxWidth = 240 - x})
  end
  if st.nameInfo then
    local n = st.nameInfo
    print(n.name, 104, 2, colors(8, 9))
    if n.gender == "M" then print("♂", 167, 2, colors(4, 5))
    elseif n.gender == "F" then print("♀", 167, 2, colors(6, 7)) end
    print("/", 174, 2, colors(8, 9))
    print(n.level, 181, 2, colors(8, 9))
  end
  if st.natureText then print(st.natureText, 1, 106, colors(1, 5)) end
  if st.upDown then
    local img = host.sprite("updown", 0, 32, 16, m.palettes.updown)
    for _, s in ipairs(st.upDown) do love.graphics.draw(img, s.x - 16, s.y + s.y2 - 8) end
  end
  if st.sparkles then
    local frames = {}
    for f = 0, Graph.Sparkles.FRAMES - 1 do
      frames[f] = host.sprite("sparkle", f * 4, 16, 16, m.palettes.sparkle)
    end
    st.sparkles:draw(nil, frames, 38 + st.monX, 64)
  end
  local menu = Kit.messageColors("std_menu", 2, 16, 9)
  if st.message then
    Chrome.stdFrame(1, 17, 28, 2)
    print(st.message, 8, 136, menu)
  end
  if st.yesNo then
    Chrome.stdFrame(24, 11, 5, 4)
    print(Text.plain("OtherText_Yes"), 192, 88, menu)
    print(Text.plain("OtherText_No"), 192, 104, menu)
    require("src.ui.game3.rs.menu_cursor").draw(192, 88 + st.yesNo.cursor * 16, 40)
  end
  if st.fade > 0 then
    love.graphics.setColor(0, 0, 0, st.fade / 16); love.graphics.rectangle("fill", 0, 0, 240, 160)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

function UI.show(opts)
  opts = opts or {}
  assert(require("src.ui.game3.rse.pokeblock_gfx").of("rse/pokeblock"):manifest().assetLayout == "rs",
    "native RS Pokeblock pack required")
  -- pokenav.c:4855
  opts.levelText = function(level) return "{LV}" .. tostring(level) end
  opts.natureText = function(mon)
    return Text.plain("gOtherText_Nature2") .. Text.at("gNatureNames", require("src.core.game3.rse.pokeblock").natureOf(mon))
  end
  opts.draw = UI.draw
  return Base.show(opts)
end
function UI.reset() return Base.reset() end
function UI.isOpen() return Base.isOpen and Base.isOpen() or Base.open end
return UI
