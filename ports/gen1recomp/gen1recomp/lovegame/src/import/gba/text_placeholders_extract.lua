local TextPlaceholders = {}

TextPlaceholders.CACHE_SUB = "text"
TextPlaceholders.FILE = "placeholders.lua"
TextPlaceholders.REQUIRED = { "text/placeholders.lua" }

-- pokeemerald/src/strings.c:6
TextPlaceholders.SYMBOLS = {
  UNKNOWN = "gText_ExpandedPlaceholder_Empty",
  KUN_MALE = "gText_ExpandedPlaceholder_Kun",
  KUN_FEMALE = "gText_ExpandedPlaceholder_Chan",
  RIVAL_MALE = "gText_ExpandedPlaceholder_May",
  RIVAL_FEMALE = "gText_ExpandedPlaceholder_Brendan",
  VERSION = "gText_ExpandedPlaceholder_Emerald",
  AQUA = "gText_ExpandedPlaceholder_Aqua",
  MAGMA = "gText_ExpandedPlaceholder_Magma",
  ARCHIE = "gText_ExpandedPlaceholder_Archie",
  MAXIE = "gText_ExpandedPlaceholder_Maxie",
  KYOGRE = "gText_ExpandedPlaceholder_Kyogre",
  GROUDON = "gText_ExpandedPlaceholder_Groudon",
}

-- pokeemerald/src/string_util.c:448
TextPlaceholders.BY_GENDER = {
  KUN = { male = "KUN_MALE", female = "KUN_FEMALE" },
  RIVAL = { male = "RIVAL_MALE", female = "RIVAL_FEMALE" },
}

local TEXT_MAX = 64

local function read_plain(rom, off)
  local TextIR = require("src.core.game3.scripting.text_ir")
  local bytes = {}
  for i = 0, TEXT_MAX - 1 do
    local b = rom:get(off + i)
    bytes[#bytes + 1] = b
    if b == 0xFF then break end
  end
  assert(bytes[#bytes] == 0xFF, string.format("placeholder text at 0x%X has no terminator", off))
  return TextIR.toPlain(TextIR.decode(bytes, { dialect = "rse" }), {})
end

function TextPlaceholders.extract(rom, offsets)
  offsets = offsets or require("src.import.gba.versions").TEXT_PLACEHOLDERS
  assert(type(offsets) == "table", "Versions.TEXT_PLACEHOLDERS is missing for this game")
  local out = { byGender = {} }
  for name in pairs(TextPlaceholders.SYMBOLS) do
    out[name] = read_plain(rom, assert(offsets[name], "no offset for placeholder " .. name))
  end
  for name, off in pairs(offsets) do
    if out[name] == nil then out[name] = read_plain(rom, off) end
  end
  for name, pair in pairs(TextPlaceholders.BY_GENDER) do
    out.byGender[name] = { male = out[pair.male], female = out[pair.female] }
  end
  return out
end

local function serialize(t)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys)
  local parts = { "{\n" }
  for _, k in ipairs(keys) do
    local v = t[k]
    if type(v) == "table" then
      local inner = {}
      local ik = {}
      for k2 in pairs(v) do ik[#ik + 1] = k2 end
      table.sort(ik)
      for _, k2 in ipairs(ik) do
        local v2 = v[k2]
        if type(v2) == "table" then
          inner[#inner + 1] = string.format("%s = { female = %q, male = %q }", k2, v2.female, v2.male)
        else
          inner[#inner + 1] = string.format("%s = %q", k2, v2)
        end
      end
      parts[#parts + 1] = string.format("  %s = { %s },\n", k, table.concat(inner, ", "))
    else
      parts[#parts + 1] = string.format("  %s = %q,\n", k, v)
    end
  end
  parts[#parts + 1] = "}"
  return table.concat(parts)
end

function TextPlaceholders.serialize(data)
  return "return " .. serialize(data) .. "\n"
end

function TextPlaceholders.run(rom, cache, opts)
  opts = opts or {}
  local root = opts.cacheRoot or "data/generated/gba"
  local data = TextPlaceholders.extract(rom, opts.offsets)
  cache:write(root .. "/" .. TextPlaceholders.CACHE_SUB .. "/" .. TextPlaceholders.FILE,
    TextPlaceholders.serialize(data))
  return data
end

return TextPlaceholders
