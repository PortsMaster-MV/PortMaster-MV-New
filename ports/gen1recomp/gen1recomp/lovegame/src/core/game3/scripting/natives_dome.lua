local Rse = require("src.core.game3.rse.init")
local Util = require("src.core.game3.rse.frontier.util")

local NativesDome = {}

local DomeMod = require("src.core.game3.rse.frontier.dome")
local function Dome() return DomeMod end
local function UI() return require("src.ui.game3.rse.dome_tourney") end

local function await(ctx, open)
  local done = false
  require("src.core.game3.scripting.natives").awaitState(ctx, function() return done end)
  open(function() done = true end)
end

-- pokeemerald/src/battle_dome.c:2142
function NativesDome.call(ctx, adapters)
  local s = Rse.session()
  local id = Rse.specialVar(ctx, Util.VAR_0x8004)
  if not s then return false end
  local F = Dome().FUNC
  if id == F.SAVE then
    return Util.saveFromNative(ctx, adapters, s, Dome().save)
  elseif id == F.SHOW_OPPONENT_INFO then
    -- pokeemerald/src/battle_dome.c:3043
    local D = Dome()
    local tid = D.tournamentId(s, D.playerOpponentTrainerId(s))
    await(ctx, function(done) UI().showCard({ session = s, mode = "next", id = tid, onClose = done }) end)
    return false
  elseif id == F.SHOW_TOURNEY_TREE then
    -- pokeemerald/src/battle_dome.c:4986
    await(ctx, function(done) UI().showTree({ session = s, mode = "interactive", onClose = done }) end)
    return false
  elseif id == F.SHOW_PREV_TOURNEY_TREE then
    -- pokeemerald/src/battle_dome.c:4997
    local f = Dome().frontier(s)
    f.lvlMode = f.domeLvlMode - 1
    f.curChallengeBattleNum = Dome().FINAL
    await(ctx, function(done) UI().showTree({ session = s, mode = "prev", onClose = done }) end)
    return false
  elseif id == F.SHOW_STATIC_TOURNEY_TREE then
    -- pokeemerald/src/battle_dome.c:5181
    await(ctx, function(done) UI().showTree({ session = s, mode = "static", onClose = done }) end)
    return false
  end
  local ok = Dome().call(ctx, adapters, s, id)
  if not ok then Rse.missing("dome", "CallBattleDomeFunction " .. tostring(id), adapters and adapters.log) end
  return false
end

-- pokeemerald/src/hall_of_fame.c:1405
function NativesDome.confetti(ctx)
  Rse.setSpecialVar(ctx, Util.VAR_0x8004, 180)
  UI().startConfetti(180)
  Rse.setSpecialVar(ctx, Util.VAR_0x8005, 1)
  return false
end

NativesDome.BY_NAME = {
  -- pokeemerald/src/battle_dome.c:2142
  CallBattleDomeFunction = function(ctx, adapters) return NativesDome.call(ctx, adapters) end,
  -- pokeemerald/src/hall_of_fame.c:1405
  DoDomeConfetti = function(ctx) return NativesDome.confetti(ctx) end,
}

return NativesDome
