-- The in-game trade animation (engine/movie/trade_animation.asm
-- TradeAnimation), the cable-and-ball sequence NPCTrade runs between
-- DoNPCTrade and TradedForText.
--
-- love-free: this file is the script and its clock, src/ui/gen2/TradeAnim.lua
-- is the half that draws.  Nothing about the trade's outcome depends on any of
-- it -- DoNPCTrade has already swapped the two mons by the time the first
-- frame runs -- which is why the screen can be skipped without a branch.
--
-- The cart drives this from a byte script (`tradeanim` rows into
-- DoTradeAnimation.Jumptable), one command per frame, and each command either
-- runs a piece of setup and advances the pointer or sits on wFrameCounter
-- until it drains.  The commands that only set something up (a palette, a
-- window position, a sprite struct) cost no frames, so the whole script
-- flattens to the list of WAITS below, with the setup a command did folded
-- into the `cue` of the beat that follows it.  Two examples, since the folding
-- is the one place this stops being a transcription:
--
--   * TradeAnim_Poof sets wFrameCounter to 16 and advances immediately, so the
--     poof is still on screen while TradeAnim_EnterLinkTube2 slides the cable
--     in over its first 40 frames.  It gets no beat of its own; `tube_in`
--     carries the "poof" cue and the drawing side gives the puff 16 frames.
--   * TradeAnim_RockingBall's 64 frames are only spent later, by the
--     TradeAnim_WaitAnim that follows EnterLinkTube2's own 40 + 80 -- the two
--     commands in between never touch wFrameCounter.  That wait is `ball_rock`.
--
-- The frame counts are the cart's own: `ld c, 80 / call DelayFrames`,
-- `ld a, 92 / ld [wFrameCounter], a`, and the scrolls' step per frame.
--
-- Only the player-1 script is here.  TradeAnimationPlayer2 is the same beats
-- in the other order and is reached from the cable club, which the port does
-- not have.

local TradeAnim = {}

-- Scroll steps, in pixels per frame.
--
-- TradeAnim_DoGivemonScroll moves hWX and hSCX 4 a frame until the window is
-- home; TradeAnim_EnterLinkTube2 / TradeAnim_ExitLinkTube move hSCX 4 a frame
-- over the tube's own $a0; the two Game Boy pans move hSCX 2 a frame.
TradeAnim.SCROLL_STEP = 4
TradeAnim.PAN_STEP = 2

-- hSCX starts at $88 for the frontpic scroll and hWX at $8f, i.e. both are
-- $88 from home.
TradeAnim.GIVEMON_SCROLL = 0x88
-- The link tube enters and leaves across $a0.
TradeAnim.TUBE_SCROLL = 0xa0

-- The Game Boy pan is a full wrap of the 256-pixel BG map: hSCX runs
-- 0 -> $50 -> $a0 -> $100, redrawing the tilemap at each boundary in the part
-- of the map the window has already left, so the three states read as one
-- continuous scene 256 pixels long.  TradeAnim_InitTubeAnim's own
-- `hlbgcoord 20, 3 / ld bc, 12 / ld a, $60 / ByteFill` is what keeps the cable
-- unbroken across the seam.
TradeAnim.PAN_TOTAL = 0x100

-- The script.  `frames` is how long the beat holds, `cue` fires on its first
-- frame.
--
-- The two Game Boy pans are one beat per hSCX target rather than one long one
-- because the cart really does stop at $50 and $a0 to swap the tilemap, and a
-- beat boundary is where the drawing side gets to notice.
TradeAnim.SCRIPT = {
  -- ShowGivemonData, then TradeAnim_DoGivemonScroll's $88 at 4 a frame.
  { id = "givemon_scroll", frames = 34, cue = "show_give" },
  { id = "givemon_hold", frames = 80 },
  -- Poof, RockingBall, EnterLinkTube1: the mon becomes a ball and the cable
  -- slides in over it.
  { id = "tube_in", frames = 40, cue = "poof" },
  -- EnterLinkTube2's `ld c, 80 / call DelayFrames` once hSCX is home.
  { id = "tube_hold", frames = 80 },
  -- The WaitAnim spending RockingBall's 64.
  { id = "ball_rock", frames = 64 },
  { id = "bulge", frames = 128, cue = "bulge" },
  -- GiveTrademonSFX, then TubeToOT2/3/4.
  { id = "send_pan_a", frames = 40, cue = "give_sfx" },
  { id = "send_pan_b", frames = 40 },
  { id = "send_pan_c", frames = 48 },
  -- TubeToOT5 spends the 92 TubeToOT1 set, TubeToOT6/7 the 128 after it.
  { id = "send_wait", frames = 92 },
  { id = "send_hold", frames = 128 },
  -- SentToOTText: the empty _MonNameSentToText holds an open box for 189
  -- frames before the line itself, which then gets 80 + 128.
  { id = "sent_blank", frames = 189, cue = "clear" },
  { id = "sent_text", frames = 208 },
  -- OTSendsText1's two pages, the second carrying its trailing `ld c, 14`.
  { id = "ot_sends_a", frames = 80 },
  { id = "ot_sends_b", frames = 94 },
  -- OTBidsFarewell's two.
  { id = "farewell_a", frames = 80 },
  { id = "farewell_b", frames = 80 },
  -- GetTrademonSFX, then TubeToPlayer2 waits its 92 BEFORE the pan (the
  -- mirror of the send, where the wait comes after).
  { id = "get_wait", frames = 92, cue = "get_sfx" },
  { id = "get_pan_a", frames = 40 },
  { id = "get_pan_b", frames = 40 },
  { id = "get_pan_c", frames = 48 },
  { id = "get_hold", frames = 128 },
  -- EnterLinkTube again, then DropBall / ExitLinkTube.
  { id = "tube_in2", frames = 40, cue = "tube" },
  { id = "tube_hold2", frames = 80 },
  { id = "tube_out", frames = 40, cue = "drop" },
  { id = "ball_wait", frames = 56 },
  -- ShowGetmonData, then Poof's 16.
  { id = "getmon_poof", frames = 16, cue = "show_get" },
  -- FrontpicScrollStart brings the stats window back up for Wait80.
  { id = "getmon_hold", frames = 80 },
  { id = "take_care", frames = 80 },
}

-- Which unrolled pan position a beat starts at, and which way it moves.  The
-- send pans forward across the 256, the get pans back: TubeToPlayer3/4/5
-- SUBTRACT 2 a frame, starting from the wrap.
local PAN = {
  send_pan_a = { base = 0x00, step = TradeAnim.PAN_STEP },
  send_pan_b = { base = 0x50, step = TradeAnim.PAN_STEP },
  send_pan_c = { base = 0xa0, step = TradeAnim.PAN_STEP },
  send_wait = { base = 0x100, step = 0 },
  send_hold = { base = 0x100, step = 0 },
  get_wait = { base = 0x100, step = 0 },
  get_pan_a = { base = 0x100, step = -TradeAnim.PAN_STEP },
  get_pan_b = { base = 0xb0, step = -TradeAnim.PAN_STEP },
  get_pan_c = { base = 0x60, step = -TradeAnim.PAN_STEP },
  get_hold = { base = 0x00, step = 0 },
}

-- The beats that print a line, and the text label each one prints.  The empty
-- _MonNameSentToText is not here: it draws an open box and nothing else, which
-- is what `sent_blank` having no entry means.
TradeAnim.TEXT = {
  sent_text = "_MonWasSentToText",
  ot_sends_a = "_ForYourMonSendsText",
  ot_sends_b = "_OTSendsText",
  farewell_a = "_BidsFarewellToMonText",
  farewell_b = "_MonNameBidsFarewellText",
  take_care = "_TakeGoodCareOfMonText",
}

TradeAnim.TOTAL = 0
for _, beat in ipairs(TradeAnim.SCRIPT) do
  TradeAnim.TOTAL = TradeAnim.TOTAL + beat.frames
end

-- The beat a frame index (0-based) lands in, and how far into it that is.
-- Past the end answers the last beat, so a caller that overruns by a frame
-- draws the final picture rather than nothing.
function TradeAnim.beatAt(frame)
  frame = math.max(0, math.floor(tonumber(frame) or 0))
  local start = 0
  for index, beat in ipairs(TradeAnim.SCRIPT) do
    if frame < start + beat.frames then
      return beat, frame - start, index
    end
    start = start + beat.frames
  end
  local last = TradeAnim.SCRIPT[#TradeAnim.SCRIPT]
  return last, last.frames, #TradeAnim.SCRIPT
end

-- The frame index a beat starts on, for tests and for a caller that wants to
-- jump.
function TradeAnim.startOf(id)
  local start = 0
  for _, beat in ipairs(TradeAnim.SCRIPT) do
    if beat.id == id then return start end
    start = start + beat.frames
  end
  return nil
end

-- hSCX during the two scrolls that bring the give-mon panel home.  Both the
-- background and the window are $88 out and close at 4 a frame.
function TradeAnim.givemonOffset(t)
  return math.max(0, TradeAnim.GIVEMON_SCROLL - TradeAnim.SCROLL_STEP * t)
end

-- hSCX for the link tube.  Entering, it closes from $a0; leaving, it opens
-- back out to $a0.  The tube's tilemap sits at hlcoord 8, 2, so the drawing
-- side subtracts this from that x -- SCX scrolls the BACKGROUND, and a
-- positive value moves the picture LEFT.
function TradeAnim.tubeOffset(id, t)
  local step = TradeAnim.SCROLL_STEP * t
  if id == "tube_out" then
    return math.min(TradeAnim.TUBE_SCROLL, step)
  end
  return math.max(0, TradeAnim.TUBE_SCROLL - step)
end

-- How far along the 256-pixel Game Boy scene the window is, unrolled: 0 is the
-- player's Game Boy at the left, 256 is the other one.  nil for a beat that is
-- not part of a pan.
function TradeAnim.pan(id, t)
  local row = PAN[id]
  if not row then return nil end
  local value = row.base + row.step * (tonumber(t) or 0)
  if value < 0 then return 0 end
  if value > TradeAnim.PAN_TOTAL then return TradeAnim.PAN_TOTAL end
  return value
end

-- The trademon object's two ends, in screen pixels: TubeToOT1's
-- `depixel 5, 11, 4, 0` and TubeToPlayer1's `depixel 9, 18, 4, 4`, OAM-adjusted.
local ICON_NEAR_X, ICON_NEAR_Y = 80, 28
local ICON_FAR_X, ICON_FAR_Y = 140, 60
-- .MoveRight's `cp $94` / .MoveLeft's `cp $58` and .MoveDown's `cp $4c` /
-- .MoveUp's `cp $2c`, one pixel a frame.
local ICON_RUN = ICON_FAR_X - ICON_NEAR_X
local ICON_DROP = ICON_FAR_Y - ICON_NEAR_Y

-- .WaitTimer1 and .WaitTimer2 hold it still for their $80 apiece.
local ICON_PARKED = {
  send_pan_a = true, send_pan_b = true, send_pan_c = true,
  get_pan_a = true, get_pan_b = true, get_pan_c = true,
}

-- Where TradeAnim_AnimateTrademonInTube has the icon and its bubble on a pan
-- beat, or nil once .done_move_down / .WaitTimer2 zero SPRITEANIMSTRUCT_INDEX.
function TradeAnim.tubeIcon(id, t)
  t = math.max(0, math.floor(tonumber(t) or 0))
  if ICON_PARKED[id] then return ICON_NEAR_X, ICON_NEAR_Y end
  if id == "send_wait" then
    local run = math.min(ICON_RUN, t)
    local drop = math.min(ICON_DROP, math.max(0, t - ICON_RUN))
    return ICON_NEAR_X + run, ICON_NEAR_Y + drop
  end
  if id == "get_wait" then
    local drop = math.min(ICON_DROP, t)
    local run = math.min(ICON_RUN, math.max(0, t - ICON_DROP))
    return ICON_FAR_X - run, ICON_FAR_Y - drop
  end
  return nil
end

-- The two trademon records TradeAnimation reads, built the way DoNPCTrade
-- fills them: the PLAYER's is the mon that just left the party (its own DVs,
-- OT and ID, under the player's name as sender), the OT's is the row's mon
-- (the row's OT name doubling as the sender).  Called with the two records
-- NpcTrade.perform answered, so the given mon is the one that walked in, not
-- whatever now sits in that party slot.
function TradeAnim.records(data, save, row, given, received)
  local pokemon = (data and data.pokemon) or {}
  local player = (save and save.player) or {}
  local function speciesOf(id)
    local def = id and pokemon[id]
    return {
      species = id,
      name = (def and def.name) or id or "?",
      dex = (def and def.dex) or 0,
    }
  end
  local give = speciesOf(given and given.species)
  local get = speciesOf(received and received.species
    or (row and row.get))
  give.senderName = player.name or "GOLD"
  give.otName = (given and (given.otName or given.ot)) or give.senderName
  give.id = (given and given.otId) or player.id or 0
  give.shiny = given and given.shiny or false
  -- The DVs ride along because TradeAnim_GetFrontpic runs `predef
  -- GetUnownLetter` before GetBaseData (engine/movie/trade_animation.asm:
  -- 795-804): without them a traded Unown draws as letter A.  unownLetter is
  -- carried too, since Unown.monLetter prefers the stored form.
  give.dvs = given and given.dvs
  give.unownLetter = given and given.unownLetter
  get.senderName = (row and row.otName) or (received and received.otName) or "?"
  get.otName = get.senderName
  get.id = (received and received.otId) or (row and row.otId) or 0
  get.shiny = received and received.shiny or false
  get.dvs = received and received.dvs
  get.unownLetter = received and received.unownLetter
  return give, get
end

return TradeAnim
