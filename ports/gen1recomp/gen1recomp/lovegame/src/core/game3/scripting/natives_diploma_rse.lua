local Natives = {}

Natives.BY_NAME = {
  -- pokeruby/src/field_specials.c:70
  ScrSpecial_ShowDiploma = function(ctx, adapters)
    local Native = require("src.core.game3.scripting.natives")
    return Native.yieldHost(ctx, adapters, function(done)
      require("src.ui.game3.rs.diploma").show({onDone = done})
    end)
  end,
  -- pokeemerald/src/field_specials.c:141
  Special_ShowDiploma = function(ctx, adapters)
    local Native = require("src.core.game3.scripting.natives")
    local Diploma = require("src.ui.game3.diploma")
    return Native.yieldHost(ctx, adapters, function(done)
      local shown = Diploma.show({ onDone = done })
      if not shown then done() end
    end)
  end,
}

return Natives
