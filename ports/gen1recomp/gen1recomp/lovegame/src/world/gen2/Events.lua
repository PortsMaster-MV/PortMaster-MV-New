-- Gen 2 event-flag bitfield (wEventFlags).  Flag SET → object with that
-- eventFlag is hidden (CheckObjectFlag in map_objects_2.asm).

local Runtime = require("src.mods.Runtime")

local Events = {}
Events.__index = Events

local FLAGS_PER_BYTE = 8

function Events.new(initial)
  local self = setmetatable({ flags = {} }, Events)
  if type(initial) == "table" then
    for _, id in ipairs(initial) do self:set(id, true) end
  end
  return self
end

function Events:get(id)
  if not id or id < 0 then return false end
  local byte = math.floor(id / FLAGS_PER_BYTE)
  local bitn = id % FLAGS_PER_BYTE
  local row = self.flags[byte] or 0
  return math.floor(row / (2 ^ bitn)) % 2 == 1
end

-- flag.changed carries the SAME name and the same two payload keys Gen 1's
-- src/script/Flags.lua emits, and fires on the same condition: only a real
-- transition, so a redundant set of an already-set flag is silent.
--
-- One difference, and it is a difference in the data rather than in the API:
-- `name` holds a NUMBER here.  Gen 2 flags are bits in wEventFlags and the
-- cart's EVENT_* constants are indices into that bitfield, where Gen 1 flags
-- are string keys in save.flags.  src/world/gen2/WorldAPI.lua's setFlag tells
-- a mod the same thing from the other side, so a dual-generation listener
-- branches on type(payload.name) rather than on the generation.
--
-- Events:restore and Events:resetMapBuffer deliberately do NOT come through
-- here: a save load and HandleNewMap's one-byte wipe are not script writes,
-- and Gen 1 does not emit for its own save load either.
function Events:set(id, value)
  if not id or id < 0 then return end
  local watched = Runtime.wants("flag.changed")
  local before = watched and self:get(id) or false
  local byte = math.floor(id / FLAGS_PER_BYTE)
  local bitn = id % FLAGS_PER_BYTE
  local mask = 2 ^ bitn
  local row = self.flags[byte] or 0
  if value then
    self.flags[byte] = row + (math.floor(row / mask) % 2 == 0 and mask or 0)
  else
    if math.floor(row / mask) % 2 == 1 then
      self.flags[byte] = row - mask
    end
  end
  if watched then
    local after = value and true or false
    if before ~= after then
      Runtime.emit("flag.changed", { name = id, value = after })
    end
  end
end

-- ResetMapBufferEventFlags (home/flag.asm): `xor a / ld hl, wEventFlags /
-- ld [hli], a` zeroes exactly ONE byte -- flags 0-7, the
-- EVENT_TEMPORARY_UNTIL_MAP_RELOAD block -- and HandleNewMap runs it on every
-- map load.  This is what re-arms every "once per visit" script latch: Bill's
-- grandpa hands out one stone per house entry because his script sets flag 0
-- and checks it at the top, and Kurt's house, the ports, Dragon's Den B1F and
-- the National Park gate all lean on the same byte the same way.
function Events:resetMapBuffer()
  self.flags[0] = nil
end

function Events:objectVisible(eventFlag)
  -- Extracted maps may keep 0xFFFF instead of nil for "always appear".
  if eventFlag == nil or eventFlag == 0xFFFF then return true end
  return not self:get(eventFlag)
end

-- The bitfield as a plain table for the save file, and back.  Stored as
-- byte -> value rather than a flag list because that is what the cart's SRAM
-- holds, and because a sparse map keeps a save small (most bytes are 0).
function Events:serialize()
  local out = {}
  for byte, value in pairs(self.flags) do
    if value ~= 0 then out[byte] = value end
  end
  return out
end

function Events:restore(bytes)
  if type(bytes) ~= "table" then return self end
  self.flags = {}
  for byte, value in pairs(bytes) do
    local index = tonumber(byte)
    if index then self.flags[index] = value end
  end
  return self
end

return Events
