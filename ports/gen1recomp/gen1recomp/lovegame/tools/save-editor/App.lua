-- Save editor app shell.  Boots the game's generated Data plus a save file
-- and draws the chrome the design spec fixes (SaveEditor.dc.html): a version
-- rail, a title bar, a tab rail and a status bar, with one panel filling the
-- space between.  Panels own their tab's content; this module owns everything
-- around it.
--
-- The editor is reachable two ways and behaves the same in both:
--   * `love . --editor`      standalone window, Close quits
--   * Edit on a launcher save row (main.lua, embedded = true), Close returns
--     to the launcher with the slot list refreshed
--
-- Chrome reflows inside the platform safe area. Phones use a compact action
-- menu and popup page choosers; wide windows keep actions on one row. Each page
-- owns its scrolling viewport and slides with the launcher's navigation.

local Data = require("src.core.Data")
local SafeArea = require("src.core.SafeArea")
local TileRenderer = require("src.render.TileRenderer")
local SaveIO = require("SaveIO")
local Catalog = require("Catalog")
local State = require("State")
local Kit = require("Kit")
local Theme = require("Theme")
local Ops = require("Ops")
local Gen = require("Gen")
local PadInput = require("PadInput")
local Motion = require("Motion")
local Chooser = require("Chooser")
local PAL = Theme.PAL

local Party = require("Party")
local Boxes = require("Boxes")
local Items = require("Items")
local Events = require("Events")
local MapBrowser = require("MapBrowser")
local Dex = require("Dex")
-- chrome, not a tab panel, so deliberately kept out of PANELS below (#541)
local SpeciesPicker = require("SpeciesPicker")
local MovePicker = require("MovePicker")
local ItemPicker = require("ItemPicker")

local App = {}
local S
-- one loader per process: registries collide if a second load re-registers
-- vanilla records over an already-merged Data
local mods
local mouseClicked = false
-- Click position from the press event.  Kit samples the pointer in draw, so a
-- touch / mouse / pad-A click must use the event coords -- not love.mouse
-- (often stale on NX) and not the virtual cursor when a finger taps elsewhere.
local clickX, clickY
-- Wheel notches queued by App.wheelmoved since the last draw, handed to Kit
-- there like mouseClicked is: LOVE delivers events before love.draw, so a
-- notch is always spent by the frame that follows it (#595).
local TouchEditor = require("TouchEditor")
local wheelY = 0
local touch

-- Which game's cache Data was loaded from.  main.lua checks this before
-- opening the editor on a save from the other version, because the two
-- caches cannot both be mounted in one process (see CacheFs.mountVersion).
App.dataVersion = nil

local TABS = {
  { id = "party", glyph = "PT", label = "Party" },
  { id = "boxes", glyph = "BX", label = "Boxes" },
  { id = "items", glyph = "IT", label = "Items" },
  { id = "events", glyph = "EV", label = "Events" },
  { id = "map", glyph = "MP", label = "Map" },
  { id = "dex", glyph = "DX", label = "Pokédex" },
  { id = "trainer", glyph = "TR", label = "Trainer" },
  { id = "legality", glyph = "CK", label = "Checks" },
}

local PANELS = {
  party = Party,
  boxes = Boxes,
  items = Items,
  events = Events,
  map = MapBrowser,
  dex = Dex,
  trainer = require("Trainer"),
  legality = require("Checks"),
}

local function fileExists(path)
  local f = io.open(path, "rb")
  if f then
    f:close()
    return true
  end
  return false
end

-- Apply a load attempt for `path` into the current State (S must exist).
local function applyLoaded(path, statusVerb)
  statusVerb = statusVerb or "Loaded"
  Motion.reset()
  Kit.blur()
  S.path = path
  local existed = fileExists(path)
  local save, err = SaveIO.load(path)
  if save then
    S.save = save
    S.status = statusVerb .. " " .. path
    S.loadError = false
    S.allowSave = true
  elseif existed then
    S.save = Gen.newGame(S.version)
    S.status = "Corrupt save at "
      .. path
      .. " ("
      .. tostring(err)
      .. "),  Save disabled, use Reload after fixing the file"
    S.loadError = true
    S.allowSave = false
  else
    S.save = Gen.newGame(S.version)
    S.status = "No save at " .. path .. " (" .. tostring(err) .. "),  editing new game stub"
    S.loadError = false
    S.allowSave = true
  end
  if Gen.of(S.save, S.version) == 3 then
    S.events = Catalog.game3EventList(S.modRoots)
    S.game3Events = Catalog.game3Categories(S.modRoots)
  elseif Gen.of(S.save, S.version) == 2 then
    S.events = Catalog.gen2EventList(Gen.engineOf(S.save, S.version), S.modRoots)
  end
  local mapId = Gen.playerMap(S.save)
  S.mapId = mapId
  S.dirty = false
  S.undoStack, S.redoStack = {}, {}
  S.historyToken, S.historySavedToken = 0, 0
  S.revision = (S.revision or 0) + 1
  S.speciesPicker, S.movePicker, S.itemPicker = nil, nil, nil
  S.formMon, S.nicknameMon = nil, nil
  S.monDrafts, S.trainerDrafts, S.walletDrafts = {}, {}, {}
  S.propertyChoice, S.itemMenu = nil, nil
  S.navPopup, S.editPopup = nil, nil
  S._listState = nil
  S.mobileInspector = nil
  S._quitArmed = false
  S._openArmed = false
  S.editingMon = nil
  Ops.disarm(S)
  local prepared, prepareError = pcall(function()
    Gen.ensureBoxes(S.save)
    Gen.hydrateSave(Data, S.save)
  end)
  if not prepared then
    S.loadError, S.allowSave = true, false
    S.status = "Save disabled: " .. tostring(prepareError)
    return
  end
  local probe = require("src.mods.Merge").deepCopy(S.save)
  S.validation = Gen.validate(probe, Data)
  if not Gen.emptyReport(S.save, S.validation) then
    if Gen.of(S.save, S.version) == 2 then
      S.status = S.status
        .. string.format(
          ",  game would quarantine: %d script bytes, %d mail, %d events",
          #(S.validation.lostScriptMem or {}),
          #(S.validation.lostMail or {}),
          #(S.validation.lostEvents or {})
        )
    elseif Gen.of(S.save, S.version) ~= 3 then
      S.status = S.status
        .. string.format(
          ",  game would quarantine: %d mons, %d items, %d maps",
          #S.validation.lostMons,
          #S.validation.lostItems,
          #S.validation.remappedMaps
        )
    end
  end
end

-- pathOverride lets tests point App.load at a scratch file instead of the
-- real default save path (used to exercise the corrupt-save branch below).
-- opts carries what only the launcher knows: which game the save belongs to,
-- its slot id, and where Close should go back to.
function App.load(pathOverride, opts)
  opts = opts or {}
  Motion.reset()
  local transition = require("src.ui.kit.Transition")
  local okMotion, motionOptions = pcall(function()
    return require("src.core.SaveData").loadOptions()
  end)
  transition.reduceMotion = opts.reduceMotion == true
    or os.getenv("POKEPORT_REDUCE_MOTION") == "1"
    or (okMotion and type(motionOptions) == "table" and motionOptions.reduceMotion == true)
    or transition.reduceMotion
  S = State.new()
  S.data = Data
  S.version = opts.version
  S.slotId = opts.slotId
  S.embedded = opts.embedded or false
  S.onClose = opts.onClose
  if opts.version then
    require("src.core.GameVersion").set(opts.version)
  end
  if
    (Gen.of(nil, opts.version) == 3 or require("src.core.GameVersion").generation() == 3)
    and not Gen.game3CacheReady()
  then
    S.path = pathOverride or SaveIO.defaultPath()
    S.missingCache = Gen.missingCacheMessage(opts.version)
    S.status = S.missingCache
    S.loadError, S.allowSave = true, false
    return
  end
  -- the same mod set the game loads, merged into Data before the catalogs
  -- build, so modded species/items/moves are editable and MonOps stops
  -- asserting on them
  if not mods or App.dataVersion ~= opts.version then
    -- One loader per editor session.  A previous session leaves Data holding
    -- that session's merged registries (and possibly the other game's cache),
    -- and a second builtin registration over them collides -- "statuses
    -- already registered: FRZ".  _pristineKeys only exists once Data has been
    -- loaded at least once, so it doubles as the "needs evicting" marker.
    if Data._pristineKeys then
      Data:unloadGenerated()
    end
    Data:load()
    if Gen.of(nil, opts.version) == 3 or require("src.core.GameVersion").generation() == 3 then
      Gen.bindGame3Data(Data)
    elseif Gen.of(nil, opts.version) == 2 or require("src.core.GameVersion").generation() == 2 then
      Gen.bindGoldData(Data)
    end
    local ModLoader = require("src.mods.Loader")
    mods = ModLoader.new()
    mods:load(Data)
    App.dataVersion = opts.version
  end
  S.mods = mods
  S.cat = Catalog.build(Data)
  local modRoots = {}
  for _, mod in ipairs(S.mods:status().loaded) do
    modRoots[#modRoots + 1] = mod.path
  end
  S.modRoots = modRoots
  if Gen.of(nil, opts.version) == 3 or require("src.core.GameVersion").generation() == 3 then
    S.events = Catalog.game3EventList(modRoots)
  elseif Gen.of(nil, opts.version) == 2 or require("src.core.GameVersion").generation() == 2 then
    S.events = Catalog.gen2EventList(Gen.engineOf(nil, opts.version), modRoots)
  else
    S.events =
      Catalog.scrapeEvents("data/scripts", "data/generated/trainer_headers.lua", nil, modRoots)
  end
  applyLoaded(pathOverride or SaveIO.defaultPath(), "Loaded")
end

-- Switch to another save file (Open button, drag-drop, or --save arg).
-- If there are unsaved edits, the first call arms a confirm; call again
-- (or pass force=true) to discard and open.
function App.openPath(path, force)
  if not path or path == "" then
    return false
  end
  if not S or S.missingCache then
    return false
  end
  if S.dirty and not force and not S._openArmed then
    S._openArmed = true
    S.status = "Unsaved changes,  open again to discard and load " .. path
    return false
  end
  applyLoaded(path, "Opened")
  return true
end

function App.chooseAndOpen()
  local path = SaveIO.choosePath()
  if path then
    App.openPath(path)
  else
    local osName = love and love.system and love.system.getOS and love.system.getOS()
    if osName ~= "OS X" and osName ~= "Windows" and osName ~= "Linux" then
      S.status = "File picker unavailable,  drop a save.lua onto the window"
    end
  end
end

function App.filedropped(file)
  if not (file and S) then
    return
  end
  local path = file.getFilename and file:getFilename() or nil
  if not path or path == "" then
    S.status = "Could not read dropped file path"
    return
  end
  App.openPath(path)
end

-- Test hook: App.load keeps its state in a module-local so headless tests
-- can drive App.load/App.draw against a scratch path and then inspect the
-- resulting flags/status without loving a real save file.
function App.getState()
  return S
end

-- Tear the editor down far enough that a later App.load rebuilds from
-- scratch.  main.lua calls this after Close so the next Edit -- possibly on
-- the other game's save -- re-runs Data:load against whatever cache is
-- mounted by then, instead of reusing this session's merged registries.
function App.unload()
  Motion.reset()
  touch = nil
  Kit.touchDown, Kit.ignoreMouseDown = nil, nil
  Kit._touchDrag, Kit._pointerDrag, Kit._tapPending, Kit._dragDelta = nil, nil, nil, 0
  S = nil
  mods = nil
  App.dataVersion = nil
  -- Kit is never evicted from package.loaded, so a Close taken while a text
  -- field still owns focus would leak Kit.focus and a raised soft keyboard
  -- (against a rect that is gone) into the launcher and the next session
  -- (#529).  A Close taken on the frame the species picker went up would
  -- likewise leave its modal shield raised, and the next session would open
  -- deaf to every click (#541).
  Kit.blur()
  Kit.blockClicks = false
  PadInput.reset()
end

local function cycleTab(delta)
  if not S then
    return
  end
  local idx = 1
  for i, t in ipairs(TABS) do
    if t.id == S.tab then
      idx = i
      break
    end
  end
  idx = ((idx - 1 + delta) % #TABS) + 1
  Motion.change(S, "tab", TABS[idx].id, delta)
  Ops.say(S, "Tab: " .. TABS[idx].label)
end

-- Pad / Joy-Con actions from PadInput.gamepadpressed (A/B via GamepadMap so
-- NX physical A confirms and B closes).
local function handlePadAction(action)
  if not action or not S then
    return
  end
  if action == "a" then
    local mx, my = PadInput.pointer()
    App.mousepressed(mx, my, 1)
  elseif action == "b" then
    if S.editPopup then
      TouchEditor.close(S, Kit)
    elseif S.navPopup then
      Chooser.close(S)
    else
      App.close()
    end
  elseif action == "tab_prev" then
    if S.editPopup then
      TouchEditor.keypressed(S, Kit, S.editPopup.mode == "number" and "left" or "up")
    elseif S.navPopup then
      Chooser.keypressed(S, "up")
    else
      cycleTab(-1)
    end
  elseif action == "tab_next" then
    if S.editPopup then
      TouchEditor.keypressed(S, Kit, S.editPopup.mode == "number" and "right" or "down")
    elseif S.navPopup then
      Chooser.keypressed(S, "down")
    else
      cycleTab(1)
    end
  end
end

function App.save()
  if S.missingCache then
    return Ops.say(S, S.missingCache)
  end
  if not S.allowSave then
    return Ops.say(S, "Save disabled,  corrupt save loaded; fix the file and Reload first")
  end
  local output = S.save
  if Gen.ofState(S) == 3 then
    local prepared, result = pcall(require("Game3Adapter").export, S.save)
    if not prepared then
      S.status = "Save failed: " .. tostring(result)
      return false
    end
    output = result
  end
  local ok, err = SaveIO.save(S.path, output)
  if ok then
    S.dirty = false
    S.historySavedToken = S.historyToken or 0
    S._quitArmed = false
    Ops.disarm(S)
    S.status = "Saved " .. S.path
    return true
  end
  S.status = "Save failed: " .. tostring(err)
  return false
end

function App.reload()
  if S.missingCache then
    return Ops.say(S, S.missingCache)
  end
  local save, err = SaveIO.load(S.path)
  if save then
    applyLoaded(S.path, "Reloaded")
    return not S.loadError
  end
  S.status = "Reload failed: " .. tostring(err)
  return false
end

-- Close: back to the launcher when hosted there, otherwise quit.  Unsaved
-- edits arm a confirm exactly like Open does, so leaving can't lose work.
--
-- The teardown itself is DEFERRED to the end of the frame (App.draw calls
-- finishClose below).  Close is dispatched from inside drawTitleBar, and the
-- host's onClose runs App.unload, which drops S -- doing that inline left the
-- rest of the frame drawing against a nil state.
function App.close()
  if not S then
    return false
  end
  if S.dirty and not S._quitArmed then
    S._quitArmed = true
    S.status = "Unsaved changes,  Save first or click Close again to discard"
    return false
  end
  S._closeRequested = true
  return true
end

local function finishClose()
  local embedded, onClose = S.embedded, S.onClose
  S._closeRequested = false
  if embedded and onClose then
    onClose()
  elseif love and love.event then
    love.event.quit()
  end
end

function App.update(dt)
  -- Immediate-mode UI: nothing to simulate per-frame; input is sampled
  -- directly in App.draw() via Kit.beginFrame. Tile animation (water,
  -- flowers) still needs ticking so the Map tab isn't static.
  TileRenderer.tick()
  PadInput.update(dt)
  local notches = PadInput.takeWheel()
  if notches ~= 0 then
    App.wheelmoved(0, notches)
  end

  -- Dev harness, the launcher's POKEPORT_LAUNCHER_SHOT for this window:
  -- POKEPORT_EDITOR_SHOT=/path.png with POKEPORT_WIN=WxH resizes, lets the
  -- view settle, captures one frame and quits, so a scripted run can see the
  -- real editor at any window shape.  POKEPORT_EDITOR_TAB picks the tab and
  -- POKEPORT_EDITOR_ITEMPICK=1 opens the add-item modal.
  local shot = os.getenv("POKEPORT_EDITOR_SHOT")
  if shot and not App._shotDone then
    if not App._shotSized then
      App._shotSized = true
      local w, h = (os.getenv("POKEPORT_WIN") or ""):match("^(%d+)x(%d+)$")
      if w and love.window and love.window.setMode then
        pcall(love.window.setMode, tonumber(w), tonumber(h), { resizable = true })
      end
      local tab = os.getenv("POKEPORT_EDITOR_TAB")
      if tab and tab ~= "" and S then
        S.tab = tab
      end
      local monSlot = tonumber(os.getenv("POKEPORT_EDITOR_MON") or "")
      if monSlot and S and S.save and S.save.party then
        S.editingMon = S.save.party[monSlot]
      end
      if os.getenv("POKEPORT_EDITOR_ITEMPICK") == "1" and S then
        Ops.openItemPicker(S, Kit, "bag")
      end
    end
    App._shotTimer = (App._shotTimer or 0) + dt
    if App._shotTimer > 1.0 then
      App._shotDone = true
      love.graphics.captureScreenshot(function(imagedata)
        local fd = imagedata:encode("png")
        local f = io.open(shot, "wb")
        if f then
          f:write(fd:getString())
          f:close()
        end
        love.event.quit()
      end)
    end
  end
end

function App.mousepressed(x, y, button)
  if touch then
    return
  end
  if button == 1 then
    mouseClicked = true
    clickX, clickY = x, y
    -- A finger / mouse tap yields the virtual cursor so the click lands where
    -- the event said, not under the Joy-Con pointer (NX touch soft-miss).
    PadInput.yieldToPointer()
  end
end

function App.touchpressed(id, x, y)
  if S and MapBrowser.touchpressed(S, id, x, y) then
    if touch then touch.moved = true end
    Kit.blur()
    return
  end
  if touch then
    return
  end
  touch = { id = id, x = x, y = y, startX = x, startY = y, moved = false }
  Kit.touchDown = true
  Kit.ignoreMouseDown = true
  Kit._pointerDrag, Kit._tapPending = nil, nil
  Kit._touchDrag = { x = x, startY = y }
  Kit._dragDelta = 0
  PadInput.yieldToPointer()
end

function App.touchmoved(id, x, y)
  local pinched = S and MapBrowser.touchmoved(S, id, x, y)
  if pinched and touch then touch.moved = true end
  if not touch or touch.id ~= id then
    return
  end
  local lastY = touch.y
  touch.x, touch.y = x, y
  if math.abs(x - touch.startX) + math.abs(y - touch.startY) > 10 then
    touch.moved = true
  end
  if touch.moved and not pinched then
    Kit.dragAdd(lastY - y)
  end
end

function App.touchreleased(id, x, y)
  App.touchmoved(id, x, y)
  local pinched = S and MapBrowser.touchreleased(S, id)
  if not touch or touch.id ~= id then
    return
  end
  if pinched then
    local nextId, point = next(S._mapTouches)
    if nextId then
      touch = { id = nextId, x = point.x, y = point.y, startX = point.x, startY = point.y, moved = true }
      Kit._touchDrag = { x = point.x, startY = point.y }
      return
    end
  end
  if not touch.moved then
    mouseClicked, clickX, clickY = true, x, y
  end
  touch = nil
  Kit.touchDown = false
  Kit.ignoreMouseDown = true
end

function App.textinput(text)
  Kit.textinput(text)
end

function App.gamepadpressed(joystick, button)
  handlePadAction(PadInput.gamepadpressed(joystick, button))
end

function App.gamepadreleased(joystick, button)
  PadInput.gamepadreleased(joystick, button)
end

function App.gamepadaxis(joystick, axis, value)
  PadInput.gamepadaxis(joystick, axis, value)
end

function App.joystickpressed(joystick, button)
  handlePadAction(PadInput.joystickpressed(joystick, button))
end

function App.joystickreleased(joystick, button)
  PadInput.joystickreleased(joystick, button)
end

function App.joystickaxis(joystick, axis, value)
  PadInput.joystickaxis(joystick, axis, value)
end

function App.joystickhat(joystick, hat, direction)
  PadInput.joystickhat(joystick, hat, direction)
end

-- ------------------------------------------------------------------ chrome
-- Compact action row, with file identity above it when height allows.
local function drawTitleBar(x, y, w, h)
  local pad, gap, row = 12 * Kit.scale, 8 * Kit.scale, Kit.controlH()
  local inner = w - 2 * pad
  if not S.compactChrome and not Kit.desktop then
    Kit.text(
      "tab",
      "SAVE EDITOR" .. (S.version and (" / " .. S.version:upper()) or ""),
      x + pad,
      y + 8 * Kit.scale,
      PAL.heading
    )
    Kit.text(
      "tiny",
      Kit.ellipsize("tiny", (S.dirty and "UNSAVED  " or "SAVED  ") .. (S.path or "New save"), inner),
      x + pad,
      y + Kit.textHeight("tab") + 12 * Kit.scale,
      S.dirty and PAL.yellow or PAL.caption
    )
  end
  local narrow = w < 600 * Kit.scale and not S.compactChrome
  local cols = narrow and 4 or 6
  local bw = (inner - (cols - 1) * gap) / cols
  local by = S.compactChrome and (y + 8 * Kit.scale)
    or (y + Kit.textHeight("tab") + Kit.textHeight("tiny") + 20 * Kit.scale)
  local saveInk = S.allowSave and S.dirty and PAL.green or PAL.muted
  local actions = {
    {
      S.allowSave and (S.dirty and "Save" or "Saved") or "Save locked",
      "ghost",
      function()
        App.save()
      end,
      S.dirty or not S.allowSave,
      {
        face = "invert",
        ink = saveInk,
        stroke = saveInk,
        icon = S.allowSave and "save" or "lock",
      },
    },
    {
      "Undo",
      "ghost",
      function()
        require("History").undo(S)
      end,
      S.undoStack and #S.undoStack > 0,
    },
    {
      "Redo",
      "ghost",
      function()
        require("History").redo(S)
      end,
      S.redoStack and #S.redoStack > 0,
    },
    {
      "Reload",
      "ghost",
      function()
        App.reload()
      end,
      true,
    },
    {
      "Open",
      "accent",
      function()
        App.chooseAndOpen()
      end,
      true,
    },
    {
      S._quitArmed and "Discard?" or "Close",
      S._quitArmed and "danger" or "ghost",
      function()
        App.close()
      end,
      true,
    },
  }
  local function actionOptions(action)
    local opts = action[5] or {}
    opts.kind, opts.enabled, opts.font = action[2], action[4], "small"
    return opts
  end
  if Kit.desktop then
    local widths, total = {}, 5 * gap
    for i, action in ipairs(actions) do
      widths[i] = Kit.buttonWidth(action[1], actionOptions(action), row)
      if i == 1 then
        widths[i] = math.max(widths[i], Kit.buttonWidth("Save locked", { font = "small", icon = "lock" }, row))
      elseif i == 6 then
        widths[i] = math.max(widths[i], Kit.buttonWidth("Discard?", { font = "small" }, row))
      end
      total = total + widths[i]
    end
    local bx, by = x + w - pad - total, y + 8 * Kit.scale
    local identityW = bx - gap - (x + pad)
    local labelH, pathH = Kit.textHeight("tab"), Kit.textHeight("tiny")
    local ty = by + (row - labelH - pathH - 4 * Kit.scale) / 2
    Kit.text("tab", Kit.ellipsize("tab", "SAVE EDITOR" .. (S.version and (" / " .. S.version:upper()) or ""), identityW), x + pad, ty, PAL.heading)
    Kit.text("tiny", Kit.ellipsize("tiny", (S.dirty and "UNSAVED  " or "SAVED  ") .. (S.path or "New save"), identityW), x + pad, ty + labelH + 4 * Kit.scale, S.dirty and PAL.yellow or PAL.caption)
    for i, action in ipairs(actions) do
      if Kit.button(bx, by, widths[i], row, action[1], actionOptions(action)) then action[3]() end
      bx = bx + widths[i] + gap
    end
    return
  end
  if narrow then
    local more = {
      S.chromeMenu and "Less" or "More",
      "ghost",
      function()
        S.chromeMenu = not S.chromeMenu
        Kit.blur()
      end,
      true,
    }
    local primary = { actions[1], actions[2], actions[3], more }
    for i, a in ipairs(primary) do
      if Kit.button(x + pad + (i - 1) * (bw + gap), by, bw, row, a[1], actionOptions(a)) then
        a[3]()
      end
    end
    if S.chromeMenu then
      local menuW = (inner - 2 * gap) / 3
      for i = 4, 6 do
        local a = actions[i]
        if
          Kit.button(
            x + pad + (i - 4) * (menuW + gap),
            by + row + gap,
            menuW,
            row,
            a[1],
            actionOptions(a)
          )
        then
          a[3]()
        end
      end
    end
    return
  end
  for i, a in ipairs(actions) do
    if
      Kit.button(
        x + pad + (i - 1) % cols * (bw + gap),
        by + math.floor((i - 1) / cols) * (row + gap),
        bw,
        row,
        a[1],
        actionOptions(a)
      )
    then
      a[3]()
    end
  end
end

local function drawTabRail(x, y, w, h)
  local pad, row = 12 * Kit.scale, Kit.controlH()
  Chooser.navigation(
    S,
    Kit,
    "tab",
    "Save editor page",
    TABS,
    x + pad,
    y,
    math.min(w - 2 * pad, (Kit.desktop and 240 or 360) * Kit.scale),
    row,
    function()
      S.mobileInspector = false
      S.chromeMenu, S.itemMenu = false, nil
    end
  )
end

local function drawStatusBar(x, y, w, h)
  local s = Kit.scale
  local pad = 22 * s
  Theme.col(PAL.bgBot, 0.6)
  love.graphics.rectangle("fill", x, y, w, h)
  Theme.col(PAL.cardBorder, 0.22)
  love.graphics.rectangle("fill", x, y, w, 1)

  local ctrl = (love.system and love.system.getOS and love.system.getOS() == "OS X") and "Cmd"
    or "Ctrl"
  local hint = S.embedded
      and (ctrl .. "+S save . " .. ctrl .. "+R reload . Esc clear selection . Close returns to the launcher")
    or (
      ctrl
      .. "+S save . "
      .. ctrl
      .. "+R reload . Esc clear selection . arrows pan map . wheel scrolls lists"
    )
  -- The status message is the load-bearing half of this bar (every Ops verb
  -- narrates through it); the keyboard map is decoration.  On a phone the
  -- two used to overlap because the hint was drawn unconditionally and the
  -- status ellipsized against a negative budget (#715), so now the hint only
  -- draws when the status still keeps a readable share of the bar.
  local hintW = Kit.textWidth("tiny", hint)
  local avail = w - 2 * pad - hintW - 14 * s
  if avail >= 120 * s then
    Kit.textRight("tiny", hint, x + w - pad, y + (h - Kit.textHeight("tiny")) / 2, PAL.faint)
  else
    avail = w - 2 * pad
  end
  Kit.text(
    "mono",
    Kit.ellipsize("mono", S.status or "", avail),
    x + pad,
    y + (h - Kit.textHeight("mono")) / 2,
    PAL.detail
  )
end

function App.draw()
  -- Closing the editor unloads it, and the host may still deliver one more
  -- frame or a queued event before it re-routes; every entry point below
  -- tolerates that rather than indexing a torn-down state.
  if not S then
    return
  end
  local width, height = love.graphics.getDimensions()
  width = math.max(1, tonumber(width) or 1)
  height = math.max(1, tonumber(height) or 1)
  -- Usable chrome rect.  Background still fills the window so the notch /
  -- home-indicator bands stay the field colour; every button (Save first)
  -- lives inside the safe area, matching the launcher and Skin Studio (#917).
  local ox, oy, sw, sh = SafeArea.rect()
  ox = math.max(0, tonumber(ox) or 0)
  oy = math.max(0, tonumber(oy) or 0)
  sw = math.max(1, tonumber(sw) or width)
  sh = math.max(1, tonumber(sh) or height)
  Kit.layout(sw, sh)
  local s = Kit.scale
  if S.tab == "map" then
    local shape = sw .. "x" .. sh
    if S._mapFocusShape ~= shape then
      S._mapFocusShape = shape
      if not Kit.desktop and sw > sh and sh < 500 * s then S.mapFocused = true end
    end
  else
    S._mapFocusShape = nil
  end

  local mx, my = love.mouse.getPosition()
  local padX, padY, padOn = PadInput.pointer()
  if mouseClicked and clickX ~= nil then
    mx, my = clickX, clickY
  elseif touch then
    mx, my = touch.x, touch.y
  elseif padOn then
    mx, my = padX, padY
  end
  Motion.update()
  Kit.beginFrame(mx, my, mouseClicked, wheelY)
  mouseClicked = false
  clickX, clickY = nil, nil
  wheelY = 0
  -- Modal shield.  Kit has no z-order, so the picker cannot simply be drawn
  -- last: the chrome and the panel underneath would take the same tap.  The
  -- shield goes up before anything dispatches and comes down only for the
  -- picker's own layer at the bottom of this function (#541).
  Kit.blockClicks = (S.speciesPicker ~= nil)
    or (S.itemPicker ~= nil)
    or (S.movePicker ~= nil)
    or (S.navPopup ~= nil)
    or (S.editPopup ~= nil)
    or Motion.active()
  if S.tab ~= "map" or Kit.blockClicks then MapBrowser.clearTouches(S) end

  Theme.field(width, height)

  if S.missingCache then
    Theme.versionRail(ox, oy, sw, 6 * s)
    local pad = 22 * s
    local ty = oy + sh / 2 - 60 * s
    for line in (S.missingCache .. " "):gmatch("(.-%.)%s+") do
      Kit.textCenter("button", line, ox + pad, ty, sw - 2 * pad, PAL.heading)
      ty = ty + Kit.textHeight("button") + 8 * s
    end
    local label = "Close"
    local bw = 22 * s + Kit.textWidth("button", label)
    if Kit.button(ox + (sw - bw) / 2, ty + 40 * s, bw, 38 * s, label, { kind = "ghost" }) then
      App.close()
    end
    Kit.endFrame()
    PadInput.draw()
    if S._closeRequested then
      finishClose()
    end
    return
  end

  local railH = 6 * s
  -- The title bar reflows to two rows (identity above, buttons below) when
  -- the window is too narrow for both on one, instead of the buttons and the
  -- identity painting through each other (#715).  The taller bar simply
  -- costs the content column height, which scrolls.
  S.compactChrome = sh < 500 * s and sw > sh
  local titleTwoRow = sw < 600 * s and not S.compactChrome and S.chromeMenu
  local titleH = Kit.textHeight("tab")
    + Kit.textHeight("tiny")
    + 28 * s
    + (titleTwoRow and 2 or 1) * (Kit.controlH() + 8 * s)
  if S.compactChrome or Kit.desktop then
    titleH = Kit.controlH() + 16 * s
  end
  local tabH = Kit.controlH() + 6 * s
  local statusH = (Kit.desktop and 28 or 38) * s
  -- A phone map needs room for actual cells. Its focus control
  -- hides the editor chrome while keeping the map navigation and status.
  local focusMap = S.tab == "map" and S.mapFocused
  if focusMap then
    titleH, tabH = 0, 0
  end

  Theme.versionRail(ox, oy, sw, railH)
  if not focusMap then
    drawTitleBar(ox, oy + railH, sw, titleH)
    drawTabRail(ox, oy + railH + titleH, sw, tabH)
  end

  local contentY = oy + railH + titleH + tabH
  local contentH = sh - railH - titleH - tabH - statusH
  local px, py = ox + 10 * s, contentY + 8 * s
  local pw, ph = sw - 20 * s, math.max(1, contentH - 16 * s)
  local ok, err = xpcall(function()
    Motion.pages(S, Kit, "tab", px, py, pw, ph, function(state, kit, dx, dy, dw, dh)
      local panel = PANELS[state.tab]
      if not panel then
        return
      end
      local minH = (state.tab == "events" and 360 or state.tab == "dex" and 580 or 0) * s
      state._scrollingPage = minH > dh
      kit.pushClip(dx, dy, dw, dh)
      if minH > dh then
        state.pageScroll = state.pageScroll or {}
        local off = state.pageScroll[state.tab] or 0
        panel.draw(state, kit, dx, dy - off, dw, minH)
        state.pageScroll[state.tab] = kit.scrollPixels(dx, dy, dw, dh, off, minH)
      else
        panel.draw(state, kit, dx, dy, dw, dh)
      end
      kit.popClip()
    end)
  end, debug.traceback)
  if not ok then
    Kit.resetClip()
    print(string.format("[SAVE-EDITOR ERROR in %s panel]\n%s", tostring(S.tab), tostring(err)))
    Kit.text(
      "mono",
      "Error rendering " .. tostring(S.tab) .. " panel",
      px + 12 * s,
      py + 12 * s,
      PAL.red
    )
  end

  drawStatusBar(ox, oy + sh - statusH, sw, statusH)
  Kit.blockClicks = false
  -- Scrim still covers the full window (including unsafe bands); the card
  -- itself is centred in the safe rect so search fields clear the notch.
  if S.editPopup then
    TouchEditor.draw(S, Kit, width, height)
  elseif S.navPopup then
    Chooser.draw(S, Kit, width, height)
  else
    SpeciesPicker.draw(S, Kit, width, height)
    MovePicker.draw(S, Kit, width, height)
    ItemPicker.draw(S, Kit, width, height)
  end
  Kit.endFrame()
  PadInput.draw()

  -- Only now, with the whole frame painted, is it safe to drop the editor.
  if S._closeRequested then
    finishClose()
  end
end

function App.keypressed(key)
  if not S or S.missingCache then
    return
  end
  if TouchEditor.keypressed(S, Kit, key) then
    return
  end
  if Chooser.keypressed(S, key) then
    return
  end
  -- The picker takes Enter and Escape before the focused field does: Kit maps
  -- fields handle their own commit/cancel instead of submitting a form.
  if S.itemPicker then
    if key == "return" or key == "kpenter" then
      S.itemPicker.query = Kit.flushText("item-picker", S.itemPicker.query)
      ItemPicker.commitFirst(S, Kit)
      return
    elseif key == "escape" then
      Ops.closeItemPicker(S, Kit)
      return
    end
  end
  if S.movePicker then
    if key == "return" or key == "kpenter" then
      S.movePicker.query = Kit.flushText("move-picker", S.movePicker.query)
      MovePicker.commitFirst(S, Kit)
      return
    elseif key == "escape" then
      Ops.closeMovePicker(S, Kit)
      return
    end
  end
  if S.speciesPicker then
    if key == "return" or key == "kpenter" then
      S.speciesPicker.query = Kit.flushText("species-picker", S.speciesPicker.query)
      SpeciesPicker.commitFirst(S, Kit)
      return
    elseif key == "escape" then
      Ops.closeSpeciesPicker(S, Kit)
      return
    end
  end
  -- The inspector's nickname field is a commit-on-Enter field, unlike the
  -- search fields, which are live view state.  Enter commits the draft through
  -- Ops and blurs; Escape discards it and blurs.  Both must run before
  -- Kit.keypressed. Drain queued typing before committing the draft.
  if Kit.focus == "mon-nickname" then
    if key == "return" or key == "kpenter" then
      if
        S.editingMon
        and Ops.setNickname(
          S,
          S.editingMon,
          Kit.flushText("mon-nickname", S.nicknameDraft, function(v)
            return Ops.nicknameSanitize(S, v)
          end)
        )
      then
        S.nicknameDraft = S.editingMon.nickname or ""
      end
      Kit.blur()
      return
    elseif key == "escape" then
      Kit.blur()
      if S.editingMon then
        S.nicknameDraft = S.editingMon.nickname or ""
      end
      return
    end
  end
  -- A focused text field eats the keys it cares about (typing "s" into the
  -- map filter must not trigger Save).
  if Kit.keypressed(key) then
    return
  end
  if Kit.focus then
    if key == "escape" then
      Kit.blur()
    end
    return
  end
  -- Save and Reload both touch the file on disk (Reload discards unsaved
  -- edits), so they need a modifier. A bare letter must remain safe to type.
  local mod = love.keyboard
    and love.keyboard.isDown
    and (love.keyboard.isDown("lgui", "rgui") or love.keyboard.isDown("lctrl", "rctrl"))
  if key == "escape" and (S.itemMenu or S.chromeMenu) then
    S.itemMenu, S.chromeMenu = nil, false
    Ops.say(S, "Menu closed")
    return
  end
  if key == "escape" and S.tab == "map" and S.mapFocused then
    S.mapFocused = false
    MapBrowser.clearTouches(S)
    Kit.blur()
    return
  end
  if key == "escape" then
    S.editingMon = nil
    Ops.disarm(S)
    Ops.say(S, "Selection cleared")
  elseif key == "z" and mod then
    if love.keyboard.isDown("lshift", "rshift") then
      require("History").redo(S)
    else
      require("History").undo(S)
    end
  elseif key == "y" and mod then
    require("History").redo(S)
  elseif key == "s" and mod then
    App.save()
  elseif key == "r" and mod then
    App.reload()
  end
  if S.tab == "map" and MapBrowser.keypressed then
    MapBrowser.keypressed(S, key)
  end
end

function App.wheelmoved(x, y)
  if not S or S.missingCache then
    return
  end
  if S.navPopup or S.editPopup or S.speciesPicker or S.movePicker or S.itemPicker then
    wheelY = wheelY + (y or 0)
    return
  end
  -- Only the map viewport spends the wheel on zoom. Search results and
  -- spawn cards keep the launcher's normal scrolling under the pointer.
  local mx, my = love.mouse.getPosition()
  if
    S.tab == "map"
    and MapBrowser.wheelmoved
    and not S._scrollingPage
    and (not S._mapStacked or not S.mapSection or S.mapSection == "view")
    and (not S._mapViewRect or MapBrowser.contains(S, mx, my))
  then
    MapBrowser.wheelmoved(S, y)
    return
  end
  wheelY = wheelY + (y or 0)
end

function App.quit()
  if not S then
    return false
  end
  if S.dirty then
    -- simple: block quit once and set status; user saves or force-quits again
    if not S._quitArmed then
      S._quitArmed = true
      S.status = "Unsaved changes,  save or press quit again"
      return true
    end
  end
  return false
end

return App
