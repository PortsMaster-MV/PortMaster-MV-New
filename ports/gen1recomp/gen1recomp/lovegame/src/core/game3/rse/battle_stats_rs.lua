local Stats = {}

function Stats.firstBattle(opts)
  return opts.firstBattle == true or opts.firstBattleKind == "birch"
end

-- pokeruby/src/battle_setup.c:519
function Stats.countedKind(opts)
  if Stats.firstBattle(opts) or opts.link or opts.recordedLink or opts.battleTower or opts.eReader
      or opts.specialBattleKind == 1 or opts.safari or opts.tutorialKind == "wally" then return nil end
  return opts.wild and "wild" or "trainer"
end

function Stats.onAccepted(session, opts)
  local kind = Stats.countedKind(opts)
  if not kind then return false end
  session.gameStats = session.gameStats or {}
  for _, id in ipairs({ 7, kind == "wild" and 8 or 9 }) do
    session.gameStats[id] = math.min(0xFFFFFF, math.floor(tonumber(session.gameStats[id]) or 0) + 1)
  end
  return true
end

function Stats.onStarted(session, opts)
  if Stats.firstBattle(opts) or opts.link or opts.recordedLink or opts.battleTower or opts.eReader or opts.specialBattleKind == 1 then return end
  local C = require("src.core.game3.constants").active(session)
  local poison = C:require("vars", "VAR_POISON_STEP_COUNTER")
  require("src.core.game3.rse.init").setVar(poison, 0, session)
  session.vars = session.vars or {}
  session.vars[poison], session.poisonSteps = 0, 0
  require("src.core.game3.encounters").resetRateModifiers()
end

return Stats
