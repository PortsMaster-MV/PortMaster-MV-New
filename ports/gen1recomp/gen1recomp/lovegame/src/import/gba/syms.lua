local Syms = {}

local loaded = {}

local function parse(src)
  local objs = {}
  for line in src.objs:gmatch("[^\n]+") do objs[#objs + 1] = line end
  local collide = {}
  for line in src.collide:gmatch("[^\n]+") do collide[line] = true end
  local byName, byOff = {}, {}
  for name, off, size, obj in src.data:gmatch("([^ \n]+) (%x+) (~?%x+) ?(%d*)") do
    local span = size:sub(1, 1) == "~"
    local row = {
      name = name,
      off = tonumber(off, 16),
      size = tonumber(span and size:sub(2) or size, 16),
      span = span,
      obj = obj ~= "" and objs[tonumber(obj)] or nil,
    }
    if collide[name] then
      byName[(row.obj or "") .. ":" .. name] = row
    else
      byName[name] = row
      if row.obj then byName[row.obj .. ":" .. name] = row end
    end
    local at = byOff[row.off]
    if not at then at = {}; byOff[row.off] = at end
    at[#at + 1] = name
  end
  return { byName = byName, byOff = byOff, collide = collide }
end

local function lazy(game, suffix)
  local key = game .. suffix
  local t = loaded[key]
  if t then return t end
  local ok, src = pcall(require, "src.import.gba.syms." .. key)
  if not ok or type(src) ~= "table" then
    error("syms: no symbol table for '" .. tostring(game) .. "'", 3)
  end
  t = parse(src)
  package.loaded["src.import.gba.syms." .. key] = nil
  loaded[key] = t
  return t
end

local function row(t, game, name, what)
  local r = t.byName[name]
  if r then return r end
  if t.collide[name] then
    error(string.format("syms(%s): %s '%s' is defined in several objects; use 'file.o:%s'",
      game, what, name, name), 3)
  end
  error(string.format("syms(%s): unknown %s '%s'", game, what, tostring(name)), 3)
end

local instances = {}

function Syms.of(game)
  assert(type(game) == "string" and game ~= "", "Syms.of needs a game id")
  local S = instances[game]
  if S then return S end
  S = { game = game }

  local function data() return lazy(game, "") end
  local function funcs() return lazy(game, "_funcs") end

  function S.has(name)
    local t = data()
    return t.byName[name] ~= nil
  end

  function S.off(name)
    return row(data(), game, name, "symbol").off
  end

  function S.addr(name)
    return 0x08000000 + row(data(), game, name, "symbol").off
  end

  function S.size(name)
    return row(data(), game, name, "symbol").size
  end

  function S.sizeKind(name)
    return row(data(), game, name, "symbol").span and "span" or "elf"
  end

  function S.obj(name)
    return row(data(), game, name, "symbol").obj
  end

  function S.count(name, stride)
    assert(type(stride) == "number" and stride > 0, "Syms.count needs a positive stride")
    local size = row(data(), game, name, "symbol").size
    if size % stride ~= 0 then
      error(string.format("syms(%s): %s size %d is not a multiple of %d", game, name, size, stride), 2)
    end
    return size / stride
  end

  function S.namesAt(off)
    local at = data().byOff[off]
    if not at then return {} end
    local out = {}
    for i, n in ipairs(at) do out[i] = n end
    return out
  end

  function S.hasFunc(name)
    return funcs().byName[name] ~= nil
  end

  function S.funcOff(name)
    return row(funcs(), game, name, "function").off
  end

  function S.funcAt(ptr)
    local off = tonumber(ptr)
    if not off then return nil end
    if off >= 0x08000000 then off = off - 0x08000000 end
    if off % 2 == 1 then off = off - 1 end
    local at = funcs().byOff[off]
    return at and at[1] or nil
  end

  instances[game] = S
  return S
end

function Syms.reset()
  loaded = {}
  instances = {}
end

return Syms
