local Pokemon = require("src.core.game3.pokemon")
local Storage = require("src.core.game3.storage")
local M = {}

-- pokeruby/pokemon_storage_system_3.c:40
function M.start(seq)
  seq._rsRelease = nil
  local index = seq.slotIdx - 1
  if seq.loc == "party" then
    seq.startX = index == 0 and 104 or 152
    seq.startY = index == 0 and 64 or 16 + (index - 1) * 24
  else
    seq.startX, seq.startY = 100 + index % 6 * 24, 44 + math.floor(index / 6) * 24
  end
end

function M.begin(seq)
  seq._rsRelease = {phase = "shrink", frame = 0, scale = 256, matrix = 256,
    affineEnded = false, invisible = false, target = seq.loc}
end
function M.state(seq) return seq._rsRelease end
function M.close(seq) seq._rsRelease = nil end

function M.handleInput(seq, input)
  if seq.state == "return_anim" then return true end
  if seq.state ~= "surprise" then return false end
  if input:wasPressed("a") or input:wasPressed("b") then
    seq.state = "return_anim"
    seq._rsRelease = {phase = "grow", frame = 0, scale = 16, matrix = 4096,
      affineEnded = false, invisible = false, target = seq.loc}
  end
  return true
end

local function finalize(seq)
  if not seq.returns and seq.session then
    if seq.loc == "party" then
      table.remove(seq.session.party, seq.slotIdx)
      Storage.compactParty(seq.session.party)
    else Storage.releaseMon(seq.session, seq.boxId, seq.slotIdx) end
  end
  seq.state = "released"
end

function M.update(seq)
  local a = seq._rsRelease
  if not a or (seq.state ~= "anim" and seq.state ~= "return_anim") then return end
  -- pokemon_storage_system_2.c:377
  if a.phase == "finalize" then finalize(seq) return end
  if a.phase == "shrink" then
    if a.invisible then a.phase = "finalize" return end
    if a.affineEnded then a.invisible = true return end
    a.frame = a.frame + 1
    if a.frame <= 120 then a.scale = 256 - 2 * a.frame
    else a.affineEnded = true end
  else
    if a.detached then seq.state = "came_back" return end
    if a.affineEnded then a.detached = true return end
    a.frame = a.frame + 1
    if a.frame <= 16 then a.scale = 16 * a.frame
    else a.affineEnded = true end
  end
  a.matrix = math.floor(65536 / a.scale)
end

local shader
local SOURCE = [[
extern vec2 sheetSize;
extern vec2 frameOrigin;
extern float matrixScale;
vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
  vec2 pos = floor(tc * sheetSize - frameOrigin);
  vec2 source = floor((pos - vec2(16.0)) * matrixScale / 256.0) + vec2(16.0);
  if (source.x < 0.0 || source.y < 0.0 || source.x >= 32.0 || source.y >= 32.0) discard;
  return Texel(tex, (frameOrigin + source + vec2(0.5)) / sheetSize) * color;
}
]]
function M.draw(seq)
  local a = seq._rsRelease
  if not a or a.invisible then return end
  local icon = assert(Pokemon.monIcon(seq.mon), "native RS release icon missing")
  local img = assert(icon.image, "native RS release icon image missing")
  local width, height = img:getDimensions()
  local q = icon.quads and icon.quads[0]
  local x, y, w, h = 0, 0, width, height
  if q then x, y, w, h = q:getViewport() end
  assert(w == 32 and h == 32, "native RS release requires32x32 frame0 icon")
  shader = shader or love.graphics.newShader(SOURCE)
  shader:send("sheetSize", {width, height})
  shader:send("frameOrigin", {x, y})
  shader:send("matrixScale", a.matrix)
  love.graphics.push("all")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setShader(shader)
  if q then love.graphics.draw(img, q, seq.startX - 16, seq.startY - 16)
  else love.graphics.draw(img, seq.startX - 16, seq.startY - 16) end
  love.graphics.pop()
end
return M
