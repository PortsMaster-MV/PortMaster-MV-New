-- FRLG-style start menu on Sevii (pret start_menu.c SetUpStartMenu_NormalField).
-- Window at tilemapLeft=22 (right column), double-spaced entries.

local Stack = require("src.ui.game3.stack")
local Window = require("src.ui.game3.window")
local Chrome = require("src.ui.game3.chrome")
local FrlgFont = require("src.ui.game3.frlg_font")
local Strings = require("src.core.Strings")
local RomText = require("src.core.game3.rom_text")
local ModRuntime = require("src.mods.Runtime")
local FrlgData = require("src.ui.game3.start_menu_frlg")

local StartMenu = { isMenu = true }

local function se(id)
  pcall(function() require("src.core.game3.audio").playSe(require("src.core.game3.se_ids").resolve(id)) end)
end

StartMenu.open = false
StartMenu.cursor = 1
StartMenu.ENTRIES = {}
StartMenu._confirmExit = false
StartMenu._confirmCursor = 2 -- 1=YES, 2=NO (default NO)
StartMenu.MAX_VISIBLE = 8
StartMenu._scrollOffset = 0

local function player_label(session)
  local name = (session and (session.name or session.playerName)) or "PLAYER"
  -- PLAYER_NAME_LENGTH counts characters, and a kana is three bytes
  name = FrlgFont.truncate(name, 7)
  return string.upper(name)
end

-- pokefirered/src/overworld.c:1386 IsUpdateLinkStateCBActive
local function link_state_active()
  local Link = package.loaded["src.core.game3.link"]
  if not (type(Link) == "table" and Link.link and Link.inLinkRoom) then return false end
  local ok, inRoom = pcall(Link.inLinkRoom)
  return ok and inRoom == true
end

-- pokefirered/src/union_room.c:4558 InUnionRoom
local function in_union_room(session)
  local Map = package.loaded["src.core.game3.map"]
  local cur = (Map and type(Map.current) == "string" and Map.current) or (session and session.map)
  return require("src.core.game3.link.union_room").isUnionMap(cur)
end

local function safari_active(session)
  return require("src.core.game3.safari").isActive(session) == true
end

local function data(session)
  local ok, Profile = pcall(require, "src.core.game3.profile")
  local row = ok and Profile.forSession(session) or nil
  local mod = row and type(row.ui) == "table" and row.ui.startMenu or nil
  if not mod then return FrlgData end
  return require(mod)
end

local function context(session)
  local ctx = { session = session }
  function ctx.playerLabel() return player_label(session) end
  function ctx.linkActive() return link_state_active() end
  function ctx.inUnionRoom() return in_union_room(session) end
  function ctx.safariActive() return safari_active(session) end
  function ctx.mapId()
    local Map = package.loaded["src.core.game3.map"]
    return (Map and type(Map.current) == "string" and Map.current) or (session and session.map)
  end
  function ctx.version() return session and session.version end
  function ctx.flag(name, fallback)
    local Flags = package.loaded["src.core.game3.scripting.flags"]
    local Space = package.loaded["src.core.game3.scripting.space"]
    local store = Space and Space.store
    if not (store and Flags and Flags.getFlag) then return true end
    local ids = require("src.ui.game3.screens").flags(session).IDS
    local id = ids and ids[name] or fallback
    if id == nil then return false end
    return Flags.getFlag(store, nil, id) == true
  end
  function ctx.var(name)
    local Flags = package.loaded["src.core.game3.scripting.flags"]
    local Space = package.loaded["src.core.game3.scripting.space"]
    local store = Space and Space.store
    if not (store and Flags and Flags.getVar) then return 0 end
    local id = require("src.ui.game3.screens").flags(session).VAR_IDS[name]
    return id and Flags.getVar(store, nil, id) or 0
  end
  function ctx.safariBalls() return require("src.core.game3.safari").balls(session) end
  function ctx.pyramidFloor()
    local f = session and session.frontier
    return tonumber(f and f.curChallengeBattleNum) or 0
  end
  return ctx
end

-- pret MENU_POKEDEX..MENU_EXIT order for normal field.
-- `game` is only read for modStatus (the gated MODS row); session alone is
-- enough for the retail entry lists.
local function build_entries(session, game)
  local ctx = context(session)
  local entries, kind = data(session).build(ctx)
  -- Same discoverable home as Gen 1/2 start menus (18-mod-manager-ux):
  -- only once at least one mod is discovered, so vanilla is unchanged.
  local status = game and game.modStatus
  if kind == "normal" and status and #(status.available or {}) > 0 then
    table.insert(entries, #entries, { id = "mods", label = "MODS" })
  end
  return entries, kind, ctx
end

function StartMenu.resetCursor()
  StartMenu.cursor = 1
  StartMenu._scrollOffset = 0
end

function StartMenu.clampScroll(delta, prevCursor)
  local maxVisible = (StartMenu._data and StartMenu._data.maxVisible) or StartMenu.MAX_VISIBLE or 8
  local n = #(StartMenu.ENTRIES or {})
  local visible = math.min(n, maxVisible)
  StartMenu._scrollOffset = StartMenu._scrollOffset or 0
  if visible >= n then
    StartMenu._scrollOffset = 0
    return
  end

  if delta and prevCursor then
    if prevCursor == 1 and StartMenu.cursor == n then
      StartMenu._scrollOffset = n - visible
    elseif prevCursor == n and StartMenu.cursor == 1 then
      StartMenu._scrollOffset = 0
    elseif StartMenu.cursor > StartMenu._scrollOffset + visible then
      StartMenu._scrollOffset = StartMenu.cursor - visible
    elseif StartMenu.cursor <= StartMenu._scrollOffset then
      StartMenu._scrollOffset = StartMenu.cursor - 1
    end
  else
    if StartMenu.cursor > StartMenu._scrollOffset + visible then
      StartMenu._scrollOffset = StartMenu.cursor - visible
    elseif StartMenu.cursor <= StartMenu._scrollOffset then
      StartMenu._scrollOffset = math.max(0, StartMenu.cursor - 1)
    end
  end

  if StartMenu._scrollOffset < 0 then
    StartMenu._scrollOffset = 0
  elseif StartMenu._scrollOffset > n - visible then
    StartMenu._scrollOffset = n - visible
  end
end

function StartMenu.saveOffered(session, game)
  for _, entry in ipairs(build_entries(session, game)) do
    if entry.id == "save" then return true end
  end
  return false
end

function StartMenu.show(opts)
  opts = opts or {}
  StartMenu.open = true
  StartMenu._confirmExit = false
  StartMenu._confirmCursor = 2
  StartMenu._session = opts.session
  StartMenu._game = opts.game
  StartMenu._onClose = opts.onClose
  StartMenu._tutorial = opts.tutorial and true or false
  StartMenu._onTutorialSelect = opts.onTutorialSelect
  local d = data(opts.session)
  local entries, kind, ctx
  if StartMenu._tutorial and d.tutorialEntries then
    ctx = context(opts.session)
    entries, kind = d.tutorialEntries(ctx)
  else
    entries, kind, ctx = build_entries(opts.session, opts.game)
  end
  StartMenu.ENTRIES = entries
  StartMenu._kind = kind
  StartMenu._data = d
  StartMenu._ctx = ctx
  StartMenu._safariStats = kind == "safari"
  if ModRuntime.wantsHook("ui.start_menu.items") then
    local hooked = ModRuntime.call("ui.start_menu.items", function(_, items) return items end,
      opts.game, StartMenu.ENTRIES)
    if type(hooked) == "table" then StartMenu.ENTRIES = hooked end
  end
  local pos = tonumber(opts.cursor or StartMenu.cursor) or 1
  if pos < 1 or pos > #StartMenu.ENTRIES then pos = 1 end -- pokefirered/src/menu.c:276
  StartMenu.cursor = pos -- pokefirered/src/start_menu.c:329
  StartMenu.clampScroll()
  Stack.push("start", StartMenu, { hideBelow = true })
  se("SE_WIN_OPEN")
end

function StartMenu.close(silent)
  StartMenu.open = false
  StartMenu._confirmExit = false
  StartMenu._tutorial = false
  StartMenu._onTutorialSelect = nil
  Stack.pop("start")
  local cb = StartMenu._onClose
  StartMenu._onClose = nil
  if not silent then se("SE_SELECT") end -- pokefirered/src/start_menu.c:1005
  if cb then cb() end
end

function StartMenu.cancel()
  if StartMenu._confirmExit then
    StartMenu._confirmExit = false
    -- pokefirered/src/menu.c:381
    return
  end
  if StartMenu._tutorial then
    local cb = StartMenu._onTutorialSelect
    StartMenu.close(true)
    if cb then cb(127) end -- MULTI_B_PRESSED
    return
  end
  StartMenu.close()
end

function StartMenu.move(delta)
  if StartMenu._confirmExit then
    StartMenu._confirmCursor = (StartMenu._confirmCursor == 1) and 2 or 1
    se("SE_SELECT")
    return
  end
  local n = #StartMenu.ENTRIES
  if n < 1 then return end
  local prevCursor = StartMenu.cursor
  StartMenu.cursor = ((StartMenu.cursor - 1 + delta) % n) + 1
  StartMenu.clampScroll(delta, prevCursor)
  se("SE_SELECT")
end

function StartMenu.confirm()
  se("SE_SELECT")
  if StartMenu._tutorial then
    local sel = StartMenu.cursor - 1
    local cb = StartMenu._onTutorialSelect
    StartMenu.close(true)
    if cb then cb(sel) end
    return
  end
  if StartMenu._confirmExit then
    if StartMenu._confirmCursor == 1 then -- YES
      StartMenu.open = false
      StartMenu._confirmExit = false
      Stack.pop("start")
      local Runtime = package.loaded["src.core.game3.runtime"]
      local game = (StartMenu._session and StartMenu._session.game)
        or (Runtime and Runtime._game)
        or StartMenu._game
      if game and game.returnToTitle then
        game:returnToTitle({ skipIntro = true })
      end
    else -- NO
      StartMenu._confirmExit = false
    end
    return
  end

  local e = StartMenu.ENTRIES[StartMenu.cursor]
  if not e then return end
  local session = StartMenu._session
  local d = StartMenu._data or data(session)
  local Screens = require("src.ui.game3.screens")
  if type(e.onSelect) == "function" then
    local ok, err = pcall(e.onSelect, StartMenu._game, session)
    if not ok then print("[game3/start_menu] onSelect failed: " .. tostring(err)) end
  elseif e.id == "exit" then
    if d.exitConfirms then
      StartMenu._confirmExit = true
      StartMenu._confirmCursor = 2 -- Default to NO
    else
      StartMenu.close(true) -- pokeemerald/src/start_menu.c:747
    end
  elseif e.id == "bag" then
    local BagMenu = Screens.get("bag", session)
    BagMenu.show(session and session.bag, {
      session = session,
      onClose = function() end,
    })
  elseif e.id == "pokedex" then
    if d.dexNeedsSeen and not StartMenu.anySeen(session) then return end
    local Pokedex = Screens.get("pokedex", session)
    Pokedex.show(session and session.dex, { session = session })
  elseif e.id == "pokemon" then
    local PartyMenu = Screens.get("party", session)
    PartyMenu.show(session and session.party, session and session.move_overlay, {
      session = session,
    })
  elseif e.id == "pokenav" or e.id == "pyramid_bag" or e.id == "retire_frontier" then
    local mod = Screens.get(e.id, session)
    if mod and mod.show then
      mod.show({ session = session, game = StartMenu._game })
    else
      StartMenu.logUnported(e.id)
    end
  elseif e.id == "retire" then
    -- pokefirered/src/start_menu.c:546 StartMenuSafariZoneRetireCallback
    local game = StartMenu._game
    StartMenu.close(true)
    require("src.core.game3.safari").retirePrompt(session, game)
  elseif e.id == "trainer_link" then
    -- pokefirered/src/start_menu.c:556 StartMenuLinkPlayerCallback
    local TrainerCard = require("src.ui.game3.trainer_card")
    TrainerCard.show({ session = require("src.core.game3.link").localTrainerCard() })
  elseif e.id == "trainer" then
    local pass = StartMenu._kind ~= "union" and StartMenu.frontierPassScreen(session)
    if pass then
      pass.show({ session = session, game = StartMenu._game }) -- pokeemerald/src/start_menu.c:711
    else
      local TrainerCard = Screens.get("trainer_card", session)
      TrainerCard.show({ session = session })
    end
  elseif e.id == "save" or e.id == "rest_frontier" then
    local SaveMenu = Screens.get("save", session)
    SaveMenu.show({ session = session, game = StartMenu._game })
  elseif e.id == "option" then
    local OptionMenu = Screens.get("option", session)
    OptionMenu.show({ session = session })
  elseif e.id == "mods" then
    local ModManager = require("src.ui.game3.mod_manager")
    ModManager.show({
      game = StartMenu._game or (session and session.game),
      session = session,
    })
  end
end

function StartMenu.isOpen()
  return StartMenu.open
end

-- pokeemerald/src/start_menu.c:612
function StartMenu.anySeen(session)
  local dex = session and session.dex
  local seen = type(dex) == "table" and (dex.seen or dex.owned) or nil
  if type(seen) ~= "table" then return false end
  for _, on in pairs(seen) do
    if on and on ~= 0 then return true end
  end
  return false
end

-- pokeemerald/src/start_menu.c:700
function StartMenu.frontierPassScreen(session)
  local Flags = package.loaded["src.core.game3.scripting.flags"]
  local Space = package.loaded["src.core.game3.scripting.space"]
  local store = Space and Space.store
  if not (store and Flags) then return nil end
  local id = require("src.ui.game3.screens").flags(session).IDS.SYS_FRONTIER_PASS
  if not (id and Flags.getFlag(store, nil, id)) then return nil end
  local Screens = require("src.ui.game3.screens")
  if not Screens.path("frontier_pass", session) then return nil end
  return Screens.get("frontier_pass", session)
end

local unported = {}
function StartMenu.logUnported(id)
  if unported[id] then return end
  unported[id] = true
  print("[game3/start_menu] no screen registered for " .. tostring(id))
end

--- pret: content at (22,1), width 7; labels at +8px, rows every 15px.
function StartMenu.contentTemplate()
  local maxVisible = (StartMenu._data and StartMenu._data.maxVisible) or StartMenu.MAX_VISIBLE or 8
  local n = math.min(math.max(1, #StartMenu.ENTRIES), maxVisible)
  local d = StartMenu._data
  if d and d.window then
    return Window.template(d.window.left, d.window.top, d.window.width, n * 2 + 2) -- pokeemerald/src/menu.c:493
  end
  -- Window height in tiles: pret (numActions*2)+2 includes frame padding;
  -- content height for n×15px rows ≈ ceil(n*15/8) tiles.
  local contentH = math.max(2, math.ceil((n * Window.OPTION_HEIGHT) / 8))
  return Window.template(22, 1, 7, contentH)
end

function StartMenu.draw()
  if not StartMenu.open then return end
  local dd = StartMenu._data
  local ex = dd and dd.extraWindow and StartMenu._ctx and dd.extraWindow(StartMenu._kind, StartMenu._ctx) or nil
  if ex then
    local stats = Window.template(ex.left, ex.top, ex.width, ex.height)
    Window.stdFrame(stats)
    local text = RomText.plain(ex.key, { stringVars = ex.vars })
    Window.printPx(text, stats.left * 8 + (ex.textX or 0), stats.top * 8 + (ex.textY or 1))
  end
  local tpl = StartMenu.contentTemplate()
  Window.stdFrame(tpl)
  local leftPx = tpl.left * 8
  local topPx = tpl.top * 8
  local d = StartMenu._data

  local maxVisible = (d and d.maxVisible) or StartMenu.MAX_VISIBLE or 8
  local visibleCount = math.min(#StartMenu.ENTRIES, maxVisible)
  local scroll = StartMenu._scrollOffset or 0
  local nativeCursorX, nativeCursorY

  for r = 1, visibleCount do
    local i = scroll + r
    local e = StartMenu.ENTRIES[i]
    if not e then break end
    -- pret: cursor (0, r*15), text (8, r*15) inside the window.
    local yPx = Window.menuRowPx(topPx, r)
    if d and d.rowPitch then yPx = topPx + d.textY + (r - 1) * d.rowPitch end
    if not StartMenu._confirmExit and i == StartMenu.cursor then
      if d and d.drawCursor then nativeCursorX, nativeCursorY = leftPx, yPx
      else Window.cursorPx(leftPx, yPx) end
    end
    Window.printPx(e.label, leftPx + (d and d.textX or Window.CURSOR_WIDTH), yPx)
  end
  if nativeCursorX then d.drawCursor(nativeCursorX, nativeCursorY) end

  local n = #StartMenu.ENTRIES
  if n > visibleCount and not StartMenu._confirmExit then
    local showUp = scroll > 0
    local showDown = scroll + visibleCount < n
    StartMenu._frames = ((StartMenu._frames or 0) + 1) % 256
    local okL, ListMenu = pcall(require, "src.ui.game3.list_menu")
    if okL and ListMenu and ListMenu.drawScrollArrows then
      pcall(ListMenu.drawScrollArrows, tpl, showUp, showDown, StartMenu._frames)
    end
  end

  if StartMenu._confirmExit then
    -- Bottom Dialogue Window
    Chrome.dialogueFrame()
    local prompt = Strings("RETURN TO MAIN\nMENU?")
    FrlgFont.draw(prompt, 2 * 8 + 4, 15 * 8 + 2, { linePitch = 15, colors = FrlgFont.COLOR.NORMAL })

    -- Right YES/NO Window
    local popX = 21
    local popY = 9
    local popW = 6
    local popH = 4
    Window.stdFrame(Window.template(popX, popY, popW, popH))
    local rowY1 = popY * 8 + 2
    local rowY2 = popY * 8 + 18
    local curY = (StartMenu._confirmCursor == 1) and rowY1 or rowY2
    Window.cursorPx(popX * 8 + 1, curY)
    FrlgFont.draw(RomText.plain("gText_Yes"), popX * 8 + 9, rowY1, { colors = FrlgFont.COLOR.NORMAL })
    FrlgFont.draw(RomText.plain("gText_No"), popX * 8 + 9, rowY2, { colors = FrlgFont.COLOR.NORMAL })
  end
end

return StartMenu
