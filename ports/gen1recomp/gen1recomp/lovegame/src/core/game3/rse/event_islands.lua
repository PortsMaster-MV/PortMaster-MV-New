local Rse = require("src.core.game3.rse.init")

local EventIslands = {}

EventIslands.MANIFEST = "data/generated/gba/rse/event_islands/manifest.lua"

-- pokeemerald/src/field_specials.c:3261
EventIslands.ROCK_LEVELS = 11
-- pokeemerald/include/constants/field_specials.h:84
EventIslands.ROCK = { FAILED = 0, PROGRESSED = 1, SOLVED = 2, COMPLETE = 3 }
-- pokeemerald/data/maps/BirthIsland_Exterior/map.json:18
EventIslands.LOCALID_ROCK = 1
EventIslands.BIRTH_ISLAND = "EM_BIRTH_ISLAND_EXTERIOR"
-- pokeemerald/src/field_specials.c:3360
EventIslands.RESET_FRAMES, EventIslands.MOVE_FRAMES = 60, 5
EventIslands.VAR_RESULT = 0x800D
-- pokeemerald/src/option_menu.c:79
EventIslands.OPTION_KEY = "eventTickets"

-- pokeemerald/data/scripts/gift_aurora_ticket.inc:5
EventIslands.GIFT_FLAGS = {
  aurora = "FLAG_RECEIVED_AURORA_TICKET",
  mystic = "FLAG_RECEIVED_MYSTIC_TICKET",
  oldSeaMap = "FLAG_RECEIVED_OLD_SEA_MAP",
}

local cache = {}

function EventIslands.manifest()
  local GameVersion = require("src.core.GameVersion")
  local key = tostring(GameVersion.get())
  local hit = cache[key]
  if hit then return hit end
  local src = require("src.core.game3.dataset").cache():read(EventIslands.MANIFEST)
  if type(src) ~= "string" then error("event_islands: " .. EventIslands.MANIFEST .. " missing from the cache", 0) end
  local chunk = assert((loadstring or load)(src, "@" .. EventIslands.MANIFEST))
  if setfenv then setfenv(chunk, {}) end
  hit = chunk()
  cache[key] = hit
  return hit
end

local function C(sess)
  local Constants = require("src.core.game3.constants")
  return Constants.of(Constants.versionOf(sess or Rse.session()))
end

local function optionsBlock(sess)
  local Options = require("src.core.game3.options")
  return Options.ensure(sess)
end

function EventIslands.enabled(sess)
  sess = sess or Rse.session()
  if not (sess and Rse.isRse(sess)) then return false end
  local o = optionsBlock(sess)
  return (tonumber(o[EventIslands.OPTION_KEY]) or 0) ~= 0
end

function EventIslands.setEnabled(sess, on)
  sess = sess or Rse.session()
  local o = optionsBlock(sess)
  o[EventIslands.OPTION_KEY] = on and 1 or 0
  EventIslands.sync(sess)
  return on
end

local function hasItem(sess, name)
  local Bag = require("src.core.game3.bag")
  return Bag.has(sess.bag, C(sess):require("items", name), 1)
end

function EventIslands.eonPending(sess)
  return not hasItem(sess, "ITEM_EON_TICKET") and not Rse.flag("FLAG_ENABLE_SHIP_SOUTHERN_ISLAND", sess)
end

-- pokeemerald/src/mystery_gift.c:156
function EventIslands.pendingGift(sess)
  sess = sess or Rse.session()
  if not EventIslands.enabled(sess) then return nil end
  for _, g in ipairs(EventIslands.manifest().gifts) do
    local flag = EventIslands.GIFT_FLAGS[g.id]
    if flag and not Rse.flag(flag, sess) then return g end
  end
  return nil
end

-- pokeemerald/src/field_specials.c:3630
function EventIslands.sync(sess)
  sess = sess or Rse.session()
  if not (sess and Rse.isRse(sess) and Rse.store()) then return false end
  if not EventIslands.enabled(sess) then return false end
  local pending = EventIslands.eonPending(sess) or EventIslands.pendingGift(sess) ~= nil
  Rse.setVar("VAR_DISTRIBUTE_EON_TICKET", pending and 1 or 0, sess)
  return pending
end

function EventIslands.optionRow()
  local Strings = require("src.core.Strings")
  return {
    id = EventIslands.OPTION_KEY, label = Strings("EVENT TICKETS"),
    value = function(c)
      local o = require("src.core.game3.options").block(c.options)
      return Strings((tonumber(o[EventIslands.OPTION_KEY]) or 0) ~= 0 and "ON" or "OFF")
    end,
    step = function(c)
      local o = require("src.core.game3.options").block(c.options)
      o[EventIslands.OPTION_KEY] = (tonumber(o[EventIslands.OPTION_KEY]) or 0) ~= 0 and 0 or 1
      pcall(EventIslands.sync, c.session)
      return true
    end,
  }
end

local function injectGift(g)
  local Space = package.loaded["src.core.game3.scripting.space"] or require("src.core.game3.scripting.space")
  local bundle = Space.bundle or (Space.ensureBundle and Space.ensureBundle(nil))
  if not bundle then return nil end
  local man = EventIslands.manifest()
  for key, rows in pairs(man.giftScripts) do
    if not bundle.scripts[key] then bundle.scripts[key] = rows end
  end
  for key, ir in pairs(man.giftTexts) do
    if not bundle.text[key] then bundle.text[key] = ir end
  end
  local vm = Space.vm
  if vm then
    if vm.scripts and not vm.scripts[g.script] then vm.scripts[g.script] = man.giftScripts[g.script] end
    if vm.text then
      for key, ir in pairs(man.giftTexts) do
        if not vm.text[key] then vm.text[key] = ir end
      end
    end
  end
  return g.script
end
EventIslands.injectGift = injectGift

-- pokeemerald/src/script.c:441 GetSavedRamScriptIfValid
function EventIslands.cardGift(sess)
  sess = sess or Rse.session()
  if not (sess and Rse.isRse(sess)) then return nil end
  local MysteryGift = require("src.core.game3.mystery_gift")
  if not MysteryGift.validateSavedCard(sess) then return nil end
  local id = MysteryGift.ramScriptId(sess)
  if not id then return nil end
  local ok, man = pcall(EventIslands.manifest)
  if not ok then return nil end
  for _, g in ipairs(man.gifts or {}) do
    if g.id == id then return g end
  end
  return nil
end

-- pokeemerald/src/scrcmd.c:2228
function EventIslands.tryWonderCardScript(vm)
  local g = EventIslands.pendingGift() or EventIslands.cardGift()
  if not g then return nil end
  local key = injectGift(g)
  if not key then return nil end
  EventIslands.lastGift = g.id
  local ctx, cur = vm.ctx, vm.ctx and vm.ctx.pc
  if cur and ctx.stack then ctx.stack[#ctx.stack + 1] = { listKey = cur.listKey, index = cur.index } end
  vm:setPc(key, 1)
  return false
end

function EventIslands.installWonderCardHook()
  if EventIslands._wcHooked then return true end
  local okO, OpsRse = pcall(require, "src.core.game3.scripting.ops_rse")
  if not (okO and OpsRse and OpsRse.HANDLERS) then return false end
  local H = OpsRse.HANDLERS
  local prev = H.trywondercardscript
  H.trywondercardscript = function(vm, row, B)
    local r = EventIslands.tryWonderCardScript(vm)
    if r ~= nil then return r end
    if prev then return prev(vm, row, B) end
    return B.base(vm, row)
  end
  EventIslands._wcHooked = true
  return true
end

local function rgb8(c)
  c = (tonumber(c) or 0) % 32768
  return { math.floor((c % 32) * 255 / 31 + 0.5), math.floor((math.floor(c / 32) % 32) * 255 / 31 + 0.5),
    math.floor((math.floor(c / 1024) % 32) * 255 / 31 + 0.5) }
end

local function rockColours(level)
  local pals = EventIslands.manifest().deoxysRockPalettes
  local p = pals[(level or 0) + 1] or pals[1]
  local out = {}
  for i = 2, 16 do out[#out + 1] = rgb8(p[i]) end
  return out
end
EventIslands.rockColours = rockColours

local function rockObject()
  local Objects = package.loaded["src.core.game3.objects"]
  return Objects and Objects.find and Objects.find(EventIslands.LOCALID_ROCK)
end

-- pokeemerald/src/field_specials.c:3389
function EventIslands.setRockPalette(sess, level)
  sess = sess or Rse.session()
  level = level or (Rse.var("VAR_DEOXYS_ROCK_LEVEL", sess) % 256)
  local eo = rockObject()
  local gfx = eo and tonumber(eo.graphicsId) or C(sess):require("event_objects", "OBJ_EVENT_GFX_DEOXYS_TRIANGLE")
  local ok, OwSprites = pcall(require, "src.core.game3.ow_sprites")
  if not (ok and OwSprites and OwSprites.setObjectPalette) then return false end
  EventIslands.rockLevelShown = level
  if level == 0 and OwSprites.clearObjectPalette then
    OwSprites.clearObjectPalette(gfx)
    return true
  end
  return OwSprites.setObjectPalette(gfx, "em_deoxys_rock_" .. level, rockColours(level), rockColours(0))
end

local function playSe(name)
  local okA, Audio = pcall(require, "src.core.game3.audio")
  if not (okA and Audio and Audio.playSe) then return end
  local okS, id = pcall(function() return C():song(name) end)
  pcall(Audio.playSe, okS and id or name)
end

-- pokeemerald/src/field_specials.c:3339
function EventIslands.changeRockLevel(sess, level)
  local man = EventIslands.manifest()
  EventIslands.setRockPalette(sess, level)
  playSe(level == 0 and "SE_M_CONFUSE_RAY" or "SE_RG_DEOXYS_MOVE")
  local xy = man.deoxysRockCoords[level + 1]
  local frames = level == 0 and EventIslands.RESET_FRAMES or EventIslands.MOVE_FRAMES
  local okF, FieldEffects = pcall(require, "src.core.game3.field_effects")
  local anim
  if okF and FieldEffects and FieldEffects.startMoveDeoxysRock then
    anim = FieldEffects.startMoveDeoxysRock(EventIslands.LOCALID_ROCK, xy[1], xy[2], frames)
  end
  local Objects = package.loaded["src.core.game3.objects"]
  if Objects and Objects.rememberPerm and Objects._mapId then
    Objects.rememberPerm(Objects._mapId, EventIslands.LOCALID_ROCK, { x = xy[1], y = xy[2] })
  end
  return anim
end

-- pokeemerald/src/field_specials.c:3297
function EventIslands.rockInteraction(sess)
  local man = EventIslands.manifest()
  if Rse.flag("FLAG_DEOXYS_ROCK_COMPLETE", sess) then return EventIslands.ROCK.COMPLETE, nil end
  local level = Rse.var("VAR_DEOXYS_ROCK_LEVEL", sess)
  local steps = Rse.var("VAR_DEOXYS_ROCK_STEP_COUNT", sess)
  Rse.setVar("VAR_DEOXYS_ROCK_STEP_COUNT", 0, sess)
  if level ~= 0 and (man.deoxysRockMaxSteps[level] or 0) < steps then
    local anim = EventIslands.changeRockLevel(sess, 0)
    Rse.setVar("VAR_DEOXYS_ROCK_LEVEL", 0, sess)
    return EventIslands.ROCK.FAILED, anim
  elseif level == EventIslands.ROCK_LEVELS - 1 then
    Rse.setFlag("FLAG_DEOXYS_ROCK_COMPLETE", true, sess)
    return EventIslands.ROCK.SOLVED, nil
  end
  level = level + 1
  local anim = EventIslands.changeRockLevel(sess, level)
  Rse.setVar("VAR_DEOXYS_ROCK_LEVEL", level, sess)
  return EventIslands.ROCK.PROGRESSED, anim
end

-- pokeemerald/src/field_specials.c:3377
function EventIslands.incrementStepCount(sess)
  sess = sess or Rse.session()
  if not (sess and sess.map == EventIslands.BIRTH_ISLAND) then return false end
  local n = Rse.var("VAR_DEOXYS_ROCK_STEP_COUNT", sess) + 1
  if n > 99 then n = 0 end
  Rse.setVar("VAR_DEOXYS_ROCK_STEP_COUNT", n, sess)
  return true
end

local okT, TimeEvents = pcall(require, "src.core.game3.time_events")
if okT and TimeEvents and TimeEvents.onMinute then
  TimeEvents.onMinute("EventTicketsSync", function(session)
    if Rse.isRse(session) then pcall(EventIslands.sync, session) end
  end)
end

EventIslands.installWonderCardHook()

Rse.register("eventIslands", EventIslands)

return EventIslands
