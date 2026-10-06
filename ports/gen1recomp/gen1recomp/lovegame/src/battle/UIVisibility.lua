-- Shared visibility rules for battle-owned UI states.  Text and choice
-- overlays live above BattleState on the state stack, but they are still part
-- of its bottom UI layer and must inherit that layer's visibility.

local Runtime = require("src.mods.Runtime")

local UIVisibility = {}

local function enclosingBattle(state)
  local stack = state and state.game and state.game.stack
  local states = stack and stack.states
  local found = false
  for i = #(states or {}), 1, -1 do
    local candidate = states[i]
    if candidate == state then found = true end
    if found and candidate and candidate.isBattle then return candidate end
  end
  return nil
end

-- queryState keeps the existing TextBox contract: a mod may still decide
-- visibility for that individual box.  ChoiceBox only inherits the enclosing
-- battle decision, so field YES/NO prompts never become battle-hook states.
function UIVisibility.bottomVisible(state, queryState)
  if not Runtime.wantsHook("battle.bottom_ui_visible") then return true end
  local battle = enclosingBattle(state)
  if battle and battle ~= state
      and Runtime.call("battle.bottom_ui_visible",
                       function() return true end, battle) == false then
    return false
  end
  if queryState or battle == state then
    return Runtime.call("battle.bottom_ui_visible",
                        function() return true end, state) ~= false
  end
  return true
end

return UIVisibility
