local Song = require("src.core.game3.song_ids")

local function isSongName(k)
  return type(k) == "string" and (k:find("^MUS_") or k:find("^SE_") or k:find("^PH_")) ~= nil
end

local function lookup(_, k)
  if isSongName(k) then return Song[k] end
  return nil
end

return function(t)
  local mt = getmetatable(t)
  if mt == nil then
    return setmetatable(t, { __index = lookup })
  end
  local prev = mt.__index
  mt.__index = function(self, k)
    local v
    if type(prev) == "function" then v = prev(self, k)
    elseif type(prev) == "table" then v = prev[k] end
    if v ~= nil then return v end
    return lookup(self, k)
  end
  return t
end
