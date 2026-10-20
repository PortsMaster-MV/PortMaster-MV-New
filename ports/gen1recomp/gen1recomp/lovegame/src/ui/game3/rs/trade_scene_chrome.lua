local Sprites = require("src.core.game3.gba_sprites")
local Affine = require("src.core.game3.bg_affine")
local Fx = require("src.core.game3.gba_fx")
local Kit = require("src.ui.game3.rse.scene_kit")
local Pokemon = require("src.core.game3.pokemon")
local Font = require("src.ui.game3.frlg_font")
local M = {}

local function png(read, path)
  local bytes = assert(read(path), "native RS trade PNG missing: " .. tostring(path))
  local data = love.image.newImageData(love.filesystem.newFileData(bytes, path:match("[^/]+$")))
  local image = love.graphics.newImage(data); image:setFilter("nearest", "nearest")
  return image, data
end
function M.load(read, lua, root)
  local man = assert(lua(root .. "/rse/trade/manifest.lua"), "native RS trade manifest missing")
  assert(man.assetLayout == "rs", "native RS trade requires RS assets")
  local art = {native = true, manifest = man, images = {}, data = {}, spriteStates = {}, variants = {}}
  for _, group in ipairs({man.layers, man.sprites}) do
    for key, entry in pairs(group) do art.images[key], art.data[key] = png(read, entry.png) end
  end
  art.images.glow2_base, art.data.glow2_base = png(read, man.sprites.glow2.base)
  art.images.glow2_color4, art.data.glow2_color4 = png(read, man.sprites.glow2.color4Mask)
  local summary = lua(root .. "/rse/summary/manifest.lua")
  art.noFlip = summary and summary.noFlip or {}
  return art
end

local bgShader
local function affineBg(image, refX, refY, centerX, centerY, scale, angle)
  if not bgShader then bgShader = love.graphics.newShader([[
    extern vec4 rows;
    extern vec2 offset;
    extern vec2 sourceSize;
    vec4 effect(vec4 color, Image image, vec2 uv, vec2 sc) {
      vec2 p = floor(uv * vec2(240.0,160.0));
      vec2 t = floor((vec2(dot(rows.xy,p),dot(rows.zw,p)) + offset) / 256.0);
      if (t.x < 0.0 || t.y < 0.0 || t.x >= sourceSize.x || t.y >= sourceSize.y) return vec4(0.0);
      return Texel(image,(t + 0.5) / sourceSize) * color;
    }
  ]]) end
  local reg = Affine.bgAffineSet({texX = refX * 256, texY = refY * 256,
    scrX = centerX, scrY = centerY, sx = scale, sy = scale, alpha = angle})
  local previous = love.graphics.getShader()
  bgShader:send("rows", {reg.pa, reg.pb, reg.pc, reg.pd})
  bgShader:send("offset", {reg.dx, reg.dy}); bgShader:send("sourceSize", {image:getDimensions()})
  love.graphics.setShader(bgShader); love.graphics.setColor(1,1,1,1)
  love.graphics.draw(image, 0, 0, 0, 240 / image:getWidth(), 160 / image:getHeight())
  love.graphics.setShader(previous)
end
local function layer(image, x, y)
  love.graphics.setColor(1,1,1,1); love.graphics.draw(image, x or 0, y or 0)
end
local function glowVariant(art, color)
  if art.variants[color] then return art.variants[color] end
  local base, mask = art.data.glow2_base, art.data.glow2_color4
  local w,h = base:getDimensions()
  local data = love.image.newImageData(w,h)
  local r,g,b = Kit.rgb555(color)
  for y = 0,h-1 do for x = 0,w-1 do
    local br,bg,bb,ba = base:getPixel(x,y)
    local _,_,_,ma = mask:getPixel(x,y)
    if ma > 0 then data:setPixel(x,y,r,g,b,ma) else data:setPixel(x,y,br,bg,bb,ba) end
  end end
  local image = love.graphics.newImage(data); image:setFilter("nearest","nearest")
  art.variants[color] = image
  return image
end
local function sprite(art, key, instance, age, x, y, anim, affineAnim, color, white)
  local entry = art.manifest.sprites[key]
  if not entry then return end
  age = math.max(0, age or 0)
  local state = art.spriteStates[instance]
  if not state or state.age > age then
    local collection = Sprites.new()
    local id = collection:create({w = entry.w, h = entry.h, anims = entry.anims,
      affineAnims = entry.affineAnims, affineMode = entry.affineMode}, 0,0,0)
    state = {collection = collection, sprite = collection.sprites[id], age = -1, quads = {}}
    Sprites.startAnim(state.sprite, anim or 0)
    if entry.affineAnims then collection:startAffineAnim(state.sprite, affineAnim or 0) end
    art.spriteStates[instance] = state
  end
  while state.age < age do state.collection:animate(state.sprite); state.age = state.age + 1 end
  local image = key == "glow2" and color and glowVariant(art,color) or art.images[key]
  local frame = state.sprite.frame or 0
  local quad = state.quads[frame]
  if not quad then quad = love.graphics.newQuad(0,frame * entry.h,entry.w,entry.h,image:getDimensions()); state.quads[frame] = quad end
  local sx,sy,angle = state.sprite.oam.hFlip and -1 or 1, state.sprite.oam.vFlip and -1 or 1, 0
  if entry.affineAnims then
    local st = state.collection.affineStates[state.collection:matrixNumOf(state.sprite)]
    sx,sy,angle = st.xScale / 256, st.yScale / 256, -math.floor(st.rotation / 256) * math.pi / 128
  end
  local function draw()
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(image,quad,x,y,angle,sx,sy,entry.w/2,entry.h/2)
  end
  Fx.draw(draw, white and white > 0 and {y = math.floor(white * 16), color = Fx.WHITE} or nil,
    entry.objMode == 1 and {eva = 12,evb = 4} or nil)
end
local function mon(mon, x, y, scale, mirror)
  local pic = Pokemon.monFrontPic(mon)
  if pic and pic.image and (scale or 1) > 0.02 then
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(pic.image,x,y,0,(scale or 1) * (mirror and -1 or 1),scale or 1,32,32)
  end
end
function M.draw(s, art)
  love.graphics.setColor(s.whiteBlend or 0,s.whiteBlend or 0,s.whiteBlend or 0,1)
  love.graphics.rectangle("fill",0,0,240,160)
  if s.rsBackground == "shadow" then
    layer(art.images.scene_textbox)
    layer(art.images.shadow,-(s.bg2hofs or 0),0)
  elseif s.rsBackground == "gba_affine" then
    local scale = math.floor(32768 / math.max(1,s.bg2Zoom or 1024))
    affineBg(art.images.gba_affine,64,92,120,80,scale,0)
  elseif s.rsBackground == "gba" then
    layer(art.images.gba,0,-(s.bg1vofs or 348))
    layer(art.images.gba,0,512-(s.bg1vofs or 348))
    if s.rsSymbolVisible then affineBg(art.images.ball_symbol,64,64,120,s.rsSymbolY,256,s.rsSymbolRotation) end
  elseif s.rsBackground == "cable" then layer(art.images.cable) end
  local elapsed = s.elapsed or 0
  if s.rsCableCreated and elapsed - s.rsCableCreated < 10 then
    local age = elapsed-s.rsCableCreated
    sprite(art,"cable_end","cable_" .. s.rsCableCreated,age,128,65+(age+1)*s.rsCableDirection)
  end
  if s.flash ~= nil then sprite(art,"gba_screen","flash_" .. tostring(s.rsFlashCreated),elapsed-(s.rsFlashCreated or elapsed),120,80) end
  if s.linkVisible then
    local age,y = elapsed-(s.rsLinkCreated or elapsed),(s.linkY or 0)+(s.linkY2 or 0)
    sprite(art,"glow","glow_" .. tostring(s.rsLinkCreated),age,128,y)
    local colors = art.manifest.glow2Colors
    sprite(art,"glow2","shadow_" .. tostring(s.rsLinkCreated),age,128,y,1,nil,colors[(age+1)%12+1])
  end
  if s.crossVisible then
    local age = elapsed-(s.rsCrossCreated or elapsed)
    local index = (age+1)%12
    if s.rsCrossColorFrozen then
      index = s.rsCrossColorFrozen
      if s.rsCrossColorResumed then index = (index+elapsed-s.rsCrossColorResumed+1)%12 end
    end
    local color = art.manifest.glow2Colors[index+1]
    sprite(art,"glow2","cross0_" .. tostring(s.rsCrossCreated),age,111,(s.crossMonAy or 170)+(s.crossY2a or 0),0,nil,color)
    sprite(art,"glow2","cross1_" .. tostring(s.rsCrossCreated),age,129,(s.crossMonBy or -10)+(s.crossY2b or 0),0,nil,color)
  end
  if s.crossMonVisible then
    local species = tonumber(Pokemon.speciesOf(s.offer))
    mon(s.offer,60,192+(s.monY2a or 0),1,not art.noFlip[species])
    mon(s.received,180,-32+(s.monY2b or 0),1)
  end
  if s.playerVisible then mon(s.offer,120+(s.monX2 or 0),60,s.monScale or 1) end
  if s.partnerVisible then mon(s.received,120,60,1) end
  if s.ballVisible then
    local age = elapsed-(s.rsBallCreated or elapsed)
    local incoming = s.partnerVisible or s.ballStage == "fall" or s.ballStage == "bounce"
    local endPart = s.ballStage == "end"
    sprite(art,"ball","ball_" .. tostring(s.rsBallCreated) .. (endPart and "end" or ""),endPart and s.ballIdx or age,
      s.ballX or 120,(s.ballY or 32)+(s.ballY2 or 0),incoming and 1 or 0,incoming and 2 or (endPart and 1 or 0),nil,s.ballWhite)
  end
  if s.text and s.text ~= "" then
    local w,pal = s.link and art.manifest.windows.sceneLink or art.manifest.windows.sceneNpc,art.manifest.palettes.font
    local function color(index,transparent)
      local r,g,b = Kit.rgb555(pal[index+1]); return {r,g,b,transparent and 0 or 1}
    end
    Font.draw(s.text,16,120,{font = "native_" .. w.fontNum,maxWidth = 208,
      colors = {fg=color(w.foregroundColor),shadow=color(w.shadowColor),bg=color(w.backgroundColor,w.backgroundColor == 0)}})
  end
  if (s.veil or 0) > 0 then love.graphics.setColor(0,0,0,math.min(1,s.veil)); love.graphics.rectangle("fill",0,0,240,160) end
  love.graphics.setColor(1,1,1,1)
end
return M
