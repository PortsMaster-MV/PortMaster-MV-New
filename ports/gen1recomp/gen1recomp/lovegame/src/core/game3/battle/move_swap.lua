local MoveSwap = {}

local function filled(mv)
  return mv ~= nil and mv ~= 0 and mv ~= ""
end

function MoveSwap.moveCount(mon)
  local n = 0
  for i = 1, 4 do
    if not filled(mon and mon.moves and mon.moves[i]) then break end
    n = n + 1
  end
  return n
end

-- pokeemerald/src/battle_controller_player.c:601
function MoveSwap.canStart(st, battler)
  if not st or st.link or not battler or not battler.mon then return false end
  return MoveSwap.moveCount(battler.mon) > 1
end

-- pokeemerald/src/battle_controller_player.c:604
function MoveSwap.initialCursor(current)
  if current ~= 0 then return 0 end
  return current + 1
end

-- pokeemerald/src/battle_controller_player.c:795
function MoveSwap.step(cursor, dir, n)
  if dir == "left" then
    if cursor % 2 == 1 then return cursor - 1 end
  elseif dir == "right" then
    if cursor % 2 == 0 and cursor + 1 < n then return cursor + 1 end
  elseif dir == "up" then
    if cursor >= 2 then return cursor - 2 end
  elseif dir == "down" then
    if cursor < 2 and cursor + 2 < n then return cursor + 2 end
  end
  return cursor
end

local function swap_field(t, a, b)
  if type(t) == "table" then t[a], t[b] = t[b], t[a] end
end

-- pokeemerald/src/battle_controller_player.c:676
function MoveSwap.apply(battler, slotA, slotB)
  if not battler or not battler.mon or slotA == slotB then return false end
  local Pokemon = require("src.core.game3.pokemon")
  local State = require("src.core.game3.battle.state")
  local party = State.partyMon(battler)
  if battler._partyMon then
    local proxy = battler.mon
    swap_field(rawget(proxy, "moves"), slotA, slotB)
    swap_field(rawget(proxy, "pp"), slotA, slotB)
    swap_field(battler.permanentSlots, slotA, slotB)
    swap_field(battler.sketched, slotA, slotB)
    if not battler.transformed and party then
      Pokemon.swapMoves(party, slotA, slotB)
    end
  else
    Pokemon.swapMoves(party or battler.mon, slotA, slotB)
  end
  for _, key in ipairs({ "expLockedSlot", "expEncoreSlot" }) do
    if battler[key] == slotA then
      battler[key] = slotB
    elseif battler[key] == slotB then
      battler[key] = slotA
    end
  end
  return true
end

return MoveSwap
