-- Gen 2 automated joypad input: home/joypad.asm (GetJoypad's .auto arm,
-- StartAutoInput, StopAutoInput).
--
-- While a stream is armed the cart stops looking at the joypad entirely.
-- GetJoypad branches on wInputType == AUTO_INPUT before it ever reads
-- hJoypadDown, and writes hJoyDown / hJoyPressed straight out of the stream,
-- so anything the player is physically holding is discarded until the stream
-- ends.  That suppression is half the feature: the catching tutorial hands the
-- DUDE the controller, and a player mashing A must not be able to steer it.
--
-- Stream format, quoting the asm: [input][duration], and an input of $ff ends
-- the stream immediately.  A duration is the number of EXTRA frames the input
-- is held for (wAutoInputLength counts down, and only a zero count re-reads
-- the stream), so a duration of 0 means "one frame".  A duration of $ff is the
-- odd one: it stores $ff, forces the input to NO_INPUT, and leaves
-- wAutoInputAddress pointing at the same pair -- the two `dec hl`s in that arm
-- are vestigial, because only the .next arm ever writes the address back.  The
-- effect is "hold nothing forever", re-arming itself every 256 frames, which
-- is how every stream in the ROM parks at its end without releasing control.
--
-- The port feeds the decoded frame through src/core/Input.lua the way
-- src/core/TouchControls.lua does, under its own source names, so the per
-- fixed-step edge detection in Input:step sees a real press and a real
-- release.  Game2 steps this BEFORE Input:step for the same reason tool
-- mods run there: a button chosen this tick has to be visible to this
-- tick's logic, not the next one.

local AutoInput = {}
AutoInput.__index = AutoInput

-- constants/hardware.inc PAD_*.  Same bit order as hJoypadDown.
local PAD_A      = 0x01
local PAD_B      = 0x02
local PAD_SELECT = 0x04
local PAD_START  = 0x08
local PAD_RIGHT  = 0x10
local PAD_LEFT   = 0x20
local PAD_UP     = 0x40
local PAD_DOWN   = 0x80
local NO_INPUT   = 0x00

AutoInput.PAD_A = PAD_A
AutoInput.PAD_B = PAD_B
AutoInput.PAD_RIGHT = PAD_RIGHT
AutoInput.PAD_DOWN = PAD_DOWN
AutoInput.NO_INPUT = NO_INPUT

-- Bit -> the GB button name the rest of the engine uses.  Ordered so a decoded
-- frame always presses in the same sequence, which keeps Input:step's queue
-- deterministic for the tests.
local BITS = {
  { PAD_A, "a" },
  { PAD_B, "b" },
  { PAD_SELECT, "select" },
  { PAD_START, "start" },
  { PAD_RIGHT, "right" },
  { PAD_LEFT, "left" },
  { PAD_UP, "up" },
  { PAD_DOWN, "down" },
}

-- Lua 5.1 has no bitops in the base library and the engine targets LuaJIT
-- semantics, so the mask test is arithmetic: these are eight distinct single
-- bits, and a stream byte is always < 256.
local function held(mask, bit)
  return math.floor(mask / bit) % 2 == 1
end

-- The four streams that exist in the ROM.  Flat [input][duration] byte arrays,
-- transcribed rather than generated: the extractor emits only the bank and
-- pointer an `autoinput` command carries (Script_autoinput's three GetScriptByte
-- calls), never the bytes behind it.
AutoInput.STREAMS = {
  -- engine/events/catch_tutorial.asm CatchTutorial.AutoInput: the DUDE's battle
  -- is played entirely by the re-arms below, so the stream wrapped around
  -- StartBattle only has to hold the player's own hands off the controller.
  CATCH_TUTORIAL = { NO_INPUT, 0xff },
  -- engine/events/catch_tutorial_input.asm.  PromptButton, the battle menu and
  -- the pack re-arm one of these each time they want the DUDE to answer, which
  -- is why the tutorial reads as a person playing rather than as a macro.
  DUDE_A = {
    NO_INPUT, 0x50,
    PAD_A, 0x00,
    NO_INPUT, 0xff,
  },
  DUDE_RIGHT_A = {
    NO_INPUT, 0x08,
    PAD_RIGHT, 0x00,
    NO_INPUT, 0x08,
    PAD_A, 0x00,
    NO_INPUT, 0xff,
  },
  DUDE_DOWN_A = {
    NO_INPUT, 0xfe,
    NO_INPUT, 0xfe,
    NO_INPUT, 0xfe,
    NO_INPUT, 0xfe,
    PAD_DOWN, 0x00,
    NO_INPUT, 0xfe,
    NO_INPUT, 0xfe,
    NO_INPUT, 0xfe,
    NO_INPUT, 0xfe,
    PAD_A, 0x00,
    NO_INPUT, 0xff,
  },
}

-- bank:address -> stream name, from ../pokegold-symbols/pokegold.sym.  An
-- `autoinput` command names its stream by a `dba`, so this is how a script's
-- bank:pointer becomes bytes we actually have.  Nothing else in the ROM can be
-- the target: StartAutoInput has exactly these four call sites.
AutoInput.POINTERS = {
  ["08:79fc"] = "CATCH_TUTORIAL",
  ["70:4dfe"] = "DUDE_A",
  ["70:4e04"] = "DUDE_RIGHT_A",
  ["70:4e0e"] = "DUDE_DOWN_A",
}

function AutoInput.new()
  return setmetatable({
    -- wAutoInputAddress, as an index into `bytes`
    pos = 1,
    -- wAutoInputLength
    length = 0,
    bytes = nil,
    active = false,
    -- hJoyDown's current value, kept so a frame inside a duration can leave the
    -- mirrors alone the way the .quit arm does
    current = NO_INPUT,
  }, AutoInput)
end

function AutoInput:isActive()
  return self.active
end

-- StartAutoInput.  `stream` is a stream name from AutoInput.STREAMS or a raw
-- byte array; `input` is src/core/Input.lua, whose mirrors are cleared here the
-- way StartAutoInput clears hJoyPressed / hJoyReleased / hJoyDown, so a button
-- the player was holding when the stream armed does not leak into it.
function AutoInput:start(stream, input)
  local bytes = stream
  if type(stream) == "string" then bytes = AutoInput.STREAMS[stream] end
  if type(bytes) ~= "table" or bytes[1] == nil then return false end
  self.bytes = bytes
  self.pos = 1
  -- "Start reading the stream immediately": a zero length makes the very next
  -- step take the .updateauto arm.
  self.length = 0
  self.current = NO_INPUT
  self.active = true
  -- Frame pace unless the caller asks for poll pace; see skipIdle.
  self.pollPaced = nil
  if input and input.reset then input:reset() end
  return true
end

-- Play the armed stream at POLL pace instead of frame pace: every pair that
-- presses nothing is skipped, so only the buttons are left, one per step.
--
-- This is a PORT correction, not something the cart does, and it is only for
-- the streams a menu consumes.  The cart advances the stream once per GetJoypad
-- call, and a menu's wait loop calls GetJoypad with no frame delay at all
-- (engine/menus/menu.asm `.loopRTC`, engine/items/pack.asm's own loop), so
-- DudeAutoInput_DownA's four `NO_INPUT, $fe` runs are loop iterations there and
-- are gone in a frame or two.  This port polls once per fixed step, where the
-- same runs would be 1020 steps of the DUDE staring at the battle menu.  The
-- presses and their ORDER -- which is all those streams encode -- are untouched.
--
-- PromptButton's own loop DOES delay a frame per iteration, so DUDE_A is left
-- frame-paced and its 0x51 blank frames are the real beat between two lines.
--
-- A `$ff` duration is never skipped: that pair is the stream parking itself,
-- not a pause before a press.
function AutoInput:skipIdle()
  self.pollPaced = true
  if not self.active then return false end
  local skipped = self:dropIdlePairs()
  -- A zero length is what makes the next step re-read the stream.
  self.length = 0
  self.current = NO_INPUT
  return skipped
end

function AutoInput:dropIdlePairs()
  local bytes = self.bytes or {}
  local skipped = false
  while true do
    local value = bytes[self.pos]
    local duration = bytes[self.pos + 1]
    if value ~= NO_INPUT or duration == nil or duration == 0xff then break end
    self.pos = self.pos + 2
    skipped = true
  end
  return skipped
end

-- Script_autoinput's `dba`: bank first, then the 16-bit address.
function AutoInput:startPointer(bank, address, input)
  local key = string.format("%02x:%04x", bank or 0, address or 0)
  local name = AutoInput.POINTERS[key]
  if not name then
    -- The bytes are not in the cache and the pointer is not one of the ROM's
    -- own streams, so there is nothing to replay.  Recorded rather than
    -- guessed: arming an invented stream would take the controller away from
    -- the player with no way to hand it back.
    self.unknownPointer = key
    return false
  end
  return self:start(name, input)
end

-- StopAutoInput.  Clears the stream and puts wInputType back to normal input;
-- Input:reconcile is the port's equivalent of GetJoypad going back to reading
-- hJoypadDown, i.e. a key the player is still physically holding is down again
-- on the very next step rather than waiting for a fresh keypress event.
function AutoInput:stop(input)
  self.bytes = nil
  self.pos = 1
  self.length = 0
  self.current = NO_INPUT
  local wasActive = self.active
  self.active = false
  self.restorePending = nil
  if wasActive and input then
    if input.reset then input:reset() end
    if input.reconcile then input:reconcile() end
  end
  return wasActive
end

-- One GetJoypad .auto pass.  Returns the pad mask for this frame, and true as
-- a second value on the frame the stream ended: .stopauto calls StopAutoInput
-- from inside GetJoypad, so the ring is disarmed here rather than by the
-- caller, and the handback to the real pad is left for the step after.
function AutoInput:advance()
  if not self.active then return NO_INPUT end
  -- "We only update when the input duration has expired."
  if self.length ~= 0 then
    self.length = self.length - 1
    return self.current
  end
  -- A poll-paced stream drops the blank pairs BETWEEN its presses as well as
  -- the ones in front of them: on the cart the loop consuming it burns through
  -- both at the same speed.  See skipIdle.
  if self.pollPaced then self:dropIdlePairs() end
  local bytes = self.bytes or {}
  local value = bytes[self.pos]
  -- "An input of $ff will end the stream."  A stream that runs off its own end
  -- is malformed data rather than something the ROM can produce, and is
  -- treated as the terminator so control still comes back.
  if value == nil or value == 0xff then
    self:stop()
    self.restorePending = true
    return NO_INPUT, true
  end
  local duration = bytes[self.pos + 1]
  if duration == nil then
    self:stop()
    self.restorePending = true
    return NO_INPUT, true
  end
  self.length = duration
  if duration == 0xff then
    -- "A duration of $ff will end the stream indefinitely": the current input
    -- is overwritten and the address is left pointing at this same pair.
    value = NO_INPUT
  else
    self.pos = self.pos + 2
  end
  self.current = value
  return value
end

-- Called once per fixed step, before Input:step.  Presses this frame's buttons
-- through the same per-source bookkeeping the touch overlay and mod input use.
-- Returns true while the stream owns the controller.
function AutoInput:step(input)
  if not self.active then
    -- The terminator frame below still belonged to the stream, so the handback
    -- lands here, one step later: that is the frame GetJoypad would first read
    -- hJoypadDown again.  Doing it on the terminator frame itself would let a
    -- key the player was leaning on register a press the cart never saw.
    if self.restorePending then
      self.restorePending = nil
      if input then
        if input.reset then input:reset() end
        if input.reconcile then input:reconcile() end
      end
    end
    return false
  end
  local mask = self:advance()
  if input then
    -- GetJoypad overwrites the mirrors outright in this arm, so every other
    -- source is dropped for the frame.  Re-pressing each held button every
    -- step is deliberate: hJoyPressed is written once per stream update and
    -- then left latched for the whole duration, so an auto-held A really does
    -- read as pressed on every frame it covers.
    if input.reset then input:reset() end
    for _, entry in ipairs(BITS) do
      if held(mask, entry[1]) then
        input:sourcePress(entry[2], "auto:" .. entry[2])
      end
    end
  end
  -- .stopauto has already disarmed the ring inside advance; the frame the
  -- terminator lands on is still an auto frame (NO_INPUT into the mirrors),
  -- and the step after it is the player's.
  return true
end

return AutoInput
