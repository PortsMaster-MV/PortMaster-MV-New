local ArenaBoot = require("src.online.ArenaBoot")
local Chrome = require("src.ui.gen2.Chrome")
local LinkBattle2 = require("src.link.LinkBattle2")
local Logger = require("src.core.Logger")
local Runtime = require("src.mods.Runtime")
local Strings = require("src.core.Strings")

local ArenaState = {}
ArenaState.__index = ArenaState
ArenaState.isOpaque = true
ArenaState.screenId = "Gen2ArenaState"

local HOLD_FRAMES = 300

function ArenaState:wantsFillScale() return true end
function ArenaState:drawsWidescreen() return true end

function ArenaState.new(game, spec)
  local self = setmetatable({}, ArenaState)
  self.game = game
  self.spec = spec
  self.stage = "boot"
  self.battle = nil
  self.frames = 0
  self.finished = false
  self.message = nil
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
  Logger.error("arena2: battle could not start (%s)", tostring(reason))
  self.stage = "failed"
  self.frames = 0
  self.message = tostring(reason or Strings("The battle could not start."))
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
    battle, why = LinkBattle2.newSpectator(game, spec.session, opts)
  elseif spec.role == "guest" then
    battle, why = LinkBattle2.newGuest(game, spec.session, opts)
  else
    battle, why = LinkBattle2.newHost(game, spec.session, opts)
  end
  if not battle then return self:fail(why) end

  self.battle = battle
  self.stage = "running"
  game.stack:push(battle)
end

function ArenaState:update(_dt)
  if self.stage == "failed" then
    self.frames = self.frames + 1
    local input = self.game.input
    local dismissed = input and (input:wasPressed("a") or input:wasPressed("b")
      or input:wasPressed("start"))
    if dismissed or self.frames >= HOLD_FRAMES then
      self.stage = "done"
      self:report("error")
      self:leave()
    end
    return
  end
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

function ArenaState:drawPanel()
  Chrome.clear()
  if self.message then
    Chrome.textbox(0, 12, 18, 4)
    Chrome.printWrapped(self.message, 1, 13, 18, 4)
  end
end

function ArenaState:draw()
  self:drawPanel()
end

function ArenaState:drawWidescreen(winW, winH)
  local G = love.graphics
  Chrome.letterbox(winW, winH)
  local scale = Chrome.fitScale(winW, winH)
  G.push()
  G.translate(Chrome.fitOrigin(winW, winH, scale))
  G.scale(scale, scale)
  self:drawPanel()
  G.pop()
end

return ArenaState
