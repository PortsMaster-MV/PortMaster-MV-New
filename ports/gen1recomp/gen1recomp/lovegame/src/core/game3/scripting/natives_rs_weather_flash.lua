local N = {BY_NAME = {}}
N.BY_NAME.sub_807E25C = function(ctx)
  local done = false
  require("src.core.game3.rse.weather_flash_rs").start(function() done = true end)
  require("src.core.game3.scripting.natives").awaitState(ctx, function() return done end)
  return false
end
return N
