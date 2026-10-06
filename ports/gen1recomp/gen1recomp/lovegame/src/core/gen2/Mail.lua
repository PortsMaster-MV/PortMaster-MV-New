-- MAIL: the ten mail items, the letter a party mon carries, and the MAILBOX
-- the player's PC keeps.  engine/pokemon/mail.asm and engine/pokemon/mail_2.asm,
-- with the `mailmsg` struct from macros/ram.asm as it is laid out in
-- ram/sram.asm (sPartyMail, sMailboxCount, sMailboxes).
--
-- The struct is what makes this save-format work rather than a field on a mon:
--
--   Message    MAIL_MSG_LENGTH bytes, drawn as two MAIL_LINE_LENGTH lines
--   Author     NAME_LENGTH - 1 characters, the player at compose time
--   AuthorID   dw, wPlayerID -- what CheckPokeMail's OT half would read
--   Species    db, wCurPartySpecies when the letter was written
--   Type       db, the MAIL item itself, which is what picks the stationery
--
-- sPartyMail is SIX of those indexed BY PARTY SLOT, not by mon, which is the
-- whole reason `removeSlot` and `swapSlots` exist below: RemoveMonFromPartyOrBox
-- shifts the mail up behind a departing mon (engine/pokemon/move_mon.asm's
-- "Mail time!" tail) and SwitchPartyMons swaps two structs
-- (engine/pokemon/switchpartymons.asm).  Hanging the letter off the mon table
-- instead would have been easier and would have been a different save.
--
-- Nothing here touches love or a screen: the four mail screens
-- (src/ui/gen2/MailCompose, MailRead, MailMenu, MailboxMenu) and the script
-- VM's `givepokemail` / `checkpokemail` all drive these routines, so the rules
-- are testable without a keyboard on screen.

local Runtime = require("src.mods.Runtime")

local Mail = {}

-- constants/item_data_constants.asm.
Mail.MAIL_MSG_LENGTH = 0x20
Mail.MAIL_LINE_LENGTH = 0x10
Mail.MAILBOX_CAPACITY = 10
-- constants/text_constants.asm NAME_LENGTH is 11 including the terminator, and
-- the struct's Author field is NAME_LENGTH - 1.
Mail.AUTHOR_LENGTH = 10
-- constants/pokemon_data_constants.asm PARTY_LENGTH; sPartyMail is this many
-- structs and no more.
Mail.PARTY_LENGTH = 6

-- data/items/mail_items.asm MailItems, in its order.  ItemIsMail is a linear
-- search of exactly this list, so anything not on it is not mail however its
-- id is spelled -- which matters, because LITEBLUEMAIL and PORTRAITMAIL do not
-- end in "_MAIL" and a name test would miss both.
Mail.ITEMS = {
  "FLOWER_MAIL", "SURF_MAIL", "LITEBLUEMAIL", "PORTRAITMAIL", "LOVELY_MAIL",
  "EON_MAIL", "MORPH_MAIL", "BLUESKY_MAIL", "MUSIC_MAIL", "MIRAGE_MAIL",
}

-- The *_MAIL_INDEX block at the top of engine/pokemon/mail_2.asm, which is a
-- plain `const_def` (0-based) and indexes both MailGFXPointers and
-- LoadMailPalettes.MailPals.  Kept as a lookup because the READ screen needs
-- it to know where the author line sits: PORTRAITMAIL_INDEX puts it at column
-- 8, MORPH_MAIL_INDEX at 6, everything else at 5 (MailGFX_PlaceMessage).
Mail.INDEX = {}
local IS_MAIL = {}
for i, id in ipairs(Mail.ITEMS) do
  Mail.INDEX[id] = i - 1
  IS_MAIL[id] = true
end

-- constants/script_constants.asm POKEMAIL_*, a `const_def` block, so 0-based.
Mail.POKEMAIL_WRONG_MAIL = 0
Mail.POKEMAIL_CORRECT = 1
Mail.POKEMAIL_REFUSED = 2
Mail.POKEMAIL_NO_MAIL = 3
Mail.POKEMAIL_LAST_MON = 4

-- ItemIsMail (engine/pokemon/mail_2.asm), which is the ONLY definition of
-- "this is mail" anywhere on the cart.  Everything that asks -- the Day-Care,
-- the PC's deposit, the party submenu's MAIL row, the Time Capsule -- calls it.
function Mail.isMail(itemId)
  return itemId ~= nil and IS_MAIL[itemId] == true
end

function Mail.monHoldsMail(mon)
  return type(mon) == "table" and Mail.isMail(mon.item)
end

--------------------------------------------------------------------------
-- Storage
--------------------------------------------------------------------------

-- save.mail is the pair of SRAM regions: `party` is sPartyMail (a sparse array
-- keyed by party slot) and `box` is sMailboxes with sMailboxCount implied by
-- its length.  Created on demand so a save that has never seen a letter still
-- serializes as an empty table rather than six zero-filled structs.
function Mail.state(save)
  if type(save) ~= "table" then return { party = {}, box = {} } end
  local state = save.mail
  if type(state) ~= "table" then
    state = { party = {}, box = {} }
    save.mail = state
  end
  state.party = state.party or {}
  state.box = state.box or {}
  return state
end

-- One `mailmsg`.  `message` keeps the line break as "\n" the way the text
-- decoder does, because GivePokeMail copies the script's bytes verbatim and a
-- `next` in there is a real character in the buffer.
function Mail.entry(itemId, message, author, authorId, species)
  return {
    type = itemId,
    message = message or "",
    author = author or "",
    authorId = authorId or 0,
    species = species,
  }
end

-- Picking a party letter out of the record.  This is also the mail.read
-- latch's re-arm (see Mail.lines): every reader asks here for the struct it is
-- about to open, so a second look at the same letter is a second event.
function Mail.get(save, slot)
  Mail.armRead()
  return Mail.state(save).party[slot]
end

function Mail.set(save, slot, entry)
  if not (slot and slot >= 1 and slot <= Mail.PARTY_LENGTH) then return false end
  Mail.state(save).party[slot] = entry
  return true
end

function Mail.clear(save, slot)
  Mail.state(save).party[slot] = nil
end

-- The "Mail time!" tail of RemoveMonFromPartyOrBox: every struct after the
-- departing slot moves up one, and the slot that was last is cleared.  Called
-- by anything that takes a mon OUT of the party -- a deposit, a trade, the
-- CheckPokeMail handover -- because sPartyMail is keyed by slot and would
-- otherwise hand the next mon along someone else's letter.
function Mail.removeSlot(save, slot)
  local party = Mail.state(save).party
  if not (slot and slot >= 1) then return end
  for i = slot, Mail.PARTY_LENGTH - 1 do
    party[i] = party[i + 1]
  end
  party[Mail.PARTY_LENGTH] = nil
end

-- SwitchPartyMons copies the two structs through wSwitchMonBuffer, so a party
-- reorder carries each letter with its mon.
function Mail.swapSlots(save, a, b)
  local party = Mail.state(save).party
  party[a], party[b] = party[b], party[a]
end

-- IsAnyMonHoldingMail.  The PC's MOVE POKéMON W/O MAIL row and the Time
-- Capsule's party check are the two callers; both refuse outright rather than
-- naming which mon.
function Mail.anyMonHoldingMail(save)
  for _, mon in ipairs((save and save.party) or {}) do
    if Mail.monHoldsMail(mon) then return true end
  end
  return false
end

--------------------------------------------------------------------------
-- Writing
--------------------------------------------------------------------------

-- mail.written, a Gen 2 invention: Gen 1 has no mail, so there is no name to
-- share.  Both routines that put a NEW struct into a party slot raise it --
-- the compose screen and the `givepokemail` a gift script runs -- because from
-- a mod's side they are the same fact: a letter now exists and is pinned to a
-- mon.  Moving one that already exists (MoveMailFromPCToParty, SwitchPartyMons)
-- does not, because nothing was written.
--
--   entry    the `mailmsg` struct, already trimmed to MAIL_MSG_LENGTH
--   slot     the party slot it landed on, 1 based
--   mon      the party record it is pinned to, or nil when compose was handed
--            no mon
--   message  the stored text, with its "\n" kept as one character
--   author   whose name the letter carries -- the player for a composed one,
--            the giver's OT for a scripted one
--   source   "compose" for ComposeMailMessage, "script" for GivePokeMail
local function emitWritten(entry, slot, mon, source)
  if not Runtime.wants("mail.written") then return end
  Runtime.emit("mail.written", {
    entry = entry, slot = slot, mon = mon,
    message = entry.message, author = entry.author, source = source,
  })
end

-- ComposeMailMessage (engine/pokemon/mon_menu.asm), the tail after the
-- keyboard closes: the author is wPlayerName, the id wPlayerID, the species
-- wCurPartySpecies and the type wCurItem -- so a letter remembers who wrote it
-- and which mon it was pinned to, neither of which the reader can change
-- afterwards.
function Mail.compose(save, slot, message, mon, itemId)
  if not (save and slot and itemId) then return false end
  local player = save.player or {}
  local entry = Mail.entry(itemId, Mail.trim(message),
    (player.name or ""):sub(1, Mail.AUTHOR_LENGTH), player.id or 0,
    mon and mon.species)
  local ok = Mail.set(save, slot, entry)
  if ok then emitWritten(entry, slot, mon, "compose") end
  return ok
end

-- GivePokeMail (engine/pokemon/mail.asm): `ld a, [wPartyCount] / dec a` -- the
-- letter always lands on the LAST party member, which is the mon the
-- `givepoke` right before it just added.  The author fields come from that
-- mon's OT rather than from the player, because the giver is the OT.
function Mail.give(save, itemId, message)
  local party = save and save.party
  if not (party and #party > 0 and Mail.isMail(itemId)) then return false end
  local slot = #party
  local mon = party[slot]
  mon.item = itemId
  local entry = Mail.entry(itemId, Mail.trim(message),
    tostring(mon.otName or mon.ot or ""):sub(1, Mail.AUTHOR_LENGTH),
    mon.otId or 0, mon.species)
  local ok = Mail.set(save, slot, entry)
  if ok then emitWritten(entry, slot, mon, "script") end
  return ok
end

-- The buffer is MAIL_MSG_LENGTH bytes and the compose screen can never write
-- past it, but a script's string and a hand-built save can, so the trim is
-- here rather than at each call site.  Counted in characters, not bytes: the
-- charset carries a handful of multi-byte glyphs (é, ♂, ¥, …).
function Mail.trim(message)
  message = tostring(message or "")
  local out, count = {}, 0
  for _, ch in ipairs(Mail.characters(message)) do
    if count >= Mail.MAIL_MSG_LENGTH then break end
    out[#out + 1] = ch
    count = count + 1
  end
  return table.concat(out)
end

-- UTF-8 aware split, so "é" counts as one character the way one charmap byte
-- does.  A "\n" is a character too: it is the `next` byte GivePokeMail copied.
function Mail.characters(text)
  local out = {}
  local i, n = 1, #text
  while i <= n do
    local b = text:byte(i)
    local width = 1
    if b >= 0xF0 then width = 4
    elseif b >= 0xE0 then width = 3
    elseif b >= 0xC0 then width = 2 end
    out[#out + 1] = text:sub(i, i + width - 1)
    i = i + width
  end
  return out
end

-- The two rows MailGFX_PlaceMessage draws.  A message written on the compose
-- screen has no break in it -- the cart stores '<NEXT>' at offset
-- MAIL_LINE_LENGTH and PlaceString obeys it -- so the split is by width; a
-- script's message carries its own break and is split on that instead.
-- mail.read, a Gen 2 invention: Gen 1 has no mail, so there is no name to
-- share.  MailGFX_PlaceMessage is the cart's own "the player is looking at
-- this letter" moment and Mail.lines is the port's transcription of it, so the
-- event rides here rather than on the reader screen -- one seam serves the
-- party reader, the MAILBOX reader and anything a mod opens itself.
--
-- The latch is what makes it one event per opened letter instead of one per
-- frame: src/ui/gen2/MailRead.lua redraws the page every frame while it is up.
-- It is re-armed by Mail.get and Mail.mailbox, which are how a reader picks
-- the letter it is about to open (src/ui/gen2/MailMenu.lua:read,
-- src/ui/gen2/MailboxMenu.lua:readMail), so opening the SAME letter twice is
-- two events rather than one.
--
--   entry    the `mailmsg` struct being read
--   message  its stored text
--   author   the name printed under it, "" when the struct carries none
--   top, bottom  the two rows as MailGFX_PlaceMessage lays them out
local lastRead = nil

function Mail.armRead()
  lastRead = nil
end

local function emitRead(entry, top, bottom)
  if type(entry) ~= "table" then return end
  if not Runtime.wants("mail.read") then
    lastRead = nil
    return
  end
  if lastRead == entry then return end
  lastRead = entry
  Runtime.emit("mail.read", {
    entry = entry, message = entry.message, author = entry.author,
    top = top, bottom = bottom,
  })
end

function Mail.lines(entry)
  local message = (type(entry) == "table" and entry.message) or ""
  local top, bottom = message:match("^(.-)\n(.*)$")
  if not top then
    local chars = Mail.characters(message)
    if #chars <= Mail.MAIL_LINE_LENGTH then
      top, bottom = message, ""
    else
      top = table.concat(chars, "", 1, Mail.MAIL_LINE_LENGTH)
      bottom = table.concat(chars, "", Mail.MAIL_LINE_LENGTH + 1)
    end
  end
  emitRead(entry, top, bottom)
  return top, bottom
end

--------------------------------------------------------------------------
-- The MAILBOX
--------------------------------------------------------------------------

function Mail.mailboxCount(save)
  return #Mail.state(save).box
end

-- sMailboxes itself.  Re-arms the mail.read latch for the same reason
-- Mail.get does: the MAILBOX reader picks its letter out of this list.
function Mail.mailbox(save)
  Mail.armRead()
  return Mail.state(save).box
end

function Mail.mailboxFull(save)
  return Mail.mailboxCount(save) >= Mail.MAILBOX_CAPACITY
end

-- SendMailToPC.  Carry (false here) on either "this mon is not holding mail"
-- or "the MAILBOX is full" -- MonMailAction prints the same .MailboxFullText
-- for both, because the first can only happen if the menu row lied.  On
-- success the struct moves, the party slot is zero-filled AND the mon's held
-- item is cleared, all three in the one routine.
function Mail.sendToPc(save, slot)
  local mon = save and save.party and save.party[slot]
  if not (mon and Mail.monHoldsMail(mon)) then return false end
  if Mail.mailboxFull(save) then return false end
  local state = Mail.state(save)
  local entry = state.party[slot]
  if not entry then
    -- A mon carrying a mail ITEM with no struct behind it (an older save, or a
    -- letter the extractor could not resolve): the cart would copy 47 zero
    -- bytes, so send a blank letter rather than dropping the item on the floor.
    entry = Mail.entry(mon.item, "", "", 0, mon.species)
  end
  state.box[#state.box + 1] = entry
  state.party[slot] = nil
  mon.item = nil
  return true
end

-- DeleteMailFromPC: the shift-up that keeps sMailboxes dense and decrements
-- sMailboxCount.
function Mail.deleteFromPc(save, index)
  local box = Mail.state(save).box
  if not box[index] then return nil end
  return table.remove(box, index)
end

-- MoveMailFromPCToParty, ATTACH MAIL's own half.  The struct is copied into
-- the party slot, the mail's TYPE byte becomes the mon's held item -- which is
-- how a letter and its stationery stay together -- and only then is the
-- mailbox entry deleted.
function Mail.moveFromPcToParty(save, index, slot)
  local box = Mail.state(save).box
  local entry = box[index]
  local mon = save and save.party and save.party[slot]
  if not (entry and mon) then return false end
  Mail.set(save, slot, entry)
  mon.item = entry.type
  table.remove(box, index)
  return true
end

--------------------------------------------------------------------------
-- CheckPokeMail
--------------------------------------------------------------------------

-- CheckPokeMail (engine/pokemon/mail.asm), the `checkpokemail` opcode's whole
-- body once the party list has answered.  `slot` is nil for the B press.
--
-- The order is the cart's and it matters: a REFUSED never looks at the mon at
-- all, NO_MAIL beats WRONG_MAIL, and LAST_MON is checked AFTER the message
-- compares equal -- so handing over the right mon with the right letter while
-- it is your last conscious one still loses you the reward and keeps the mon.
--
-- `expected` is the raw string the script points at, terminated by '@' on the
-- cart; the comparison runs until that terminator, so a stored message LONGER
-- than the expected one still matches.  The removal on CORRECT is
-- RemoveMonFromPartyOrBox with REMOVE_PARTY, which is why the mail shift rides
-- along with it.
function Mail.checkPokeMail(save, slot, expected)
  if not slot then return Mail.POKEMAIL_REFUSED end
  local mon = save and save.party and save.party[slot]
  if not (mon and Mail.monHoldsMail(mon)) then return Mail.POKEMAIL_NO_MAIL end
  local entry = Mail.get(save, slot)
  local got = (entry and entry.message) or ""
  if type(expected) ~= "string" or expected == "" then
    -- No expected message resolved (a cache built before the extractor
    -- followed the operand).  The cart compares against real bytes; with none,
    -- WRONG_MAIL is the answer that changes nothing and keeps the mon.
    return Mail.POKEMAIL_WRONG_MAIL
  end
  if got:sub(1, #expected) ~= expected then
    return Mail.POKEMAIL_WRONG_MAIL
  end
  -- CheckCurPartyMonFainted: carry when this is the last conscious mon.
  local healthy = 0
  for i, member in ipairs(save.party) do
    if i ~= slot and (member.hp or 0) > 0 then healthy = healthy + 1 end
  end
  if (mon.hp or 0) > 0 and healthy == 0 then return Mail.POKEMAIL_LAST_MON end
  table.remove(save.party, slot)
  Mail.removeSlot(save, slot)
  return Mail.POKEMAIL_CORRECT
end

--------------------------------------------------------------------------
-- Save hygiene
--------------------------------------------------------------------------

-- A quarantine pass with the same discipline src/core/gen2/Save.lua's
-- scrubScriptMem has: a struct play would nil-index or draw off the screen
-- never reaches the game, and whatever had to be dropped is reported.
--
-- What can go wrong here that nothing else can vouch for: a party key outside
-- 1..6 (sPartyMail is six structs), a mailbox past MAILBOX_CAPACITY, a `type`
-- that is not one of the ten mail items (so the READ screen would have no
-- stationery and MoveMailFromPCToParty would hang a non-item on a mon), and a
-- message longer than the buffer, which is trimmed rather than dropped because
-- the first MAIL_MSG_LENGTH characters are still the player's letter.
local function cleanEntry(entry)
  if type(entry) ~= "table" then return nil, "not a struct" end
  if not Mail.isMail(entry.type) then return nil, "not a MAIL item" end
  local message = tostring(entry.message or "")
  local trimmed = Mail.trim(message)
  local author = tostring(entry.author or ""):sub(1, Mail.AUTHOR_LENGTH)
  local authorId = tonumber(entry.authorId) or 0
  if authorId ~= math.floor(authorId) or authorId < 0 or authorId > 0xFFFF then
    authorId = 0
  end
  return {
    type = entry.type,
    message = trimmed,
    author = author,
    authorId = authorId,
    species = entry.species,
  }, (trimmed ~= message) and "message trimmed" or nil
end

-- report.lostMail collects { where = "party"|"box", slot, why }.
function Mail.validate(save, report)
  local lost = report and report.lostMail or {}
  if report then report.lostMail = lost end
  if type(save) ~= "table" then return lost end
  local raw = save.mail
  if raw ~= nil and type(raw) ~= "table" then
    lost[#lost + 1] = { where = "mail", why = "not a table" }
    save.mail = nil
  end
  local state = Mail.state(save)

  local party = {}
  for key, entry in pairs(state.party) do
    local slot = tonumber(key)
    if not (slot and slot == math.floor(slot)
        and slot >= 1 and slot <= Mail.PARTY_LENGTH) then
      lost[#lost + 1] = { where = "party", slot = key, why = "slot out of range" }
    else
      local clean, why = cleanEntry(entry)
      if clean then
        party[slot] = clean
        if why then
          lost[#lost + 1] = { where = "party", slot = slot, why = why }
        end
      else
        lost[#lost + 1] = { where = "party", slot = slot, why = why }
      end
    end
  end
  state.party = party

  local box = {}
  for _, entry in ipairs(state.box) do
    local clean, why = cleanEntry(entry)
    if not clean then
      lost[#lost + 1] = { where = "box", slot = #box + 1, why = why }
    elseif #box >= Mail.MAILBOX_CAPACITY then
      lost[#lost + 1] = { where = "box", slot = #box + 1, why = "MAILBOX full" }
    else
      box[#box + 1] = clean
      if why then
        lost[#lost + 1] = { where = "box", slot = #box, why = why }
      end
    end
  end
  state.box = box
  return lost
end

return Mail
