-- Script_ReceivePhoneCall (engine/phone/phone.asm), as the row list the VM
-- runs around a caller script:
--
--   Script_ReceivePhoneCall:
--       reanchormap
--       callasm RingTwice_StartCall
--       memcall wCallerContact + PHONE_CONTACT_SCRIPT2_BANK
--       waitbutton
--       callasm HangUp
--       closetext
--       callasm InitCallReceiveDelay
--       end
--
-- The memcall is the caller's own bank $41 script, which the extractor
-- reaches through PhoneContacts / SpecialPhoneCallList and the call
-- descriptor names by its scripts.lua key.  Around it:
--
--   * RingTwice_StartCall dispatches through src/script/gen2/CallAsm.lua for
--     both of its halves: SFX_CALL, and the caller-ID box it draws through
--     .CallerTextboxWithName -> Phone_TextboxWithName (:466, :474, :582) --
--     the phone icon, the caller's name, the class under it -- which is
--     src/ui/gen2/CallerBox.lua, pushed under this call's text pages and taken
--     down again by the InitCallReceiveDelay row at the tail.  What the port
--     cannot keep is the FLASH: the cart blinks the box against
--     Phone_Wait20Frames six times, and this port's textbox holds for A rather
--     than returning the way PrintText does, so the box goes up with the first
--     ring and stays.  The rawtext page below is the beat that hold needs; it
--     names the caller too, so a player who is looking at the bottom of the
--     screen reads the same thing the box says.
--     The RINGS themselves are real, though: RingTwice_StartCall is `call
--     .Ring` falling through into .Ring (engine/phone/phone.asm:458-469), so
--     it rings TWICE, and each pass opens on Phone_StartRinging's `call
--     WaitSFX` before its PlaySFX (:564-567).  The handler is one ring, so
--     both halves are rows here: waitsfx, ring, the three Phone_Wait20Frames
--     that separate the passes (:576-580), waitsfx, ring.  The wait is not
--     decoration -- SFX_CALL is $6a (constants/sfx_constants.asm:109), low
--     enough that the PlaySFX priority gate DROPS it outright while a louder
--     sound (SFX_READ_TEXT_2 $08, the A-press beep of the textbox that
--     queued the call) is still on the channels, so without it the player
--     can hear no ring at all.
--   * HangUp is the VM's own `hangup` op: SFX_HANG_UP under the Click! page,
--     transcribed once there rather than twice.
--   * InitCallReceiveDelay dispatches through CallAsm too, so a hung-up call
--     restarts the same receive countdown a map load does.
--
-- Mom's shopping call (engine/events/mom_phone.asm MomTriesToBuySomething)
-- ends `farsjump Script_ReceivePhoneCall` with her pages queued in
-- wCallerContact, which is why `scriptKey` may be an inline row list: the
-- VM's runList takes either.
--
-- Kept apart from src/core/gen2/Phone.lua on purpose: the model stays
-- dependency-free, and this file is the one that needs Strings.

local Runtime = require("src.mods.Runtime")
local Strings = require("src.core.Strings")

local PhoneRing = {}

local RING_PAGE = Strings.source("RING!…RING!…\n%s")

-- GetCallerClassAndName: a trainer contact is "<name>:" with the class name
-- beside it, a non-trainer its NonTrainerCallerNames row and the colon alone.
function PhoneRing.callerId(name, className)
  local line = (name or "") .. ":"
  if className and className ~= "" then
    line = line .. " " .. className
  end
  return line
end

-- `call` is a Phone.loadCallerScript / Phone.checkSpecialCall descriptor.
-- `delay` on it is the `pause 30` Script_SpecialElmCall's siblings run before
-- the ring; a random call carries none.
function PhoneRing.script(call, name, className)
  -- phone.call_received, a Gen 2 invention: Gen 1 has no Pokegear and so no
  -- name to share.  It lives here rather than beside the two model-side
  -- deciders (Phone.tryRandomCall and Phone.checkSpecialCall) because this is
  -- the point every incoming call actually reaches the player: all three World
  -- sites that ring the phone -- the random call, the queued special call and
  -- Mom's shopping call -- build their rows through this one function, and a
  -- descriptor the world decided not to run never gets here.
  --
  --   call        the descriptor, exactly as Phone.loadCallerScript built it
  --   contact     the PHONE_* contact id, 0 for the wrong-number script
  --   name        the caller's name as the caller-ID box prints it
  --   className   the trainer class under it, nil for a non-trainer caller
  --   special     the SPECIALCALL_* id for a scripted call, nil for a random
  --   scriptKey   the "bank:addr" key of the caller's own bank $41 script
  --
  -- Observation only: the rows are built after it, so a listener cannot veto
  -- the call.  The veto seam is the VM's own script.started, which fires when
  -- these rows run.
  if Runtime.wants("phone.call_received") then
    Runtime.emit("phone.call_received", {
      call = call,
      contact = call and call.contact or 0,
      name = name, className = className,
      special = call and call.special,
      scriptKey = call and call.scriptKey,
    })
  end
  local rows = {}
  rows.phoneContact = call and call.contact
  if call and call.delay then
    rows[#rows + 1] = { op = "pause", frames = call.delay }
  end
  rows[#rows + 1] = { op = "reanchormap" }
  -- RingTwice_StartCall's two .Ring passes, each opening on
  -- Phone_StartRinging's WaitSFX (engine/phone/phone.asm:458-469, :564-567)
  -- and spaced by its three Phone_Wait20Frames (:576-580).
  -- The box goes up inside the FIRST of these (idempotent, so the second pass
  -- does not stack a duplicate) and comes down inside the InitCallReceiveDelay
  -- row at the bottom -- no row of its own, because Script_ReceivePhoneCall has
  -- none: the cart's box is tilemap that nothing erases.
  rows[#rows + 1] = { op = "waitsfx" }
  rows[#rows + 1] = { op = "callasm", label = "RingTwice_StartCall" }
  rows[#rows + 1] = { op = "pause", frames = 60 }
  rows[#rows + 1] = { op = "waitsfx" }
  rows[#rows + 1] = { op = "callasm", label = "RingTwice_StartCall" }
  rows[#rows + 1] = { op = "rawtext",
    text = Strings(RING_PAGE, PhoneRing.callerId(name, className)) }
  rows[#rows + 1] = { op = "farscall", script = call and call.scriptKey }
  rows[#rows + 1] = { op = "waitbutton" }
  rows[#rows + 1] = { op = "hangup" }
  rows[#rows + 1] = { op = "closetext" }
  rows[#rows + 1] = { op = "callasm", label = "InitCallReceiveDelay" }
  rows[#rows + 1] = { op = "end" }
  return rows
end

return PhoneRing
