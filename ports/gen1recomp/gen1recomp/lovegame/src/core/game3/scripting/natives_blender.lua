local Std = require("src.core.game3.scripting.stdscripts")
local Rse = require("src.core.game3.rse.init")
local Blender = require("src.core.game3.rse.berry_blender")
local RsPolicy = require("src.core.game3.rs.berry_blender_policy")

local NativesBlender = {}

-- pokeemerald/include/constants/vars.h:287
local VAR_0x8004 = 0x8004

local function session()
  return Rse.session()
end

local function playerName(sess)
  return tostring(sess and (sess.name or sess.playerName) or "")
end

local function frameType(sess)
  local ok, Options = pcall(require, "src.core.game3.options")
  if not ok or not (Options and Options.block) then return 0 end
  local okB, block = pcall(Options.block, sess and sess.options)
  return okB and type(block) == "table" and tonumber(block.frameType) or 0
end

local function screen()
  local ok, Screens = pcall(require, "src.ui.game3.screens")
  local mod = ok and Screens.get("berry_blender", session()) or nil
  return mod or require("src.ui.game3.rse.berry_blender")
end

NativesBlender.last = nil

-- pokeemerald/src/berry_blender.c:1047
function NativesBlender.doBerryBlending(ctx, adapters, opts)
  opts = opts or {}
  local sess = session()
  local nativeRS = RsPolicy.matches(require("src.core.game3.profile").forSession(sess).id)
  local opponents = Rse.specialVar(ctx, VAR_0x8004)
  local linkSession
  local playerNames, numPlayers
  if opponents == 0 then
    local Link = require("src.core.game3.link.init")
    local lk = Link.link
    local players = lk and lk.players and lk:players() or nil
    local Game3Link = require("src.link.Game3Link")
    if not (lk and lk.isOpen and lk:isOpen() and lk.isReady and lk:isReady()
        and type(players) == "table" and #players >= 2 and #players <= Blender.MAX_PLAYERS) then
      Rse.missing("berryBlender", "link DoBerryBlending without a ready 2-4 player session", adapters and adapters.log)
      return false
    end
    if lk.linkType ~= Game3Link.LINKTYPE.BERRY_BLENDER_SETUP
        and lk.linkType ~= Game3Link.LINKTYPE.BERRY_BLENDER then
      Rse.missing("berryBlender", "link DoBerryBlending without Berry Blender linkup", adapters and adapters.log)
      return false
    end
    for index, player in ipairs(players) do
      if tonumber(player.seat) ~= index - 1 then
        Rse.missing("berryBlender", "non-contiguous Blender relay seats", adapters and adapters.log)
        return false
      end
    end
    local LinkSession = require("src.core.game3.rse.berry_blender_link")
    linkSession = LinkSession.new(lk, players)
    numPlayers, playerNames = #players, {}
    for _, player in ipairs(players) do playerNames[(tonumber(player.seat) or 0) + 1] = tostring(player.name or "") end
    lk.linkType = Game3Link.LINKTYPE.BERRY_BLENDER
  end
  local Natives = require("src.core.game3.scripting.natives")
  return Natives.yieldHost(ctx, adapters, function(done)
    local Fade = require("src.ui.game3.fade")
    Fade.clear()
    NativesBlender.last = { opponents = opponents, linkSession = linkSession }
    NativesBlender.last.screen = screen().open({
      session = sess,
      opponents = opponents,
      linkSession = linkSession,
      numPlayers = numPlayers,
      playerNames = playerNames,
      blendMaster = not nativeRS and not Rse.flag("FLAG_HIDE_LILYCOVE_CONTEST_HALL_BLEND_MASTER", sess),
      version = require("src.core.game3.profile").forSession(sess).id,
      playerName = playerName(sess),
      frameType = frameType(sess),
      chooseBerry = opts.chooseBerry,
      onDone = function(s)
        NativesBlender.last.done = true
        NativesBlender.last.result = s and s.result
        Fade.mode, Fade.t, Fade.active = Fade.MODE.TO_BLACK, 16, false
        Fade.begin(Fade.MODE.FROM_BLACK, 1)
        -- pokeemerald/src/overworld.c:1684
        pcall(function() require("src.core.game3.audio").mapLoadMusic({}) end)
        done()
      end,
    })
  end)
end

-- pokeemerald/src/berry_blender.c:3755
function NativesBlender.recordWindow(sess)
  local M = Blender.manifest()
  if RsPolicy.matches(require("src.core.game3.profile").forSession(sess).id) then return RsPolicy.recordWindow(sess,M) end
  local t = M.texts
  local tpl = M.recordWindow
  local FrlgFont = require("src.ui.game3.frlg_font")
  local function width(s)
    local best = 0
    for line in (tostring(s) .. "\n"):gmatch("([^\n]*)\n") do
      local ok, w = pcall(FrlgFont.measure, line)
      if ok and w and w > best then best = w end
    end
    return best
  end
  local win = { left = tpl.left, top = tpl.top, width = tpl.width, height = tpl.height, prints = {} }
  local function put(s, x, y) win.prints[#win.prints + 1] = { s = s, x = x, y = y } end
  local x = math.floor((144 - width(t.blenderMaxSpeedRecord)) / 2)
  local pitch = 16
  local row = 0
  for line in (t.blenderMaxSpeedRecord .. "\n"):gmatch("([^\n]*)\n") do
    put(line, x, 1 + row * pitch)
    row = row + 1
  end
  row = 0
  for line in (t.players234 .. "\n"):gmatch("([^\n]*)\n") do
    put(line, 4, 41 + row * pitch)
    row = row + 1
  end
  local rec = Blender.records(sess)
  for i = 0, 2 do
    local s = Blender.recordText(rec[i + 1], t)
    put(s, 140 - width(s), 41 + i * 16)
  end
  return win
end

-- pokeemerald/src/berry_blender.c:3755
function NativesBlender.showRecordWindow(sess)
  local Records = require("src.ui.game3.rse.frontier_records")
  local win = NativesBlender.recordWindow(sess)
  return Records.showWindow(win)
end

NativesBlender.BY_NAME = {
  -- pokeemerald/src/berry_blender.c:1047
  DoBerryBlending = function(ctx, adapters)
    return NativesBlender.doBerryBlending(ctx, adapters)
  end,
  -- pokeemerald/src/berry_blender.c:3755
  ShowBerryBlenderRecordWindow = function()
    NativesBlender.showRecordWindow(session())
    return false
  end,
}

Std.legacyHandlers(NativesBlender)

return NativesBlender
