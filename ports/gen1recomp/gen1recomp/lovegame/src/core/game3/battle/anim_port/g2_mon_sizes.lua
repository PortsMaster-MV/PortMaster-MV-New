local sizes = require("src.core.game3.battle.anim_port.g1_pic_sizes")

local function convert(packed)
  local w = math.floor(packed / 256)
  local h = packed % 256
  return (w / 8) * 16 + h / 8
end

local built = setmetatable({}, { __mode = "k" })

local function active()
  local src = sizes.active()
  local out = built[src]
  if out then return out end
  out = { front = {}, back = {} }
  for sp, packed in pairs(src.front or {}) do out.front[sp] = convert(packed) end
  for sp, packed in pairs(src.back or {}) do out.back[sp] = convert(packed) end
  built[src] = out
  return out
end

return setmetatable({}, {
  __index = function(_, k)
    if k == "front" or k == "back" then return active()[k] end
    return nil
  end,
})
