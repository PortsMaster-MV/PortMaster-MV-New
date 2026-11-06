-- The caller-ID box an incoming phone call puts across the top of the screen:
-- Phone_TextboxWithName (pokegold engine/phone/phone.asm:582), which is
--
--   Phone_TextboxWithName:
--       push bc
--       call Phone_CallerTextbox
--       hlcoord 1, 1
--       ld [hl], '☎'
--       inc hl
--       inc hl
--       ld d, h
--       ld e, l
--       pop bc
--       call GetCallerClassAndName
--       ret
--
--   Phone_CallerTextbox:
--       hlcoord 0, 0
--       ld b, 2
--       ld c, SCREEN_WIDTH - 2
--       call Textbox
--       ret
--
-- so the box is the top four rows of the screen (b/c are INTERIOR rows and
-- columns, hence 20x4 on screen), the phone icon sits at (1,1), and
-- GetCallerClassAndName places the caller's name from (3,1) -- hl after the
-- two `inc hl` -- with a ':' written straight after it.  A trainer contact
-- then gets its class name a further `SCREEN_WIDTH + 3` on, which is (6,2);
-- a non-trainer (Mom, ELM, the wrong number) stops at the colon and has no
-- second line at all (:635-666).
--
-- WHEN IT IS UP.  RingTwice_StartCall (:458-469) flashes the box on and off
-- against Phone_Wait20Frames while SFX_CALL plays, and nothing ever erases it
-- afterwards: it was written straight into wTilemap rather than through a
-- window, so CloseText restores it along with everything else under the
-- speech box and it survives until the overworld redraws its tilemap at the
-- end of the call.  This port has no twenty-frame flash to hang the middle
-- beats on (src/core/gen2/PhoneRing.lua explains why: its text box holds for
-- A where the cart's PrintText returns), so the box goes UP with the ring and
-- stays for the whole call, which is the state the player actually reads.
--
-- A state, not a widget: it rides src/core/StateStack.lua UNDER the call's
-- text pages, so those draw over it exactly as the cart's speech box draws
-- over the tilemap.  Deliberately no `update` -- src/core/Game2.lua's fixed
-- step hands the tick to the TOP state and returns, so an update here would
-- stop the world (and with it the script VM that is running the call) the
-- moment the last text page popped.
--
-- Pushed and popped by the two callasm handlers in src/script/gen2/CallAsm.lua
-- that src/core/gen2/PhoneRing.lua's rows name.

local Chrome = require("src.ui.gen2.Chrome")
local PhoneRing = require("src.core.gen2.PhoneRing")

local CallerBox = {}
CallerBox.__index = CallerBox

-- Phone_CallerTextbox's own coordinates, kept as names so the two draw calls
-- below read like the ASM they came from.
local BOX_X, BOX_Y = 0, 0
local BOX_INTERIOR_W, BOX_INTERIOR_H = 18, 2
local ICON_X, ICON_Y = 1, 1
local NAME_X, NAME_Y = 3, 1
local CLASS_X, CLASS_Y = 6, 2

-- charmap.asm:88 `charmap "☎", $62`.  The glyph itself is
-- PokegearPhoneIconGFX, which _LoadFontsExtra copies over vTiles2 tile $62
-- (engine/gfx/load_font.asm:12-15) on top of the three bold letters FontExtra
-- ships there; a cache whose font_extra page still carries FontExtra's own
-- $62 draws a bold C in its place, which is an extractor gap and not a
-- layout one, so the sequence is written out here the way the cart writes it.
local PHONE_ICON = "\xe2\x98\x8e"

-- `name` / `className` are what src/core/gen2/Phone.lua contactName answers:
-- the caller's name, and the trainer class under it or nil for a non-trainer.
function CallerBox.new(name, className)
  return setmetatable({
    name = name or "",
    className = className,
    -- The overworld has to keep drawing behind it (this is a strip across the
    -- top, not a page), so the stack must not treat it as a base.
    isOpaque = false,
  }, CallerBox)
end

function CallerBox:draw()
  Chrome.textbox(BOX_X, BOX_Y, BOX_INTERIOR_W, BOX_INTERIOR_H)
  Chrome.print(PHONE_ICON, ICON_X, ICON_Y)
  -- GetCallerName places the name and then writes ':' into the cell the
  -- string ended on, which is what PhoneRing.callerId already composes for
  -- the ring page -- same colon, same source, so the two can never drift.
  Chrome.print(PhoneRing.callerId(self.name), NAME_X, NAME_Y)
  if self.className and self.className ~= "" then
    Chrome.print(self.className, CLASS_X, CLASS_Y)
  end
end

return CallerBox
