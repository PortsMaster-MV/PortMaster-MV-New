local Stack = require("src.ui.game3.stack")
local Kit = require("src.ui.game3.rse.scene_kit")
local Font = require("src.ui.game3.frlg_font")
local Pal = require("src.core.game3.pal_fade")
local Fx = require("src.core.game3.gba_fx")
local Reader = {isMenu = true, open = false}

function Reader.manifest()
  local man = assert(Kit.manifest("rse/mail"), "native RS mail pack missing")
  assert(man.layout == "rs", "native RS mail pack required")
  return man
end

function Reader.designOf(mail, man)
  man = man or Reader.manifest()
  local design = (tonumber(mail and mail.itemId) or 0) - man.firstMailItem
  if not man.designs[design] then return 0, false end
  return design, true
end

function Reader.content(mail, man)
  man = man or Reader.manifest()
  local design, hasText = Reader.designOf(mail, man)
  local result = {design = design, hasText = hasText, rows = {}}
  local icon = man.icon
  local species, letter = tonumber(mail and mail.species) or 0, nil
  if species >= icon.unownMailBase and species < icon.unownMailBase + icon.unownForms then
    letter, species = species - icon.unownMailBase, icon.unown
  end
  local pos = icon.positions[design]
  if species >= 1 and species <= icon.maxMailSpecies and pos then
    local iconSpecies = species
    if species == icon.unown then
      iconSpecies = letter and letter > 0 and icon.unownB + letter - 1 or icon.unown
    elseif species > icon.egg then iconSpecies = icon.fallback end
    result.icon = {species = iconSpecies, x = pos[1], y = pos[2], frame = icon.frame}
  end
  if not hasText then return result end
  local layout = man.layouts.tall[design]
  local Easy = require("src.core.game3.easy_chat_text")
  local word, y = 1, 0
  for _, line in ipairs(layout.lines) do
    local parts = {}
    for i = 1, line.words do
      local id = tonumber(mail.words and mail.words[word]) or 65535
      parts[#parts + 1] = Easy.rawWord(id)
      if i < line.words and id ~= 65535 then parts[#parts + 1] = " " end
      word = word + 1
    end
    local value = table.concat(parts)
    if value ~= "" and value:sub(1, 1) ~= " " then
      y = y + line.yOffset
      result.rows[#result.rows + 1] = {text = value, x = (layout.wordsX + line.xOffset) * 8, y = (layout.wordsY + y) * 8}
      y = y + 2
    end
  end
  local name = tostring(mail.playerName or ""):gsub("{[^}]*}", "")
  local length = 0; for _ in name:gmatch("[^\128-\191]") do length = length + 1 end
  result.signature = {prefix = man.from, name = name, japaneseName = length < 6,
    text = man.from .. name, x = layout.signatureX * 8, y = layout.signatureY * 8}
  return result
end

function Reader.read(mail, opts)
  opts = opts or {}
  Reader._man, Reader._mail, Reader._session = Reader.manifest(), assert(mail), opts.session
  Reader._content, Reader._onClose = Reader.content(mail, Reader._man), opts.onClose
  Reader._pal = Pal.new()
  Reader._pal:beginFade(Pal.ALL, 0, 16, 0, Pal.BLACK)
  Reader._state, Reader.open = "fade_in", true
  Stack.push("rs_mail", Reader, {hideBelow = true, fullscreen = true})
end

function Reader.isOpen() return Reader.open end
function Reader.close()
  if not Reader.open then return end
  Reader.open = false
  Stack.pop("rs_mail")
  local cb = Reader._onClose
  Reader._onClose = nil
  if cb then cb() end
end
function Reader.reset()
  Reader._onClose = nil
  Reader.close()
  Reader._mail, Reader._content, Reader._session, Reader._pal = nil, nil, nil, nil
end
function Reader.update()
  if not Reader.open or Reader._state == "input" then return end
  Reader._pal:updateFade()
  if not Reader._pal:fadeActive() then
    if Reader._state == "fade_out" then Reader.close() else Reader._state = "input" end
  end
end
function Reader.handleInput(input)
  if not Reader.open or Reader._state ~= "input" then return end
  if input:wasPressed("a") or input:wasPressed("b") then
    Reader._pal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK)
    Reader._state = "fade_out"
  end
end

local function gender(session)
  local value = session and (session.gender or session.playerGender)
  return (value == 1 or value == "female" or value == "F") and 1 or 0
end
local function color(value, slot)
  local out = {}
  for i = 1, 3 do
    local channel = math.floor(value / 2 ^ ((i - 1) * 5)) % 32
    channel = channel + math.floor(((slot.color[i] or 0) - channel) * slot.y / 16)
    out[i] = (channel * 8 + math.floor(channel / 4)) / 255
  end
  out[4] = 1
  return out
end
function Reader.draw()
  if not Reader.open then return end
  local man, content = Reader._man, Reader._content
  local design = assert(man.designs[content.design])
  local bg = assert(Kit.image(design.files[gender(Reader._session) + 1]), "native RS stationery missing")
  love.graphics.setColor(1, 1, 1, 1)
  Fx.draw(function() love.graphics.draw(bg, 0, 0) end, Reader._pal:fx(0))
  local colors = {fg = color(design.textColor, Reader._pal.slots[15]),
    shadow = color(design.textShadow, Reader._pal.slots[15]), bg = {0, 0, 0, 0}}
  local font = "native_" .. man.nativeWindow.fontNum
  for _, row in ipairs(content.rows) do Font.draw(row.text, row.x, row.y, {colors = colors, font = font}) end
  local signature = content.signature
  if signature then
    Font.draw(signature.prefix, signature.x, signature.y, {colors = colors, font = font})
    Font.draw(signature.name, signature.x + Font.measure(signature.prefix, {font = font}), signature.y,
      {colors = colors, font = font, japanese = signature.japaneseName})
  end
  if content.icon then
    local icon = content.icon
    local entry = assert(require("src.core.game3.pokemon").icon(icon.species), "native RS mail mon icon missing")
    love.graphics.setColor(1, 1, 1, 1)
    Fx.draw(function()
      love.graphics.draw(entry.image, assert(entry.quads[icon.frame]), icon.x - entry.w / 2, icon.y - entry.h / 2)
    end, Reader._pal:fx(16))
  end
end

return Reader
