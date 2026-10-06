local N = {BY_NAME = {}}
N.BY_NAME.ShowBattleTowerRecords = function()
  local session = assert(require("src.core.game3.rse.init").session(), "RS records-board session missing")
  require("src.ui.game3.rs.battle_tower_records").show(session)
  return false
end
return N
