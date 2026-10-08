local RomText = require("src.core.game3.rom_text")

local Data = {}

Data.layout = "rse"

-- pokeemerald/src/start_menu.c:182
Data.TEXT = {
  pokedex = "gText_MenuPokedex",
  pokemon = "gText_MenuPokemon",
  bag = "gText_MenuBag",
  pokenav = "gText_MenuPokenav",
  trainer = "gText_MenuPlayer",
  save = "gText_MenuSave",
  option = "gText_MenuOption",
  exit = "gText_MenuExit",
  retire = "gText_MenuRetire",
  trainer_link = "gText_MenuPlayer",
  rest_frontier = "gText_MenuRest",
  retire_frontier = "gText_MenuRetire",
  pyramid_bag = "gText_MenuBag",
}

-- pokeemerald/src/battle_pike.c:1326
Data.PIKE_MAPS = {
  EM_BATTLE_FRONTIER_BATTLE_PIKE_THREE_PATH_ROOM = true,
  EM_BATTLE_FRONTIER_BATTLE_PIKE_ROOM_NORMAL = true,
  EM_BATTLE_FRONTIER_BATTLE_PIKE_ROOM_WILD_MONS = true,
}

-- pokeemerald/src/battle_pyramid.c:1423
Data.PYRAMID_MAPS = {
  EM_BATTLE_FRONTIER_BATTLE_PYRAMID_FLOOR = "floor",
  EM_BATTLE_FRONTIER_BATTLE_PYRAMID_TOP = "top",
}

-- pokeemerald/src/field_specials.c:1663
Data.MULTI_PARTNER_ROOM = "EM_BATTLE_FRONTIER_BATTLE_TOWER_MULTI_PARTNER_ROOM"
-- pokeemerald/include/constants/battle_frontier.h:25
Data.FRONTIER_MODE_MULTIS = 2

function Data.entry(id, ctx)
  return { id = id, label = RomText.plain(Data.TEXT[id], { playerName = ctx.playerLabel() }) }
end

-- pokeemerald/src/field_specials.c:1663
local function inMultiPartnerRoom(ctx)
  if ctx.mapId() ~= Data.MULTI_PARTNER_ROOM then return false end
  return ctx.var("FRONTIER_BATTLE_MODE") == Data.FRONTIER_MODE_MULTIS
end

-- pokeemerald/src/start_menu.c:276
function Data.build(ctx)
  local entry = function(id) return Data.entry(id, ctx) end
  local nav = ctx.flag("SYS_POKENAV_GET")
  local list, kind
  if ctx.linkActive() then
    -- pokeemerald/src/start_menu.c:350
    list = { entry("pokemon"), entry("bag") }
    if nav then list[#list + 1] = entry("pokenav") end
    list[#list + 1] = entry("trainer_link")
    kind = "link"
  elseif ctx.inUnionRoom() then
    -- pokeemerald/src/start_menu.c:365
    list = { entry("pokemon"), entry("bag") }
    if nav then list[#list + 1] = entry("pokenav") end
    list[#list + 1] = entry("trainer")
    kind = "union"
  elseif ctx.safariActive() then
    -- pokeemerald/src/start_menu.c:339
    list = { entry("retire"), entry("pokedex"), entry("pokemon"), entry("bag"), entry("trainer") }
    kind = "safari"
  elseif Data.PIKE_MAPS[ctx.mapId() or ""] then
    -- pokeemerald/src/start_menu.c:380
    list = { entry("pokedex"), entry("pokemon"), entry("trainer") }
    kind = "pike"
  elseif Data.PYRAMID_MAPS[ctx.mapId() or ""] then
    -- pokeemerald/src/start_menu.c:389
    list = {
      entry("pokemon"), entry("pyramid_bag"), entry("trainer"), entry("rest_frontier"), entry("retire_frontier"),
    }
    kind = "pyramid"
  elseif inMultiPartnerRoom(ctx) then
    -- pokeemerald/src/start_menu.c:400
    list = { entry("pokemon"), entry("trainer") }
    kind = "multi_partner"
  else
    -- pokeemerald/src/start_menu.c:315
    list = {}
    if ctx.flag("SYS_POKEDEX_GET") then list[#list + 1] = entry("pokedex") end
    if ctx.flag("SYS_POKEMON_GET") then list[#list + 1] = entry("pokemon") end
    list[#list + 1] = entry("bag")
    if nav then list[#list + 1] = entry("pokenav") end
    list[#list + 1] = entry("trainer")
    list[#list + 1] = entry("save")
    kind = "normal"
  end
  list[#list + 1] = entry("option")
  list[#list + 1] = entry("exit")
  return list, kind
end

-- pokeemerald/src/script_menu.c:687
function Data.tutorialEntries(ctx)
  local entry = function(id) return Data.entry(id, ctx) end
  return {
    entry("pokedex"),
    entry("pokemon"),
    entry("bag"),
    entry("pokenav"),
    entry("trainer"),
    entry("save"),
    entry("option"),
    entry("exit"),
  }, "tutorial"
end

-- pokeemerald/src/start_menu.c:408
function Data.extraWindow(kind, ctx)
  if kind == "safari" then
    return { left = 1, top = 1, width = 9, height = 4, key = "gText_SafariBallStock",
      vars = { string.format("%2d", ctx.safariBalls()) } }
  end
  if kind == "pyramid" then
    local floor = ctx.pyramidFloor()
    -- pokeemerald/src/start_menu.c:150
    local names = { "gText_Floor1", "gText_Floor2", "gText_Floor3", "gText_Floor4",
      "gText_Floor5", "gText_Floor6", "gText_Floor7", "gText_Peak" }
    local peak = floor >= 7
    return { left = 1, top = 1, width = peak and 12 or 10, height = 4, key = "gText_BattlePyramidFloor",
      vars = { RomText.plain(names[math.min(floor, 7) + 1]) } }
  end
  return nil
end

-- pokeemerald/src/menu.c:490
Data.window = { left = 22, top = 1, width = 7 }
-- pokeemerald/src/start_menu.c:462
Data.textX, Data.textY, Data.rowPitch = 8, 9, 16

-- pokeemerald/src/start_menu.c:612
Data.dexNeedsSeen = true
Data.exitConfirms = true

return Data
