local TextIR = require("src.core.game3.scripting.text_ir")
local Strings = require("src.core.Strings")

local RomText = {}

RomText.overrides = {}

local function bundle()
  return require("src.core.game3.scripting.space").ensureBundle()
end

local function alias(key)
  local ok, row = pcall(function() return require("src.core.game3.profile").forSession() end)
  local aliases = ok and type(row) == "table" and type(row.ui) == "table" and row.ui.textAliases or nil
  return aliases and aliases[key] or nil
end

local function cachedText(b, key)
  local text = b and b.text
  if not text then return nil end
  if text[key] ~= nil then return text[key] end
  local to = alias(key)
  if type(to) == "string" then return text[to] end
  if type(to) == "table" and to.key and to.line then
    local source = text[to.key]
    if not source then return nil end
    local out, header, line, leading, found = {}, {}, 1, true, false
    for _, seg in ipairs(source) do
      if leading and seg.t == "ext" then header[#header + 1] = seg
      else leading = false end
      if seg.t == "nl" then
        line = line + 1
        if line == to.line then
          for _, control in ipairs(header) do out[#out + 1] = control end
        end
      elseif line == to.line then
        out[#out + 1] = seg
        found = true
      end
    end
    return found and out or nil
  end
end

function RomText.ir(key)
  local over = RomText.overrides[key]
  if over ~= nil then return over end
  local b = bundle()
  local ir = cachedText(b, key)
  return assert(ir, "ROM text " .. tostring(key) .. " is not in the script cache")
end

function RomText.has(key)
  if RomText.overrides[key] ~= nil then return true end
  local b = bundle()
  return cachedText(b, key) ~= nil
end

function RomText.irOr(key, fallback)
  if key ~= nil and RomText.has(key) then return RomText.ir(key) end
  return fallback
end

function RomText.refIr(ref)
  if type(ref) ~= "table" then return nil end
  return RomText.irOr(ref.name, RomText.irOr(ref.key, ref.ir))
end

local SOURCE_FORMS = {}
for _, named in ipairs({ false, true }) do
  for _, nl in ipairs({ "\n", "\\n" }) do
    for _, para in ipairs({ "\\p", "\n", "\f" }) do
      for _, digits in ipairs({ false, true }) do
        for _, trim in ipairs({ false, true }) do
          SOURCE_FORMS[#SOURCE_FORMS + 1] = { named = named, nl = nl, para = para, digits = digits,
            trim = trim, scroll = (nl ~= "\n") and "\\l" or nil }
        end
      end
    end
  end
end

local function hasDigits(args)
  for _, v in ipairs(args) do
    if tostring(v):match("^%d+$") then return true end
  end
  return false
end

local function eachSource(ir, ctx, fn)
  local seen, numeric = {}, nil
  for _, form in ipairs(SOURCE_FORMS) do
    local source, args, suffix
    if form.digits then
      if numeric == nil then numeric = hasDigits(select(2, TextIR.toSource(ir, ctx))) end
      if numeric then source, args, suffix = TextIR.toSource(ir, ctx, form) end
    else
      source, args, suffix = TextIR.toSource(ir, ctx, form)
    end
    if source and not seen[source] then
      seen[source] = true
      local done = fn(source, args, suffix)
      if done ~= nil then return done end
    end
  end
  return nil
end

function RomText.sources(ir, ctx)
  local out = {}
  eachSource(ir, ctx, function(source, args, suffix)
    out[#out + 1] = { source = source, args = args, suffix = suffix }
  end)
  return out
end

function RomText.translate(ir, ctx, key)
  if not Strings.active() then return ir end
  if key ~= nil then
    local source, args = TextIR.toSource(ir, ctx)
    local out = Strings.translateLabel(key, source, (table.unpack or unpack)(args, 1, #args))
    if out ~= nil then return TextIR.fromAscii(out) end
  end
  return eachSource(ir, ctx, function(source, args, suffix)
    local out = Strings.translate(source, key, (table.unpack or unpack)(args, 1, #args))
    if out ~= nil then return TextIR.fromAscii(out .. suffix) end
  end) or ir
end

function RomText.box(key, ctx)
  ctx = ctx or {}
  return TextIR.toTextBox(RomText.translate(RomText.ir(key), ctx, key), ctx)
end

-- Segment types whose expansion reads nothing but the segment itself.  An IR
-- made only of these expands to the same plain string every time.
local PURE_SEG = { text = true, tag = true, nl = true, para = true, scroll = true, eos = true, ext = true }

-- plain() results for pure IRs, keyed by the IR table itself (false = not
-- pure).  Keying on the IR follows overrides, profile aliases and bundle
-- reloads for free: each resolves to a different table.
local plainCache = setmetatable({}, { __mode = "k" })

local function pure_ir(ir)
  if type(ir) ~= "table" then return false end
  for i = 1, #ir do
    local seg = ir[i]
    if type(seg) ~= "table" or not PURE_SEG[seg.t] then return false end
  end
  return true
end

function RomText.plain(key, ctx)
  if ctx == nil and not Strings.active() then
    local ir = RomText.ir(key)
    local hit = plainCache[ir]
    if hit then return hit end
    if hit == nil then
      local pure = pure_ir(ir)
      local out = TextIR.toPlain(ir, {})
      plainCache[ir] = pure and out or false
      return out
    end
    return TextIR.toPlain(ir, {})
  end
  ctx = ctx or {}
  return TextIR.toPlain(RomText.translate(RomText.ir(key), ctx, key), ctx)
end

function RomText.ascii(key, ctx)
  ctx = ctx or {}
  return TextIR.toAscii(RomText.translate(RomText.ir(key), ctx, key), ctx)
end

function RomText.key(name, i, j)
  if j ~= nil then return string.format("%s[%d][%d]", name, i, j) end
  return string.format("%s[%d]", name, i)
end

function RomText.count(name)
  local b = bundle()
  local tables = assert(b and b.textTables, "scripts/text_tables.lua is not in the script cache")
  local n = assert(tables[name], "ROM text table " .. tostring(name) .. " is not in the script cache")
  if type(n) == "table" then return n[1], n[2] end
  return n
end

function RomText.at(name, i, j, ctx)
  return RomText.plain(RomText.key(name, i, j), ctx)
end

function RomText.list(name, ctx)
  local out = {}
  for i = 0, RomText.count(name) - 1 do
    local key = RomText.key(name, i)
    out[i + 1] = RomText.has(key) and RomText.plain(key, ctx) or nil
  end
  return out
end

function RomText.lazy(map, ctx)
  return setmetatable({}, {
    __index = function(_, k)
      local key = map[k]
      if key == nil then return nil end
      return RomText.plain(key, ctx)
    end,
  })
end

return RomText
