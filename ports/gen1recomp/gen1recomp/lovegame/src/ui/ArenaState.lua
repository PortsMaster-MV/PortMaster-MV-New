local ArenaBoot = require("src.online.ArenaBoot")
local LinkBattle = require("src.link.LinkBattle")
local Logger = require("src.core.Logger")
local Runtime = require("src.mods.Runtime")

local ArenaState = {}
ArenaState.__index = ArenaState
ArenaState.isOpaque = true
ArenaState.screenId = "ArenaState"

function ArenaState.new(game, spec)
  local self = setmetatable({}, ArenaState)
  self.game = game
  self.spec = spec
  self.stage = "boot"
  self.battle = nil
  self.finished = false
  return self
end

function ArenaState:report(result)
  if self.finished then return end
  self.finished = true
  local onDone = self.spec and self.spec.onDone
  if onDone then pcall(onDone, result) end
end

function ArenaState:leave()
  local game = self.game
  game.linkNet = nil
  game.linkSession = nil
  if game.stack and game.stack:top() == self then game.stack:pop() end
  if type(game.returnToLauncher) == "function" then
    game.returnToLauncher({ tab = "online" })
  end
end

function ArenaState:fail(reason)
  Logger.error("arena: battle could not start (%s)", tostring(reason))
  self.stage = "done"
  self:report("error")
  self:leave()
end

function ArenaState:enter()
  local game, spec = self.game, self.spec
  game.linkNet = spec.session
  game.linkSession = true

  if spec.role ~= "spectator" then
    local packed, packErr = ArenaBoot.packOwnParty(game, spec)
    if not packed then return self:fail(packErr) end
  end

  local opts, optsErr = ArenaBoot.battleOpts(spec)
  if not opts then return self:fail(optsErr) end

  local battle, why
  if spec.role == "spectator" then
    battle, why = LinkBattle.newSpectator(game, spec.session, opts)
  elseif spec.role == "guest" then
    battle, why = LinkBattle.newGuest(game, spec.session, opts)
  else
    battle, why = LinkBattle.newHost(game, spec.session, opts)
  end
  if not battle then return self:fail(why) end

  self.battle = battle
  self.stage = "running"
  game.stack:push(battle)
end

function ArenaState:update(_dt)
  if self.stage ~= "running" then return end
  if self.game.stack:top() ~= self then return end
  self.stage = "done"
  local battle = self.battle
  local result = (battle and battle.result) or "ended"
  if battle and Runtime.wants("link.battle_ended") then
    Runtime.emit("link.battle_ended", {
      result = result,
      myParty = battle.playerParty,
      theirParty = battle.enemyParty,
      peerName = self.spec.peerName,
      role = self.spec.role,
    })
  end
  self.battle = nil
  self:report(result)
  self:leave()
end

function ArenaState:draw()
  local G = love.graphics
  G.setColor(0, 0, 0, 1)
  G.rectangle("fill", 0, 0, 160, 144)
  G.setColor(1, 1, 1, 1)
end

return ArenaState
