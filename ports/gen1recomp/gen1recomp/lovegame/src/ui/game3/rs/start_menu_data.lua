local RomText = require("src.core.game3.rom_text")
local Font = require("src.ui.game3.frlg_font")
local Data = {layout = "rs"}
Data.TEXT = {
  pokedex = "SystemText_Pokedex", pokemon = "SystemText_Pokemon", bag = "SystemText_BAG",
  pokenav = "SystemText_Pokenav", trainer = "SystemText_Player", trainer_link = "SystemText_Player",
  save = "SystemText_Save", option = "SystemText_Option", exit = "SystemText_Exit", retire = "SystemText_Retire",
}

function Data.entry(id, ctx)
  local session = ctx.session
  local name = session and (session.name or session.playerName) or ctx.playerLabel()
  return {id = id, label = RomText.plain(Data.TEXT[id], {playerName = Font.truncate(name or "", 7)})}
end

-- pokeruby/src/start_menu.c:244
function Data.build(ctx)
  local list, kind = {}, "normal"
  local function add(id) list[#list + 1] = Data.entry(id, ctx) end
  local nav = ctx.flag("SYS_POKENAV_GET")
  if ctx.linkActive() then
    kind = "link"
    add("pokemon"); add("bag")
    if nav then add("pokenav") end
    add("trainer_link")
  elseif ctx.safariActive() then
    kind = "safari"
    add("retire"); add("pokedex"); add("pokemon"); add("bag"); add("trainer")
  else
    if ctx.flag("SYS_POKEDEX_GET") then add("pokedex") end
    if ctx.flag("SYS_POKEMON_GET") then add("pokemon") end
    add("bag")
    if nav then add("pokenav") end
    add("trainer"); add("save")
  end
  add("option"); add("exit")
  return list, kind
end

function Data.extraWindow(kind, ctx)
  if ctx.safariActive() then
    return {left = 1, top = 1, width = 9, height = 4, key = "gOtherText_SafariStock",
      textY = 0, vars = {string.format("%2d", ctx.safariBalls())}}
  end
end

Data.window = {left = 23, top = 1, width = 6}
Data.textX, Data.textY, Data.rowPitch = 0, 8, 16
Data.maxVisible, Data.dexNeedsSeen, Data.exitConfirms = 8, true, true
function Data.drawCursor(x, y)
  require("src.ui.game3.rs.menu_cursor").draw(x, y, 48)
end
return Data
