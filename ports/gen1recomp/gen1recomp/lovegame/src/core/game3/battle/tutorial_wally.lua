local Commands = require("src.core.game3.battle.commands")
local BattleProfile = require("src.core.game3.battle.profile")

local Wally = {}

-- pokeemerald/include/constants/battle.h:324
Wally.WAIT_LONG = 64
-- pokeemerald/src/battle_controller_wally.c:1230
Wally.MOVE_FRAMES = 80

function Wally.active(st)
  return st ~= nil and st.kinds ~= nil and st.kinds.tutorial == "wally"
end

function Wally.ballItem(st)
  return BattleProfile.constants(BattleProfile.of(st)):require("items", "ITEM_POKE_BALL")
end

-- pokeemerald/src/battle_controller_wally.c:188
function Wally.peek(st)
  local n = tonumber(st and st.wallyState) or 0
  if n < 2 then
    local act = Commands.playerAction(st, 1, 1)
    act.user = "player"
    return act, "fight"
  end
  if n == 2 then return { kind = "wally_throw", user = "player" }, "throw" end
  return { kind = "bag", itemId = Wally.ballItem(st), user = "player", wally = true }, "bag"
end

function Wally.take(st)
  local act, step = Wally.peek(st)
  st.wallyState = (tonumber(st.wallyState) or 0) + 1
  return act, step
end

-- pokeemerald/src/battle_controller_wally.c:188
function Wally.menuStep(Ui, st, playSelect)
  local w = Ui._wally
  if not w then return end
  local _, step = Wally.peek(st)
  w.timer = w.timer + 1
  if step == "fight" then
    if w.sub == 0 and w.timer >= Wally.WAIT_LONG then
      playSelect()
      w.sub, w.timer = 1, 0
      if Ui._openMoveMenu then Ui._openMoveMenu() end
    elseif w.sub == 1 and w.timer >= Wally.MOVE_FRAMES then
      -- pokeemerald/src/battle_controller_wally.c:1244
      playSelect()
      Ui._pendingCommand = Wally.take(st)
      Ui._mode = "none"
      Ui._wally = nil
    end
  elseif step == "throw" then
    if w.timer >= Wally.WAIT_LONG then
      Ui._pendingCommand = Wally.take(st)
      Ui._mode = "none"
      Ui._wally = nil
    end
  else
    if w.sub == 0 and w.timer >= Wally.WAIT_LONG then
      -- pokeemerald/src/battle_controller_wally.c:232
      playSelect()
      Ui._menuIndex = 2
      w.sub, w.timer = 1, 0
    elseif w.sub == 1 and w.timer >= Wally.WAIT_LONG then
      playSelect()
      Ui._pendingCommand = Wally.take(st)
      Ui._mode = "none"
      Ui._wally = nil
    end
  end
end

return Wally
