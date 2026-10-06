-- pokeruby/src/battle_records.c:184
local M = {}
local function increment(card, key)
  if type(card) ~= "table" then return end
  local before = math.floor(tonumber(card[key]) or 0) % 65536
  card[key] = math.min(9999, (before + 1) % 65536)
end
-- battle_main.c:5505
function M.callbackOutcome(result, outcome)
  if result == "run" then return 2 end
  return outcome
end
function M.update(localCard, opponentCard, outcome)
  if outcome == 1 then
    increment(localCard, "linkBattleWins")
    increment(opponentCard, "linkBattleLosses")
  elseif outcome == 2 then
    increment(localCard, "linkBattleLosses")
    increment(opponentCard, "linkBattleWins")
  else
    return false
  end
  return true
end
function M.apply(session, outcome, peer)
  if type(session) ~= "table" or (outcome ~= 1 and outcome ~= 2) then return false end
  if type(session.trainerCard) ~= "table" then session.trainerCard = {} end
  -- trainer_card.c:395
  local stats = type(session.gameStats) == "table" and session.gameStats or {}
  for _, row in ipairs({{23, "linkBattleWins"}, {24, "linkBattleLosses"}}) do
    if session.trainerCard[row[2]] == nil then
      session.trainerCard[row[2]] = math.min(9999, math.max(0,
        math.floor(tonumber(stats[row[1]]) or tonumber(stats[row[2]]) or 0)))
    end
  end
  return M.update(session.trainerCard, peer and peer.trainerCard, outcome)
end
return M
