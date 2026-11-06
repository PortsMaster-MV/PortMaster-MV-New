local OpsRse = {}

-- pokeemerald/include/constants/vars.h:280
local VAR_0x8000 = 0x8000
local VAR_0x8001 = 0x8001
local VAR_0x8002 = 0x8002
local VAR_RESULT = 0x800D

local function Rse()
  return require("src.core.game3.rse.init")
end

local function Flags()
  return require("src.core.game3.scripting.flags")
end

local function session()
  local rt = package.loaded["src.core.game3.runtime"]
  return rt and rt.getSession and rt.getSession() or nil
end

local function logger(vm)
  return vm and vm.adapters and vm.adapters.log or nil
end

local function setResult(vm, v)
  Flags().setVar(vm.store, vm.ctx, VAR_RESULT, v)
end

local function arg(vm, row, i, H)
  return H.varGet(vm.store, vm.ctx, row[i])
end

local function as(row, op)
  local copy = {}
  for k, v in pairs(row) do copy[k] = v end
  copy.op = op
  return copy
end

local function system(vm, name, fn, what, ...)
  return Rse().call(name, fn, what, logger(vm), ...)
end

local function rtcOn(sess)
  local ok, Rtc = pcall(require, "src.core.game3.rtc")
  return ok and Rtc and Rtc.enabled(sess) and Rtc or nil
end

local H = {}

-- pokeemerald/src/scrcmd.c:682
H.initclock = function(vm, row, B)
  local sess = session()
  local Rtc = rtcOn(sess)
  if not Rtc then
    Rse().missing("rtc", "initclock", logger(vm))
    return false
  end
  Rtc.initLocalTimeOffset(sess, arg(vm, row, 1, B), arg(vm, row, 2, B))
  return false
end

-- pokeemerald/src/scrcmd.c:691
H.dotimebasedevents = function(vm)
  local sess = session()
  if not rtcOn(sess) then
    Rse().missing("rtc", "dotimebasedevents", logger(vm))
    return false
  end
  require("src.core.game3.time_events").run(sess)
  return false
end

-- pokeemerald/src/scrcmd.c:697
H.gettime = function(vm)
  local sess = session()
  local Rtc = rtcOn(sess)
  local t = Rtc and Rtc.calcLocalTime(sess) or { hours = 0, minutes = 0, seconds = 0 }
  if not Rtc then Rse().missing("rtc", "gettime", logger(vm)) end
  Flags().setVar(vm.store, vm.ctx, VAR_0x8000, t.hours)
  Flags().setVar(vm.store, vm.ctx, VAR_0x8001, t.minutes)
  Flags().setVar(vm.store, vm.ctx, VAR_0x8002, t.seconds)
  return false
end

-- pokeemerald/src/scrcmd.c:1924
H.setberrytree = function(vm, row)
  system(vm, "berryTrees", "plant", "setberrytree", tonumber(row[1]) or 0, tonumber(row[2]) or 0,
    tonumber(row[3]) or 0, false, vm.store)
  return false
end

-- pokeemerald/src/scrcmd.c:1937
H.getpokenewsactive = function(vm, row, B)
  local Tv = require("src.core.game3.rse.tv")
  local shouldApply = function(kind)
    local r = system(vm, "tv", "shouldApplyPokeNews", "ShouldApplyPokeNewsEffect", kind)
    return r == true
  end
  setResult(vm, Tv.isPokeNewsActive(session(), arg(vm, row, 1, B), shouldApply) and 1 or 0)
  return false
end

local function decor(fn, what)
  -- pokeemerald/src/scrcmd.c:550
  return function(vm, row, B)
    local r, handled = system(vm, "decorations", fn, what, arg(vm, row, 1, B))
    setResult(vm, handled and (tonumber(r) or (r and 1 or 0)) or 0)
    return false
  end
end
H.adddecoration = decor("add", "adddecoration")
H.removedecoration = decor("remove", "removedecoration")
H.checkdecorspace = decor("checkSpace", "checkdecorspace")
H.checkdecor = decor("has", "checkdecor")

local function contest(fn)
  -- pokeemerald/src/scrcmd.c:1945
  return function(vm, row)
    local r, handled = system(vm, "contest", fn, fn, vm, row)
    if handled then return r == true end
    return false
  end
end
H.choosecontestmon = contest("choosecontestmon")
H.startcontest = contest("startcontest")
H.showcontestresults = contest("showcontestresults")
H.contestlinktransfer = contest("contestlinktransfer")

-- pokeemerald/src/scrcmd.c:1469
H.showcontestpainting = function(vm, row, B)
  local r, handled = system(vm, "contestPainting", "show", "showcontestpainting", vm, arg(vm, row, 1, B))
  if handled then return r == true end
  return false
end

-- pokeemerald/src/scrcmd.c:1636
H.buffercontestname = function(vm, row, B)
  local RomText = require("src.core.game3.rom_text")
  local dest = (tonumber(row[1]) or 0) + 1
  vm.ctx.stringVars[dest] = RomText.at("sContestNames", arg(vm, row, 2, B))
  return false
end

local function rotating(fn)
  -- pokeemerald/src/scrcmd.c:2159
  return function(vm, row, B)
    local a1 = row[1] ~= nil and arg(vm, row, 1, B) or nil
    local r, handled = system(vm, "rotatingTilePuzzle", fn, fn, vm, a1)
    if handled then return r == true end
    return false
  end
end
H.moverotatingtileobjects = rotating("moverotatingtileobjects")
H.turnrotatingtileobjects = rotating("turnrotatingtileobjects")
H.initrotatingtilepuzzle = rotating("initrotatingtilepuzzle")
H.freerotatingtilepuzzle = rotating("freerotatingtilepuzzle")

-- pokeemerald/src/scrcmd.c:1915
H.playslotmachine = function(vm, row, B)
  return require("src.core.game3.scripting.natives_game_corner_rse").opPlaySlotMachine(vm, row, B)
end

-- pokeemerald/src/scrcmd.c:2187
H.selectapproachingtrainer = function(vm)
  local r, handled = system(vm, "trainerApproach", "select", "selectapproachingtrainer", vm)
  if handled and r then
    require("src.core.game3.scripting.ctx").selectObject(vm.ctx, r)
  end
  return false
end

-- pokeemerald/src/scrcmd.c:2193
H.lockfortrainer = function(vm, row, B)
  local r, handled = system(vm, "trainerApproach", "lock", "lockfortrainer", vm)
  if handled then return r == true end
  return B.base(vm, as(row, "lockall"))
end

-- pokeemerald/src/scrcmd.c:1536
H.closebraillemessage = function(vm, row, B)
  local ok, Braille = pcall(require, "src.ui.game3.braille")
  if ok and Braille and Braille.hide then pcall(Braille.hide) end
  vm.ctx.messageOpen = false
  return false
end

-- pokeemerald/src/scrcmd.c:1299
H.messageinstant = function(vm, row, B)
  B.showMessage(vm, row.ptr or row[1], true)
  local Message = package.loaded["src.ui.game3.message"]
  if Message and Message.skipReveal then Message.skipReveal() end
  return false
end

-- pokeemerald/src/scrcmd.c:1276
H.pokenavcall = function(vm, row, B)
  local r, handled = system(vm, "pokenav", "fieldMessage", "pokenavcall", vm, row.ptr or row[1])
  if handled then return r == true end
  return B.showMessage(vm, row.ptr or row[1], true)
end

-- pokeemerald/src/scrcmd.c:644
H.fadescreenswapbuffers = function(vm, row, B)
  return B.base(vm, as(row, "fadescreen"))
end

-- pokeemerald/src/scrcmd.c:2273
H.buffertrainerclassname = function(vm, row, B)
  local Trainers = require("src.core.game3.scripting.trainers")
  local t = Trainers.get(arg(vm, row, 2, B))
  vm.ctx.stringVars[(tonumber(row[1]) or 0) + 1] = t and t.className or ""
  return false
end

-- pokeemerald/src/scrcmd.c:2282
H.buffertrainername = function(vm, row, B)
  local Trainers = require("src.core.game3.scripting.trainers")
  local t = Trainers.get(arg(vm, row, 2, B))
  vm.ctx.stringVars[(tonumber(row[1]) or 0) + 1] = t and t.name or ""
  return false
end

-- pokeemerald/src/scrcmd.c:814
H.warpmossdeepgym = function(vm, row, B) return B.base(vm, row) end
-- pokeemerald/src/scrcmd.c:2296
H.warpwhitefade = function(vm, row, B) return B.base(vm, row) end

OpsRse.HANDLERS = H

function OpsRse.names()
  local out = {}
  for k in pairs(H) do out[#out + 1] = k end
  table.sort(out)
  return out
end

return OpsRse
