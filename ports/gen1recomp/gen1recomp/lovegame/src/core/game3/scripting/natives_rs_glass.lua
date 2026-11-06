local N = {BY_NAME = {}}
N.BY_NAME.ShowGlassWorkshopMenu = function(ctx, adapters)
  return require("src.core.game3.scripting.natives").yieldHost(ctx, adapters, function(done)
    require("src.ui.game3.rs.glass_workshop").show(function(value)
      require("src.core.game3.rse.init").setSpecialVar(ctx, 0x800D, value)
      done()
    end)
  end)
end
return N
