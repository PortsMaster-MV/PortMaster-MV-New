local Pokeblock = {}

-- pokeemerald/include/constants/global.h:45
Pokeblock.COUNT = 40
-- pokeemerald/src/pokeblock.c:46
Pokeblock.MAX_FEEL = 99
-- pokeemerald/include/constants/berry.h:18
Pokeblock.FLAVOR_COUNT = 5
-- pokeemerald/include/constants/pokemon.h:197
Pokeblock.MAX_SHEEN = 255
Pokeblock.MAX_CONDITION = 255
-- pokeemerald/include/menu_specialized.h:43
Pokeblock.MAX_CONDITION_SPARKLES = 10
-- pokeemerald/src/safari_zone.c:24
Pokeblock.NUM_FEEDERS = 10
-- pokeemerald/src/safari_zone.c:219
Pokeblock.FEEDER_STEPS = 100
-- pokeemerald/src/safari_zone.c:171
Pokeblock.FEEDER_RANGE = 5
-- pokeemerald/include/fieldmap.h:18
Pokeblock.MAP_OFFSET = 7

-- pokeemerald/include/pokeblock.h:6
Pokeblock.COLOR = {
  NONE = 0, RED = 1, BLUE = 2, PINK = 3, GREEN = 4, YELLOW = 5, PURPLE = 6, INDIGO = 7,
  BROWN = 8, LITE_BLUE = 9, OLIVE = 10, GRAY = 11, BLACK = 12, WHITE = 13, GOLD = 14,
}
Pokeblock.NUM_COLORS = 15

-- pokeemerald/include/global.h:596
Pokeblock.FIELDS = { "color", "spicy", "dry", "sweet", "bitter", "sour", "feel" }
-- pokeemerald/include/constants/berry.h:13
Pokeblock.FLAVORS = { "spicy", "dry", "sweet", "bitter", "sour" }

-- pokeemerald/include/pokeblock.h:36
Pokeblock.CASE = { FIELD = 0, BATTLE = 1, FEEDER = 2, GIVE = 3 }

-- pokeemerald/include/menu_specialized.h:58
Pokeblock.CONDITIONS = { "cool", "tough", "smart", "cute", "beauty" }
-- pokeemerald/src/use_pokeblock.c:190
Pokeblock.CONDITION_FLAVOR = { 0, 4, 3, 2, 1 }
-- pokeemerald/src/use_pokeblock.c:289
Pokeblock.CONDITION_NAMES = { "gText_Coolness", "gText_Toughness", "gText_Smartness", "gText_Cuteness", "gText_Beauty3" }

local function session_of(s)
  if s then return s end
  local rt = package.loaded["src.core.game3.runtime"]
  return rt and rt.getSession and rt.getSession() or nil
end
Pokeblock.session = session_of

local function num(v)
  return math.floor(tonumber(v) or 0)
end

function Pokeblock.empty()
  return { color = 0, spicy = 0, dry = 0, sweet = 0, bitter = 0, sour = 0, feel = 0 }
end

function Pokeblock.new(t)
  local b = Pokeblock.empty()
  if type(t) == "table" then
    for i, k in ipairs(Pokeblock.FIELDS) do
      local v = t[k]
      if v == nil then v = t[i] end
      b[k] = num(v) % 256
    end
  end
  return b
end

function Pokeblock.copy(b)
  return Pokeblock.new(b)
end

-- pokeemerald/src/pokeblock.c:1314
function Pokeblock.clearAll(session)
  session = session_of(session)
  if not session then return nil end
  local list = {}
  for i = 1, Pokeblock.COUNT do list[i] = Pokeblock.empty() end
  session.pokeblocks = list
  return list
end

function Pokeblock.slots(session)
  session = session_of(session)
  if not session then return nil end
  local list = session.pokeblocks
  if type(list) ~= "table" then return Pokeblock.clearAll(session) end
  for i = 1, Pokeblock.COUNT do
    if type(list[i]) ~= "table" then list[i] = Pokeblock.empty() end
  end
  return list
end

function Pokeblock.get(session, id)
  local list = Pokeblock.slots(session)
  return list and list[num(id) + 1] or nil
end

-- pokeemerald/src/pokeblock.c:1387
function Pokeblock.data(block, field)
  if type(block) ~= "table" then return 0 end
  local key = Pokeblock.FIELDS[num(field) + 1]
  if not key then return 0 end
  return num(block[key])
end

-- pokeemerald/src/pokeblock.c:1346
function Pokeblock.firstFreeSlot(session)
  local list = Pokeblock.slots(session)
  if not list then return -1 end
  for i = 0, Pokeblock.COUNT - 1 do
    if num(list[i + 1].color) == Pokeblock.COLOR.NONE then return i end
  end
  return -1
end

-- pokeemerald/src/pokeblock.c:1359
function Pokeblock.add(session, block)
  local slot = Pokeblock.firstFreeSlot(session)
  if slot == -1 then return false end
  Pokeblock.slots(session)[slot + 1] = Pokeblock.new(block)
  return true
end

-- pokeemerald/src/pokeblock.c:1374
function Pokeblock.tryClear(session, id)
  local list = Pokeblock.slots(session)
  local b = list and list[num(id) + 1]
  if not b or num(b.color) == Pokeblock.COLOR.NONE then return false end
  list[num(id) + 1] = Pokeblock.empty()
  return true
end

function Pokeblock.count(session)
  local list = Pokeblock.slots(session)
  local n = 0
  for i = 1, Pokeblock.COUNT do
    if list and num(list[i].color) ~= Pokeblock.COLOR.NONE then n = n + 1 end
  end
  return n
end

-- pokeemerald/src/pokeblock.c:818
function Pokeblock.compact(session)
  local list = Pokeblock.slots(session)
  if not list then return end
  for i = 0, Pokeblock.COUNT - 2 do
    for j = i + 1, Pokeblock.COUNT - 1 do
      if num(list[i + 1].color) == Pokeblock.COLOR.NONE then
        list[i + 1], list[j + 1] = list[j + 1], list[i + 1]
      end
    end
  end
end

-- pokeemerald/src/pokeblock.c:836
function Pokeblock.move(session, id1, id2)
  local list = Pokeblock.slots(session)
  if not list or id1 == id2 then return end
  local saved = list[id1 + 1]
  if id2 > id1 then
    id2 = id2 - 1
    for i = id1, id2 - 1 do list[i + 1] = list[i + 2] end
  else
    for i = id1, id2 + 1, -1 do list[i + 1] = list[i] end
  end
  list[id2 + 1] = saved
end

-- pokeemerald/src/pokeblock.c:1322
function Pokeblock.highestFlavorLevel(block)
  local best = Pokeblock.data(block, 1)
  for i = 1, Pokeblock.FLAVOR_COUNT - 1 do
    local cur = Pokeblock.data(block, 1 + i)
    if best < cur then best = cur end
  end
  return best
end

-- pokeemerald/src/pokeblock.c:1337
function Pokeblock.feel(block)
  local feel = Pokeblock.data(block, 6)
  if feel > Pokeblock.MAX_FEEL then feel = Pokeblock.MAX_FEEL end
  return feel
end

-- pokeemerald/src/pokeblock.c:1444
function Pokeblock.flavorOf(block)
  local best = 0
  for i = 0, Pokeblock.FLAVOR_COUNT - 1 do
    if Pokeblock.data(block, best + 1) < Pokeblock.data(block, i + 1) then best = i end
  end
  return best
end

function Pokeblock.flavors(block)
  local out = {}
  for i, k in ipairs(Pokeblock.FLAVORS) do out[i] = num(block and block[k]) end
  return out
end

local compatCache
function Pokeblock.compatTable(session)
  if compatCache then return compatCache end
  local BattleProfile = require("src.core.game3.battle.profile")
  local cfg = BattleProfile.get(session_of(session)).safari
  local Rules = require("src.core.game3.battle.rules")
  local t = Rules.safari.rseTables(cfg)
  compatCache = assert(t.flavorCompatibility, "safari tables have no flavorCompatibility")
  return compatCache
end

function Pokeblock.setCompatTable(t)
  compatCache = t
end

-- pokeemerald/src/pokemon.c:6590
function Pokeblock.flavorRelation(nature, flavor, compat)
  compat = compat or Pokeblock.compatTable()
  return num(compat[num(nature) * Pokeblock.FLAVOR_COUNT + num(flavor)])
end

-- pokeemerald/src/pokeblock.c:1407
function Pokeblock.gain(nature, block, compat)
  compat = compat or Pokeblock.compatTable()
  local total = 0
  for f = 0, Pokeblock.FLAVOR_COUNT - 1 do
    local cur = Pokeblock.data(block, f + 1)
    if cur > 0 then total = total + cur * num(compat[Pokeblock.FLAVOR_COUNT * num(nature) + f]) end
  end
  return total
end

local namesCache
function Pokeblock.names()
  if namesCache then return namesCache end
  local rel = "data/generated/gba/berries/berries.lua"
  local src = require("src.core.game3.dataset").cache():read(rel)
  assert(type(src) == "string", rel .. " is missing from the cache")
  local t = assert(load(src, "@" .. rel, "t", {}))()
  namesCache = assert(t.pokeblockNames, "berries pack has no pokeblockNames")
  return namesCache
end

function Pokeblock.setNames(t)
  namesCache = t
end

-- pokeemerald/src/pokeblock.c:197
function Pokeblock.colorName(color)
  return Pokeblock.names()[num(color)] or ""
end

-- pokeemerald/src/pokeblock.c:1422
function Pokeblock.name(block)
  return Pokeblock.colorName(Pokeblock.data(block, 0))
end

local manifestCache
function Pokeblock.manifest()
  if manifestCache then return manifestCache end
  local rel = "data/generated/gba/rse/pokeblock/manifest.lua"
  local src = require("src.core.game3.dataset").cache():read(rel)
  assert(type(src) == "string", rel .. " is missing from the cache")
  manifestCache = assert(load(src, "@" .. rel, "t", {}))()
  return manifestCache
end

local favorites
function Pokeblock.favoriteTable()
  if favorites then return favorites end
  favorites = assert(Pokeblock.manifest().favorites, "pokeblock manifest has no favorites")
  return favorites
end

function Pokeblock.setFavoriteTable(t)
  favorites = t
end

-- pokeemerald/src/pokeblock.c:1428
function Pokeblock.favoriteName(nature, compat)
  local fav = Pokeblock.favoriteTable()
  for i = 0, Pokeblock.FLAVOR_COUNT - 1 do
    if Pokeblock.gain(nature, fav[i + 1], compat) > 0 then
      return Pokeblock.colorName(i + 1)
    end
  end
  return nil
end

local function natureOf(mon)
  return num(mon and mon.personality) % 25
end
Pokeblock.natureOf = natureOf

function Pokeblock.contest(mon)
  if type(mon) ~= "table" then return nil end
  local c = mon.contest
  if type(c) ~= "table" then
    c = {}
    mon.contest = c
  end
  for _, k in ipairs({ "cool", "beauty", "cute", "smart", "tough", "sheen" }) do
    c[k] = num(c[k])
  end
  return c
end

-- pokeemerald/src/use_pokeblock.c:988
function Pokeblock.conditions(mon)
  local c = Pokeblock.contest(mon) or {}
  local out = {}
  for i, k in ipairs(Pokeblock.CONDITIONS) do out[i] = num(c[k]) end
  return out
end

function Pokeblock.sheen(mon)
  local c = Pokeblock.contest(mon)
  return c and num(c.sheen) or 0
end

-- pokeemerald/src/use_pokeblock.c:1070
function Pokeblock.isSheenMaxed(mon)
  return Pokeblock.sheen(mon) == Pokeblock.MAX_SHEEN
end

-- pokeemerald/include/menu_specialized.h:47
function Pokeblock.sparkles(sheen)
  sheen = num(sheen)
  if sheen ~= Pokeblock.MAX_SHEEN then
    return math.floor(sheen / (math.floor(Pokeblock.MAX_SHEEN / (Pokeblock.MAX_CONDITION_SPARKLES - 1)) + 1))
  end
  return Pokeblock.MAX_CONDITION_SPARKLES - 1
end

-- pokeemerald/src/use_pokeblock.c:1039
function Pokeblock.statBoosts(block, mon, gain, compat)
  local boosts = {}
  for i = 1, #Pokeblock.CONDITIONS do
    boosts[i] = num(block and block[Pokeblock.FLAVORS[Pokeblock.CONDITION_FLAVOR[i] + 1]])
  end
  local direction
  if gain > 0 then direction = 1 elseif gain < 0 then direction = -1 else return boosts end
  local nature = natureOf(mon)
  for i = 1, #Pokeblock.CONDITIONS do
    local amount = boosts[i]
    local boost = math.floor(amount / 10)
    if amount % 10 >= 5 then boost = boost + 1 end
    local rel = Pokeblock.flavorRelation(nature, Pokeblock.CONDITION_FLAVOR[i], compat)
    if rel == direction then boosts[i] = boosts[i] + boost * rel end
  end
  return boosts
end

-- pokeemerald/src/use_pokeblock.c:996
function Pokeblock.applyToMon(block, mon, gain, compat)
  local c = Pokeblock.contest(mon)
  if not c or num(c.sheen) == Pokeblock.MAX_SHEEN then return false end
  local boosts = Pokeblock.statBoosts(block, mon, gain, compat)
  for i, k in ipairs(Pokeblock.CONDITIONS) do
    local stat = num(c[k]) + boosts[i]
    if stat < 0 then stat = 0 end
    if stat > Pokeblock.MAX_CONDITION then stat = Pokeblock.MAX_CONDITION end
    c[k] = stat
  end
  local sheen = num(c.sheen) + num(block and block.feel)
  if sheen > Pokeblock.MAX_SHEEN then sheen = Pokeblock.MAX_SHEEN end
  c.sheen = sheen
  return true
end

-- pokeemerald/src/use_pokeblock.c:1026
function Pokeblock.feed(block, mon, gain, compat)
  if gain == nil then gain = Pokeblock.gain(natureOf(mon), block, compat) end
  local before = Pokeblock.conditions(mon)
  Pokeblock.applyToMon(block, mon, gain, compat)
  local after = Pokeblock.conditions(mon)
  local enh = {}
  for i = 1, #before do enh[i] = (after[i] - before[i]) % 256 end
  return { before = before, after = after, enhancements = enh, gain = gain }
end

-- pokeemerald/src/use_pokeblock.c:969
function Pokeblock.enhancementTexts(enh)
  local RomText = require("src.core.game3.rom_text")
  local out = {}
  for i = 1, #Pokeblock.CONDITIONS do
    if num(enh[i]) ~= 0 then
      out[#out + 1] = RomText.plain(Pokeblock.CONDITION_NAMES[i]) .. RomText.plain("gText_WasEnhanced")
    end
  end
  if #out == 0 then out[1] = RomText.plain("gText_NothingChanged") end
  return out
end

-- pokeemerald/src/pokeblock_feed.c:867
function Pokeblock.ateText(gain)
  if gain == 0 then return "gText_Var1AteTheVar2" end
  if gain > 0 then return "gText_Var1HappilyAteVar2" end
  return "gText_Var1DisdainfullyAteVar2"
end

local function feederRow()
  return { x = 0, y = 0, mapNum = 0, stepCounter = 0, pokeblock = Pokeblock.empty() }
end

local function safariState(session)
  session = session_of(session)
  if not session then return nil end
  session.safari = session.safari or {}
  return session.safari
end

-- pokeemerald/src/safari_zone.c:35
function Pokeblock.feeders(session)
  local st = safariState(session)
  if not st then return nil end
  if type(st.feeders) ~= "table" then st.feeders = {} end
  local f = st.feeders
  for i = 1, Pokeblock.NUM_FEEDERS do
    local row = f[i]
    if type(row) ~= "table" or num(row.stepCounter) == 0 then f[i] = feederRow() end
  end
  return f
end

function Pokeblock.clearFeeders(session)
  local st = safariState(session)
  if st then st.feeders = {} end
end

local DELTA = { up = { 0, -1 }, down = { 0, 1 }, left = { -1, 0 }, right = { 1, 0 } }

-- pokeemerald/src/field_player_avatar.c:1134
function Pokeblock.playerFront()
  local P = package.loaded["src.core.game3.player"]
  if not P then return nil end
  local d = DELTA[P.facing] or DELTA.down
  return num(P.cellX) + d[1] + Pokeblock.MAP_OFFSET, num(P.cellY) + d[2] + Pokeblock.MAP_OFFSET
end

-- pokeemerald/src/field_player_avatar.c:1141
function Pokeblock.playerDest()
  local P = package.loaded["src.core.game3.player"]
  if not P then return nil end
  local x = P.targetX or P.cellX
  local y = P.targetY or P.cellY
  return num(x) + Pokeblock.MAP_OFFSET, num(y) + Pokeblock.MAP_OFFSET
end

function Pokeblock.mapNum(session)
  session = session_of(session)
  local Rse = require("src.core.game3.rse.init")
  local _, n = Rse.mapGroupNum(session and session.map, session)
  return num(n)
end

local function s8(v)
  v = num(v) % 256
  return v >= 128 and v - 256 or v
end

-- pokeemerald/src/safari_zone.c:131
function Pokeblock.feederInFront(session, x, y, mapNum)
  local f = Pokeblock.feeders(session)
  if not f then return -1 end
  if x == nil then x, y = Pokeblock.playerFront() end
  mapNum = mapNum or Pokeblock.mapNum(session)
  for i = 0, Pokeblock.NUM_FEEDERS - 1 do
    local row = f[i + 1]
    if s8(mapNum) == s8(row.mapNum) and row.x == x and row.y == y then
      return i, Pokeblock.name(row.pokeblock)
    end
  end
  return -1
end

-- pokeemerald/src/safari_zone.c:153
function Pokeblock.feederWithinRange(session, x, y, mapNum)
  local f = Pokeblock.feeders(session)
  if not f then return -1 end
  if x == nil then x, y = Pokeblock.playerDest() end
  mapNum = mapNum or Pokeblock.mapNum(session)
  for i = 0, Pokeblock.NUM_FEEDERS - 1 do
    local row = f[i + 1]
    if s8(mapNum) == s8(row.mapNum) then
      x = x - row.x
      y = y - row.y
      if x < 0 then x = -x end
      if y < 0 then y = -y end
      if x + y <= Pokeblock.FEEDER_RANGE then return i end
    end
  end
  return -1
end

-- pokeemerald/src/safari_zone.c:193
function Pokeblock.activeFeederBlock(session, x, y, mapNum)
  local i = Pokeblock.feederWithinRange(session, x, y, mapNum)
  if i == -1 then return nil end
  return Pokeblock.feeders(session)[i + 1].pokeblock
end

function Pokeblock.installEncounterHooks(session)
  local okE, E = pcall(require, "src.core.game3.encounters")
  if okE and type(E) == "table" and not E.pokeblockGain then
    E.pokeblockGain = function(nature, pb) return Pokeblock.gain(nature, pb) end
  end
  local st = safariState(session)
  if not st then return end
  local mt = getmetatable(st)
  if mt and mt.pokeblockFeeders then return end
  local sess = session_of(session)
  setmetatable(st, {
    pokeblockFeeders = true,
    __index = function(_, k)
      if k == "activePokeblock" then return Pokeblock.activeFeederBlock(sess) end
      return nil
    end,
  })
end

-- pokeemerald/src/safari_zone.c:203
function Pokeblock.activateFeeder(session, id, x, y, mapNum)
  local f = Pokeblock.feeders(session)
  local block = Pokeblock.get(session, id)
  if not (f and block) then return nil end
  for i = 0, Pokeblock.NUM_FEEDERS - 1 do
    local row = f[i + 1]
    if row.mapNum == 0 and row.x == 0 and row.y == 0 then
      if x == nil then x, y = Pokeblock.playerFront() end
      row.mapNum = s8(mapNum or Pokeblock.mapNum(session))
      row.pokeblock = Pokeblock.copy(block)
      row.stepCounter = Pokeblock.FEEDER_STEPS
      row.x = x
      row.y = y
      Pokeblock.installEncounterHooks(session)
      return i
    end
  end
  return nil
end

-- pokeemerald/src/pokeblock.c:1256
function Pokeblock.chooseForBattle(session, done)
  session = session_of(session)
  local Case = require("src.ui.game3.screens").get("pokeblock_case", session)
    or require("src.ui.game3.rse.pokeblock_case")
  Case.show({
    session = session,
    caseId = Pokeblock.CASE.BATTLE,
    onUse = function(id)
      local block = Pokeblock.copy(Pokeblock.get(session, id))
      Pokeblock.tryClear(session, id)
      return { name = Pokeblock.name(block), flavors = Pokeblock.flavors(block), color = block.color }
    end,
    onClose = function(result) done(result) end,
  })
end

-- pokeemerald/src/pokeblock.c:446
function Pokeblock.openCase(session, opts)
  opts = opts or {}
  local sess = session_of(session)
  local Case = require("src.ui.game3.screens").get("pokeblock_case", sess)
    or require("src.ui.game3.rse.pokeblock_case")
  return Case.show({
    session = sess,
    caseId = opts.caseId or Pokeblock.CASE.FIELD,
    onUse = opts.onUse,
    onClose = opts.onClose,
  })
end

Pokeblock.SAVE_FIELDS = { "pokeblocks" }

local okS, SaveSections = pcall(require, "src.core.game3.save_sections")
if okS and SaveSections then
  SaveSections.register("pokeblocks", SaveSections.fields(Pokeblock.SAVE_FIELDS, function(session)
    -- pokeemerald/src/new_game.c:188
    Pokeblock.clearAll(session)
  end))
end

local okR, Rse = pcall(require, "src.core.game3.rse.init")
if okR and Rse and Rse.register then Rse.register("pokeblock", Pokeblock) end

return Pokeblock
