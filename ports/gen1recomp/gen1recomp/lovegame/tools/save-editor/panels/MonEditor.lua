-- Species art and the inspector shell. InspectorBody owns the six forms;
-- phones open them as pages and wide windows dock them next to the roster.

local Theme = require("Theme")
local PAL = Theme.PAL
local Gen = require("Gen")

local MonEditor = {}

-- Front sprites are read straight off the generated cache.  One image per
-- species, cached for the process: the old panel called newImage every frame,
-- which re-decoded a PNG sixty times a second.
local spriteCache = {}
function MonEditor.sprite(S, species)
  if not species then return nil end
  if spriteCache[species] ~= nil then return spriteCache[species] or nil end
  if Gen.ofState(S) == 3 then
    local okP, Pokemon = pcall(require, "src.core.game3.pokemon")
    if okP and Pokemon then
      local spId = tonumber(species) or (Pokemon.speciesFromName and Pokemon.speciesFromName(tostring(species)))
      if spId then
        local pic = (Pokemon.frontPic and Pokemon.frontPic(spId)) or (Pokemon.icon and Pokemon.icon(spId))
        if pic and pic.image then
          spriteCache[species] = pic.image
          return pic.image
        end
      end
    end
  end
  local def = S.data and S.data.pokemon and (S.data.pokemon[species] or (type(species) == "number" and S.data.pokemon[species]))
  local path = def and def.spriteFront
  if not path or not love.graphics.newImage then
    spriteCache[species] = false
    return nil
  end
  local ok, img = pcall(love.graphics.newImage, path)
  spriteCache[species] = ok and img or false
  return ok and img or nil
end

-- Draw a species sprite fitted into a box, or a dashed placeholder when the
-- cache has no art for it (a modded species, or a headless run).
function MonEditor.drawSprite(S, Kit, species, x, y, size)
  local img = MonEditor.sprite(S, species)
  if img and love.graphics.draw and img.getDimensions then
    local iw, ih = img:getDimensions()
    if iw > 0 and ih > 0 then
      local scale = math.min(size / iw, size / ih)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(img, x + (size - iw * scale) / 2,
        y + (size - ih * scale) / 2, 0, scale, scale)
      return
    end
  end
  Theme.col(PAL.blue, 0.1)
  love.graphics.rectangle("fill", x, y, size, size, 8 * Kit.scale, 8 * Kit.scale)
  Theme.col(PAL.cardBorder, 0.35)
  Theme.dashed(x, y, size, size, 8 * Kit.scale, 5 * Kit.scale, 4 * Kit.scale)
  Kit.textCenter("micro", tostring(species or "?"):sub(1, 3), x,
    y + size / 2 - Kit.textHeight("micro") / 2, size, PAL.muted)
end

-- The inspector uses sections so a phone gives each editing task its full height.
function MonEditor.draw(S, Kit, x, y, w, h)
  Kit.card(x, y, w, h)
  require("InspectorBody").draw(S, Kit, x, y, w, h)
end

return MonEditor
