local Stack = require("src.ui.game3.stack")
local Options = require("src.core.game3.options")
local Rows = require("src.ui.game3.option_rows")
local RomText = require("src.core.game3.rom_text")
local FrlgFont = require("src.ui.game3.frlg_font")
local Chrome = require("src.ui.game3.chrome")
local Kit = require("src.ui.game3.rse.scene_kit")
local Screens = require("src.ui.game3.screens")
local ShaderFXMenu = require("src.ui.game3.shaderfx_menu")

local OptionMenu = { isMenu = true }

OptionMenu.ID = "option"
OptionMenu.VISIBLE = 7
OptionMenu.isOpen = Screens.openFlag(OptionMenu.ID)

-- pokeemerald/src/option_menu.c:79
OptionMenu.CART = {
  { id = "textSpeed", label = "gText_TextSpeed", key = "textSpeed", count = 3,
    choices = { "gText_TextSpeedSlow", "gText_TextSpeedMid", "gText_TextSpeedFast" } },
  { id = "battleScene", label = "gText_BattleScene", key = "battleScene", count = 2, toggle = true,
    choices = { "gText_BattleSceneOn", "gText_BattleSceneOff" } },
  { id = "battleStyle", label = "gText_BattleStyle", key = "battleStyle", count = 2, toggle = true,
    choices = { "gText_BattleStyleShift", "gText_BattleStyleSet" } },
  { id = "sound", label = "gText_Sound", key = "sound", count = 2, toggle = true,
    choices = { "gText_SoundMono", "gText_SoundStereo" } },
  { id = "buttonMode", label = "gText_ButtonMode", key = "buttonMode", count = 3,
    choices = { "gText_ButtonTypeNormal", "gText_ButtonTypeLR", "gText_ButtonTypeLEqualsA" } },
  { id = "frameType", label = "gText_Frame", key = "frameType", frame = true },
}

local st = {}
OptionMenu._st = st

local function se(name)
  pcall(function() require("src.core.game3.audio").playSe(name) end)
end

local function manifest()
  return Kit.manifest("rse/menus")
end

local function stripColors(s)
  s = tostring(s or "")
  s = s:gsub("{COLOR[^}]*}", ""):gsub("{SHADOW[^}]*}", ""):gsub("{HIGHLIGHT[^}]*}", "")
  s = s:gsub("\252[\1\2\3].", ""):gsub("\252\4...", "")
  return s
end

local function cart()
  return Options.block(st.ctx.options)
end

local function cartValue(key)
  return tonumber(cart()[key]) or 0
end

local function setCart(key, v)
  Options.set({ options = cart() }, key, v)
  local g = st.ctx.game
  if g and g.writeOptions then g:writeOptions() end
end

local function portRows()
  local cartRows = {}
  for _, r in ipairs(OptionMenu.CART) do cartRows[r.id] = { id = r.id, cart = r } end
  return Rows.withCart(st.ctx, cartRows, function(title, members)
    st.pages[#st.pages + 1] = { title = title, rows = members, index = 1, scroll = 0 }
  end)
end

local function page()
  return st.pages and st.pages[#st.pages]
end

function OptionMenu.show(opts)
  opts = opts or {}
  local Runtime = package.loaded["src.core.game3.runtime"]
  local game = opts.game or (Runtime and Runtime._game)
  local engine = Options.engine(opts.session) or (game and game.options) or (opts.session and opts.session.options) or {}
  Options.bind(opts.session or {}, engine)
  st.ctx = { session = opts.session, game = game, options = engine }
  st.onClose = opts.onClose
  st.pages = {}
  local rows = portRows()
  table.insert(st.pages, 1, { title = RomText.plain("gText_Option"), rows = rows, index = 1, scroll = 0, top = true })
  while #st.pages > 1 do table.remove(st.pages) end
  st.k = 0
  OptionMenu.cursor = 1
  Stack.push(OptionMenu.ID, OptionMenu, { hideBelow = true, fullscreen = true })
end

function OptionMenu.close()
  ShaderFXMenu.close()
  st.pages = nil
  Stack.pop(OptionMenu.ID)
  local cb = st.onClose
  st.onClose = nil
  if cb then cb() end
end

local function rowCount(p)
  return #p.rows + 1
end

local function clampScroll(p)
  local total = rowCount(p)
  local vis = OptionMenu.VISIBLE
  if p.index - 1 < p.scroll then p.scroll = p.index - 1 end
  if p.index > p.scroll + vis then p.scroll = p.index - vis end
  p.scroll = math.max(0, math.min(p.scroll, math.max(0, total - vis)))
end

-- pokeemerald/src/option_menu.c:398
local function stepCart(r, input)
  local cur = cartValue(r.key)
  local nextV = cur
  if r.frame then
    local n = Chrome.userFrameCount()
    if input:wasPressed("right") then nextV = (cur + 1) % n
    elseif input:wasPressed("left") then nextV = (cur - 1 + n) % n end
    if nextV ~= cur then
      setCart(r.key, nextV)
      Chrome.setFrameType(nextV)
    end
    return
  end
  if r.toggle then
    if input:wasPressed("left") or input:wasPressed("right") then nextV = 1 - cur end
  else
    if input:wasPressed("right") then nextV = (cur + 1) % r.count
    elseif input:wasPressed("left") then nextV = (cur - 1 + r.count) % r.count end
  end
  if nextV ~= cur then
    setCart(r.key, nextV)
    if r.id == "sound" then
      pcall(function() require("src.core.game3.audio").applyOptions({ options = cart() }) end)
    end
  end
end

function OptionMenu.handleInput(input)
  if not input then return end
  if ShaderFXMenu.isOpen() then return ShaderFXMenu.handleInput(input) end
  local p = page()
  if not p then return end
  local total = rowCount(p)
  if input:wasPressed("up") then
    p.index = p.index > 1 and p.index - 1 or total
  elseif input:wasPressed("down") then
    p.index = p.index < total and p.index + 1 or 1
  elseif input:wasPressed("b") or input:wasPressed("start") then
    OptionMenu.back()
    return
  elseif input:wasPressed("a") then
    if p.index > #p.rows then
      OptionMenu.back()
      return
    end
    local row = p.rows[p.index]
    if row and row.activate then
      se("SE_SELECT")
      row.activate(st.ctx)
    elseif row and row.step and not row.cart then
      if row.step(st.ctx, 1) then
        local g = st.ctx.game
        if g and g.writeOptions then g:writeOptions() end
      end
    end
    return
  else
    local row = p.rows[p.index]
    if row and row.cart then
      stepCart(row.cart, input)
    elseif row and row.step and (input:wasPressed("left") or input:wasPressed("right")) then
      if row.step(st.ctx, input:wasPressed("left") and -1 or 1) then
        local g = st.ctx.game
        if g and g.writeOptions then g:writeOptions() end
      end
    end
  end
  OptionMenu.cursor = p.index
  clampScroll(p)
end

function OptionMenu.back()
  if st.pages and #st.pages > 1 then
    table.remove(st.pages)
    local p = page()
    OptionMenu.cursor = p and p.index or 1
    return
  end
  OptionMenu.close()
end

function OptionMenu.update()
  ShaderFXMenu.update()
  st.k = (st.k or 0) + 1
end

local function colorsFor(pal, fg, shadow)
  return { fg = Kit.color555(pal[fg + 1]), shadow = Kit.color555(pal[shadow + 1]), bg = { 0, 0, 0, 0 } }
end

-- pokeemerald/src/option_menu.c:380
local function choice(key, x, y, selected, pal)
  local t = stripColors(RomText.plain(key))
  FrlgFont.draw(t, x, y, { colors = selected and colorsFor(pal, 4, 5) or colorsFor(pal, 6, 7) })
  return t
end

local function drawCart(r, x0, y, pal)
  local cur = cartValue(r.key)
  if r.frame then
    -- pokeemerald/src/option_menu.c:541
    choice("gText_FrameType", x0 + 104, y, false, pal)
    local n = cur + 1
    local num = stripColors(RomText.plain("gText_FrameTypeNumber")) .. (n >= 10 and tostring(n) or (tostring(n) .. " "))
    FrlgFont.draw(num, x0 + 128, y, { colors = colorsFor(pal, 4, 5) })
    return
  end
  local keys = r.choices
  if #keys == 2 then
    choice(keys[1], x0 + 104, y, cur == 0, pal)
    local t = stripColors(RomText.plain(keys[2]))
    choice(keys[2], x0 + 198 - FrlgFont.measure(t), y, cur == 1, pal)
    return
  end
  -- pokeemerald/src/option_menu.c:421
  local w1 = FrlgFont.measure(stripColors(RomText.plain(keys[1])))
  local w2 = FrlgFont.measure(stripColors(RomText.plain(keys[2]))) - 94
  local w3 = FrlgFont.measure(stripColors(RomText.plain(keys[3])))
  choice(keys[1], x0 + 104, y, cur == 0, pal)
  choice(keys[2], x0 + math.floor((w1 - w2 - w3) / 2) + 104, y, cur == 1, pal)
  choice(keys[3], x0 + 198 - w3, y, cur == 2, pal)
end

function OptionMenu.draw()
  local p = page()
  if not p then return end
  if ShaderFXMenu.isOpen() then return ShaderFXMenu.draw() end
  local m = manifest()
  local o = m and m.option
  local pal = o and o.textPalette or {}
  local bd = Kit.color555(o and o.bgColor or 0)
  love.graphics.clear(bd[1], bd[2], bd[3], 1)
  local frameType = cartValue("frameType")
  local wins = o and o.windows or {}
  local head = wins[1] or { left = 2, top = 1, width = 26, height = 2 }
  local body = wins[2] or { left = 2, top = 5, width = 26, height = 14 }
  local white = Kit.color555(pal[2] or 0x7FFF)
  Kit.userFrame(head.left, head.top, head.width, head.height, frameType, white)
  Kit.userFrame(body.left, body.top, body.width, body.height, frameType, white)
  local label = colorsFor(pal, 2, 3)
  -- pokeemerald/src/option_menu.c:618
  FrlgFont.draw(p.title, head.left * 8 + 8, head.top * 8 + 1, { colors = label })

  clampScroll(p)
  local x0, y0 = body.left * 8, body.top * 8
  local total = rowCount(p)
  for slot = 1, OptionMenu.VISIBLE do
    local idx = p.scroll + slot
    if idx > total then break end
    local y = y0 + (slot - 1) * 16 + 1
    if idx > #p.rows then
      FrlgFont.draw(RomText.plain("gText_OptionMenuCancel"), x0 + 8, y, { colors = label })
    else
      local row = p.rows[idx]
      if row.cart then
        FrlgFont.draw(RomText.plain(row.cart.label), x0 + 8, y, { colors = label })
        drawCart(row.cart, x0, y, pal)
      else
        FrlgFont.draw(row.label or "?", x0 + 8, y, { colors = label })
        if row.value then
          local ok, text = pcall(row.value, st.ctx)
          FrlgFont.draw(ok and tostring(text) or "----", x0 + 104, y, { colors = colorsFor(pal, 6, 7) })
        end
      end
    end
  end

  -- pokeemerald/src/option_menu.c:374
  local selTop = y0 + (p.index - p.scroll - 1) * 16
  local selBot = selTop + 16
  local W = body.width * 8
  love.graphics.setColor(0, 0, 0, 4 / 16)
  if selTop > y0 then love.graphics.rectangle("fill", x0, y0, W, selTop - y0) end
  local bottom = y0 + body.height * 8
  if selBot < bottom then love.graphics.rectangle("fill", x0, selBot, W, bottom - selBot) end
  love.graphics.setColor(1, 1, 1, 1)

  if total > OptionMenu.VISIBLE then
    local BagChrome = require("src.ui.game3.rse.bag_chrome")
    if p.scroll > 0 then BagChrome.drawArrow("up", 120, y0 - 4, st.k) end
    if p.scroll + OptionMenu.VISIBLE < total then BagChrome.drawArrow("down", 120, bottom + 4, st.k) end
  end
end

function OptionMenu.reset()
  ShaderFXMenu.close()
  if st.pages then Stack.pop(OptionMenu.ID) end
  st.pages, st.onClose = nil, nil
end

return OptionMenu
