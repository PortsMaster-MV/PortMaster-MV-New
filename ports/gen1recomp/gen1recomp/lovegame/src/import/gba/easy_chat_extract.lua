-- src/data/easy_chat/easy_chat_groups.h:26, src/easy_chat.c:41, :640

local Versions = require("src.import.gba.versions")
local TextIR = require("src.core.game3.scripting.text_ir")

local EasyChatExtract = {}

EasyChatExtract.CACHE_SUB = "easy_chat"
EasyChatExtract.FILE = "easy_chat/words.lua"
EasyChatExtract.REQUIRED = { EasyChatExtract.FILE }

-- include/constants/easy_chat.h:15
local VALUE_GROUPS = { [0] = "species", [18] = "move", [19] = "move", [21] = "species" }

local function read_string(rom, off, maxLen)
  local bytes = {}
  for i = 0, maxLen - 1 do
    local b = rom:get(off + i)
    bytes[#bytes + 1] = b
    if b == 0xFF then break end
  end
  assert(bytes[#bytes] == 0xFF, string.format("easy chat string at 0x%X has no EOS", off))
  return TextIR.toPlain(TextIR.decode(bytes), {})
end

local function ptr_offset(rom, ptr, what)
  return assert(rom:ptrOffset(ptr), string.format("%s is not a ROM pointer (0x%08X)", what, ptr))
end

function EasyChatExtract.extractFromRom(rom)
  local groups = {}
  local speciesStride = Versions.SPECIES_NAME_LENGTH
  local moveStride = Versions.MOVE_NAME_LENGTH + 1
  for gid = 0, Versions.EASY_CHAT_GROUP_COUNT - 1 do
    local gOff = Versions.EASY_CHAT_GROUPS + gid * 8
    local dataOff = ptr_offset(rom, rom:u32(gOff), "sEasyChatGroups[" .. gid .. "]")
    local numWords = rom:u16(gOff + 4)
    local numEnabled = rom:u16(gOff + 6)
    local nameOff = ptr_offset(rom, rom:u32(Versions.EASY_CHAT_GROUP_NAMES + gid * 4),
      "sEasyChatGroupNamePointers[" .. gid .. "]")
    local words = {}
    local kind = VALUE_GROUPS[gid]
    for i = 0, numWords - 1 do
      if kind then
        local value = rom:u16(dataOff + i * 2)
        local text
        if kind == "species" then
          text = read_string(rom, Versions.SPECIES_NAMES + value * speciesStride, speciesStride)
        else
          text = read_string(rom, Versions.MOVE_NAMES + value * moveStride, moveStride)
        end
        words[#words + 1] = { id = gid * 512 + value, value = value, text = text }
      else
        local entry = dataOff + i * 12
        local textOff = ptr_offset(rom, rom:u32(entry), string.format("easy chat word %d:%d", gid, i))
        words[#words + 1] = {
          id = gid * 512 + i,
          text = read_string(rom, textOff, 32),
          alphabeticalOrder = rom:u32(entry + 4),
          enabled = rom:u32(entry + 8) ~= 0,
        }
      end
    end
    groups[gid] = {
      id = gid,
      name = read_string(rom, nameOff, 32),
      numWords = numWords,
      numEnabled = numEnabled,
      words = words,
    }
  end
  return groups
end

-- pokeemerald/src/easy_chat.c:428
function EasyChatExtract.templatesFromRom(rom)
  local T = Versions.EASY_CHAT_TEMPLATES
  local function text(ptr)
    local off = rom:ptrOffset(ptr)
    return off and read_string(rom, off, 256) or ""
  end
  local out = {}
  for i = 0, T.count - 1 do
    local e = T.off + i * 24
    local b3 = rom:get(e + 3)
    out[#out + 1] = {
      type = rom:get(e), numColumns = rom:get(e + 1), numRows = rom:get(e + 2),
      frameId = b3 % 128, fourFooterOptions = b3 >= 128,
      title = text(rom:u32(e + 4)), instructions1 = text(rom:u32(e + 8)), instructions2 = text(rom:u32(e + 12)),
      confirm1 = text(rom:u32(e + 16)), confirm2 = text(rom:u32(e + 20)),
    }
  end
  local frames = {}
  for i = 0, T.frameCount - 1 do
    local e = T.frames + i * 4
    local b0 = rom:get(e)
    frames[i] = { left = b0 % 32, top = math.floor(b0 / 32), width = rom:get(e + 1), height = rom:get(e + 2),
      footerId = rom:get(e + 3) }
  end
  return out, frames
end

function EasyChatExtract.run(rom, cache, opts)
  opts = opts or {}
  local serialize = require("src.import.gba.extract_scripts").serialize_lua
  local groups = EasyChatExtract.extractFromRom(rom)
  local outRel = (opts.cacheRoot or "data/generated/gba") .. "/" .. EasyChatExtract.FILE
  local pack = { groups = groups }
  if Versions.EASY_CHAT_TEMPLATES then
    pack.templates, pack.frames = EasyChatExtract.templatesFromRom(rom)
  end
  assert(cache:write(outRel, "return " .. serialize(pack) .. "\n"),
    "could not write " .. outRel)
  return { ok = true, groupCount = Versions.EASY_CHAT_GROUP_COUNT, path = outRel }
end

return EasyChatExtract
