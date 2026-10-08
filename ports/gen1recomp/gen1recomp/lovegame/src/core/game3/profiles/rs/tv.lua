local Policy = {}
Policy.lifecycle = "src.core.game3.rs.tv_daily"
Policy.latiFlag = "FLAG_SYS_TV_LATI"
local function n(v) return math.floor(tonumber(v) or 0) end

-- pokeruby/src/battle_tower.c:1397
function Policy.currentWinStreak(tower, levelType)
  local i = n(levelType) + 1
  local challenges = type(tower.curStreakChallengesNum) == "table" and tower.curStreakChallengesNum[i] or 0
  local battle = type(tower.curChallengeBattleNum) == "table" and tower.curChallengeBattleNum[i] or 0
  local streak = ((n(challenges) - 1) * 7 - 1 + n(battle)) % 65536
  return math.min(streak, 9999)
end

-- pokeruby/src/tv.c:986
function Policy.towerInterview(session)
  local tower = type(session.battleTower) == "table" and session.battleTower or {}
  local level = n(tower.lastStreakLevelType)
  local outcome = n(tower.battleOutcome)
  return {
    opponentName = tower.defeatedByTrainerName or "",
    playerSpecies = n(tower.firstMonSpecies),
    opponentSpecies = n(tower.defeatedBySpecies),
    numFights = Policy.currentWinStreak(tower, level),
    battleOutcome = outcome,
    wonTheChallenge = outcome == 1,
    lvlMode = level,
  }
end

return Policy
