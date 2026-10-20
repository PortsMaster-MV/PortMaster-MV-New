
local Battle = require("src.battle.gen2.Battle")
local BattleState = require("src.ui.gen2.BattleState")
local Fingerprint = require("src.link.Fingerprint")
local Handshake = require("src.link.Handshake")
local Logger = require("src.core.Logger")
local Protocol = require("src.link.Protocol")
local Runtime = require("src.mods.Runtime")
local Strings = require("src.core.Strings")

local LinkBattle2 = {}

-- BattleState:refuseMenu already wraps its argument in Strings() (needed by
-- every other caller, which passes a raw Strings.source() marker); these two
-- used to pre-translate before that, which is now a harmless-in-practice but
-- real double Strings() call on an already-translated string.
local TEXT_NO_ITEMS_IN_LINK = Strings.source("Items can't be used in a link battle!")
local TEXT_NO_RUNNING_IN_LINK = Strings.source("No running from a link battle!")

local function makeRandom(seed, owner)
  local s = tonumber(seed) or 1
  if s ~= s or s == math.huge or s == -math.huge then s = 1 end
  s = math.floor(s) % 2147483647
  if s <= 0 then s = s + 2147483646 end
  owner.rngDraws = 0
  return function(n)
    owner.rngDraws = owner.rngDraws + 1
    s = (s * 16807) % 2147483647
    n = math.floor(tonumber(n) or 1)
    if n < 1 then n = 1 end
    return s % n
  end
end

local PARTS = { "actives", "volatile", "bench" }

local FATAL_PART = { actives = true, bench = true }

local IDLE_PHASE = {
  menu = true, moves = true, ["locked-in"] = true, ["forced-switch"] = true,
  ["link-wait"] = true, ["link-hold"] = true, ["refuse-menu"] = true,
  ["refuse-move"] = true, ["refuse-switch"] = true,
}

local function unpackParty(game, packed, unpackOpts, errFmt)
  local out = {}
  for _, p in ipairs(packed or {}) do
    local mon, why = Protocol.unpackMon2(game.data, p, unpackOpts)
    if mon then
      table.insert(out, mon)
    elseif unpackOpts.strict then
      return nil, errFmt(p, why)
    end
  end
  return out
end

local function linkSave(game, party)
  local player = (game and game.save and game.save.player) or {}
  return {
    party = party,
    player = { name = player.name or "PLAYER", gender = player.gender },
    inventory = {},
    pokedex = { seen = {}, caught = {} },
    options = {},
    modData = {},
  }
end

local function digestParts(parts)
  return {
    actives = Fingerprint.digest(parts.actives),
    volatile = Fingerprint.digest(parts.volatile),
    bench = Fingerprint.digest(parts.bench),
  }
end

local function moveSlot(mon, moveId)
  for i, mv in ipairs((mon and mon.moves) or {}) do
    if mv.id == moveId then return i end
  end
  return nil
end

local function encodeAction(battle, action)
  if action.kind == "switch" then
    return { type = "action", kind = "switch", index = action.index }
  end
  if action.kind == "run" then
    return { type = "action", kind = "run" }
  end
  if action.move == Battle.STRUGGLE then
    return { type = "action", kind = "struggle" }
  end
  local slot = moveSlot(battle.player, action.move)
  if not slot then
    return { type = "action", kind = "locked" }
  end
  return { type = "action", kind = "move", slot = slot }
end

local function decodeAction(battle, msg, mon)
  local kind = msg.kind
  if kind == "switch" then
    local index = math.floor(tonumber(msg.index) or 1)
    return { kind = "switch", index = index }
  end
  if kind == "run" then return { kind = "run" } end
  if kind == "struggle" then
    return { kind = "move", move = Battle.STRUGGLE }
  end
  if kind == "locked" then
    local locked = battle:lockedInMove(mon)
      or battle:volatile(mon).chargeMove
      or battle:forcedMove(mon)
    return { kind = "move", move = locked }
  end
  local moves = (mon and mon.moves) or {}
  local slot = math.max(1, math.min(math.max(1, #moves),
    math.floor(tonumber(msg.slot) or 1)))
  local mv = moves[slot]
  return { kind = "move", move = mv and mv.id or Battle.STRUGGLE }
end

local function outcomeResult(outcome, battle)
  if outcome == "win" then
    if battle and not Battle.firstHealthy(battle.party) then return "draw" end
    return "win"
  end
  if outcome == "lose" then return "lose" end
  return "draw"
end

function LinkBattle2.new(game, net, opts)
  local role = opts.role
  local theirName = opts.theirName or "FOE"

  if not Handshake.battleAllowed(opts.verdict) then
    return nil, Strings("Link battle needs\nthe same version\nand mods.")
  end

  local unpackOpts = { strict = opts.strict or false,
                       forceLevel = opts.forceLevel }
  local myParty, myErr = unpackParty(game, opts.myParty, unpackOpts, function(p)
    return Strings("Your %s can't\nbattle on the\nother game.",
      tostring(p.species))
  end)
  if not myParty then return nil, myErr end
  local theirParty, theirErr = unpackParty(game, opts.theirParty, unpackOpts,
    function(p, why)
      return Strings("Their %s isn't\nin this game.\n(%s)",
        tostring(p.species), tostring(why))
    end)
  if not theirParty then return nil, theirErr end
  if #myParty == 0 or #theirParty == 0 then
    Logger.warn("link2: empty party on one side")
  end

  local function announceReceived(party)
    for _, mon in ipairs(party) do
      Runtime.emit("pokemon.received",
                   { mon = mon, from = "link", peerName = theirName })
    end
  end
  announceReceived(role == "host" and myParty or theirParty)
  announceReceived(role == "host" and theirParty or myParty)

  local owner = {}
  local random = makeRandom(opts.seed or 1, owner)
  local battle = Battle.new({
    data = game.data,
    random = random,
    party = myParty,
    trainer = { name = theirName, party = theirParty },
    save = nil,
  })
  battle.linkBattle = true
  battle.mirrored = role == "guest"
  theirParty = battle.enemyParty

  local hooks = {}
  local screen
  local ended, byeSent = false, false
  local pendingMine, pendingTheirs = nil, nil
  local remoteReplace = {}
  local turnCount = 0
  local localHashes, remoteHashes = {}, {}
  local localParts, remoteParts = {}, {}
  local checkedTurns = {}
  local clock = nil

  local function send(msg) net:send(msg) end

  local function kick(s)
    if IDLE_PHASE[s.phase] then
      s.phase = "resolving"
      s:advanceQueue()
    end
  end

  local function endWithResult(s, result, text)
    if ended then return end
    ended = true
    s.result = result
    if text then s:pushAll({ { kind = "message", text = text } }) end
    if not battle.over then
      battle:endBattle(result == "win" and "win"
        or (result == "lose" and "lose" or "draw"))
    end
    kick(s)
  end

  local function endAsDraw(s, text)
    endWithResult(s, "draw", text)
  end

  local function reportDesync(s, turn, component, localH, remoteH)
    Logger.warn("link2: desync turn %s component=%s (%s vs %s)",
                tostring(turn), component, tostring(localH), tostring(remoteH))
    Runtime.emit("link.desync", { turn = turn, component = component,
                                  localHash = localH, remoteHash = remoteH,
                                  fatal = true })
    endAsDraw(s, Strings(
      "Link desync! %s differs. Are both games the same version and mods?",
      component))
  end

  local function noteDrift(turn, component, localH, remoteH)
    Logger.warn("link2: %s drift on turn %s (%s vs %s) -- match continues",
                component, tostring(turn), tostring(localH), tostring(remoteH))
    Runtime.emit("link.desync", { turn = turn, component = component,
                                  localHash = localH, remoteHash = remoteH,
                                  fatal = false })
  end

  local function checkHashes(s)
    for turn, localH in pairs(localHashes) do
      local remoteH = remoteHashes[turn]
      if remoteH and not checkedTurns[turn] then
        checkedTurns[turn] = true
        local mine, theirs = localParts[turn], remoteParts[turn]
        if mine and theirs then
          for _, component in ipairs(PARTS) do
            if mine[component] ~= theirs[component] then
              if FATAL_PART[component] then
                reportDesync(s, turn, component, mine[component],
                             theirs[component])
                return
              end
              noteDrift(turn, component, mine[component], theirs[component])
            end
          end
        end
        if remoteH ~= localH then
          reportDesync(s, turn, "state", localH, remoteH)
          return
        end
      end
    end
  end

  local function signTurn(s)
    battle.rngDraws = owner.rngDraws
    turnCount = turnCount + 1
    local raw = battle:linkSignature(role)
    local parts = digestParts(raw)
    local value = parts.actives .. "|" .. parts.bench
    localHashes[turnCount] = value
    localParts[turnCount] = parts
    if LinkBattle2.keepSignatures then s.linkSignatures[turnCount] = raw end
    send({ type = "hash", turn = turnCount, value = value, parts = parts })
    checkHashes(s)
  end

  local function resolveLockstep(s, myMsg, theirMsg)
    if myMsg.kind == "run" or theirMsg.kind == "run" then
      local who = myMsg.kind == "run"
        and ((game.save and game.save.player and game.save.player.name)
             or "PLAYER")
        or theirName
      endAsDraw(s, Strings("%s ran from the battle!", who))
      return
    end
    local myAction = decodeAction(battle, myMsg, battle.player)
    local theirAction = decodeAction(battle, theirMsg, battle.enemy)
    local events = battle:takeLinkTurn(myAction, theirAction)
    signTurn(s)
    if ended then return end
    s.phase = "resolving"
    s:pushAll(events)
    s.message = nil
    s.messageTimer = 0
    s:advanceQueue()
  end

  local function tryResolve(s)
    if not pendingMine or not pendingTheirs then return end
    local mine, theirs = pendingMine, pendingTheirs
    pendingMine, pendingTheirs = nil, nil
    resolveLockstep(s, mine, theirs)
  end

  local function applyRemoteReplace(s)
    if not battle.pendingEnemySwitch or #remoteReplace == 0 then return end
    local index = table.remove(remoteReplace, 1)
    battle:forcedReplacement("enemy", index)
    s:pushAll(battle:takeEvents())
    if s.phase == "link-hold" then kick(s) end
  end

  hooks.submit = function(s, action)
    if ended then return end
    if action.kind == "item" then
      return s:refuseMenu(TEXT_NO_ITEMS_IN_LINK)
    end
    if action.kind == "run" then
      return s:refuseMenu(TEXT_NO_RUNNING_IN_LINK)
    end
    local msg = encodeAction(battle, action)
    send(msg)
    pendingMine = msg
    s.phase = "link-wait"
    tryResolve(s)
  end

  hooks.menuChoice = function(s, choice)
    if choice == "item" then
      s:refuseMenu(TEXT_NO_ITEMS_IN_LINK)
      return true
    end
    if choice == "run" then
      s:refuseMenu(TEXT_NO_RUNNING_IN_LINK)
      return true
    end
    return false
  end

  -- ChooseNextMon (engine/battle/core.asm:1086-1103): the replacement after a
  hooks.forcedSwitch = function(s, index)
    local mon = myParty[index]
    if not mon or (mon.hp or 0) <= 0 or mon.isEgg then
      return s:refuseSwitch(true)
    end
    if not battle:forcedReplacement("player", index) then
      return s:refuseSwitch(true)
    end
    send({ type = "replace", index = index })
    s.phase = "resolving"
    s:pushAll(battle:takeEvents())
    s:advanceQueue()
    return true
  end

  screen = BattleState.new(game, {
    battle = battle,
    save = linkSave(game, myParty),
    link = hooks,
    onDone = function(outcome)
      local result = screen.result or outcomeResult(outcome, battle)
      screen.result = result
      if not byeSent then
        byeSent = true
        send({ type = "bye" })
      end
      if not opts.keepNetOpen then
        net:close()
        if game.linkNet == net then game.linkNet = nil end
      end
      if game.stack and game.stack:top() == screen then game.stack:pop() end
      if screen.onFinish then screen.onFinish(result) end
    end,
  })

  screen.kind = "link"
  screen.linkRole = role
  screen.result = nil
  screen.playerParty = myParty
  screen.enemyParty = theirParty
  screen.localHashes = localHashes
  screen.remoteHashes = remoteHashes
  screen.localParts = localParts
  screen.remoteParts = remoteParts
  screen.linkSignatures = {}
  screen.rngOwner = owner
  game.linkNet = net

  local baseUpdate = screen.update
  screen.update = function(s, dt)
    net:update()
    for _, msg in ipairs(net:poll()) do
      if msg.type == "action" then
        pendingTheirs = msg
        tryResolve(s)
      elseif msg.type == "hash" then
        remoteHashes[msg.turn or 0] = msg.value
        remoteParts[msg.turn or 0] = msg.parts
        checkHashes(s)
      elseif msg.type == "replace" then
        table.insert(remoteReplace, math.max(1, math.min(#theirParty,
          math.floor(tonumber(msg.index) or 1))))
      elseif msg.type == "bye" then
        if not ended and not battle.over then
          endAsDraw(s, Strings("%s left the battle.", theirName))
        end
      elseif msg.type == "forfeit" then
        if not ended and not battle.over then
          endWithResult(s, "win", Strings("%s ran out of time!", theirName))
        end
      else
        s.pendingLinkMessages = s.pendingLinkMessages or {}
        table.insert(s.pendingLinkMessages, msg)
      end
    end
    if net.closed and not ended and not battle.over then
      endAsDraw(s)
    end
    applyRemoteReplace(s)
    if battle.pendingEnemySwitch
        and (s.phase == "menu" or s.phase == "moves"
             or s.phase == "locked-in") then
      s.phase = "link-hold"
    end
    if opts.turnLimit and (s.phase == "menu" or s.phase == "moves") then
      clock = (clock or opts.turnLimit) - (dt or 0)
      if clock <= 0 then
        clock = nil
        send({ type = "forfeit" })
        endWithResult(s, "lose",
          Strings("Time's up! You forfeit the match."))
      end
    elseif opts.turnLimit then
      clock = nil
    end
    return baseUpdate(s, dt)
  end

  return screen
end

function LinkBattle2.newSpectator(game, net, opts)
  local hostName = opts.hostName or "HOST"
  local guestName = opts.guestName or "GUEST"

  if not Handshake.battleAllowed(opts.verdict) then
    return nil, Strings("Link battle needs\nthe same version\nand mods.")
  end

  local unpackOpts = { strict = opts.strict or false,
                       forceLevel = opts.forceLevel }
  local hostParty, hostErr = unpackParty(game, opts.hostParty, unpackOpts,
    function(p)
      return Strings("%s's %s can't\nbattle on this\ngame.", hostName,
        tostring(p.species))
    end)
  if not hostParty then return nil, hostErr end
  local guestParty, guestErr = unpackParty(game, opts.guestParty, unpackOpts,
    function(p, why)
      return Strings("%s's %s can't\nbattle on this\ngame.\n(%s)", guestName,
        tostring(p.species), tostring(why))
    end)
  if not guestParty then return nil, guestErr end

  local owner = {}
  local random = makeRandom(opts.seed or 1, owner)
  local battle = Battle.new({
    data = game.data,
    random = random,
    party = hostParty,
    trainer = { name = guestName, party = guestParty },
    save = nil,
  })
  battle.linkBattle = true
  guestParty = battle.enemyParty

  local hooks = {}
  local screen
  local hostMsg, guestMsg = nil, nil
  local hostReplace, guestReplace = {}, {}
  local ended = false

  local function endSpectate(s, text)
    if ended then return end
    ended = true
    s.result = s.result or "ended"
    if text then s:pushAll({ { kind = "message", text = text } }) end
    if not battle.over then battle:endBattle("draw") end
    if IDLE_PHASE[s.phase] then
      s.phase = "resolving"
      s:advanceQueue()
    end
  end

  local function resolveSpecTurn(s, hMsg, gMsg)
    if hMsg.kind == "run" or gMsg.kind == "run" then
      endSpectate(s, Strings("The match ended."))
      return
    end
    local hostAction = decodeAction(battle, hMsg, battle.player)
    local guestAction = decodeAction(battle, gMsg, battle.enemy)
    local events = battle:takeLinkTurn(hostAction, guestAction)
    if ended then return end
    s.phase = "resolving"
    s:pushAll(events)
    s.message = nil
    s.messageTimer = 0
    s:advanceQueue()
  end

  hooks.forcedPrompt = function(s)
    local index = table.remove(hostReplace, 1)
    if not index then return true end
    battle:forcedReplacement("player", index)
    s.phase = "resolving"
    s:pushAll(battle:takeEvents())
    s:advanceQueue()
    return true
  end

  hooks.submit = function() end
  hooks.menuChoice = function() return true end
  hooks.forcedSwitch = function(s) return s:refuseSwitch(true) end

  screen = BattleState.new(game, {
    battle = battle,
    save = linkSave(game, hostParty),
    link = hooks,
    onDone = function(outcome)
      local result = screen.result or outcomeResult(outcome, battle)
      screen.result = result
      if game.stack and game.stack:top() == screen then game.stack:pop() end
      if screen.onFinish then screen.onFinish(result) end
    end,
  })

  screen.kind = "link"
  screen.spectating = true
  screen.result = nil
  screen.playerParty = hostParty
  screen.enemyParty = guestParty
  game.linkNet = net

  local baseUpdate = screen.update
  screen.update = function(s, dt)
    net:update()
    for _, msg in ipairs(net:poll()) do
      if msg.type == "spectate" and type(msg.msg) == "table" then
        local inner = msg.msg
        if inner.type == "action" then
          if msg.side == "host" then hostMsg = inner else guestMsg = inner end
          if hostMsg and guestMsg then
            local h, g = hostMsg, guestMsg
            hostMsg, guestMsg = nil, nil
            resolveSpecTurn(s, h, g)
          end
        elseif inner.type == "replace" then
          local index = math.floor(tonumber(inner.index) or 1)
          if msg.side == "host" then
            table.insert(hostReplace,
              math.max(1, math.min(#hostParty, index)))
          else
            table.insert(guestReplace,
              math.max(1, math.min(#guestParty, index)))
          end
        elseif inner.type == "bye" or inner.type == "forfeit" then
          endSpectate(s, Strings("The match ended."))
        end
      else
        s.pendingLinkMessages = s.pendingLinkMessages or {}
        table.insert(s.pendingLinkMessages, msg)
      end
    end
    if net.closed and not ended and not battle.over then endSpectate(s) end
    if battle.pendingEnemySwitch then
      local index = table.remove(guestReplace, 1)
      if index then
        battle:forcedReplacement("enemy", index)
        s:pushAll(battle:takeEvents())
        if s.phase == "link-hold" then
          s.phase = "resolving"
          s:advanceQueue()
        end
      elseif s.phase == "menu" or s.phase == "moves"
          or s.phase == "locked-in" then
        s.phase = "link-hold"
      end
    end
    if s.phase == "menu" or s.phase == "moves" or s.phase == "locked-in" then
      s.phase = "link-wait"
    end
    return baseUpdate(s, dt)
  end

  return screen
end

function LinkBattle2.newHost(game, net, opts)
  opts.role = "host"
  return LinkBattle2.new(game, net, opts)
end

function LinkBattle2.newGuest(game, net, opts)
  opts.role = "guest"
  return LinkBattle2.new(game, net, opts)
end

return LinkBattle2
