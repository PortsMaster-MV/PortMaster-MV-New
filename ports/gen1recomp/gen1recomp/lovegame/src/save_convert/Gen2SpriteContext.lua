local M = {}

local function refuse(reason)
  error("Gen 2 sprite metadata " .. reason .. " (re-import the ROM)", 0)
end

local function byte(value)
  if type(value) ~= "number" or value % 1 ~= 0 or value < 0 or value > 255 then
    refuse("contains an invalid sprite ID")
  end
  return value
end

local function build(data, edition, map, save)
  local constants = type(data) == "table" and data.constants
  local meta = type(constants) == "table" and constants.spriteContext
  if type(meta) ~= "table" or meta.version ~= 1 or type(meta.rows) ~= "table"
      or type(meta.outdoorGroups) ~= "table" or type(data.sprites) ~= "table" then
    refuse("is missing")
  end
  local crystal = edition == "crystal"
  if edition ~= "gold" and edition ~= "silver" and not crystal then
    refuse("has an unsupported edition")
  end
  if meta.edition ~= edition or meta.capacity ~= (crystal and 32 or 12)
      or meta.maxOutdoorSprites ~= (crystal and 23 or 11) then
    refuse("belongs to a different edition")
  end
  local order, ids = constants.spriteOrder, {}
  if type(order) ~= "table" then refuse("has no sprite order") end
  for id, name in ipairs(order) do if name ~= "UNUSED" then ids[name] = id end end
  local variables = type(save.variableSprites) == "table" and save.variableSprites or {}
  local function resolve(raw, seen)
    raw = byte(raw)
    if raw >= 0xF0 then
      seen = seen or {}
      if seen[raw] then refuse("contains a variable sprite cycle") end
      seen[raw] = true
      local nextId = variables[raw - 0xF0] or variables[tostring(raw - 0xF0)] or 0
      if type(nextId) == "string" then nextId = ids[nextId] or tonumber(nextId) end
      if nextId == 0 then nextId = 1 end
      return resolve(nextId, seen)
    end
    if raw >= 0x80 then
      if raw == 0xE0 or raw == 0xE1 then
        local care = save.dayCare or {}
        local slot = raw == 0xE0 and care.man or care.lady
        local mon = slot and slot.mon
        if not (mon and mon.species and mon.species ~= 0) then return resolve(1) end
      elseif not (order[raw] and order[raw] ~= "UNUSED" and data.sprites[order[raw]]) then
        refuse("has no data for sprite " .. raw)
      end
      return { type = 1, length = 8, palette = 0 }
    end
    local row = meta.rows[raw]
    if type(row) ~= "table" or (row.type ~= 1 and row.type ~= 2 and row.type ~= 3)
        or type(row.length) ~= "number" or row.length % 1 ~= 0 or row.length < 1
        or row.length > 128 or type(row.palette) ~= "number" or row.palette % 1 ~= 0
        or row.palette < 0 or row.palette > 7 then
      refuse("has no data for sprite " .. raw)
    end
    return row
  end
  local female = crystal and type(save.player) == "table" and save.player.gender == "female"
  local state = save.playerState or "normal"
  local name = state == "bike" and (female and "SPRITE_KRIS_BIKE" or "SPRITE_CHRIS_BIKE")
    or state == "surf" and "SPRITE_SURF"
    or (state == "surf_pika" or state == "surf_pikachu") and "SPRITE_SURFING_PIKACHU"
    or (female and "SPRITE_KRIS" or "SPRITE_CHRIS")
  local player = ids[name]
  if not player then refuse("has no player sprite") end
  local pairs, cap = {}, meta.capacity
  for i = 1, cap do pairs[i] = { id = 0, tile = 0 } end
  pairs[1].id = player
  local function insert(raw, first, last)
    for i = first, last do
      if pairs[i].id == raw then return true end
      if pairs[i].id == 0 then pairs[i].id = raw return true end
    end
    return false
  end
  -- pret/pokegold engine/overworld/overworld.asm:126; pokecrystal:310
  local function add(raw)
    raw = byte(raw)
    if raw == 0 then return end
    if crystal then
      insert(raw, 2, cap)
    else
      local row = raw < 0x80 and resolve(raw) or nil
      if row and row.type == 3 and insert(raw, cap - 1, cap) then return end
      insert(raw, 2, cap - 2)
    end
  end
  local environment = map.environment
  local outdoor = environment == "TOWN" or environment == "ROUTE"
  if not environment and constants.environmentOrder then
    environment = constants.environmentOrder[map.environmentId]
    outdoor = environment == "TOWN" or environment == "ROUTE"
  end
  if outdoor then
    local group = meta.outdoorGroups[map.group]
    if type(group) ~= "table" or #group ~= meta.maxOutdoorSprites then
      refuse("has no outdoor group " .. tostring(map.group))
    end
    for _, raw in ipairs(group) do add(raw) end
  else
    for _, obj in ipairs(map.objects or {}) do add(obj.spriteId or ids[obj.sprite] or 0) end
  end
  if crystal then
    local n = 0
    for i = 1, cap do
      if pairs[i].id == 0 then break end
      pairs[i].type = resolve(pairs[i].id).type
      pairs[i].tile = pairs[i].type
      n = i
    end
    -- pret/pokecrystal engine/overworld/overworld.asm:372,442
    for i = 1, n - 1 do
      for j = n, i + 1, -1 do
        if pairs[j].type < pairs[i].type then pairs[i], pairs[j] = pairs[j], pairs[i] end
      end
    end
    local tile = 0
    for i = 1, n do
      local length = pairs[i].type == 3 and 4 or 12
      if tile < 128 and tile + length > 128 then tile = 128 end
      if tile + length > 255 then break end
      pairs[i].tile = tile
      tile = tile + length
    end
  else
    local tile = 0
    -- pret/pokegold engine/overworld/overworld.asm:175,216
    for i = 1, cap - 2 do
      if pairs[i].id ~= 0 then
        pairs[i].tile = tile
        tile = tile + resolve(pairs[i].id).length
        if tile >= 128 then break end
      end
    end
    pairs[cap - 1].tile, pairs[cap].tile = 0x78, 0x7C
  end
  local out = {}
  -- pret/pokegold home/map_objects.asm:17; pokecrystal home/map_objects.asm:17
  local function entry(raw, isPlayer)
    raw = byte(raw)
    if raw == 0 then return end
    local tile = pairs[1].tile
    if not isPlayer then
      for i = 2, cap do if pairs[i].id == raw then tile = pairs[i].tile break end end
    end
    out[raw] = { tile = tile, palette = resolve(raw).palette }
  end
  entry(player, true)
  for _, obj in ipairs(map.objects or {}) do entry(obj.spriteId or ids[obj.sprite] or 0) end
  return out
end

function M.build(data, edition, map, save)
  local ok, result = pcall(build, data, edition, map or {}, save or {})
  if ok then return result end
  return nil, tostring(result)
end

return M
