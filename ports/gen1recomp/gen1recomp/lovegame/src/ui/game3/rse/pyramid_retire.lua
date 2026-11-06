local Retire = {}

local function startScript(label)
  local Space = package.loaded["src.core.game3.scripting.space"] or require("src.core.game3.scripting.space")
  local key = require("src.core.game3.rse.frontier.pyramid").scriptKey(label)
  if not key then return false end
  return Space.startScript(key, nil) ~= false
end

-- pokeemerald/src/start_menu.c:840
function Retire.show(opts)
  opts = opts or {}
  local StartMenu = package.loaded["src.ui.game3.start_menu"]
  if StartMenu and StartMenu.close then StartMenu.close(true) end
  local Message = require("src.ui.game3.message")
  local Choice = require("src.ui.game3.choice")
  local Field = package.loaded["src.core.game3.field"]
  if Field then Field.locked = true end
  Retire._pending = true
  -- pokeemerald/src/start_menu.c:1166
  local TextIR = require("src.core.game3.scripting.text_ir")
  local ref = require("src.core.game3.rse.frontier.pyramid").manifest().confirmRetire
  Message.show(TextIR.toPlain(ref.ir, {}), function()
    Choice.yesNo(function(yes)
      Retire._pending = false
      if Field then Field.locked = false end
      if yes == true or yes == 1 then
        -- pokeemerald/src/start_menu.c:870
        startScript("BattlePyramid_Retire")
      end
    end)
    -- pokeemerald/src/start_menu.c:1177
    Choice.cursor = 2
  end)
  return true
end

function Retire.reset()
  Retire._pending = false
end

return Retire
