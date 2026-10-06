-- FRLG battler healthboxes via pret OAM semantics + interface element tiles.
-- CreateSprite centers; HP bar subsprites are offsets from that center
-- (AddSubspritesToOamBuffer undoes centerToCorner, then applies subsprite x/y).
--
-- Healthbox GFX bake placeholder "Lv" / "/" tiles; pret TextIntoHealthboxObject
-- overwrites them. We cream-fill those regions and print like UpdateNick /
-- UpdateLvl / UpdateHpTextInHealthbox.

local BattleChrome = require("src.ui.game3.battle_chrome")
local FrlgFont = require("src.ui.game3.frlg_font")
local State = require("src.core.game3.battle.state")
local RomText = require("src.core.game3.rom_text")

local Healthbox = {}

local function rs_layout()
  local ui = require("src.core.game3.profile").forSession().ui
  return ui and ui.healthbox and ui.healthbox.layout == "rs" and ui.healthbox or nil
end

-- pret InitBattlerHealthboxCoords (singles) — sprite CENTER of left half
Healthbox.ENEMY_CENTER = { x = 44, y = 30 }
Healthbox.PLAYER_CENTER = { x = 158, y = 88 }

-- pokefirered/src/battle_interface.c:726
Healthbox.CENTERS = {
  [false] = { [0] = Healthbox.PLAYER_CENTER, [1] = Healthbox.ENEMY_CENTER },
  [true] = {
    [0] = { x = 159, y = 75 },
    [1] = { x = 44, y = 19 },
    [2] = { x = 171, y = 100 },
    [3] = { x = 32, y = 44 },
  },
}

function Healthbox.center(st, id)
  id = tonumber(id) or 0
  local rs = st and st.double and rs_layout()
  if rs then return rs.doublesCenters[id] or rs.doublesCenters[id % 2] end
  local t = Healthbox.CENTERS[(st and st.double) and true or false]
  return t[id] or t[id % 2]
end

local function c5(v)
  return math.floor(v * 255 / 31 + 0.5) / 255
end

-- Cream fill matches healthbox pal index 2 (text bg).
-- pokefirered/src/battle_interface.c:2204
local CREAM = { c5(31), c5(31), c5(27), 1 }

-- Healthbox OBJ pal text colors (gBattleInterface_Healthbox_Pal).
-- Nick: fg=1 shadow=3; gender uses DYNAMIC_COLOR_2/1 (pal 11 / 10).
local HB_TEXT = {
  fg = { c5(8), c5(8), c5(8), 1 },
  shadow = { c5(27), c5(26), c5(22), 1 },
}
local HB_MALE = {
  fg = { 65 / 255, 205 / 255, 255 / 255, 1 },
  shadow = { 0 / 255, 98 / 255, 148 / 255, 1 },
}
local HB_FEMALE = {
  fg = { 255 / 255, 156 / 255, 148 / 255, 1 },
  shadow = { 156 / 255, 65 / 255, 57 / 255, 1 },
}

-- pokefirered/src/battle_interface.c:773
local PLAYER_LVL_X = 72
local ENEMY_LVL_X = 64

-- pret AddTextPrinterAndCreateWindowOnHealthbox(..., y=3) for nick / level.
local TEXT_Y = 3
-- pokefirered/src/battle_interface.c:813
local HP_TEXT_Y = 21
local HP_CUR_X = 60
local HP_MAX_X = 80
-- pokefirered/src/battle_interface.c:2221
local HP_WIN_X, HP_WIN_W, HP_WIN_H = 56, 40, 11

-- Baked placeholder ink + drop-shadow on healthbox sheets.
-- Shadow is pal index 3 ≈ (222,214,181). Do NOT rectangle-fill (eats top border).
local PLAYER_PLACEHOLDER_INK = {
  -- "Lv" fg (66,66,66)
  { 64, 10 }, { 64, 11 }, { 68, 11 }, { 70, 11 },
  { 64, 12 }, { 68, 12 }, { 70, 12 },
  { 64, 13 }, { 68, 13 }, { 70, 13 },
  { 64, 14 }, { 65, 14 }, { 66, 14 }, { 67, 14 }, { 69, 14 },
  -- "Lv" shadow
  { 65, 11 }, { 71, 11 }, { 65, 12 }, { 71, 12 }, { 65, 13 }, { 71, 13 },
  { 68, 14 }, { 70, 14 }, { 71, 14 },
  { 64, 15 }, { 65, 15 }, { 66, 15 }, { 67, 15 }, { 68, 15 }, { 69, 15 }, { 70, 15 },
}

local ENEMY_PLACEHOLDER_INK = {
  -- "Lv" fg
  { 56, 10 }, { 56, 11 }, { 60, 11 }, { 62, 11 },
  { 56, 12 }, { 60, 12 }, { 62, 12 },
  { 56, 13 }, { 60, 13 }, { 62, 13 },
  { 56, 14 }, { 57, 14 }, { 58, 14 }, { 59, 14 }, { 61, 14 },
  -- "Lv" shadow
  { 57, 11 }, { 63, 11 }, { 57, 12 }, { 63, 12 }, { 57, 13 }, { 63, 13 },
  { 60, 14 }, { 62, 14 }, { 63, 14 },
  { 56, 15 }, { 57, 15 }, { 58, 15 }, { 59, 15 }, { 60, 15 }, { 61, 15 }, { 62, 15 },
}

local function player_top_left(cx, cy)
  return cx - 32, cy - 16
end

local function enemy_top_left(cx, cy)
  return cx - 32, cy - 16
end

--- HP bar sprite center (SpriteCB_HealthBar).
local function hp_bar_center(side, hbCx, hbCy)
  if side == "player" then
    return hbCx + 16, hbCy
  end
  return hbCx + 8, hbCy
end

--- Subsprite 0 is at (−16, 0) from center → composite TL = (cx−16, cy).
local function hp_bar_top_left(barCx, barCy)
  return barCx - 16, barCy
end

local function hp_values(side, battler)
  local ok, Anim = pcall(require, "src.core.game3.battle.anim")
  if ok and Anim and Anim.displayHpRatio then
    local _, hp, maxHp = Anim.displayHpRatio(side, battler)
    return tonumber(hp) or 0, tonumber(maxHp) or 1
  end
  local mon = battler and battler.mon
  local hp = tonumber(mon and mon.hp) or 0
  local maxHp = tonumber(mon and mon.maxHp) or 1
  if maxHp < 1 then maxHp = 1 end
  return hp, maxHp
end

-- pokefirered/src/battle_interface.c:2050
local function display_hp_nums(side, battler)
  local hp, maxHp = hp_values(side, battler)
  return math.floor(hp), math.floor(maxHp)
end

-- One read-only FrlgFont opts table per colour set (FrlgFont never writes
-- to opts), so per-frame healthbox text does not allocate.
local _smallOpts = setmetatable({}, { __mode = "k" })
local function small_opts(colors)
  colors = colors or HB_TEXT
  local o = _smallOpts[colors]
  if not o then
    o = { small = true, colors = colors }
    _smallOpts[colors] = o
  end
  return o
end

local function erase_placeholder_ink(boxX, boxY, pts)
  if rs_layout() then return end
  love.graphics.setColor(CREAM)
  for i = 1, #pts do
    local p = pts[i]
    love.graphics.rectangle("fill", boxX + p[1], boxY + p[2], 1, 1)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

local rsPalette, rsColors
local function rs_text_colors(gender)
  local pal = BattleChrome.manifest().healthboxPal
  if rsPalette ~= pal then
    rsPalette = pal
    local function color(index)
      local value = assert(pal[index + 1], "RS healthbox palette missing")
      return { c5(value % 32), c5(math.floor(value / 32) % 32), c5(math.floor(value / 1024) % 32), 1 }
    end
    rsColors = { fg = color(1), shadow = color(3), bg = color(2) }
    rsColors.M = { fg = color(11), shadow = rsColors.bg, bg = rsColors.bg }
    rsColors.F = { fg = color(10), shadow = rsColors.bg, bg = rsColors.bg }
  end
  return rsColors[gender] or rsColors
end

-- pokeruby/src/text.c:2372
local function draw_rs_row(text, x, y, width, colors, fill)
  local sx, sy, sw, sh = love.graphics.getScissor()
  if sx then
    local left, top = math.max(sx, x), math.max(sy, y)
    love.graphics.setScissor(left, top, math.max(0, math.min(sx + sw, x + width) - left),
      math.max(0, math.min(sy + sh, y + 8) - top))
  else
    love.graphics.setScissor(x, y, width, 8)
  end
  if fill then
    love.graphics.setColor(colors.bg)
    love.graphics.rectangle("fill", x, y, width, 8)
  end
  FrlgFont.draw(text, x, y - 8, { font = "native_4", textMode = 0,
    colors = { fg = colors.fg, shadow = colors.shadow, bg = { 0, 0, 0, 0 } } })
  if sx then love.graphics.setScissor(sx, sy, sw, sh) else love.graphics.setScissor() end
  love.graphics.setColor(1, 1, 1, 1)
end

--- Pret UpdateNickInHealthbox: hide gender when nick == species for Nidoran.
local function healthbox_gender(mon)
  if not mon then return nil end
  local g = mon.gender
  if g ~= "M" and g ~= "F" then
    local Pokemon = require("src.core.game3.pokemon")
    local species = tonumber(mon.species or mon.speciesId)
    if species and Pokemon.gender then
      g = Pokemon.gender(species, mon.personality)
    end
  end
  if g ~= "M" and g ~= "F" then return nil end
  local species = tonumber(mon.species or mon.speciesId) or 0
  -- SPECIES_NIDORAN_F=29, SPECIES_NIDORAN_M=32 (FRLG national)
  if species == 29 or species == 32 then
    local nick = tostring(mon.nickname or "")
    local sname = tostring(mon.name or "")
    if nick == "" or nick == sname then
      return nil
    end
  end
  return g
end

local function draw_name_gender(name, gender, x, y)
  if rs_layout() then
    -- pokeruby/src/battle_interface.c:1546
    local top = y - TEXT_Y
    for tile = 0, 6 do BattleChrome.drawElementTile(43, x + tile * 8, top, true) end
    local colors = rs_text_colors()
    draw_rs_row(name, x, top + 8, 56, colors, true)
    if gender then
      local opts = { font = "native_4", textMode = 0 }
      local offset = FrlgFont.measure(name, opts)
      local symbol = gender == "M" and "♂" or "♀"
      if offset < 56 then draw_rs_row(symbol, x + offset, top + 8, 56 - offset, rs_text_colors(gender)) end
    end
    return
  end
  FrlgFont.draw(name, x, y, small_opts(HB_TEXT))
  if not gender then return end
  local nw = FrlgFont.measure(name, { small = true })
  -- ♂/♀ join arrow↔circle mostly via shadow pixels; need HB shadow on cream
  -- (FrlgFont.COLOR.MALE shadow is nearly invisible here and splits the glyph).
  if gender == "M" then
    FrlgFont.drawGlyph(FrlgFont.CHAR_MALE, x + nw, y, small_opts(HB_MALE))
  elseif gender == "F" then
    FrlgFont.drawGlyph(FrlgFont.CHAR_FEMALE, x + nw, y, small_opts(HB_FEMALE))
  end
end

-- pokefirered/src/battle_interface.c:759
local function draw_level(lv, boxX, y, winX)
  local digits = tostring(math.max(0, math.min(999, math.floor(tonumber(lv) or 1))))
  if rs_layout() then
    -- pokeruby/src/battle_interface.c:783
    local text = digits
    if tonumber(lv) ~= 100 then
      text = string.char(0xFC, 0x11, 1, 0xFC, 0x14, 4) .. ":"
        .. string.char(0xFC, 0x14, 0) .. digits
    end
    draw_rs_row(text, boxX + winX + 8, y - TEXT_Y + 8, 16, rs_text_colors(), true)
    return
  end
  local lvW = FrlgFont.advance(FrlgFont.CHAR_LV_2, { small = true })
  local x = boxX + winX + 5 * (3 - #digits)
  FrlgFont.drawGlyph(FrlgFont.CHAR_LV_2, x, y, small_opts(HB_TEXT))
  FrlgFont.draw(digits, x + lvW, y, small_opts(HB_TEXT))
end

local function erase_hp_window(boxX, boxY)
  if rs_layout() then return end
  love.graphics.setColor(CREAM)
  love.graphics.rectangle("fill", boxX + HP_WIN_X, boxY + HP_TEXT_Y, HP_WIN_W, HP_WIN_H)
  love.graphics.setColor(1, 1, 1, 1)
end

-- pokefirered/src/battle_interface.c:615
local SAFARI_CAP_X, SAFARI_CAP_Y, SAFARI_CAP_W, SAFARI_CAP_H = 96, 17, 2, 7
local SAFARI_STRIP_X, SAFARI_STRIP_Y, SAFARI_STRIP_W, SAFARI_STRIP_H = 18, 34, 78, 4
local BOX_SHADOW_SRC_X, BOX_SHADOW_SRC_Y = 10, 35
local _shadowImg, _shadowQuad
local _ballsText, _ballsCount, _ballsW

local function draw_safari_box(boxX, boxY)
  love.graphics.setColor(CREAM)
  love.graphics.rectangle("fill", boxX + SAFARI_CAP_X, boxY + SAFARI_CAP_Y, SAFARI_CAP_W, SAFARI_CAP_H)
  love.graphics.setColor(1, 1, 1, 1)
  local img = BattleChrome._playerBox
  if not (img and love.graphics.newQuad) then return end
  if _shadowImg ~= img then
    _shadowImg = img
    _shadowQuad = love.graphics.newQuad(BOX_SHADOW_SRC_X, BOX_SHADOW_SRC_Y, 1, 1, img:getDimensions())
  end
  love.graphics.draw(img, _shadowQuad, boxX + SAFARI_STRIP_X, boxY + SAFARI_STRIP_Y, 0,
    SAFARI_STRIP_W, SAFARI_STRIP_H)
end

-- pokefirered/src/battle_interface.c:1743
local function safari_balls_text(balls)
  if _ballsCount ~= balls or not _ballsText then
    _ballsCount = balls
    local key = require("src.core.game3.battle.profile").get(nil).strings.safariBallsLeft
    _ballsText = RomText.plain(key) .. tostring(balls)
    _ballsW = FrlgFont.measure(_ballsText, { small = true })
  end
  return _ballsText, _ballsW
end

-- pokefirered/src/battle_interface.c:795
local function draw_hp_nums(cur, maxHp, boxX, boxY)
  if rs_layout() then
    -- pokeruby/src/battle_interface.c:835
    -- text.c:2382
    local opts = { font = "native_4", textMode = 0 }
    local function aligned(value, width)
      local text = tostring(math.max(0, math.floor(value or 0)))
      return string.char(0xFC, 0x13, math.max(0, width - FrlgFont.measure(text, opts))) .. text
    end
    local colors = rs_text_colors()
    draw_rs_row(aligned(cur, 19) .. "/", boxX + 56, boxY + 24, 24, colors, true)
    draw_rs_row(aligned(maxHp, 15), boxX + 80, boxY + 24, 16, colors, true)
    return
  end
  FrlgFont.draw(string.format("%3d/", cur or 0), boxX + HP_CUR_X, boxY + HP_TEXT_Y, small_opts(HB_TEXT))
  FrlgFont.draw(string.format("%3d", maxHp or 0), boxX + HP_MAX_X, boxY + HP_TEXT_Y, small_opts(HB_TEXT))
end

local LEVEL_UP_SRC = [[
extern vec3 k1;
extern vec3 k2;
extern vec3 target;
extern float coeff;
vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
  vec4 c = Texel(tex, tc) * color;
  if (distance(c.rgb, k1) < 0.04 || distance(c.rgb, k2) < 0.04) c.rgb = mix(c.rgb, target, coeff);
  return c;
}
]]
local levelUpShader = nil
-- pokefirered/graphics/battle_interface/healthbox.pal
local HB_PAL = {
  [2] = { { 255, 255, 222 }, { 222, 213, 180 } },
  [6] = { { 82, 106, 98 }, { 32, 57, 0 } },
}

-- pokefirered/src/battle_anim_special.c:569
local function set_level_up_shader(blend)
  if not (blend and (tonumber(blend.coeff) or 0) > 0) then return false end
  if levelUpShader == nil then
    local ok, sh = pcall(love.graphics.newShader, LEVEL_UP_SRC)
    levelUpShader = ok and sh or false
  end
  if not levelUpShader then return false end
  local keys = HB_PAL[blend.colorIndex or 6] or HB_PAL[6]
  local col = tonumber(blend.color) or 0
  local ok = pcall(function()
    levelUpShader:send("k1", { keys[1][1] / 255, keys[1][2] / 255, keys[1][3] / 255 })
    levelUpShader:send("k2", { keys[2][1] / 255, keys[2][2] / 255, keys[2][3] / 255 })
    levelUpShader:send("target", { (col % 32) / 31, (math.floor(col / 32) % 32) / 31, (math.floor(col / 1024) % 32) / 31 })
    levelUpShader:send("coeff", math.min(1, blend.coeff / 16))
  end)
  if not ok then return false end
  love.graphics.setShader(levelUpShader)
  return true
end

local function live_st()
  local Battle = package.loaded["src.core.game3.battle"]
  return Battle and Battle._st
end

local function anim_key(id)
  if id == 0 then return "player" elseif id == 1 then return "enemy" end
  return id
end

local function stage_entry(tbl, id)
  if type(tbl) ~= "table" then return nil end
  local e = tbl[id]
  if e == nil then e = tbl[anim_key(id)] end
  return e
end

-- pokefirered/src/battle_interface.c:992
function Healthbox.hpTextShown(st, id)
  return (st and st.double and st._hpNumbersNoBars and st._hpNumbersNoBars[id]) and true or false
end

-- pokefirered/src/battle_interface.c:992
function Healthbox.swapHpBarsWithHpText(st)
  if not (st and st.double) then return end
  st._hpNumbersNoBars = st._hpNumbersNoBars or {}
  for _, id in ipairs({ 0, 2 }) do
    if st.battlers and st.battlers[id] then
      st._hpNumbersNoBars[id] = not st._hpNumbersNoBars[id]
    end
  end
end

local BAR_FG = { c5(7), c5(7), c5(7), 1 }
local BAR_SHADOW = { c5(26), c5(25), c5(23), 1 }
local BOTTOM_RIGHT_CORNER_HP_AS_TEXT = 116

-- pokefirered/src/battle_interface.c:864
local function draw_hp_text_doubles(bx, by, cur, maxHp)
  if rs_layout() then
    -- pokeruby/src/battle_interface.c:892
    local pal = BattleChrome.manifest().healthbarPal
    local function color(i)
      local value = assert(pal[i + 1], "RS healthbar palette missing")
      return { c5(value % 32), c5(math.floor(value / 32) % 32), c5(math.floor(value / 1024) % 32), 1 }
    end
    local colors = { fg = color(1), shadow = color(3), bg = { 0, 0, 0, 0 } }
    local opts = { font = "native_4", textMode = 0 }
    local function aligned(value, width)
      local text = tostring(math.max(0, math.floor(value or 0)))
      return string.char(0xFC, 0x13, math.max(0, width - FrlgFont.measure(text, opts))) .. text
    end
    draw_rs_row(aligned(cur, 43) .. "/", bx, by, 48, colors)
    draw_rs_row(aligned(maxHp, 15), bx + 48, by, 16, colors)
    return
  end
  local opts = { small = true, colors = { fg = BAR_FG, shadow = BAR_SHADOW } }
  local left = string.format("%3d/", math.max(0, math.min(999, math.floor(cur or 0))))
  local right = string.format("%3d", math.max(0, math.min(999, math.floor(maxHp or 0))))
  if BattleChrome.hasHpBoldDigits() then
    for i = 1, 4 do
      local ch = left:sub(i, i)
      if ch ~= " " then BattleChrome.drawHpBoldChar(ch, bx + 8 * i, by) end
    end
    for i = 1, 3 do
      local ch = right:sub(i, i)
      if ch ~= " " then BattleChrome.drawHpBoldChar(ch, bx + 32 + 8 * i, by) end
    end
    return
  end
  -- pokefirered/src/text.c:1268
  local ty = by - 3
  for i = 1, 4 do
    local ch = left:sub(i, i)
    if ch ~= " " then FrlgFont.draw(ch, bx + 8 * i, ty, opts) end
  end
  for i = 1, 3 do
    local ch = right:sub(i, i)
    if ch ~= " " then FrlgFont.draw(ch, bx + 32 + 8 * i, ty, opts) end
  end
end

local function draw_doubles(id, battler, st, opts)
  local Anim = require("src.core.game3.battle.anim")
  local stage = Anim.stage and Anim.stage()
  local hb = stage and stage_entry(stage.healthbox, id)
  if hb and hb.visible == false then return end
  local ox = ((hb and hb.ox) or 0) + ((opts and opts.ox) or 0)
  local oy = ((hb and hb.oy) or 0) + ((opts and opts.oy) or 0)
  local isPlayer = (id % 2) == 0
  local c = Healthbox.center(st, id)
  local cx, cy = c.x + ox, c.y + oy
  local tlX, tlY = cx - 32, cy - 16

  local lvl = isPlayer and love and love.graphics and set_level_up_shader(hb and hb.levelUpBlend)
  BattleChrome.drawDoublesBox(isPlayer, tlX, tlY)
  if lvl then love.graphics.setShader() end
  erase_placeholder_ink(tlX, tlY, isPlayer and PLAYER_PLACEHOLDER_INK or ENEMY_PLACEHOLDER_INK)

  local SummaryChrome = require("src.ui.game3.summary_chrome")
  local SummaryData = require("src.core.game3.summary_data")
  local p = Anim.present and Anim.present(id)
  local stObj = (p and p.displayStatus ~= nil) and p.displayStatus or (battler.status or (battler.mon and (battler.mon.status or battler.mon.status1)))
  if stObj == false or stObj == 0 then stObj = nil end
  local ailment = SummaryData.statusAilment({ status = stObj, hp = battler.mon and battler.mon.hp })
  local statused = ailment >= 1 and ailment <= 6
  local hpText = isPlayer and Healthbox.hpTextShown(st, id)

  local barCx = cx + (isPlayer and 16 or 8)
  local bx, by = hp_bar_top_left(barCx, cy)
  local hp, maxHp = hp_values(id, battler)
  if hpText then
    draw_hp_text_doubles(bx, by, hp, maxHp)
    -- pokefirered/src/battle_interface.c:925
    BattleChrome.drawElementTile(BOTTOM_RIGHT_CORNER_HP_AS_TEXT, tlX + 96, tlY + 16, true)
  else
    BattleChrome.drawHpBar(bx, by, hp, maxHp, statused)
    if isPlayer and rs_layout() then
      -- pokeruby/src/battle_interface.c:1043
      BattleChrome.drawElementTile(117, tlX + 96, tlY + 16, true)
    end
  end

  local name = State.displayName(battler)
  local lv = (p and p.displayLevel) or (battler.mon and battler.mon.level) or 1
  local ty = tlY + TEXT_Y
  local gender = healthbox_gender(battler.mon)
  -- pokefirered/src/battle_interface.c:1531
  draw_name_gender(name, gender, tlX + (isPlayer and 16 or 8), ty)
  draw_level(lv, tlX, ty, isPlayer and PLAYER_LVL_X or ENEMY_LVL_X)
  if statused then
    -- pokefirered/src/battle_interface.c:1608
    if rs_layout() then
      -- pokeruby/src/battle_interface.c:1662
      BattleChrome.drawRsStatusIcon(id, ailment, tlX + (isPlayer and 16 or 8), tlY + 16)
    else
      SummaryChrome.drawStatusIcon(tlX + (isPlayer and 10 or 2), tlY + 16, ailment)
    end
  end
end

function Healthbox.draw(side, battler, opts)
  if not battler then return end
  if type(side) == "number" then
    local st = (opts and opts.st) or live_st()
    if st and st.double then
      return draw_doubles(side, battler, st, opts)
    end
    side = (side % 2 == 0) and "player" or "enemy"
  end
  local Anim = require("src.core.game3.battle.anim")
  local stage = Anim.stage and Anim.stage()
  local hb = stage and stage.healthbox and stage.healthbox[side]
  if hb and hb.visible == false then return end
  local ox = ((hb and hb.ox) or 0) + ((opts and opts.ox) or 0)
  local oy = (opts and opts.oy) or 0

  local isPlayer = side == "player"
  local bstSafari = live_st()
  local c0 = isPlayer and Healthbox.PLAYER_CENTER or Healthbox.ENEMY_CENTER
  local c = { x = c0.x, y = c0.y + oy }
  local tlX, tlY
  if isPlayer then
    tlX, tlY = player_top_left(c.x + ox, c.y)
    local lvl = love and love.graphics and set_level_up_shader(hb and hb.levelUpBlend)
    if rs_layout() and bstSafari and bstSafari.safari then
      assert(BattleChrome.drawSafariBox(tlX, tlY), "native RS Safari healthbox missing")
    else
      BattleChrome.drawPlayerBox(tlX, tlY)
    end
    if lvl then love.graphics.setShader() end
    erase_placeholder_ink(tlX, tlY, PLAYER_PLACEHOLDER_INK)
    erase_hp_window(tlX, tlY)
  else
    tlX, tlY = enemy_top_left(c.x + ox, c.y)
    BattleChrome.drawEnemyBox(tlX, tlY)
    erase_placeholder_ink(tlX, tlY, ENEMY_PLACEHOLDER_INK)
  end

  if isPlayer and bstSafari and bstSafari.safari then
    if rs_layout() then
      -- pokeruby/src/battle_interface.c:1785
      local colors = rs_text_colors()
      for tile = 0, 6 do BattleChrome.drawElementTile(43, tlX + 24 + tile * 8, tlY, true) end
      draw_rs_row(RomText.plain("BattleText_SafariBalls"), tlX + 24, tlY + 8, 56, colors, true)
      local balls = math.max(0, math.floor(tonumber(bstSafari.safariState and bstSafari.safariState.balls) or 0))
      local digits = tostring(balls)
      local width = FrlgFont.measure(digits, { font = "native_4", textMode = 0 })
      local text = RomText.plain("BattleText_SafariBallsLeft")
        .. string.char(0xFC, 0x11, math.max(0, 10 - width)) .. digits
      draw_rs_row(text, tlX + 48, tlY + 24, 40, colors, true)
      return
    end
    -- pokefirered/src/battle_interface.c:1743
    local balls = (bstSafari.safariState and tonumber(bstSafari.safariState.balls)) or 0
    local sbx, sby = hp_bar_top_left(hp_bar_center(side, c.x + ox, c.y))
    love.graphics.setColor(CREAM)
    love.graphics.rectangle("fill", sbx, sby - 2, 64, 10)
    love.graphics.setColor(1, 1, 1, 1)
    draw_safari_box(tlX, tlY)
    FrlgFont.draw(RomText.plain("gText_SafariBalls"), tlX + 16, tlY + TEXT_Y, small_opts(HB_TEXT))
    local left, w = safari_balls_text(math.max(0, math.floor(balls)))
    FrlgFont.draw(left, tlX + HP_WIN_X + HP_WIN_W - w, tlY + HP_TEXT_Y, small_opts(HB_TEXT))
    return
  end

  local p = nil
  do
    local ok, AnimP = pcall(require, "src.core.game3.battle.anim")
    if ok and AnimP and AnimP.present then
      p = AnimP.present(side)
    end
  end

  local barCx, barCy = hp_bar_center(side, c.x + ox, c.y)
  local bx, by = hp_bar_top_left(barCx, barCy)
  local statusBorder = false
  if not isPlayer then
    local SummaryData = require("src.core.game3.summary_data")
    local st1 = (p and p.displayStatus ~= nil) and p.displayStatus or (battler.status or (battler.mon and (battler.mon.status or battler.mon.status1)))
    if st1 == false or st1 == 0 then st1 = nil end
    local a = SummaryData.statusAilment({ status = st1, hp = battler.mon and battler.mon.hp })
    -- pokefirered/src/battle_interface.c:1668
    statusBorder = a >= 1 and a <= 6
  end
  local hpNow, hpMax = hp_values(side, battler)
  BattleChrome.drawHpBar(bx, by, hpNow, hpMax, statusBorder)

  local name = State.displayName(battler)
  local lv = (p and p.displayLevel) or (battler.mon and battler.mon.level) or 1

  local ty = tlY + TEXT_Y
  local lvlX = isPlayer and PLAYER_LVL_X or ENEMY_LVL_X
  local gender = healthbox_gender(battler.mon)
  -- pokefirered/src/battle_interface.c:1506
  local Battle = package.loaded["src.core.game3.battle"]
  local bst = Battle and Battle._st
  if not isPlayer and bst and bst.ghostBattle and name == RomText.plain("gText_Ghost") then
    local okA, AnimG = pcall(require, "src.core.game3.battle.anim")
    local pg = okA and AnimG.present and AnimG.present("enemy")
    if pg and pg.ghostUnveiled then
      -- pokefirered/src/battle_gfx_sfx_util.c:686
      local Pokemon = require("src.core.game3.pokemon")
      name = Pokemon.name(battler.species) or name
    else
      gender = nil
    end
  end

  local SummaryChrome = require("src.ui.game3.summary_chrome")
  local SummaryData = require("src.core.game3.summary_data")
  local stObj = (p and p.displayStatus ~= nil) and p.displayStatus or (battler.status or (battler.mon and (battler.mon.status or battler.mon.status1)))
  if stObj == false or stObj == 0 then stObj = nil end
  local ailment = SummaryData.statusAilment({ status = stObj, hp = battler.mon and battler.mon.hp })

  if isPlayer then
    draw_name_gender(name, gender, tlX + 16, ty)
    draw_level(lv, tlX, ty, lvlX)
    if ailment >= 1 and ailment <= 6 then
      -- pokefirered/src/battle_interface.c:1608
      if rs_layout() then
        -- pokeruby/src/battle_interface.c:1660
        BattleChrome.drawRsStatusIcon(0, ailment, tlX + 16, tlY + 24)
      else
        SummaryChrome.drawStatusIcon(tlX + 10, tlY + 24, ailment)
      end
    end
    local mon = battler.mon
    if mon then
      local cur, maxHp = display_hp_nums(side, battler)
      draw_hp_nums(cur, maxHp, tlX, tlY)
    end
    local expRatio = 0
    do
      local ok, AnimE = pcall(require, "src.core.game3.battle.anim")
      if ok and AnimE and AnimE.displayExpRatio then
        expRatio = AnimE.displayExpRatio(side, battler)
      else
        local Experience = require("src.core.game3.battle.experience")
        local prog = Experience.progress(battler.mon)
        expRatio = prog.progressPercent or 0
      end
    end
    BattleChrome.drawExpBar(tlX + 32, tlY + 32, expRatio)
  else
    draw_name_gender(name, gender, tlX + 8, ty)
    draw_level(lv, tlX, ty, lvlX)
    if ailment >= 1 and ailment <= 6 then
      -- pokefirered/src/battle_interface.c:1614
      if rs_layout() then
        -- pokeruby/src/battle_interface.c:1667
        BattleChrome.drawRsStatusIcon(1, ailment, tlX + 8, tlY + 16)
      else
        SummaryChrome.drawStatusIcon(tlX + 2, tlY + 16, ailment)
      end
    else
      -- pokefirered/src/battle_interface.c:1658
      local species = battler.species or (battler.mon and (battler.mon.species or battler.mon.speciesId))
      local latch = battler._caughtIcon
      if not latch or latch.mon ~= battler.mon or latch.species ~= species or latch.ailment ~= ailment
          or latch.name ~= name then
        latch = { mon = battler.mon, species = species, ailment = ailment, name = name,
          show = Healthbox.shouldShowCaughtMarker(bst, battler) }
        battler._caughtIcon = latch
      end
      if latch.show then
        BattleChrome.drawPartyBall(tlX + 8, tlY + 16, "caught")
      end
    end
  end
end

function Healthbox.shouldShowCaughtMarker(st, battler)
  if not battler then return false end
  if battler.isPlayer or battler.side == "player" then return false end

  -- Must not be first battle / tutorial / pokedude
  if st and (st.firstBattle or st.oldManTutorial or st.pokedude) then
    return false
  end

  -- Must not be trainer battle (wild only, matching pokefirered BATTLE_TYPE_TRAINER check)
  if st and (st.trainer or st.trainerId or st.isTrainerBattle or st.kind == "trainer") then
    return false
  end
  if battler.isTrainer or (battler.trainer and true) then
    return false
  end

  -- Ghost battles: un-identified ghosts (name == "GHOST") do not show caught ball
  if st and st.ghostBattle and not st.ghostUnveiled then
    return false
  end
  local name = State.displayName(battler)
  if RomText.has("gText_Ghost") and name == RomText.plain("gText_Ghost") then
    return false
  end

  local species = battler.species or (battler.mon and (battler.mon.species or battler.mon.speciesId))
  if not species or species == 0 then return false end

  local dex = (st and (st.dex or (st.session and st.session.dex)))
  if not dex then
    local Battle = package.loaded["src.core.game3.battle"]
    local bst = Battle and Battle._st
    dex = bst and (bst.dex or (bst.session and bst.session.dex))
  end
  if not dex then
    local okR, Runtime = pcall(require, "src.core.game3.runtime")
    if okR and Runtime and Runtime.getSession then
      local s = Runtime.getSession()
      dex = s and s.dex
    end
  end
  if not dex then
    local okF, Field = pcall(require, "src.core.game3.field")
    if okF and Field and Field._session then
      dex = Field._session.dex
    end
  end
  if not dex then return false end

  local Dex = require("src.core.game3.dex")
  return Dex.isCaught(dex, species) == true
end

function Healthbox.syncOam(_st)
  return
end

return Healthbox
