local bit = require("bit")

local M = {}

-- pokecrystal data/sprites/map_objects.asm:1
local MOVEMENT = {
  { 0, 1, 2, 0, 0 },
  { 0, 1, 12, 0, 0 },
  { 0, 1, 0, 0, 0 },
  { 0, 1, 0, 0, 0 },
  { 0, 1, 0, 0, 0 },
  { 0, 1, 0, 0, 0 },
  { 0, 1, 0, 0, 0 },
  { 1, 1, 0, 0, 0 },
  { 2, 1, 0, 0, 0 },
  { 3, 1, 0, 0, 0 },
  { 0, 1, 0, 0, 0 },
  { 0, 1, 2, 0, 0 },
  { 0, 1, 0, 0, 0 },
  { 0, 1, 0, 0, 0 },
  { 0, 1, 0, 0, 0 },
  { 0, 1, 0, 0, 0 },
  { 0, 1, 0, 0, 0 },
  { 0, 1, 0, 0, 0 },
  { 0, 1, 0, 0, 0 },
  { 0, 1, 2, 0, 0 },
  { 0, 1, 2, 0, 0 },
  { 0, 9, 46, 1, 192 },
  { 0, 10, 46, 0, 0 },
  { 0, 1, 12, 0, 0 },
  { 0, 1, 46, 16, 0 },
  { 0, 1, 46, 0, 64 },
  { 0, 1, 2, 0, 0 },
  { 0, 0, 142, 1, 0 },
  { 0, 8, 142, 2, 0 },
  { 0, 0, 130, 0, 0 },
  { 2, 1, 0, 0, 0 },
  { 3, 1, 0, 0, 0 },
  { 0, 12, 46, 1, 192 },
  { 0, 13, 46, 1, 192 },
  { 0, 14, 142, 1, 0 },
  { 0, 15, 142, 2, 0 },
  { 0, 1, 0, 0, 32 },
}


-- pokecrystal engine/overworld/player_object.asm:415
function M.rows(data, version, def, save, x, y, masks, first)
  local visible = {}
  for i, obj in ipairs(def.objects or {}) do
    local dx, dy = (obj.x or 0) + 5 - x, (obj.y or 0) + 5 - y
    if (obj.spriteId or 0) ~= 0 and masks[first + i] == 0 and dx >= 0 and dx < 12 and dy >= 0 and dy < 11 then
      visible[#visible + 1] = i
    end
  end
  if #visible == 0 then return {} end
  local sprites, err = require("src.save_convert.Gen2SpriteContext").build(data, version, def, save)
  if not sprites then return nil, err end
  local rows = {}
  for _, i in ipairs(visible) do
    local obj = def.objects[i]
    local attributes = MOVEMENT[(obj.movement or 0) + 1]
    local sprite = sprites[obj.spriteId]
    if not attributes then return nil, "map object movement is unsupported on cartridge" end
    if not sprite then return nil, "map cache has no object sprite metadata (re-import the ROM)" end
    local row = {}
    for j = 1, 40 do row[j] = 0 end
    local slot = first + i - 1
    local ox, oy = (obj.x or 0) + 4, (obj.y or 0) + 4
    row[1], row[2], row[3], row[4] = obj.spriteId, slot, sprite.tile, obj.movement or 0
    row[5], row[6] = attributes[3], attributes[4]
    local palette = (obj.palette or 0) ~= 0 and obj.palette % 8 or sprite.palette
    row[7] = bit.bor(attributes[5], palette)
    row[9], row[12], row[14] = attributes[1] * 4 % 16, attributes[2], 0xFF
    row[17], row[18], row[21], row[22] = ox % 256, oy % 256, ox % 256, oy % 256
    local radius = obj.radius or {}
    row[23] = (((radius.y or 0) + 1) % 16) * 16 + ((radius.x or 0) + 1) % 16
    row[24], row[25] = (ox - x) % 16 * 16, (oy - y) % 16 * 16
    row[33] = obj.sight or 0
    rows[i] = row
  end
  return rows
end

function M.carried(def, bytes, offsets)
  local map = {}
  for key, value in pairs(def) do map[key] = value end
  map.objects = {}
  for i in ipairs(def.objects or {}) do
    local at = offsets.mapObjects + (offsets.firstObjectSlot + i - 1) * 16
    local function get(off) return bytes[at + off] or 0 end
    local radius, hours, palette = get(5), { get(6), get(7) }, get(8)
    for j = 1, 2 do if hours[j] == 255 then hours[j] = -1 end end
    map.objects[i] = { index = i, spriteId = get(1), y = get(2) - 4, x = get(3) - 4,
      movement = get(4), radius = { y = math.floor(radius / 16), x = radius % 16 },
      hours = hours, palette = math.floor(palette / 16), type = palette % 16,
      sight = get(9), script = get(10) + get(11) * 256, eventFlag = get(12) + get(13) * 256 }
  end
  return map
end

M.MOVEMENT = MOVEMENT
return M
