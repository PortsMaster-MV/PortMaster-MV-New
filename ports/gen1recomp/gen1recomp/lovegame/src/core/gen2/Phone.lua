-- The POKeGEAR's phone (engine/phone/phone.asm, data/phone/*.asm and the
-- receive-call timer in engine/overworld/time.asm).
--
-- love-free on purpose: everything here is model.  The Pokegear card
-- (src/ui/gen2/Pokegear.lua) drives the outgoing half, the script VM
-- (src/script/gen2/Vm.lua) drives the incoming half and the four phone
-- opcodes, and both talk to this module rather than to each other.
--
-- The cart's phone is three separate machines that share one contact table:
--
--   OUTGOING  MakePhoneCallFromPokegear.  You pick a name off wPhoneList; the
--             contact's SCRIPT1 ("callee": you called them) runs, unless there
--             is no signal, unless they cannot take a call at this time of
--             day, or unless you are standing on their own map -- in which
--             case the game tells you to go talk to them instead.
--
--   INCOMING  CheckPhoneCall, run once per step out of PlayerEvents.  A gate
--             of five tests decides whether anyone rings; if one does, that
--             contact's SCRIPT2 ("caller": they called you) runs.  This is the
--             half that hands out the trainer rematch flags.
--
--   SPECIAL   CheckSpecialPhoneCall, run BEFORE the step is counted.  A script
--             somewhere in the world has done `specialphonecall N`, which
--             parks N in wSpecialPhoneCallID; the next time its condition
--             holds, that scripted call jumps the queue.  This is main quest,
--             not flavour: Elm's "your POKeMON was stolen" and "the egg
--             hatched" beats, Mom's lecture and the bike shop's call are all
--             special calls.
--
-- Notes that cost real time to work out, kept here so the next reader does not
-- have to:
--
--   * PhoneContacts rows carry TWO time-of-day masks.  SCRIPT1_TIME gates YOU
--     calling THEM, SCRIPT2_TIME gates THEM calling YOU.  Mom, Elm, Bill and
--     the bike shop all have SCRIPT2_TIME 0, so none of them can ever be
--     picked as a random caller -- every unprompted call from Elm arrives
--     through the special-call queue.
--
--   * The delay timer is restarted by StartMap (engine/overworld/events.asm
--     `farcall InitCallReceiveDelay`), so it starts over at twenty in-game
--     minutes on EVERY map load.  A player who keeps warping is never called.
--
--   * The queue is cleared by the called script itself (`specialphonecall
--     SPECIALCALL_NONE` is the first or second line of every special caller
--     script), not by the engine.  See Phone.endCall for the fallback a cache
--     with no bank $41 scripts still gets.
--
-- The call scripts live in ROM bank $41, which the extractor reaches by
-- seeding its queue from PhoneContacts and SpecialPhoneCallList (no map
-- points into that bank, so those two tables are the only way in), and
-- Phone.useExtracted overlays the cache's own rows below.  Every contact
-- still names its pokegold script LABEL and the "bank:addr" key from the
-- symbol file: Phone.scriptKey resolves a label to that key, a call
-- descriptor carries both, and the pair is what lets a repointed cache be
-- caught by test rather than call the wrong script.  A call's presentation
-- (the ring, the Click!, the countdown restart) is src/core/gen2/PhoneRing.lua.

local Runtime = require("src.mods.Runtime")

local Phone = {}

-- ------------------------------------------------------- constants

-- constants/phone_constants.asm
Phone.CONTACT_LIST_SIZE = 10
Phone.NUM_PHONE_CONTACTS = 36
Phone.SPECIALCALL_NONE = 0
Phone.NUM_SPECIALCALLS = 8

-- constants/ram_constants.asm wTimeOfDay.  DARKNESS has no bit of its own in
-- CheckTime's table, and IsInArray stops at the first match, so a dark map
-- resolves to c = 0: nobody is available and no contact can be called.
Phone.MORN, Phone.DAY, Phone.NITE = 1, 2, 4
Phone.ANYTIME = 7 -- MORN | DAY | NITE

-- constants/misc_constants.asm time of day boundaries.
local MORN_HOUR, DAY_HOUR, NITE_HOUR = 4, 10, 18
local MAX_HOUR = 24
-- _CalcDaysSince wraps with `add 20 * 7`; wCurDay counts inside that window.
local MAX_DAY = 140

-- constants/script_constants.asm, askforphonenumber return values.
Phone.CONTACT_GOT = 0
Phone.CONTACTS_FULL = 1
Phone.CONTACT_REFUSED = 2

-- constants/script_constants.asm readvar id, for the VM's readVar hook:
-- `dwb wSpecialPhoneCallID, RETVAR_STRBUF2` (engine/overworld/variables.asm).
Phone.VAR_SPECIALPHONECALL = 0x14

-- constants/map_data_constants.asm environments.  SpecialCallOnlyWhenOutside
-- takes TOWN and ROUTE and nothing else.
local OUTSIDE_ENVIRONMENTS = { TOWN = true, ROUTE = true }

-- constants/trainer_constants.asm.  That block opens `const_def 1`, so the
-- non-trainer contacts are ONE based and PHONECONTACT_MOM is 1, not 0.  They
-- double as PhoneContacts row indexes, which is why SpecialPhoneCallList can
-- hand PHONECONTACT_ELM straight to LoadCallerScript.
Phone.PHONECONTACT_MOM = 1
Phone.PHONECONTACT_BIKESHOP = 2
Phone.PHONECONTACT_BILL = 3
Phone.PHONECONTACT_ELM = 4

-- data/phone/non_trainer_names.asm, in table order (index = the row's trainer
-- NUMBER byte, which for a non-trainer is its PHONECONTACT_* constant).
Phone.NON_TRAINER_NAMES = {
  [0] = "----------",
  [1] = "MOM",
  [2] = "BIKE SHOP",
  [3] = "BILL",
  [4] = "PROF.ELM",
}

-- data/phone/permanent_numbers.asm.  GetRemainingSpaceInPhoneList reserves a
-- slot for each of these you do not have yet, so a player who has not met Elm
-- can only fill eight of the ten slots.
Phone.PERMANENT_NUMBERS = { Phone.PHONECONTACT_MOM, Phone.PHONECONTACT_ELM }

-- ------------------------------------------------------- the contact table
--
-- data/phone/phone_contacts.asm, one row per PHONE_* constant
-- (constants/phone_constants.asm).  The macro's argument order is
--   trainer class, trainer id, map, callee time, callee script,
--   caller time, caller script
-- and the struct order is TRAINER_CLASS, TRAINER_NUMBER, MAP_GROUP,
-- MAP_NUMBER, SCRIPT1_TIME/BANK/ADDR, SCRIPT2_TIME/BANK/ADDR -- so SCRIPT1 is
-- the callee pair and SCRIPT2 the caller pair.
--
-- `map` is the map's id string; the cart stores a group/number pair and
-- compares it against wMapGroup/wMapNumber, and data/generated/maps.lua keys
-- every map by exactly that id, so the string compare is the same test.  N_A
-- is group $ff / map $ff, which no real map ever equals: nil here.
--
-- The table is indexed from ZERO: PHONE_00 is a real row (the wrong-number
-- filler that LoadCallerScript falls back to) and three of its siblings sit in
-- the middle of the table as const_skip holes.
--
-- The non-trainer rows also carry their own `name`, copied verbatim from
-- NON_TRAINER_NAMES rather than left for Phone.contactName() to look up
-- there: the phone_contacts registry overrides `name` directly (see
-- Phone.contactName below), so a row needs its vanilla value sitting in the
-- same field a patch would replace, not in a separate table a patched row
-- would silently keep falling through to.
Phone.CONTACTS = {
  [0]  = { number = 0, name = "----------", map = nil,
           calleeTime = 0, callee = "UnusedPhoneScript",
           callerTime = 0, caller = "UnusedPhoneScript" },
  [1]  = { number = Phone.PHONECONTACT_MOM, name = "MOM",
           map = "PLAYERS_HOUSE_1F",
           calleeTime = Phone.ANYTIME, callee = "MomPhoneCalleeScript",
           callerTime = 0, caller = "UnusedPhoneScript" },
  [2]  = { number = Phone.PHONECONTACT_BIKESHOP, name = "BIKE SHOP",
           map = "OAKS_LAB",
           calleeTime = 0, callee = "UnusedPhoneScript",
           callerTime = 0, caller = "UnusedPhoneScript" },
  [3]  = { number = Phone.PHONECONTACT_BILL, name = "BILL", map = nil,
           calleeTime = Phone.ANYTIME, callee = "BillPhoneCalleeScript",
           callerTime = 0, caller = "BillPhoneCallerScript" },
  [4]  = { number = Phone.PHONECONTACT_ELM, name = "PROF.ELM",
           map = "ELMS_LAB",
           calleeTime = Phone.ANYTIME, callee = "ElmPhoneCalleeScript",
           callerTime = 0, caller = "ElmPhoneCallerScript" },
  [5]  = { class = "SCHOOLBOY", member = "JACK1", map = "NATIONAL_PARK",
           callee = "JackPhoneCalleeScript", caller = "JackPhoneCallerScript" },
  [6]  = { class = "POKEFANF", member = "BEVERLY1", map = "NATIONAL_PARK",
           callee = "BeverlyPhoneCalleeScript",
           caller = "BeverlyPhoneCallerScript" },
  [7]  = { class = "SAILOR", member = "HUEY1", map = "OLIVINE_LIGHTHOUSE_2F",
           callee = "HueyPhoneCalleeScript", caller = "HueyPhoneCallerScript" },
  -- const_skip x3
  [8]  = false, [9] = false, [10] = false,
  [11] = { class = "COOLTRAINERM", member = "GAVEN3", map = "ROUTE_26",
           callee = "GavenPhoneCalleeScript",
           caller = "GavenPhoneCallerScript" },
  [12] = { class = "COOLTRAINERF", member = "BETH1", map = "ROUTE_26",
           callee = "BethPhoneCalleeScript", caller = "BethPhoneCallerScript" },
  [13] = { class = "BIRD_KEEPER", member = "JOSE2", map = "ROUTE_27",
           callee = "JosePhoneCalleeScript", caller = "JosePhoneCallerScript" },
  [14] = { class = "COOLTRAINERF", member = "REENA1", map = "ROUTE_27",
           callee = "ReenaPhoneCalleeScript",
           caller = "ReenaPhoneCallerScript" },
  [15] = { class = "YOUNGSTER", member = "JOEY1", map = "ROUTE_30",
           callee = "JoeyPhoneCalleeScript", caller = "JoeyPhoneCallerScript" },
  [16] = { class = "BUG_CATCHER", member = "WADE1", map = "ROUTE_31",
           callee = "WadePhoneCalleeScript", caller = "WadePhoneCallerScript" },
  [17] = { class = "FISHER", member = "RALPH1", map = "ROUTE_32",
           callee = "RalphPhoneCalleeScript",
           caller = "RalphPhoneCallerScript" },
  [18] = { class = "PICNICKER", member = "LIZ1", map = "ROUTE_32",
           callee = "LizPhoneCalleeScript", caller = "LizPhoneCallerScript" },
  [19] = { class = "HIKER", member = "ANTHONY2", map = "ROUTE_33",
           callee = "AnthonyPhoneCalleeScript",
           caller = "AnthonyPhoneCallerScript" },
  [20] = { class = "CAMPER", member = "TODD1", map = "ROUTE_34",
           callee = "ToddPhoneCalleeScript", caller = "ToddPhoneCallerScript" },
  [21] = { class = "PICNICKER", member = "GINA1", map = "ROUTE_34",
           callee = "GinaPhoneCalleeScript", caller = "GinaPhoneCallerScript" },
  [22] = { class = "JUGGLER", member = "IRWIN1", map = "ROUTE_35",
           callee = "IrwinPhoneCalleeScript",
           caller = "IrwinPhoneCallerScript" },
  [23] = { class = "BUG_CATCHER", member = "ARNIE1", map = "ROUTE_35",
           callee = "ArniePhoneCalleeScript",
           caller = "ArniePhoneCallerScript" },
  [24] = { class = "SCHOOLBOY", member = "ALAN1", map = "ROUTE_36",
           callee = "AlanPhoneCalleeScript", caller = "AlanPhoneCallerScript" },
  -- const_skip
  [25] = false,
  [26] = { class = "LASS", member = "DANA1", map = "ROUTE_38",
           callee = "DanaPhoneCalleeScript", caller = "DanaPhoneCallerScript" },
  [27] = { class = "SCHOOLBOY", member = "CHAD1", map = "ROUTE_38",
           callee = "ChadPhoneCalleeScript", caller = "ChadPhoneCallerScript" },
  [28] = { class = "POKEFANM", member = "DEREK1", map = "ROUTE_39",
           callee = "DerekPhoneCalleeScript",
           caller = "DerekPhoneCallerScript" },
  [29] = { class = "FISHER", member = "CHRIS1", map = "ROUTE_42",
           callee = "ChrisPhoneCalleeScript",
           caller = "ChrisPhoneCallerScript" },
  [30] = { class = "POKEMANIAC", member = "BRENT1", map = "ROUTE_43",
           callee = "BrentPhoneCalleeScript",
           caller = "BrentPhoneCallerScript" },
  [31] = { class = "PICNICKER", member = "TIFFANY3", map = "ROUTE_43",
           callee = "TiffanyPhoneCalleeScript",
           caller = "TiffanyPhoneCallerScript" },
  [32] = { class = "BIRD_KEEPER", member = "VANCE1", map = "ROUTE_44",
           callee = "VancePhoneCalleeScript",
           caller = "VancePhoneCallerScript" },
  [33] = { class = "FISHER", member = "WILTON1", map = "ROUTE_44",
           callee = "WiltonPhoneCalleeScript",
           caller = "WiltonPhoneCallerScript" },
  [34] = { class = "BLACKBELT_T", member = "KENJI3", map = "ROUTE_45",
           callee = "KenjiPhoneCalleeScript",
           caller = "KenjiPhoneCallerScript" },
  [35] = { class = "HIKER", member = "PARRY1", map = "ROUTE_45",
           callee = "ParryPhoneCalleeScript",
           caller = "ParryPhoneCallerScript" },
  [36] = { class = "PICNICKER", member = "ERIN1", map = "ROUTE_46",
           callee = "ErinPhoneCalleeScript", caller = "ErinPhoneCallerScript" },
}

-- Every trainer row in the table is `ANYTIME, <callee>, ANYTIME, <caller>`;
-- only the five non-trainer rows above spell their masks out.  Fill the rest
-- in rather than repeating ANYTIME twenty-eight times, and turn the const_skip
-- holes into copies of row 0 so an out-of-range id can never index nil.
for index = 0, Phone.NUM_PHONE_CONTACTS do
  local row = Phone.CONTACTS[index]
  if row == false or row == nil then
    row = { number = 0, name = "----------", map = nil,
            calleeTime = 0, callee = "UnusedPhoneScript",
            callerTime = 0, caller = "UnusedPhoneScript" }
    Phone.CONTACTS[index] = row
  end
  row.index = index
  if row.class then
    row.calleeTime = row.calleeTime or Phone.ANYTIME
    row.callerTime = row.callerTime or Phone.ANYTIME
  end
end

-- ------------------------------------------------------- the registry
--
-- The `phone_contacts` registry (src/mods/Schemas.lua), one of the Gen 2-only
-- six: Red has no Pokegear, so the name is gated under Gen 1 and routed to
-- data.gen2PhoneContacts under Gen 2.  src/mods/Builtins.lua seeds it with the
-- rows above, engine-owned, so a mod's register of PHONE_YOUNGSTER_JOEY
-- collides and has to say override -- the same contract every other seeded
-- registry keeps.
--
-- The id space is the cart's own PHONE_* constants, which arrive as
-- data.gen2Constants.phoneContactOrder; `index` on each record is the row byte
-- every lookup in this file keys by, and it is what puts a merged record back
-- on the right row.  The four PHONE_UNUSED const_skip holes are not
-- registered: one id cannot name four rows, and all four are copies of the
-- wrong-number filler.
--
-- Rows are applied ONTO Phone.CONTACTS rather than read through it, because
-- every reader here (and every caller in src/ui/gen2/) has the contact byte
-- and not the dataset -- the same shape Phone.useExtracted already has for the
-- cache's own rows.  The order is literal -> cache -> registry: useExtracted
-- re-applies the stored rows at its tail, so a mod's edit survives the cache
-- overlay whichever of the two runs second.
local registryRows = nil

local function applyRegistryRows()
  if not registryRows then return 0 end
  local applied = 0
  for _, record in pairs(registryRows) do
    local index = type(record) == "table" and record.index
    local dest = index and Phone.CONTACTS[index]
    if dest then
      for key, value in pairs(record) do dest[key] = value end
      applied = applied + 1
    end
  end
  return applied
end

-- vanilla registrations, engine-owned; `data` carries the constant order the
-- ids come from, so a dataset without it registers nothing rather than
-- inventing names
function Phone.registerInto(registry, data, owner)
  local order = data and data.gen2Constants and data.gen2Constants.phoneContactOrder
  if type(order) ~= "table" then return 0 end
  local count = 0
  for index = 0, Phone.NUM_PHONE_CONTACTS do
    local id = order[index + 1]
    local row = Phone.CONTACTS[index]
    if type(id) == "string" and id ~= "PHONE_UNUSED" and row then
      registry:register(id, row, owner)
      count = count + 1
    end
  end
  return count
end

-- the merged table, held by reference and folded onto the contact rows.  Pass
-- nil to forget it (a second dataset in one process).
function Phone.useRegistry(data)
  registryRows = data and data.gen2PhoneContacts or nil
  return applyRegistryRows()
end

-- ------------------------------------------------------- script keys
--
-- ../pokegold-symbols/pokegold.sym.  scripts.lua keys a command list by
-- "<bank hex>:<addr hex>", the same form the extractor writes for a map
-- script, so these become live the moment bank $41 (the phone scripts) and
-- bank $24 (the phone engine's own little scripts) are extracted.
Phone.SCRIPT_KEYS = {
  UnusedPhoneScript = "41:4000",
  MomPhoneCalleeScript = "41:4004",
  MomPhoneLectureScript = "41:4124",
  BillPhoneCalleeScript = "41:4137",
  BillPhoneCallerScript = "41:4172",
  ElmPhoneCalleeScript = "41:4177",
  ElmPhoneCallerScript = "41:41e1",
  JackPhoneCalleeScript = "41:422a",
  JackPhoneCallerScript = "41:4234",
  BeverlyPhoneCalleeScript = "41:4256",
  BeverlyPhoneCallerScript = "41:4260",
  HueyPhoneCalleeScript = "41:4282",
  HueyPhoneCallerScript = "41:428c",
  GavenPhoneCalleeScript = "41:42a7",
  GavenPhoneCallerScript = "41:42b1",
  BethPhoneCalleeScript = "41:42d3",
  BethPhoneCallerScript = "41:42dd",
  JosePhoneCalleeScript = "41:42ff",
  JosePhoneCallerScript = "41:4309",
  ReenaPhoneCalleeScript = "41:4332",
  ReenaPhoneCallerScript = "41:433c",
  JoeyPhoneCalleeScript = "41:435e",
  JoeyPhoneCallerScript = "41:4368",
  WadePhoneCalleeScript = "41:4390",
  WadePhoneCallerScript = "41:43b5",
  RalphPhoneCalleeScript = "41:43f8",
  RalphPhoneCallerScript = "41:4402",
  LizPhoneCalleeScript = "41:4446",
  LizPhoneCallerScript = "41:4450",
  AnthonyPhoneCalleeScript = "41:4478",
  AnthonyPhoneCallerScript = "41:4482",
  ToddPhoneCalleeScript = "41:44c4",
  ToddPhoneCallerScript = "41:44ce",
  GinaPhoneCalleeScript = "41:44f6",
  GinaPhoneCallerScript = "41:4506",
  IrwinPhoneCalleeScript = "41:4534",
  IrwinPhoneCallerScript = "41:4544",
  ArniePhoneCalleeScript = "41:456c",
  ArniePhoneCallerScript = "41:4576",
  AlanPhoneCalleeScript = "41:45b2",
  AlanPhoneCallerScript = "41:45bc",
  DanaPhoneCalleeScript = "41:45de",
  DanaPhoneCallerScript = "41:45e8",
  ChadPhoneCalleeScript = "41:460a",
  ChadPhoneCallerScript = "41:4614",
  DerekPhoneCalleeScript = "41:4650",
  DerekPhoneCallerScript = "41:4675",
  ChrisPhoneCalleeScript = "41:46b2",
  ChrisPhoneCallerScript = "41:46bc",
  BrentPhoneCalleeScript = "41:46de",
  BrentPhoneCallerScript = "41:46e8",
  TiffanyPhoneCalleeScript = "41:4711",
  TiffanyPhoneCallerScript = "41:471b",
  VancePhoneCalleeScript = "41:4744",
  VancePhoneCallerScript = "41:474e",
  WiltonPhoneCalleeScript = "41:4770",
  WiltonPhoneCallerScript = "41:477a",
  KenjiPhoneCalleeScript = "41:47b8",
  KenjiPhoneCallerScript = "41:47c2",
  ParryPhoneCalleeScript = "41:47e4",
  ParryPhoneCallerScript = "41:47ee",
  ErinPhoneCalleeScript = "41:482a",
  ErinPhoneCallerScript = "41:4834",
  BikeShopPhoneCallerScript = "41:4a80",
  -- bank $24: the engine's own scripts, reached without a contact row.
  WrongNumberScript = "24:4240",
  PhoneOutOfAreaScript = "24:4626",
  PhoneScript_JustTalkToThem = "24:462f",
}

function Phone.scriptKey(label)
  return label and Phone.SCRIPT_KEYS[label] or nil
end

-- Take the contact rows and the special-call rows out of the CACHE instead of
-- out of the two tables above.
--
-- Those tables were written when nothing pointed into bank $41 and the port
-- had to name every script by its pokegold label and its symbol-file address.
-- The extractor follows PhoneContacts and SpecialPhoneCallList now, so the
-- rows arrive already resolved and a repointed table cannot silently call the
-- wrong script -- the same reason `special` is dispatched by name through
-- specialOrder rather than by a counted index.
--
-- Only the fields the cart actually stores are overlaid.  `class`, `member`
-- and the SCRIPT_KEYS labels stay: they are what the trainer rematch
-- machinery and Phone.contactName read, and the ROM row carries a trainer
-- class BYTE rather than a name.  A cache with no events.lua leaves both
-- tables exactly as they are.
function Phone.useExtracted(events)
  local rows = type(events) == "table" and events.phone
  if type(rows) ~= "table" then return false end
  local applied = 0
  for index = 0, Phone.NUM_PHONE_CONTACTS do
    local row, dest = rows[index], Phone.CONTACTS[index]
    if type(row) == "table" and dest then
      dest.map = row.map
      dest.calleeTime = row.calleeTime
      dest.callerTime = row.callerTime
      dest.calleeKey = row.callee
      dest.callerKey = row.caller
      -- A row the cart fills with UnusedPhoneScript has a real number of 0;
      -- keep the hand-ported number for the four PHONECONTACT_* rows, whose
      -- ids the rest of this file compares against by name.
      if row.number and row.number ~= 0 then dest.number = row.number end
      applied = applied + 1
    end
  end
  for _, row in ipairs(events.specialCalls or {}) do
    local dest = Phone.SPECIAL_CALLS[row.id]
    if dest then
      dest.contact = row.contact
      dest.scriptKey = row.script
    end
  end
  -- The three scripts the engine runs without a contact row.  These stay in
  -- SCRIPT_KEYS because Phone.call names them by label.
  for label, row in pairs(events.phoneScripts or {}) do
    if row.script then Phone.SCRIPT_KEYS[label] = row.script end
  end
  -- Last word to the `phone_contacts` merge: this routine overwrites six
  -- fields on every row it has a cache entry for, and it runs from
  -- src/world/gen2/World.lua:load -- after src/core/Game2.lua:load has
  -- already folded the merged rows in.  Re-applying them here is what
  -- keeps the order literal -> cache -> registry whichever way round the two
  -- calls land.
  applyRegistryRows()
  Phone.extracted = applied > 0
  return Phone.extracted
end

-- ------------------------------------------------------- special calls
--
-- data/phone/special_calls.asm, indexed by SPECIALCALL_* (which starts at
-- SPECIALCALL_NONE = 0, so the first real entry is 1 and the table is read as
-- `SpecialPhoneCallList + (id - 1) * SPECIALCALL_SIZE`).
--
-- Each row is `condition, contact, script`: the condition decides WHEN the
-- queued call is allowed to fire, the contact names whose textbox and name it
-- wears, and the script REPLACES that contact's SCRIPT2 for this one call.
Phone.SPECIAL_CALLS = {
  [1] = { name = "SPECIALCALL_POKERUS", condition = "outside",
          contact = Phone.PHONECONTACT_ELM, script = "ElmPhoneCallerScript" },
  [2] = { name = "SPECIALCALL_ROBBED", condition = "outside",
          contact = Phone.PHONECONTACT_ELM, script = "ElmPhoneCallerScript" },
  [3] = { name = "SPECIALCALL_ASSISTANT", condition = "outside",
          contact = Phone.PHONECONTACT_ELM, script = "ElmPhoneCallerScript" },
  [4] = { name = "SPECIALCALL_WEIRDBROADCAST", condition = "outside",
          contact = Phone.PHONECONTACT_ELM, script = "ElmPhoneCallerScript" },
  [5] = { name = "SPECIALCALL_SSTICKET", condition = "anywhere",
          contact = Phone.PHONECONTACT_ELM, script = "ElmPhoneCallerScript" },
  [6] = { name = "SPECIALCALL_BIKESHOP", condition = "anywhere",
          contact = Phone.PHONECONTACT_BIKESHOP,
          script = "BikeShopPhoneCallerScript" },
  [7] = { name = "SPECIALCALL_WORRIED", condition = "anywhere",
          contact = Phone.PHONECONTACT_MOM,
          script = "MomPhoneLectureScript" },
  [8] = { name = "SPECIALCALL_MASTERBALL", condition = "outside",
          contact = Phone.PHONECONTACT_ELM, script = "ElmPhoneCallerScript" },
}

-- Name -> id, so a caller can queue by the constant it reads in the decomp.
Phone.SPECIALCALL = { SPECIALCALL_NONE = 0 }
for id, entry in pairs(Phone.SPECIAL_CALLS) do
  Phone.SPECIALCALL[entry.name] = id
end

-- ------------------------------------------------------- rematch flags
--
-- engine/phone/scripts/trainers.asm: every caller script has a .WantsBattle
-- branch whose `setevent EVENT_<NAME>_READY_FOR_REMATCH` is the whole rematch
-- mechanic -- the trainer's own map script then reads that flag and offers the
-- second party.  So the flag is set by the extracted script, not by this
-- module; what lives here is the contact -> flag mapping, for the callers that
-- want to ask "is this contact waiting?" and for the fallback in
-- Phone.setRematchReady while bank $41 is unextracted.
--
-- The numbers are wEventFlags bit indexes, counted through
-- constants/event_flags.asm's const_def / const_skip / const_next chain (the
-- same chain that gives EVENT_ROUTE_30_BATTLE = 1812, which is the eventFlag
-- the extracted Route 30 object already carries -- that match is what verifies
-- this counting).
Phone.REMATCH_EVENTS = {
  [5]  = 608, -- EVENT_JACK_READY_FOR_REMATCH
  [6]  = 610, -- EVENT_BEVERLY_READY_FOR_REMATCH
  [7]  = 612, -- EVENT_HUEY_READY_FOR_REMATCH
  [11] = 620, -- EVENT_GAVEN_READY_FOR_REMATCH
  [12] = 622, -- EVENT_BETH_READY_FOR_REMATCH
  [13] = 624, -- EVENT_JOSE_READY_FOR_REMATCH
  [14] = 626, -- EVENT_REENA_READY_FOR_REMATCH
  [15] = 628, -- EVENT_JOEY_READY_FOR_REMATCH
  [16] = 630, -- EVENT_WADE_READY_FOR_REMATCH
  [17] = 632, -- EVENT_RALPH_READY_FOR_REMATCH
  [18] = 634, -- EVENT_LIZ_READY_FOR_REMATCH
  [19] = 636, -- EVENT_ANTHONY_READY_FOR_REMATCH
  [20] = 638, -- EVENT_TODD_READY_FOR_REMATCH
  [21] = 640, -- EVENT_GINA_READY_FOR_REMATCH
  [22] = 642, -- EVENT_IRWIN_READY_FOR_REMATCH
  [23] = 644, -- EVENT_ARNIE_READY_FOR_REMATCH
  [24] = 646, -- EVENT_ALAN_READY_FOR_REMATCH
  [26] = 650, -- EVENT_DANA_READY_FOR_REMATCH
  [27] = 652, -- EVENT_CHAD_READY_FOR_REMATCH
  [28] = 654, -- EVENT_DEREK_READY_FOR_REMATCH
  [29] = 656, -- EVENT_CHRIS_READY_FOR_REMATCH
  [30] = 658, -- EVENT_BRENT_READY_FOR_REMATCH
  [31] = 660, -- EVENT_TIFFANY_READY_FOR_REMATCH
  [32] = 662, -- EVENT_VANCE_READY_FOR_REMATCH
  [33] = 664, -- EVENT_WILTON_READY_FOR_REMATCH
  [34] = 666, -- EVENT_KENJI_READY_FOR_REMATCH
  [35] = 668, -- EVENT_PARRY_READY_FOR_REMATCH
  [36] = 670, -- EVENT_ERIN_READY_FOR_REMATCH
}

-- ------------------------------------------------------- save state
--
-- src/core/gen2/Save.lua owns the file; this is the block the phone keeps in
-- it.  `list` is wPhoneList (ten ordered slots, 0 = empty), which is the shape
-- the Pokegear reads and the shape AddPhoneNumber's reserved-slot arithmetic
-- needs -- a set of ids cannot answer "which slot".
--
-- save.phoneContacts (the id -> true set the VM's addcellnum/checkcellnum
-- hooks already write in src/world/gen2/World.lua) is kept mirrored in both
-- directions so neither half has to change before the other does.
local function newState()
  return {
    list = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    specialCall = 0,           -- wSpecialPhoneCallID
    timeCycles = 0,            -- wTimeCyclesSinceLastCall
    delayMins = 20,            -- wReceiveCallDelay_MinsRemaining
    delayStart = nil,          -- wReceiveCallDelay_StartTime {day,hour,minute}
  }
end

local function inList(state, id)
  for slot = 1, Phone.CONTACT_LIST_SIZE do
    if state.list[slot] == id then return slot end
  end
  return nil
end

function Phone.state(save)
  if type(save) ~= "table" then return newState() end
  local state = save.phone
  if type(state) ~= "table" then
    state = newState()
    save.phone = state
  end
  state.list = type(state.list) == "table" and state.list or {}
  for slot = 1, Phone.CONTACT_LIST_SIZE do
    state.list[slot] = tonumber(state.list[slot]) or 0
  end
  state.specialCall = tonumber(state.specialCall) or 0
  state.timeCycles = tonumber(state.timeCycles) or 0
  state.delayMins = tonumber(state.delayMins) or 20
  -- Adopt anything the VM's addcellnum hook put in the legacy set, then mirror
  -- the list back over it.  An id in the set but not the list takes the first
  -- free slot; the mirror is rebuilt from scratch so a delete propagates.
  local legacy = save.phoneContacts
  if type(legacy) == "table" then
    for key in pairs(legacy) do
      local id = tonumber(key)
      if id and id > 0 and not inList(state, id) then
        for slot = 1, Phone.CONTACT_LIST_SIZE do
          if state.list[slot] == 0 then
            state.list[slot] = id
            break
          end
        end
      end
    end
  end
  Phone.mirror(save, state)
  return state
end

-- Rebuild save.phoneContacts from wPhoneList.  Separate from Phone.state
-- because state ADOPTS the mirror first: anything that has just taken an id
-- out of the list has to mirror without adopting, or the id it removed walks
-- straight back into the first free slot.
function Phone.mirror(save, state)
  state = state or (save and save.phone) or {}
  local legacy = {}
  for slot = 1, Phone.CONTACT_LIST_SIZE do
    local id = state.list and state.list[slot]
    if id and id ~= 0 then legacy[id] = true end
  end
  save.phoneContacts = legacy
  return legacy
end

-- ------------------------------------------------------- the contact list
--
-- engine/phone/phone.asm _CheckCellNum.  Transcribed literally, including its
-- one oddity: it compares against ten slots with no "is this a real contact"
-- test, so `Phone.hasContact(save, 0)` reports true whenever a slot is empty.
-- AddPhoneNumber leans on exactly that to refuse adding contact 0.
function Phone.hasContact(save, id)
  local state = Phone.state(save)
  return inList(state, id) ~= nil
end

-- GetRemainingSpaceInPhoneList.  wRegisteredPhoneNumbers is named backwards:
-- it counts the permanent numbers you have NOT registered yet, and each one
-- costs a slot that stays reserved for it.  `id` is the number being added,
-- which is skipped (`cp c / jr z, .continue`) so a permanent number never
-- reserves a slot against itself.
function Phone.remainingSlots(save, id)
  local state = Phone.state(save)
  local reserved = 0
  for _, permanent in ipairs(Phone.PERMANENT_NUMBERS) do
    if permanent ~= id and not inList(state, permanent) then
      reserved = reserved + 1
    end
  end
  return Phone.CONTACT_LIST_SIZE - reserved
end

-- Phone_FindOpenSlot: the first empty slot inside the unreserved run.
function Phone.openSlot(save, id)
  local state = Phone.state(save)
  local usable = Phone.remainingSlots(save, id)
  for slot = 1, usable do
    if state.list[slot] == 0 then return slot end
  end
  return nil
end

-- AddPhoneNumber.  Returns true, or false plus "already" / "full" -- the cart
-- sets carry for both and Script_askforphonenumber reports either as
-- PHONE_CONTACTS_FULL, so the reason is for the port's own callers.
function Phone.addContact(save, id)
  id = tonumber(id)
  if not id or not Phone.CONTACTS[id] then return false, "unknown" end
  local state = Phone.state(save)
  if inList(state, id) then return false, "already" end
  local slot = Phone.openSlot(save, id)
  if not slot then return false, "full" end
  state.list[slot] = id
  save.phoneContacts = save.phoneContacts or {}
  save.phoneContacts[id] = true
  return true
end

-- DelCellNum: blank the slot in place, leaving the hole where it was.
function Phone.removeContact(save, id)
  local state = Phone.state(save)
  local slot = inList(state, id)
  if not slot then return false end
  state.list[slot] = 0
  Phone.mirror(save, state)
  return true
end

-- PokegearPhone_DeletePhoneNumber: the Pokegear's own delete, which blanks the
-- slot and THEN compacts the list so the display has no gap in it.  Every pass
-- of its loop pulls the next entry back one slot, which is why it runs
-- CONTACT_LIST_SIZE times rather than once.
function Phone.deleteContactAt(save, slot)
  local state = Phone.state(save)
  if not (slot and state.list[slot]) then return false end
  state.list[slot] = 0
  for _ = 1, Phone.CONTACT_LIST_SIZE do
    for index = 1, Phone.CONTACT_LIST_SIZE - 1 do
      if state.list[index] == 0 then
        state.list[index] = state.list[index + 1]
        state.list[index + 1] = 0
      end
    end
  end
  Phone.mirror(save, state)
  return true
end

-- CheckCanDeletePhoneNumber: MOM and PROF.ELM cannot be deleted, and neither
-- can an empty slot; every trainer can.  (`ld a, c / and a / ret nz` -- a row
-- with a trainer class is deletable outright.)
function Phone.canDelete(id)
  local contact = Phone.CONTACTS[id or -1]
  if not contact then return false end
  if contact.class then return true end
  if contact.number == Phone.PHONECONTACT_MOM then return false end
  if contact.number == Phone.PHONECONTACT_ELM then return false end
  return contact.number ~= 0
end

-- wPhoneList as an array of slot values, 0 for empty.  The Pokegear draws all
-- ten slots including the empty ones (they render as "----------"), so this
-- keeps them rather than compacting.
local function sameList(_, list) return list end

function Phone.contacts(save)
  local state = Phone.state(save)
  local out = {}
  for slot = 1, Phone.CONTACT_LIST_SIZE do out[slot] = state.list[slot] end
  if not Runtime.wantsHook("phone.contact_list") then return out end
  -- phone.contact_list, a Gen 2 invention: Red has no phone, so there is no
  -- Gen 1 name to share.  Shaped like the other list hooks (ui.pc.items,
  -- ui.start_menu.items) -- (save, list), returning the list to draw -- rather
  -- than a ctx table, because that is what a mod that reorders or hides rows
  -- already knows how to write.
  --
  -- The list is wPhoneList itself: exactly CONTACT_LIST_SIZE slots, each a
  -- PHONE_* contact id or 0 for an empty one, and the empty slots are part of
  -- the display.  A chain that returns something that is not a table, or one
  -- of the wrong length, is ignored: the Pokegear indexes this by slot and a
  -- short list would put the cursor on nil.  Ids the CONTACTS table does not
  -- know are blanked rather than dropped, so the slot count survives.
  local hooked = Runtime.call("phone.contact_list", sameList, save, out)
  if type(hooked) ~= "table" or #hooked ~= Phone.CONTACT_LIST_SIZE then
    return out
  end
  for slot = 1, Phone.CONTACT_LIST_SIZE do
    local id = tonumber(hooked[slot]) or 0
    hooked[slot] = Phone.CONTACTS[id] and id or 0
  end
  return hooked
end

-- Script_askforphonenumber (engine/overworld/scripting.asm).  `accepted` is
-- the YesNoBox result; the script writes one of the three PHONE_CONTACT_*
-- values into wScriptVar and its ifequal chain branches on it.
function Phone.askForNumber(save, id, accepted)
  if not accepted then return Phone.CONTACT_REFUSED end
  if Phone.addContact(save, id) then return Phone.CONTACT_GOT end
  return Phone.CONTACTS_FULL
end

-- ------------------------------------------------------- names

-- GetCallerName.  A trainer contact prints "<name>:" over its class name; a
-- non-trainer prints its NonTrainerCallerNames string and nothing under it.
-- `trainerData` is data/generated/trainers.lua; without it a trainer contact
-- still returns its member id, which is better than a bare number.
function Phone.contactName(id, trainerData)
  local contact = Phone.CONTACTS[id or -1]
  if not contact then return Phone.NON_TRAINER_NAMES[0], nil end
  -- `name` is presentation only.  Keeping class/member untouched preserves
  -- trainer lookup, rematches and script identity while allowing both the
  -- non-trainer names and an individual trainer contact to be localized by
  -- the phone_contacts registry.
  if contact.name then
    local className
    if contact.class then
      local class = trainerData and trainerData.classes
        and trainerData.classes[contact.class]
      className = (class and class.name) or contact.class
    end
    return contact.name, className
  end
  if not contact.class then
    return Phone.NON_TRAINER_NAMES[contact.number or 0]
      or Phone.NON_TRAINER_NAMES[0], nil
  end
  local class = trainerData and trainerData.classes
    and trainerData.classes[contact.class]
  if class and class.trainers then
    for _, row in ipairs(class.trainers) do
      if row.id == contact.member then
        return row.name, class.name or contact.class
      end
    end
  end
  return contact.member, contact.class
end

-- ------------------------------------------------------- context helpers

local function rngOf(ctx)
  local rng = ctx and ctx.rng
  if rng then return rng end
  return function() return math.random(0, 255) end
end

local function clockOf(ctx)
  local clock = ctx and ctx.clock
  if type(clock) == "table" then
    return {
      day = tonumber(clock.day) or 0,
      hour = tonumber(clock.hour) or 0,
      minute = tonumber(clock.minute or clock.min) or 0,
    }
  end
  return {
    day = (tonumber(os.date("%j")) or 1) % MAX_DAY,
    hour = tonumber(os.date("%H")) or 0,
    minute = tonumber(os.date("%M")) or 0,
  }
end

-- CheckTime: wTimeOfDay -> the MORN / DAY / NITE bit.  DARKNESS is absent from
-- .TimeOfDayTable's live rows, so it comes back as 0.
local TIME_BITS = {
  MORN = Phone.MORN, DAY = Phone.DAY, NITE = Phone.NITE,
  MORN_F = Phone.MORN, DAY_F = Phone.DAY, NITE_F = Phone.NITE,
  DARK = 0, DARKNESS = 0,
}

function Phone.timeOfDay(ctx)
  local given = ctx and (ctx.timeOfDay or ctx.daytime)
  if type(given) == "number" then return given end
  if type(given) == "string" then return TIME_BITS[given] or 0 end
  local hour = clockOf(ctx).hour
  if hour < MORN_HOUR then return Phone.NITE end
  if hour < DAY_HOUR then return Phone.MORN end
  if hour < NITE_HOUR then return Phone.DAY end
  return Phone.NITE
end

-- Lua 5.1 has no bit ops in the base library and this module stays
-- dependency-free, so AND the three time bits by hand.
local function timeMatches(mask, checked)
  mask = mask or 0
  checked = checked or 0
  for _, bit in ipairs({ Phone.MORN, Phone.DAY, Phone.NITE }) do
    if math.floor(mask / bit) % 2 == 1 and math.floor(checked / bit) % 2 == 1 then
      return true
    end
  end
  return false
end

Phone.timeMatches = timeMatches

-- GetMapPhoneService returns the map header's phone-service nybble and every
-- caller tests `and a` -- ZERO means the map HAS service.  maps.lua already
-- decodes that nybble into a boolean, so a map record can be handed in whole.
local function mapRecord(ctx)
  local map = ctx and ctx.map
  if type(map) == "table" then return map end
  return nil
end

function Phone.mapHasService(ctx)
  local record = mapRecord(ctx)
  if record ~= nil and record.phoneService ~= nil then
    return record.phoneService and true or false
  end
  if ctx and ctx.phoneService ~= nil then
    return ctx.phoneService and true or false
  end
  -- No header to read: assume service, the way most of Johto has it.
  return true
end

local function currentMapId(ctx)
  local record = mapRecord(ctx)
  if record then return record.id end
  local map = ctx and ctx.map
  if type(map) == "string" then return map end
  return ctx and ctx.mapId or nil
end

-- The wMapGroup / wMapNumber compare from GetAvailableCallers and
-- MakePhoneCallFromPokegear: a contact standing on your own map is skipped.
function Phone.onSameMap(contact, ctx)
  if not (contact and contact.map) then return false end
  local here = currentMapId(ctx)
  if here then return here == contact.map end
  local record = mapRecord(ctx)
  local maps = ctx and ctx.maps
  local theirs = maps and maps[contact.map]
  if record and theirs then
    return record.group == theirs.group and record.map == theirs.map
  end
  return false
end

-- SpecialCallOnlyWhenOutside: TOWN and ROUTE, nothing else.
function Phone.isOutside(ctx)
  local record = mapRecord(ctx)
  local environment = (record and record.environment)
    or (ctx and ctx.environment)
  return OUTSIDE_ENVIRONMENTS[environment] == true
end

-- ------------------------------------------------------- the receive timer
--
-- engine/overworld/time.asm.  The delay is a countdown in in-game minutes with
-- a rebasing start stamp: every check works out how many minutes have passed
-- since the stamp, writes the current time back over the stamp, and subtracts
-- the difference from what is left.

-- .ReceiveCallDelays, indexed by wTimeCyclesSinceLastCall (0..3, capped).  The
-- gap between calls shrinks the longer you go without one: twenty minutes for
-- the first, then ten, five and three.
Phone.RECEIVE_CALL_DELAYS = { 20, 10, 5, 3 }

-- CalcMinsHoursDaysSince, borrow chain and all.  Returns minutes, hours, days.
local function since(now, start)
  local borrow = 0
  local minutes = now.minute - start.minute - borrow
  if minutes < 0 then minutes = minutes + 60 borrow = 1 else borrow = 0 end
  local hours = now.hour - start.hour - borrow
  if hours < 0 then hours = hours + MAX_HOUR borrow = 1 else borrow = 0 end
  local days = now.day - start.day - borrow
  if days < 0 then days = days + MAX_DAY end
  return minutes, hours, days
end

-- RestartReceiveCallDelay: park the countdown and stamp "now".
function Phone.restartReceiveDelay(save, minutes, ctx)
  local state = Phone.state(save)
  state.delayMins = minutes
  state.delayStart = clockOf(ctx)
  return state
end

-- NextCallReceiveDelay.
function Phone.nextReceiveDelay(save, ctx)
  local state = Phone.state(save)
  local cycles = state.timeCycles or 0
  if cycles > 3 then cycles = 3 end
  return Phone.restartReceiveDelay(save,
    Phone.RECEIVE_CALL_DELAYS[cycles + 1], ctx)
end

-- InitCallReceiveDelay.  StartMap runs this on every map load, and so does the
-- tail of Script_ReceivePhoneCall after a call is hung up.
function Phone.initReceiveDelay(save, ctx)
  local state = Phone.state(save)
  state.timeCycles = 0
  return Phone.nextReceiveDelay(save, ctx)
end

-- StartMap's `farcall InitCallReceiveDelay`, under the name the World will
-- want to call it by.
function Phone.onMapLoad(save, ctx)
  return Phone.initReceiveDelay(save, ctx)
end

-- CheckReceiveCallDelay -> UpdateTimeRemaining.  True means the countdown has
-- reached zero.  Anything longer than an hour (or a rolled-over day) comes
-- back from GetMinutesSinceIfLessThan60 as -1, which UpdateTimeRemaining
-- treats as "expired" outright rather than trying to subtract it.
function Phone.checkReceiveCallDelay(save, ctx)
  local state = Phone.state(save)
  local now = clockOf(ctx)
  if not state.delayStart then
    state.delayStart = now
    return false
  end
  local minutes, hours, days = since(now, state.delayStart)
  -- The routine writes the current value back into each byte as it walks the
  -- stamp, so the next check measures from here.
  state.delayStart = now
  local elapsed = minutes
  if days ~= 0 or hours ~= 0 then elapsed = -1 end
  if elapsed == -1 then
    state.delayMins = 0
    return true
  end
  local left = (state.delayMins or 0) - elapsed
  if left < 0 then left = 0 end
  state.delayMins = left
  return left == 0
end

-- CheckReceiveCallTimer: consume the expiry, wind the cycle counter on (capped
-- at 3) and restart the countdown at the next, shorter delay.
function Phone.checkReceiveCallTimer(save, ctx)
  if not Phone.checkReceiveCallDelay(save, ctx) then return false end
  local state = Phone.state(save)
  if (state.timeCycles or 0) < 3 then
    state.timeCycles = (state.timeCycles or 0) + 1
  end
  Phone.nextReceiveDelay(save, ctx)
  return true
end

-- ------------------------------------------------------- call descriptors

-- LoadCallerScript.  Contact 0 is not a contact: the routine swaps in the
-- WrongNumber record, whose script is one writetext and an end.
local function descriptor(id, direction, scriptField)
  id = tonumber(id) or 0
  local contact = Phone.CONTACTS[id]
  if id == 0 or not contact then
    return {
      kind = "call", contact = 0, direction = direction,
      script = "WrongNumberScript",
      scriptKey = Phone.SCRIPT_KEYS.WrongNumberScript,
      wrongNumber = true,
    }
  end
  local label = contact[scriptField]
  return {
    kind = "call",
    contact = id,
    direction = direction,
    class = contact.class,
    member = contact.member,
    number = contact.number,
    map = contact.map,
    script = label,
    -- The extracted key wins over the label lookup: Phone.useExtracted put the
    -- cart's own pointer here, and the SCRIPT_KEYS table behind
    -- Phone.scriptKey is a transcription of the symbol file.
    scriptKey = contact[scriptField .. "Key"] or Phone.scriptKey(label),
  }
end

Phone.loadCallerScript = descriptor

-- ------------------------------------------------------- outgoing
--
-- MakePhoneCallFromPokegear.  `kind` says which of the three things the cart
-- does happened:
--   "call"      ring the contact and run their callee script
--   "justtalk"  PhoneScript_JustTalkToThem -- they are on this very map
--   "outofarea" PhoneOutOfAreaScript -- link mode, no signal, or wrong hour
--
-- Note what is NOT checked: whether the contact is in your phone book at all.
-- The Pokegear only ever offers listed contacts, so the cart never asks.
function Phone.call(save, id, ctx)
  ctx = ctx or {}
  local outOfArea = {
    kind = "outofarea",
    contact = tonumber(id) or 0,
    direction = "outgoing",
    script = "PhoneOutOfAreaScript",
    scriptKey = Phone.SCRIPT_KEYS.PhoneOutOfAreaScript,
  }
  if ctx.linkMode then return outOfArea end
  if not Phone.mapHasService(ctx) then return outOfArea end
  local contact = Phone.CONTACTS[tonumber(id) or -1]
  if not contact then return outOfArea end
  -- CheckPhoneContactTimeOfDay masks the row's SCRIPT1_TIME with ANYTIME and
  -- then with the current time bit.
  if not timeMatches(contact.calleeTime, Phone.timeOfDay(ctx)) then
    return outOfArea
  end
  if Phone.onSameMap(contact, ctx) then
    return {
      kind = "justtalk",
      contact = tonumber(id),
      direction = "outgoing",
      script = "PhoneScript_JustTalkToThem",
      scriptKey = Phone.SCRIPT_KEYS.PhoneScript_JustTalkToThem,
    }
  end
  return descriptor(id, "outgoing", "callee")
end

-- ------------------------------------------------------- incoming

-- GetAvailableCallers.  Walks all ten slots of wPhoneList and keeps the
-- contacts whose SCRIPT2_TIME covers the current time of day and who are not
-- standing on the map you are standing on.
function Phone.availableCallers(save, ctx)
  local state = Phone.state(save)
  local checked = Phone.timeOfDay(ctx)
  local out = {}
  for slot = 1, Phone.CONTACT_LIST_SIZE do
    local id = state.list[slot]
    if id ~= 0 then
      local contact = Phone.CONTACTS[id]
      if contact and timeMatches(contact.callerTime, checked)
          and not Phone.onSameMap(contact, ctx) then
        out[#out + 1] = id
      end
    end
  end
  return out
end

-- ChooseRandomCaller.  One Random call, whose byte is nibble-swapped and
-- masked to 0..31, then reduced modulo the number of available callers by
-- SimpleDivide (which returns the remainder in a).  The swap-and-mask is why a
-- book with more than a few contacts still samples evenly enough.
function Phone.chooseRandomCaller(callers, rng)
  if not callers or #callers == 0 then return nil end
  rng = rng or rngOf(nil)
  local roll = rng() % 256
  local swapped = (roll % 16) * 16 + math.floor(roll / 16)
  local index = (swapped % 32) % #callers
  return callers[index + 1]
end

-- CheckPhoneCall, the whole gate, in the cart's order.  The order matters: the
-- timer check has side effects (it restarts the countdown and winds the cycle
-- counter), so it must run before the coin flip and not after it.
--
--   1. CheckStandingOnEntrance -- a door, staircase or cave tile never rings
--   2. CheckReceiveCallTimer   -- the countdown has to have run out
--   3. a 50% coin flip
--   4. GetMapPhoneService      -- the map has to have a signal
--   5. someone has to be available at this hour and off this map
function Phone.tryRandomCall(save, ctx)
  ctx = ctx or {}
  if ctx.standingOnEntrance then return nil end
  if not Phone.checkReceiveCallTimer(save, ctx) then return nil end
  local rng = rngOf(ctx)
  -- `call Random / ld b, a / and %01111111 / cp b / jr nz`: equal only when
  -- the top bit was already clear, so this passes half the time.
  if (rng() % 256) >= 0x80 then return nil end
  if not Phone.mapHasService(ctx) then return nil end
  local who = Phone.chooseRandomCaller(Phone.availableCallers(save, ctx), rng)
  if not who then return nil end
  return descriptor(who, "incoming", "caller")
end

-- The cart's own name for it, for a reader coming from phone.asm.
Phone.checkPhoneCall = Phone.tryRandomCall

-- ------------------------------------------------------- special calls

-- Script_specialphonecall: the id goes into wSpecialPhoneCallID and sits there
-- until a called script clears it.  `SPECIALCALL_NONE` (0) is the clear.
function Phone.queueSpecialCall(save, id)
  local state = Phone.state(save)
  state.specialCall = tonumber(id) or 0
  return state.specialCall
end

function Phone.clearSpecialCall(save)
  return Phone.queueSpecialCall(save, Phone.SPECIALCALL_NONE)
end

-- Script_checkphonecall: false when nothing is queued.
function Phone.hasSpecialCall(save)
  return Phone.state(save).specialCall ~= 0
end

-- readvar VAR_SPECIALPHONECALL, which is how every special caller script works
-- out which of its branches to take (ElmPhoneCallerScript's ifequal chain).
function Phone.specialCallVar(save)
  return Phone.state(save).specialCall or 0
end

-- CheckSpecialPhoneCall, run from CountStep before the step is counted.  The
-- queued row's script REPLACES the contact's own SCRIPT2 for this call, which
-- is how one Elm contact serves five different scripted calls.
--
-- `delay` is the `pause 30` its little wrapper script runs before
-- Script_ReceivePhoneCall; a random call has no such pause.
function Phone.checkSpecialCall(save, ctx)
  local state = Phone.state(save)
  local queued = state.specialCall or 0
  if queued == 0 then return nil end
  local entry = Phone.SPECIAL_CALLS[queued]
  if not entry then return nil end
  if entry.condition == "outside" and not Phone.isOutside(ctx) then
    return nil
  end
  local call = descriptor(entry.contact, "incoming", "caller")
  call.special = queued
  call.specialName = entry.name
  call.script = entry.script
  call.scriptKey = entry.scriptKey or Phone.scriptKey(entry.script)
  call.delay = 30
  return call
end

-- ------------------------------------------------------- rematches

function Phone.rematchEvent(id)
  return Phone.REMATCH_EVENTS[id or -1]
end

-- The caller script's own `setevent EVENT_<NAME>_READY_FOR_REMATCH`.  With
-- bank $41 extracted the VM runs that setevent itself and nothing in the
-- engine calls this; it stays as the one named seam for a test or a cache
-- without the scripts to land the same flag.
function Phone.setRematchReady(events, id, value)
  local flag = Phone.rematchEvent(id)
  if not (flag and events) then return false end
  events:set(flag, value ~= false)
  return true
end

function Phone.isReadyForRematch(events, id)
  local flag = Phone.rematchEvent(id)
  if not (flag and events) then return false end
  return events:get(flag) and true or false
end

-- ------------------------------------------------------- ending a call

-- Script_ReceivePhoneCall's tail: HangUp, closetext, InitCallReceiveDelay.
--
-- The special-call queue is cleared by the CALLED SCRIPT on the cart
-- (`specialphonecall SPECIALCALL_NONE`, the line right after the writetext in
-- every one of them), not by the engine, and with bank $41 extracted that
-- line runs through the VM's own specialphonecall arm.  The fallback here
-- covers a cache built before the extractor reached that bank: a caller that
-- reports no script ran (`ranScript` unset) has its queue cleared so the
-- call cannot ring forever.
function Phone.endCall(save, call, ctx)
  if call and call.special and call.special ~= 0 and not call.ranScript then
    Phone.clearSpecialCall(save)
  end
  Phone.initReceiveDelay(save, ctx)
  return true
end

return Phone
