local Stack = require("src.ui.game3.stack")
local Kit = require("src.ui.game3.rse.scene_kit")
local Font = require("src.ui.game3.frlg_font")
local Pal = require("src.core.game3.pal_fade")
local Fx = require("src.core.game3.gba_fx")
local Policy = require("src.ui.game3.rs.trainer_card_policy")
local T = {isMenu = true, open = false, side = "front", _phase = "idle"}
function T.manifest()
  local m = assert(Kit.manifest("rse/trainer_card"), "native RS trainer card pack missing")
  assert(m.cardType == "rs" and m.layout == "rs", "native RS trainer card pack required")
  return m
end
local function copiedCard(card)
  local out = {}; for k, v in pairs(card) do out[k] = v end
  out.pokedexSeen = tonumber(out.pokedexSeen or out.caughtMonsCount) or 0
  out.name = tostring(out.name or out.playerName or "")
  out.gender = out.gender or out.playerGender or 0
  out.stars = math.max(0, math.min(4, math.floor(tonumber(out.stars) or 0)))
  return out
end
function T.show(opts)
  opts = opts or {}
  local rt = package.loaded["src.core.game3.runtime"]
  T._session = opts.session or (rt and rt.getSession and rt.getSession()) or {}
  T._clockSession = opts.clockSession or (rt and rt.getSession and rt.getSession()) or T._session
  T._link = opts.linkCard == true or (T._session.dex == nil and T._session.stars ~= nil)
  T._card = T._link and copiedCard(T._session) or Policy.generate(T._session)
  T._man, T._onClose = T.manifest(), opts.onClose
  T.open, T.side, T._phase, T._setup = true, "front", "setup", 0
  T._pal, T._stepper = Pal.new(), Kit.stepper()
  T._pal:blend(Pal.ALL, 16, Pal.BLACK)
  T._colon, T._colonFrame, T._printColon, T._lastColon = false, 0, false, false
  T._flip, T._offsets, T._canvas, T._quads = nil, nil, nil, {}
  Stack.push("trainer", T, {hideBelow = true, fullscreen = true})
end
function T.isOpen() return T.open end
function T.phase() return T._phase end
function T.close()
  if not T.open then return end
  T.open, T._phase = false, "idle"
  Stack.pop("trainer")
  if T._canvas and T._canvas.release then T._canvas:release() end
  T._canvas = nil
  local cb = T._onClose; T._onClose = nil
  if cb then cb() end
end
function T.reset()
  T._onClose = nil; T.close()
  T._session, T._clockSession, T._card, T._man, T._pal, T._stepper, T._flip, T._offsets, T._quads = nil, nil, nil, nil, nil, nil, nil, nil, nil
end
function T.handleInput(inp) if T.open then T._stepper:collect(inp) end end
local function startOut()
  T._phase = "out"
  T._pal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK)
end
local function tick(inp)
  if T._phase == "setup" then
    -- trainer_card.c:260
    T._setup = T._setup + 1
    if T._setup == 12 then
      T._colon = (tonumber(T._clockSession.playTimeSeconds) or 0) % 2 == 1
      T._colonFrame = tonumber(T._clockSession.playTimeVBlanks) or 0
      T._pal:beginFade(Pal.ALL, 0, 16, 0, Pal.BLACK)
      T._phase = "in"
    end
  else
    if T.side == "front" and T._phase ~= "out" then
      if T._colon ~= T._lastColon then T._printColon = not T._printColon; T._lastColon = T._colon end
    end
    if T._phase == "in" then
      if not T._pal:fadeActive() then T._phase = "wait" end
    elseif T._phase == "wait" then
      if inp.new.b then startOut()
      elseif inp.new.a then
        if T.side == "back" then startOut()
        else
          -- task.c:124
          T._flip, T._phase = {state = "down", top = 3}, "flip"
          T._offsets = Policy.flipOffsets(3, true)
          Kit.playSe("SE_CARD")
        end
      end
    elseif T._phase == "flip" then
      local f = T._flip
      if f.state == "down" then
        f.top = math.min(79, f.top + 3)
        T._offsets = Policy.flipOffsets(f.top, true)
        if f.top > 74 then f.state = "switch" end
      elseif f.state == "switch" then
        T.side, f.state = "back", "up"
        f.top = math.max(0, f.top - 3)
        T._offsets = Policy.flipOffsets(f.top, false)
      elseif f.state == "up" then
        f.top = math.max(0, f.top - 3)
        T._offsets = Policy.flipOffsets(f.top, false)
        if f.top == 0 then f.state = "finish" end
      elseif f.state == "finish" then
        T._flip, T._offsets = nil, nil
        T._phase = "flip_done"
      end
    elseif T._phase == "flip_done" then T._phase = "wait"
    elseif T._phase == "out" and not T._pal:fadeActive() then T.close(); return true end
    T._pal:updateFade()
  end
  if T._phase ~= "setup" then
    T._colonFrame = T._colonFrame + 1
    if T._colonFrame >= 60 then T._colonFrame, T._colon = 0, not T._colon end
  end
end
function T.update(dt) if T.open then T._stepper:run(dt, tick) end end

local function color(v, slot, transparent)
  if transparent then return {0, 0, 0, 0} end
  local out = {}
  for i = 1, 3 do
    local n = math.floor(v / 2 ^ ((i - 1) * 5)) % 32
    n = n + math.floor((slot.color[i] - n) * slot.y / 16)
    out[i] = (n * 8 + math.floor(n / 4)) / 255
  end
  out[4] = 1; return out
end
function T.textOptions(kind)
  kind = kind or "values"
  local w, p = T._man.windows[kind], T._man.textPalettes[kind]
  local slot = T._pal.slots[w.paletteNum]
  return {font = "native_" .. w.font, letterSpacing = w.spacing, linePitch = 16,
    japanese = T._link and tonumber(T._session.language) == 1,
    colors = {fg = color(p[w.foreground + 1], slot), shadow = color(p[w.shadow + 1], slot), bg = color(p[w.background + 1], slot, w.background == 0)}}
end
function T.texts(card, side, colon)
  local c, out, s = card or T._card, {}, T._man.strings
  local function put(id, value, x, y, kind, right, span)
    value = tostring(value)
    local width = Font.measure(value, T.textOptions(kind)) % 256
    if right then x = x - width elseif span then x = x + math.max(0, span - width) end
    out[#out + 1] = {id = id, text = value, x = x, y = y, kind = kind or "values"}
  end
  if side == "front" then
    put("name", c.name, 56, 40)
    put("id", string.format("%05d", tonumber(c.trainerId) or 0), 160, 16)
    put("money", "¥" .. tostring(tonumber(c.money) or 0), 128, 64, "values", true)
    if c.hasPokedex then put("seen", c.pokedexSeen, 128, 80, "values", true) end
    local time = T._link and c or T._session
    put("time", tostring(tonumber(time.playTimeHours) or 0) .. (colon and " : " or "   ") .. string.format("%02d", tonumber(time.playTimeMinutes) or 0), 80, 96, "values", false, 48)
    if T._link then
      local Easy, words = require("src.core.game3.easy_chat_text"), c.easyChatProfile or {}
      for row = 0, 1 do put("phrase" .. row, Easy.rawWord(words[row * 2 + 1] or 65535) .. " " .. Easy.rawWord(words[row * 2 + 2] or 65535), 16, 112 + row * 16) end
    end
  else
    put("name", c.name .. s.nameSuffix, 224, 16, "values", true)
    if (tonumber(c.hofDebutHours) or 0) ~= 0 or (tonumber(c.hofDebutMinutes) or 0) ~= 0 or (tonumber(c.hofDebutSeconds) or 0) ~= 0 then
      put("hofLabel", s.hof, 24, 40)
      put("hof", string.format("%3d", c.hofDebutHours or 0) .. T._man.colonSeparator .. string.format("%02d", c.hofDebutMinutes or 0) .. T._man.colonSeparator .. string.format("%02d", c.hofDebutSeconds or 0), 224, 40, "numbers", true)
    end
    if (tonumber(c.linkBattleWins) or 0) ~= 0 or (tonumber(c.linkBattleLosses) or 0) ~= 0 then
      put("linkLabel", s.link, 24, 56); put("wins", c.linkBattleWins or 0, 176, 56, "numbers", true); put("losses", c.linkBattleLosses or 0, 224, 56, "numbers", true)
    end
    for _, r in ipairs({{"trade", "pokemonTrades", 72, 5}, {"blender", "pokeblocksWithFriends", 88, 5}, {"contest", "contestsWithFriends", 104, 3}}) do
      local v = tonumber(c[r[2]]) or 0
      if v ~= 0 then put(r[1] .. "Label", s[r[1]], 24, r[3]); put(r[1], string.format("%" .. r[4] .. "d", v), 224, r[3], "numbers", true) end
    end
    if (tonumber(c.battleTowerWins) or 0) ~= 0 or (tonumber(c.battleTowerLosses) or 0) ~= 0 then
      put("towerLabel", s.tower, 24, 120)
      put("towerWins", c.battleTowerWins or 0, 112, 120, "numbers", false, 24)
      put("towerBest", c.battleTowerLosses or 0, 149, 120, "numbers", false, 24)
    end
  end
  return out
end
local function female(c) return c.gender == 1 or c.gender == "female" or c.gender == "F" end
local function drawContent()
  local c, m = T._card, T._man
  local p = m.palettes[c.stars][female(c) and "female" or "male"]
  love.graphics.clear(color(p[1], T._pal.slots[0]))
  local function layer(side, slot)
    local e = m.layers[side .. "_" .. c.stars]
    local img = assert(Kit.image(female(c) and e.female or e.png), "native RS card layer missing")
    Fx.draw(function() love.graphics.draw(img, 0, 0) end, T._pal:fx(slot))
  end
  layer("screen", 0)
  local side = T.side == "back" and "back" or T._link and "link" or "front"
  if T.side == "front" and not c.hasPokedex then side = side .. "_no_dex" end
  layer(side, 0)
  if T.side == "front" then
    local pic = assert(Kit.image(m.pics[female(c) and "female" or "male"].png))
    Fx.draw(function() love.graphics.draw(pic, m.pic.x, m.pic.y) end, T._pal:fx(5))
    local star = assert(Kit.image(m.star.png))
    Fx.draw(function() for i = 0, c.stars - 1 do love.graphics.draw(star, m.starPosition[1] + i * 8, m.starPosition[2]) end end, T._pal:fx(4))
    if not T._link then
      local badges = assert(Kit.image(m.badges.png))
      Fx.draw(function()
        for i = 1, 8 do
          if c.badges[i] then
            local q = T._quads["badge" .. i]
            if not q then q = love.graphics.newQuad((i - 1) * 16, 0, 16, 16, badges:getDimensions()); T._quads["badge" .. i] = q end
            love.graphics.draw(badges, q, m.badgePosition[1] + (i - 1) * m.badgePosition[3], m.badgePosition[2])
          end
        end
      end, T._pal:fx(3))
    end
  end
  for _, row in ipairs(T.texts(c, T.side, T._printColon)) do Font.draw(row.text, row.x, row.y, T.textOptions(row.kind)) end
end
function T.draw()
  if not T.open then return end
  if not T._canvas then T._canvas = love.graphics.newCanvas(256, 256); T._canvas:setFilter("nearest", "nearest") end
  local previous = love.graphics.getCanvas()
  love.graphics.push("all")
  love.graphics.setCanvas(T._canvas); love.graphics.origin(); love.graphics.setColor(1, 1, 1, 1)
  drawContent()
  love.graphics.setCanvas(previous); love.graphics.pop()
  love.graphics.setColor(1, 1, 1, 1)
  for y = 0, 159 do
    local source = (y + (T._offsets and T._offsets[y + 1] or -4)) % 256
    local q = T._quads[source]
    if not q then q = love.graphics.newQuad(0, source, 240, 1, 256, 256); T._quads[source] = q end
    love.graphics.draw(T._canvas, q, 0, y)
  end
end
return T
