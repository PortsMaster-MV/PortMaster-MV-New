local FirstBattle = {}

-- pokeruby/src/battle_setup.c:884
function FirstBattle.onStart(session)
  local C = require("src.core.game3.constants").active(session)
  session.vars = session.vars or {}
  local poison = C:require("vars", "VAR_POISON_STEP_COUNTER")
  require("src.core.game3.rse.init").setVar(poison, 0, session)
  session.vars[poison], session.poisonSteps = 0, 0
  session.gameStats = session.gameStats or {}
  -- include/constants/game_stat.h:11
  for _, id in ipairs({ 7, 8 }) do
    session.gameStats[id] = math.min(0xFFFFFF, math.floor(tonumber(session.gameStats[id]) or 0) + 1)
  end
end

return FirstBattle
