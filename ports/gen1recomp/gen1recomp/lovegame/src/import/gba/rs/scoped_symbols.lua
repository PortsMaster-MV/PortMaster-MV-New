local M = {}

function M.bind(c, aliases)
  local native = c.S
  local function key(name)
    local selected = aliases and aliases[name] or name
    if native.has(selected) then return selected end
    local global = selected:match("^[^:]+:(.+)$")
    if global and native.has(global) then return global end
    return selected
  end
  c.S = setmetatable({
    has = function(name) return native.has(key(name)) end,
    off = function(name) return native.off(key(name)) end,
    addr = function(name) return native.addr(key(name)) end,
    size = function(name) return native.size(key(name)) end,
    sizeKind = function(name) return native.sizeKind(key(name)) end,
    obj = function(name) return native.obj(key(name)) end,
    count = function(name, stride) return native.count(key(name), stride) end,
  }, {__index = native})
  return c
end
return M
