local M = {BY_NAME = {}}
M.BY_NAME.sub_80BBDD0 = function(ctx)
  require("src.core.game3.rs.room_decorations").init(ctx)
  return false
end
return M
