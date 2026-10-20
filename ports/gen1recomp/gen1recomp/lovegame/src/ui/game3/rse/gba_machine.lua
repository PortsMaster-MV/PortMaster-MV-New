local bit = require("bit")
local Ppu = require("src.core.game3.gba_ppu")
local Tasks = require("src.core.game3.gba_tasks")

local Machine = {}
Machine.__index = Machine

Machine.A_BUTTON = 0x001
Machine.B_BUTTON = 0x002
Machine.SELECT_BUTTON = 0x004
Machine.START_BUTTON = 0x008
Machine.DPAD_RIGHT = 0x010
Machine.DPAD_LEFT = 0x020
Machine.DPAD_UP = 0x040
Machine.DPAD_DOWN = 0x080
Machine.R_BUTTON = 0x100
Machine.L_BUTTON = 0x200

local KEY_BITS = {
  { "a", Machine.A_BUTTON }, { "b", Machine.B_BUTTON }, { "select", Machine.SELECT_BUTTON },
  { "start", Machine.START_BUTTON }, { "right", Machine.DPAD_RIGHT }, { "left", Machine.DPAD_LEFT },
  { "up", Machine.DPAD_UP }, { "down", Machine.DPAD_DOWN }, { "r", Machine.R_BUTTON }, { "l", Machine.L_BUTTON },
}

function Machine.new()
  local self = setmetatable({}, Machine)
  self.ppu = Ppu.new()
  self.tasks = Tasks.new()
  self.vblankCounter1 = 0
  self.vblankCb = nil
  self.cb2 = nil
  self.stall = 0
  self.state = 0
  self.newKeys = 0
  self.heldKeys = 0
  self.globals = { battleBg1X = 0, battleBg1Y = 0 }
  self.manifests = {}
  return self
end

function Machine:readKeys(input)
  local held, new = 0, 0
  if input then
    for _, kb in ipairs(KEY_BITS) do
      if input.isDown and input:isDown(kb[1]) then held = bit.bor(held, kb[2]) end
      if input.wasPressed and input:wasPressed(kb[1]) then new = bit.bor(new, kb[2]) end
    end
  end
  self.heldKeys = bit.bor(held, new)
  self.newKeys = new
end

function Machine:joyNew(mask)
  return bit.band(self.newKeys, mask) ~= 0
end

function Machine:joyHeld(mask)
  return bit.band(self.heldKeys, mask)
end

function Machine:setCb2(fn)
  self.cb2 = fn
  self.state = 0
end

function Machine:setVBlank(fn)
  self.vblankCb = fn
end

-- pokeemerald/src/main.c:340
function Machine:frame(input)
  self.vblankCounter1 = self.vblankCounter1 + 1
  local stalled = (self.stall or 0) > 0
  local vb = self.vblankCb
  if stalled and self.stallHold then vb = self.stallVblank end
  if vb then vb(self) end
  if stalled then
    self.stall = self.stall - 1
    if self.stall == 0 then self.stallHold = false end
    return
  end
  self.iterVblank = self.vblankCb
  self:readKeys(input)
  if self.cb2 then self.cb2(self) end
end

function Machine:addStall(frames, holdVBlank)
  self.stall = (self.stall or 0) + frames
  if holdVBlank then
    self.stallHold = true
    self.stallVblank = self.iterVblank
  end
end

function Machine:manifest(path)
  local m = self.manifests[path]
  if not m then
    local chunk = assert(love.filesystem.load(path), "gba_machine: missing manifest " .. tostring(path))
    m = chunk()
    self.manifests[path] = m
  end
  return m
end

function Machine.layer(entry)
  assert(entry and entry.index, "gba_machine: layer entry without an index map")
  return Ppu.indexLayer(entry.index, entry.w, entry.h, entry.bpp or 4)
end

function Machine.sheet(entry)
  assert(entry and entry.png, "gba_machine: sprite entry without a sheet")
  return Ppu.indexSheet(entry.png, entry.w, entry.h)
end

function Machine.template(entry, extra)
  local t = {
    w = entry.w, h = entry.h, bpp = entry.bpp or 4,
    anims = entry.anims, affineAnims = entry.affineAnims,
    priority = entry.priority or 0, affineMode = entry.affineMode or 0, objMode = entry.objMode or 0,
    sheet = Machine.sheet(entry),
  }
  for k, v in pairs(extra or {}) do t[k] = v end
  return t
end

return Machine
