local Kit = require("src.ui.game3.rse.scene_kit")
local Pokemon = require("src.core.game3.pokemon")
local Font = require("src.ui.game3.frlg_font")
local Pal = require("src.core.game3.pal_fade")
local Chrome = {native = true}
local tiles, quads, icons = {}, {}, {}
function Chrome.manifest()
  local m = assert(Kit.manifest("rse/party"), "native RS party pack missing")
  assert(m.layout == "rs", "native RS party pack required")
  return m
end
function Chrome.install()
  Chrome._man = Chrome.manifest(); tiles, quads, icons = {}, {}, {}
  Chrome._pal = Pal.new(); Chrome._pal:beginFade(Pal.ALL, 0, 16, 0, Pal.BLACK)
end
function Chrome.ready() return Chrome._man ~= nil end
local function man() return Chrome._man or Chrome.manifest() end
function Chrome.layout(ui)
  return math.max(0, math.min(3, tonumber(ui._nativeLayout) or (ui._layout == "double" and 1 or 0)))
end
function Chrome.hpLevel(hp, maximum)
  hp, maximum = tonumber(hp) or 0, math.max(1, tonumber(maximum) or 1)
  if hp == maximum then return 4 end
  local fraction = math.floor(hp * 48 / maximum)
  if fraction == 0 and hp > 0 then fraction = 1 end
  return fraction >= 25 and 3 or fraction >= 10 and 2 or fraction > 0 and 1 or 0
end
function Chrome.panelPalette(ui, slot, mon)
  local layout, base, selected = Chrome.layout(ui), 3, ui.cursor == slot
  if layout == 2 and (slot == 2 or slot == 5 or slot == 6) or ui._multi and ui._multi[slot] then base = 4 end
  if ui.switchFrom == slot then base, selected = 6, ui.cursor ~= slot end
  if mon and (tonumber(mon.hp) or 0) == 0 then base = 5 end
  return base + (selected and 4 or 0)
end
local function entryImage(entry) return assert(Kit.image(entry.png), entry.png) end
local function strip(entry, index, x, y, variant)
  local path = variant and entry.variants[variant] or entry.png
  local image = assert(Kit.image(path), path)
  local key = path .. ":" .. index
  if not quads[key] then quads[key] = love.graphics.newQuad(0, index * entry.h, entry.w, entry.h, image:getDimensions()) end
  love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(image, quads[key], x, y)
end
local function tile(tileId, paletteBank, x, y, sourceKey)
  local m, key = man(), tostring(sourceKey or "misc") .. tileId .. ":" .. paletteBank
  local image = tiles[key]
  if not image then
    local source = assert(love.filesystem.read(sourceKey == "order" and m.orderGfx or m.gfx))
    local data = love.image.newImageData(8, 8)
    for py = 0, 7 do for px = 0, 7 do
      local byte = source:byte(tileId * 32 + py * 4 + math.floor(px / 2) + 1) or 0
      local index = math.floor(byte / 16 ^ (px % 2)) % 16
      local r, g, b = Kit.rgb555(m.palettes.bg[paletteBank * 16 + index + 1])
      data:setPixel(px, py, r, g, b, index == 0 and 0 or 1)
    end end
    image = love.graphics.newImage(data); image:setFilter("nearest", "nearest"); tiles[key] = image
  end
  love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(image, x, y)
end
function Chrome.drawBg()
  love.graphics.setColor(1, 1, 1, 1); love.graphics.rectangle("fill", 0, 0, 240, 160)
  love.graphics.draw(entryImage(man().bg), 0, 1)
end
local function button(kind, selected)
  local row = man().buttons[kind]
  for i, id in ipairs(row.tiles) do tile(id, selected and 2 or 1, (row.x + (i - 1) % 6) * 8, (row.y + math.floor((i - 1) / 6)) * 8 + 1) end
end
function Chrome.drawCancelButton(_, _, selected) button("cancel", selected) end
function Chrome.drawConfirmButton(_, _, selected) button("confirm", selected) end
function Chrome.ballEntry() return nil end
function Chrome.statusEntry() return nil end
function Chrome.textOptions(kind)
  local m, win = man(), man().windows[kind or "monText"]
  local pal = m.palettes.bg
  local function color(index) local r, g, b = Kit.rgb555(pal[241 + index]); return {r, g, b, 1} end
  return {font = "native_" .. win.fontNum, colors = {fg = color(win.foregroundColor), shadow = color(win.shadowColor), bg = color(win.backgroundColor)}}
end
local function text(value, x, y, right)
  local opts = Chrome.textOptions("monText")
  opts.colors.bg = {0,0,0,0}
  if right then x = x - Font.measure(value, opts) end
  Font.draw(value, x, y, opts)
end
local function iconAnim(mon)
  local level = Chrome.hpLevel(mon.hp, mon.maxHp or mon.maxhp)
  return level == 4 and 0 or level == 3 and 1 or level == 2 and 2 or level == 1 and 3 or 4
end
function Chrome.update(ui)
  if Chrome._pal then Chrome._pal:updateFade() end
  for i = 1, 6 do
    local mon = ui._party and ui._party[i]
    if mon then
      local anim = iconAnim(mon)
      local state = icons[i]
      if not state or state.mon ~= mon or state.anim ~= anim then state = {mon = mon, anim = anim, cmd = 1, delay = 0, frame = 0, dy = 0}; icons[i] = state end
      local selected = ui.cursor == i
      if selected ~= state.selected then state.dy, state.selected = 0, selected end
      if state.delay > 0 then state.delay = state.delay - 1
      else
        local command = man().monIconAnims[anim + 1][state.cmd]
        if command.op == "jump" then state.cmd = command.target + 1
        elseif command.op == "frame" then
          state.frame, state.delay, state.cmd = command.tile, command.duration, state.cmd + 1
          if selected then state.dy = (state.cmd - 1) % 2 == 1 and -3 or 1 end
        end
      end
    else icons[i] = nil end
  end
end
function Chrome.inputAllowed() return not (Chrome._pal and Chrome._pal:fadeActive()) end
function Chrome.drawFade() if Chrome._pal then Kit.drawFade(Chrome._pal) end end
local function panelPosition(ui, index)
  local m, layout = man(), Chrome.layout(ui)
  if layout < 2 then return m.coordinates.panels[layout + 1][index] end
  return m.coordinates.linkPanels[layout - 1][index]
end
local function drawSlot(ui, index, mon)
  local m, layout = man(), Chrome.layout(ui)
  local pos = panelPosition(ui, index)
  local large = layout == 0 and index == 1 or layout ~= 0 and (index == 1 or index == 2)
  if layout == 3 then large = index == 1 or index == 4 end
  local panel = m.panels[large and "large" or mon and "small" or "empty"]
  local bank = mon and Chrome.panelPalette(ui, index, mon) or 3
  love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(assert(Kit.image(panel.variants[bank])), pos[1] * 8, pos[2] * 8)
  if not mon then return end
  local nick, data = Pokemon.displayName(mon), m.textSettings[layout + 1][index]
  local nameOam = data.oam[1]
  local x, y = data.x + nameOam[2] % 512, data.y + nameOam[1] % 256
  local sx, sy, sw, sh = love.graphics.getScissor()
  love.graphics.intersectScissor(x, y, 64, 16); text(nick, x, y)
  if sx then love.graphics.setScissor(sx, sy, sw, sh) else love.graphics.setScissor() end
  local desc = ui.slotDescription(index)
  if desc then
    local coords = m.coordinates.descriptors[layout == 0 and 1 or 2][index]
    require("src.ui.game3.rs.party_menu_data").drawDescription(desc, coords[1] * 8, coords[2] * 8)
  end
  if not Pokemon.isEgg(mon) then
    local point = m.coordinates.text[layout + 1][index]
    local status = require("src.core.game3.summary_data").statusAilment(mon)
    if status > 0 and status ~= 6 then strip(m.sprites.status, status - 1, (point[1] - 1) * 8, (point[2] + 1) * 8)
    else
      tile(0x40, 0, (point[1] - 1) * 8, (point[2] + 1) * 8, "order")
      local row = data.oam[5]
      -- src/party_menu.c:2662
      text(tostring(mon.level or 1), data.x + row[2] % 512 + 8, data.y + row[1] % 256 - 8)
    end
    local species, gender = Pokemon.speciesOf(mon), require("src.core.game3.summary_data").gender(mon)
    local hideGender = (species == 29 or species == 32) and tostring(nick):gsub("{[^}]*}", "") == Pokemon.name(species)
    if not hideGender and (gender == "M" or gender == "F") then
      tile(gender == "M" and 0x42 or 0x44, 0, (point[1] + 3) * 8, (point[2] + 1) * 8, "order")
    end
    if not desc then
      local hp = tonumber(mon.hp) or 0
      if ui._hpAnim and ui._hpAnim.slot == index then hp = math.floor(ui._hpAnim.current + 0.5) end
      local maximum = tonumber(mon.maxHp or mon.maxhp) or 1
      local row = data.oam[6]
      -- src/party_menu.c:2739
      local hx, hy = data.x + row[2] % 512, data.y + row[1] % 256 - 8
      text(tostring(hp), hx + 15, hy, true); text("/", hx + 15, hy); text(tostring(maximum), hx + 35, hy, true)
      local hpPoint = m.coordinates.hpBars[layout + 1][index]
      local ticks = math.floor(hp * 48 / math.max(1, maximum))
      if ticks == 0 and hp > 0 then ticks = 1 end
      local level = Chrome.hpLevel(hp, maximum)
      local variant = level > 2 and "green" or level == 2 and "yellow" or "red"
      for i = 0, 5 do strip(m.hpTiles, math.max(0, math.min(8, ticks - i * 8)), (hpPoint[1] + i) * 8, hpPoint[2] * 8, variant) end
      for i, offset in ipairs({-2, -1, 6}) do strip(m.hpTiles, i + 8, (hpPoint[1] + offset) * 8, hpPoint[2] * 8, "caps") end
    end
  end
  local state = icons[index] or {frame = 0, dy = 0}
  local point = m.coordinates.monIcons[layout + 1][index]
  local icon = Pokemon.monIcon(mon)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(icon.image, icon.quads[state.frame], point[1] - icon.w / 2, point[2] + state.dy - icon.h / 2)
  local item = ui.heldItemFrame(mon)
  if item ~= nil then
    local held = m.sprites.heldItems
    local frame = held.anims[item + 1][1].frame
    strip(held, frame, point[1] + m.heldItemOffset[1] - held.w / 2, point[2] + state.dy + m.heldItemOffset[2] - held.h / 2)
  end
end
function Chrome.drawParty(ui)
  Chrome.drawBg()
  for i = 1, 6 do drawSlot(ui, i, ui._party and ui._party[i]) end
end
return Chrome
