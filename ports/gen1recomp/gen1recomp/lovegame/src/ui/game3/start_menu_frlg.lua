local RomText = require("src.core.game3.rom_text")

local Data = {}

Data.layout = "frlg"
Data.textKey = "sStartMenuActionTable"

-- pokefirered/src/start_menu.c:116
Data.ACTION = { pokedex = 0, pokemon = 1, bag = 2, trainer = 3, save = 4, option = 5, exit = 6, retire = 7, trainer_link = 8 }

function Data.entry(id, ctx)
  return { id = id, label = RomText.at(Data.textKey, Data.ACTION[id], nil, { playerName = ctx.playerLabel() }) }
end

function Data.build(ctx)
  local entry = function(id) return Data.entry(id, ctx) end
  if ctx.linkActive() then
    -- pokefirered/src/start_menu.c:236 SetUpStartMenu_Link
    return { entry("pokemon"), entry("bag"), entry("trainer_link"), entry("option"), entry("exit") }, "link"
  end
  if ctx.inUnionRoom() then
    -- pokefirered/src/start_menu.c:245 SetUpStartMenu_UnionRoom
    return { entry("pokemon"), entry("bag"), entry("trainer"), entry("option"), entry("exit") }, "union"
  end
  if ctx.safariActive() then
    -- pokefirered/src/start_menu.c:226 SetUpStartMenu_SafariZone
    return {
      entry("retire"), entry("pokedex"), entry("pokemon"), entry("bag"),
      entry("trainer"), entry("option"), entry("exit"),
    }, "safari"
  end
  local entries = {}
  -- pokefirered/src/start_menu.c:215
  if ctx.flag("SYS_POKEDEX_GET", 0x829) then entries[#entries + 1] = entry("pokedex") end
  -- pokefirered/src/start_menu.c:217
  if ctx.flag("SYS_POKEMON_GET", 0x828) then entries[#entries + 1] = entry("pokemon") end
  entries[#entries + 1] = entry("bag")
  entries[#entries + 1] = entry("trainer")
  entries[#entries + 1] = entry("save")
  entries[#entries + 1] = entry("option")
  entries[#entries + 1] = entry("exit")
  return entries, "normal"
end

-- pokefirered/src/start_menu.c:255 DrawSafariZoneStatsWindow
function Data.extraWindow(kind, ctx)
  if kind ~= "safari" then return nil end
  local Safari = require("src.core.game3.safari")
  return { left = 1, top = 1, width = 10, height = 4, key = "gText_MenuSafariStats", textX = 4, textY = 3,
    vars = {
      string.format("%3d", Safari.steps(ctx.session)),
      string.format("%3d", Safari.STEPS),
      string.format("%2d", Safari.balls(ctx.session)),
    } }
end

Data.exitConfirms = true

return Data
