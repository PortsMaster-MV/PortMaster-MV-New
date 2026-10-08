local N = {BY_NAME = {}}
-- pokeruby/src/roulette.c:1782
N.BY_NAME.PlayRoulette = function(ctx, adapters)
  return require("src.core.game3.scripting.natives_game_corner_rse").playRoulette(ctx, adapters)
end
return N
