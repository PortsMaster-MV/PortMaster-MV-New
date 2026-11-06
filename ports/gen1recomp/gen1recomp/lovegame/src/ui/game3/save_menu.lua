-- FRLG Save confirm dialog (start_menu save path matching pret start_menu.c).
-- Features:
-- 1. Top-left Save Stats Window (1, 1, 14, 9): Location header, Player, Badges, Pokédex, Time.
-- 2. Bottom Dialogue Window (2, 15, 26, 4): "Would you like to save...", "SAVING...", "[Player] saved the game."
-- 3. Right YES/NO Window (21, 9, 6, 4).

local Stack = require("src.ui.game3.stack")
local Window = require("src.ui.game3.window")
local Chrome = require("src.ui.game3.chrome")
local FrlgFont = require("src.ui.game3.frlg_font")
local MapSectionsExtract = require("src.import.gba.map_sections_extract")
local Strings = require("src.core.Strings")
local RomText = require("src.core.game3.rom_text")
local Flags = require("src.core.game3.scripting.flags")
local Dex = require("src.core.game3.dex")

local SaveMenu = { isMenu = true }

SaveMenu.open = false
SaveMenu.cursor = 1 -- 1=YES 2=NO
SaveMenu._phase = "confirm" -- confirm | overwrite | saving | saved | save_failed
SaveMenu._error = nil -- reason the last write failed, for the log
SaveMenu._session = nil
SaveMenu._game = nil
SaveMenu._onClose = nil

local function se(id)
  pcall(function() require("src.core.game3.audio").playSe(require("src.core.game3.se_ids").resolve(id)) end)
end

function SaveMenu.flagStore(session)
  local Space = package.loaded["src.core.game3.scripting.space"]
  local live = Space and Space.getStore and Space.getStore()
  if type(live) == "table" and type(live.flags) == "table" then return live end
  if type(session) ~= "table" then return { flags = {} } end
  if type(session.store) == "table" and type(session.store.flags) == "table" then
    return session.store
  end
  return { flags = type(session.flags) == "table" and session.flags or {} }
end

-- pokefirered/src/save_menu_util.c:44
function SaveMenu.countBadges(session)
  return Flags.countBadges(SaveMenu.flagStore(session))
end

-- pokefirered/src/save_menu_util.c:25
function SaveMenu.countDex(session)
  local dex = type(session) == "table" and session.dex or nil
  if SaveMenu.layout(session) == "rse" then
    -- pokeemerald/src/menu.c:2122
    local st = SaveMenu.flagStore(session)
    return Dex.summaryCount({ version = session.version, dex = dex, flags = st.flags, vars = st.vars })
  end
  if type(dex) ~= "table" then return tonumber(session and session.caughtMonsCount) or 0 end
  local national = false
  local okP, PokedexData = pcall(require, "src.core.game3.pokedex_data")
  if okP and PokedexData and PokedexData.isNationalUnlocked then
    local ok, on = pcall(PokedexData.isNationalUnlocked, session, dex)
    national = ok and on == true
  end
  return Dex.countCaught(dex, national and "national" or "kanto")
end

-- pokefirered/src/start_menu.c:984
function SaveMenu.hasDex(session)
  local id = require("src.ui.game3.screens").flags(session).IDS.SYS_POKEDEX_GET
  return id ~= nil and Flags.getFlag(SaveMenu.flagStore(session), nil, id) == true
end

function SaveMenu.layout(session)
  local ok, Profile = pcall(require, "src.core.game3.profile")
  local row = ok and Profile.forSession(session) or nil
  local ui = row and type(row.ui) == "table" and row.ui or nil
  return ui and ui.saveMenu or "frlg"
end

local function saveExists(session)
  local ok, raw = pcall(require("src.core.SaveData").load, session and session.version)
  return ok and type(raw) == "table"
end

function SaveMenu.show(opts)
  opts = opts or {}
  SaveMenu.open = true
  SaveMenu.cursor = 1
  SaveMenu._phase = "confirm"
  SaveMenu._rse = SaveMenu.layout(opts.session) == "rse"
  SaveMenu._timer = nil
  SaveMenu._error = nil
  SaveMenu._session = opts.session
  SaveMenu._game = opts.game
  SaveMenu._onClose = opts.onClose
  Stack.push("save", SaveMenu, { hideBelow = true })
  -- pokefirered/src/start_menu.c:605
end

function SaveMenu.close()
  SaveMenu.open = false
  Stack.pop("save")
  local cb = SaveMenu._onClose
  SaveMenu._onClose = nil
  if cb then cb() end
end

function SaveMenu.isOpen()
  return SaveMenu.open
end

function SaveMenu.move(delta)
  if SaveMenu._phase ~= "confirm" and SaveMenu._phase ~= "overwrite" then return end
  SaveMenu.cursor = SaveMenu.cursor == 1 and 2 or 1
  se("SE_SELECT")
end

local function do_save()
  SaveMenu._phase = "saving"
  local Runtime = require("src.core.game3.runtime")
  local Bridge = require("src.core.game3.bridge")
  local game = Runtime._game
  local mod = Runtime._mod

  -- A write that did not happen must not be reported as one.  Neither call
  -- signals success by itself: persistSessionOnly returns nothing useful, and
  -- saveGame returns false for a refused write and nil for a deliberate no-op
  -- (no session / quest-log phase).  Treat a raise, an explicit false, or an
  -- absent saveGame as failure.
  local failure = nil
  if SaveMenu._rse then
    -- pokeemerald/src/start_menu.c:1091
    require("src.core.game3.rse.init").call("pyramid", "pause", nil, nil, SaveMenu._session)
  end
  if game and mod and Bridge and type(Bridge.persistSessionOnly) == "function" then
    local ok, err = pcall(Bridge.persistSessionOnly, mod, game)
    if not ok then failure = "sidecar persist failed: " .. tostring(err) end
  end
  if not failure then
    if game and type(game.saveGame) == "function" then
      local ok, written = pcall(game.saveGame, game)
      if not ok then
        failure = "saveGame raised: " .. tostring(written)
      elseif not written then
        failure = "saveGame did not confirm a write (" .. tostring(written) .. ")"
      end
    else
      failure = "no saveGame available"
    end
  end

  if failure then
    SaveMenu._phase = "save_failed"
    SaveMenu._error = failure
    pcall(function() require("src.core.Logger").warn("[save] %s", failure) end)
    return
  end

  se("SE_SAVE")
  SaveMenu._phase = "saved"
  -- pokeemerald/src/start_menu.c:1086
  if SaveMenu._rse then SaveMenu._timer = 60 end
end

-- pokeemerald/src/start_menu.c:1123
function SaveMenu.update()
  if not (SaveMenu.open and SaveMenu._rse) then return end
  if SaveMenu._phase == "saving_msg" then
    SaveMenu._phase = "saving"
    do_save()
    return
  end
  if SaveMenu._phase == "saved" and SaveMenu._timer then
    SaveMenu._timer = SaveMenu._timer - 1
    if SaveMenu._timer <= 0 then
      SaveMenu._timer = nil
      SaveMenu.confirm()
    end
  end
end

function SaveMenu.confirm()
  if SaveMenu._phase == "save_failed" then
    -- The dialog stays up so the failure is readable; dismissing it returns
    -- to the start menu so the player can retry.
    SaveMenu.close()
    return
  end
  if SaveMenu._phase == "saved" then
    SaveMenu.close()
    local StartMenu = require("src.ui.game3.start_menu")
    if StartMenu.isOpen() then StartMenu.close(true) end -- pokefirered/src/start_menu.c:583
    return
  end
  if SaveMenu._phase == "saving" or SaveMenu._phase == "saving_msg" then
    return
  end

  if SaveMenu.cursor == 1 and SaveMenu._rse then
    se("SE_SELECT")
    if SaveMenu._phase == "confirm" and saveExists(SaveMenu._session) then
      -- pokeemerald/src/start_menu.c:1003
      SaveMenu._phase = "overwrite"
      SaveMenu.cursor = 1
    else
      -- pokeemerald/src/start_menu.c:1080
      SaveMenu._phase = "saving_msg"
    end
  elseif SaveMenu.cursor == 1 then -- YES
    if SaveMenu._phase == "confirm" then
      -- If there is an active save file, ask overwrite confirm
      SaveMenu._phase = "overwrite"
      SaveMenu.cursor = 1
      se("SE_SELECT")
    elseif SaveMenu._phase == "overwrite" then
      do_save()
    end
  else -- NO
    se("SE_SELECT") -- pokefirered/src/menu.c:376
    SaveMenu.close()
  end
end

function SaveMenu.cancel()
  if SaveMenu._phase == "saved" then
    if SaveMenu._rse then return end
    SaveMenu.confirm()
    return
  end
  if SaveMenu._phase == "saving" or SaveMenu._phase == "saving_msg" then
    return
  end
  SaveMenu.close()
end

-- pret resolves the header through save_menu_util.c SAVE_STAT_LOCATION ->
-- GetMapNameGeneric(dest, gMapHeader.regionMapSectionId) -> region_map.c
-- GetMapName(dst, mapsec, 0), i.e. the sMapNames place name and never the
-- engine's internal map id (which is what session.map holds).
-- pokeemerald/src/menu.c:2135
local function rseLocationName(session)
  local sec = require("src.core.game3.pokemon").currentMapSec(session)
  local pack = require("src.ui.game3.rse.scene_kit").loadLua("data/generated/gba/region_map/map_sections.lua")
  local row = sec and pack and pack.sections and pack.sections[sec]
  return row and row.name or ""
end

function SaveMenu.locationName(session)
  session = session or {}
  if SaveMenu.layout(session) == "rse" then return rseLocationName(session) end
  if type(session.mapName) == "string" and session.mapName ~= "" and not session.mapName:find("^FR_") and not session.mapName:find("^SEVII_") then
    return session.mapName:upper()
  end
  local mapId = session.map
  local Runtime = package.loaded["src.core.game3.runtime"]
  local game = SaveMenu._game or (Runtime and Runtime._game)
  local def = mapId and game and game.data and game.data.maps and game.data.maps[mapId]
  local secId = session.regionMapSectionId or session.mapSec or (def and def.regionMapSectionId)
  -- floorNum 0: save_menu_util.c passes fill = 0, like map_name_popup.c.
  local info = MapSectionsExtract.getInfo(secId, mapId, 0)
  if info and info.resolved and type(info.name) == "string" and info.name ~= "" then
    return (info.rawName or info.name):upper()
  end
  if info and type(info.name) == "string" and info.name ~= "" and info.name ~= "PALLET TOWN" then
    return (info.rawName or info.name):upper()
  end
  -- Not a map we can identify (a mod's map, or one with no header data): show
  -- a readable form of the id rather than getInfo's Pallet Town placeholder.
  return tostring(mapId or "PALLET TOWN"):gsub("^FR_", ""):gsub("^SEVII_", ""):gsub("_", " "):upper()
end

-- pret prints every stat value at one x (56 px into the window, labels at 4).
-- A translated label can be wider than the English one the column was placed
-- for ("DUREE JEU", "SPIELZEIT"), so push the column past the widest label,
-- keeping the English gap.
local VALUE_X = 56
local VALUE_GAP = VALUE_X - 4 - 42 -- 42 = width of "POKéDEX", the widest US label

function SaveMenu.valueX(labels)
  local x = VALUE_X
  for _, label in ipairs(labels) do
    x = math.max(x, 4 + FrlgFont.measure(label) + VALUE_GAP)
  end
  return x
end

-- pokeemerald/src/start_menu.c:1332
local SAVE_BLUE = { fg = FrlgFont.STDPAL[8], shadow = FrlgFont.STDPAL[9], bg = FrlgFont.STDPAL[0] }
local SAVE_RED = { fg = FrlgFont.STDPAL[4], shadow = FrlgFont.STDPAL[5], bg = FrlgFont.STDPAL[0] }
local SAVE_GREEN = { fg = FrlgFont.STDPAL[6], shadow = FrlgFont.STDPAL[7], bg = FrlgFont.STDPAL[0] }

function SaveMenu.drawRse()
  local session = SaveMenu._session or {}
  local hasDex = SaveMenu.hasDex(session)
  local win = Window.template(1, 1, 14, hasDex and 10 or 8)
  Window.stdFrame(win)
  local x0, y0 = win.left * 8, win.top * 8
  local color = (session.gender == 1 or session.playerGender == 1) and SAVE_RED or SAVE_BLUE
  local NORMAL = FrlgFont.COLOR.NORMAL
  local function row(y, labelKey, value)
    FrlgFont.draw(RomText.plain(labelKey), x0, y0 + y, { colors = NORMAL })
    FrlgFont.draw(value, x0 + 0x70 - FrlgFont.measure(value), y0 + y, { colors = color })
  end
  FrlgFont.draw(Strings(SaveMenu.locationName(session)), x0, y0 + 1, { colors = SAVE_GREEN })
  row(17, "gText_SavingPlayer", tostring(session.name or session.playerName or ""))
  row(33, "gText_SavingBadges", tostring(SaveMenu.countBadges(session)))
  local y = 49
  if hasDex then
    row(y, "gText_SavingPokedex", tostring(SaveMenu.countDex(session)))
    y = y + 16
  end
  local pt = session.playtime or session.playTime or {}
  row(y, "gText_SavingTime", string.format("%d:%02d", tonumber(pt.hours or session.hours) or 0,
    tonumber(pt.minutes or session.minutes) or 0))

  Chrome.dialogueFrame()
  local left, top, width = Chrome.dialogueWindow()
  local key = ({ confirm = "gText_ConfirmSave", overwrite = "gText_AlreadySavedFile",
    saving_msg = "gText_SavingDontTurnOff", saving = "gText_SavingDontTurnOff", saved = "gText_PlayerSavedGame",
    save_failed = "gText_SaveError" })[SaveMenu._phase] or "gText_ConfirmSave"
  local msg
  local pyramid = SaveMenu._phase == "confirm" and require("src.core.game3.rse.init").system("pyramid")
  if pyramid and pyramid.inPyramid(session) then
    -- pokeemerald/src/start_menu.c:986
    msg = require("src.core.game3.scripting.text_ir").toPlain(pyramid.manifest().confirmRest.ir)
  else
    msg = RomText.plain(key, { playerName = tostring(session.name or session.playerName or "") })
  end
  FrlgFont.draw(FrlgFont.wrap(msg, width * 8), left * 8, top * 8 + 1,
    { maxWidth = width * 8, colors = NORMAL, linePitch = FrlgFont.linePitch() })

  if SaveMenu._phase == "confirm" or SaveMenu._phase == "overwrite" then
    -- pokeemerald/src/menu.c:98
    local yn = Window.template(21, 9, 5, 4)
    Window.stdFrame(yn)
    local yx, yy = yn.left * 8, yn.top * 8
    FrlgFont.draw(RomText.plain("gText_Yes"), yx + 8, yy + 1, { colors = NORMAL })
    FrlgFont.draw(RomText.plain("gText_No"), yx + 8, yy + 17, { colors = NORMAL })
    Window.cursorPx(yx, yy + 1 + (SaveMenu.cursor == 2 and 16 or 0))
  end
end

function SaveMenu.draw()
  if not SaveMenu.open then return end
  if SaveMenu._rse then return SaveMenu.drawRse() end
  local session = SaveMenu._session or {}
  local name = tostring(session.name or session.playerName or "")
  local map = Strings(SaveMenu.locationName(session))
  local labels = {
    RomText.plain("gSaveStatName_Player"), RomText.plain("gSaveStatName_Badges"),
    RomText.plain("gSaveStatName_Pokedex"), RomText.plain("gSaveStatName_Time"),
  }
  local valueX = 1 * 8 + SaveMenu.valueX(labels)
  local badges = SaveMenu.countBadges(session)
  local hasDex = SaveMenu.hasDex(session)
  local pt = session.playtime or session.playTime or {}
  local hours = tonumber(pt.hours or session.playTimeHours or session.hours) or 0
  local mins = tonumber(pt.minutes or session.playTimeMinutes or session.minutes) or 0

  -- 1. Top-Left Save Stats Box (pret sSaveStatsWindowTemplate at (1, 1, 14, 9))
  -- pokefirered/src/start_menu.c:971
  Window.fixedStdFrame(Window.template(1, 1, 14, 9))
  -- Location Header.  pret start_menu.c PrintSaveStats centres it in the
  -- 14-tile window: x = (112 - GetStringWidth(FONT_NORMAL, text)) / 2.
  local headerW = 14 * 8
  local mapW = FrlgFont.measure(map)
  local mapX = 1 * 8 + math.max(0, math.floor((headerW - mapW) / 2))
  FrlgFont.draw(map, mapX, 1 * 8 + 2, { maxWidth = headerW, colors = FrlgFont.COLOR.NORMAL })
  -- PLAYER
  FrlgFont.draw(labels[1], 1 * 8 + 4, 1 * 8 + 18, { colors = FrlgFont.COLOR.NORMAL })
  FrlgFont.draw(name, valueX, 1 * 8 + 18, { colors = FrlgFont.COLOR.NORMAL })
  -- BADGES
  FrlgFont.draw(labels[2], 1 * 8 + 4, 1 * 8 + 32, { colors = FrlgFont.COLOR.NORMAL })
  FrlgFont.draw(tostring(badges), valueX, 1 * 8 + 32, { colors = FrlgFont.COLOR.NORMAL })
  -- POKéDEX
  local timeY = 1 * 8 + 46
  if hasDex then
    FrlgFont.draw(labels[3], 1 * 8 + 4, 1 * 8 + 46, { colors = FrlgFont.COLOR.NORMAL })
    FrlgFont.draw(tostring(SaveMenu.countDex(session)), valueX, 1 * 8 + 46, { colors = FrlgFont.COLOR.NORMAL })
    timeY = 1 * 8 + 60
  end
  -- TIME
  FrlgFont.draw(labels[4], 1 * 8 + 4, timeY, { colors = FrlgFont.COLOR.NORMAL })
  FrlgFont.draw(string.format("%d:%02d", hours, mins), valueX, timeY, { colors = FrlgFont.COLOR.NORMAL })

  -- 2. Bottom Dialogue Window (pret WindowFunc_DrawDialogueFrame at (2, 15, 26, 4))
  Chrome.dialogueFrame()
  -- pokefirered/src/start_menu.c:715
  local msg = RomText.plain("gText_WouldYouLikeToSaveTheGame")
  if SaveMenu._phase == "overwrite" then
    -- pokefirered/src/start_menu.c:750
    msg = RomText.plain("gText_AlreadySaveFile_WouldLikeToOverwrite")
  elseif SaveMenu._phase == "saving" then
    -- pokefirered/src/start_menu.c:787
    msg = RomText.plain("gText_SavingDontTurnOffThePower")
  elseif SaveMenu._phase == "saved" then
    -- pokefirered/src/start_menu.c:810
    msg = RomText.plain("gText_PlayerSavedTheGame", { playerName = name })
  elseif SaveMenu._phase == "save_failed" then
    -- do_save refused to report success; say so instead of claiming a save.
    msg = Strings("The game could not be saved.")
  end
  FrlgFont.draw(msg, 2 * 8 + 4, 15 * 8 + 2, { linePitch = 15, colors = FrlgFont.COLOR.NORMAL })

  -- 3. Right YES/NO Window (pret sSaveStatsWindow / YesNo popup at (21, 9, 6, 4))
  if SaveMenu._phase == "confirm" or SaveMenu._phase == "overwrite" then
    local popX = 21
    local popY = 9
    local popW = 6
    local popH = 4
    Window.stdFrame(Window.template(popX, popY, popW, popH))
    local rowY1 = popY * 8 + 2
    local rowY2 = popY * 8 + 18
    local curY = (SaveMenu.cursor == 1) and rowY1 or rowY2
    Window.cursorPx(popX * 8 + 1, curY)
    FrlgFont.draw(RomText.plain("gText_Yes"), popX * 8 + 9, rowY1, { colors = FrlgFont.COLOR.NORMAL })
    FrlgFont.draw(RomText.plain("gText_No"), popX * 8 + 9, rowY2, { colors = FrlgFont.COLOR.NORMAL })
  end
end

return SaveMenu
