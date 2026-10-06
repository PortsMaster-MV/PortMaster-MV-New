-- pokefirered/src/diploma.c:100

local Display = require("src.core.game3.display")
local Stack = require("src.ui.game3.stack")
local FrlgFont = require("src.ui.game3.frlg_font")
local RomText = require("src.core.game3.rom_text")
local Extract = require("src.import.gba.extract_island1")

local Diploma = {}

Diploma.ID = "diploma"

-- pokefirered/include/constants/songs.h:267
local Song = require("src.core.game3.song_ids")
-- pokefirered/src/diploma.c:58
-- pokefirered/src/diploma.c:97
local TEXT_COLORS = { fg = FrlgFont.STDPAL[2], shadow = FrlgFont.STDPAL[3], bg = { 0, 0, 0, 0 } }
-- pokefirered/src/new_menu_helpers.c:84
local LINE_PITCH = 14
-- pokefirered/src/diploma.c:84
local WIN_X, WIN_Y = 0, 16

Diploma.open = false
Diploma._phase = "idle"
Diploma._national = false
Diploma._onDone = nil
Diploma._images = {}

local function fade()
  return require("src.ui.game3.fade")
end

local function image(key)
  local rse = require("src.core.game3.profile").family() == "rse"
  if rse then
    if key == "kanto" then key = "emerald_hoenn" end
    if key == "national" then key = "emerald_national" end
  end
  if Diploma._images[key] ~= nil then return Diploma._images[key] or nil end
  local rel = (Extract.CACHE_ROOT or "data/generated/gba") .. "/diploma/" .. key .. ".rgba"
  local bytes = require("src.core.game3.dataset").cache():read(rel)
  local img = false
  if bytes and #bytes == Display.W * Display.H * 4 and love and love.image then
    local data = love.image.newImageData(Display.W, Display.H, "rgba8", bytes)
    img = love.graphics.newImage(data)
    img:setFilter("nearest", "nearest")
  end
  Diploma._images[key] = img
  return img or nil
end

-- pokefirered/src/pokedex.c:123
local function has_all_mons()
  local Runtime = package.loaded["src.core.game3.runtime"]
  local session = Runtime and Runtime.getSession and Runtime.getSession()
  local id = require("src.core.game3.constants").versionOf(session)
  if id == "ruby" or id == "sapphire" then return require("src.core.game3.profiles.rs.pokedex").completedNational(session) end
  local Queries = require("src.core.game3.scripting.natives_queries")
  local _, v = Queries.BY_NAME.HasAllMons(nil)
  return v == 1
end

local function player_name()
  local rt = package.loaded["src.core.game3.runtime"]
  local session = rt and rt.getSession and rt.getSession()
  return tostring((session and (session.name or session.playerName)) or "")
end

function Diploma.isOpen()
  return Diploma.open
end

function Diploma.isNational()
  return Diploma._national
end

function Diploma.phase()
  return Diploma._phase
end

-- pokefirered/src/diploma.c:119
function Diploma.show(opts)
  opts = opts or {}
  if not image("kanto") or not image("national") then return false end
  Diploma._onDone = opts.onDone
  -- pokefirered/src/diploma.c:138
  Diploma._national = has_all_mons()
  local name = player_name()
  if require("src.core.game3.profile").family() == "rse" then
    -- pokeemerald/src/diploma.c:133-140
    local dexName = RomText.plain(Diploma._national and "gText_DexNational" or "gText_DexHoenn")
    Diploma._player = ""
    local textCtx = {
      playerName = name,
      stringVars = { dexName },
      dialect = "rse",
    }
    Diploma._body = RomText.plain("gText_PokedexDiploma", textCtx)
    Diploma._gameFreak = ""
    Diploma._playerX, Diploma._bodyX = 40, 40
  else
    -- pokefirered/src/diploma.c:260
    local dynamic = {
      [0] = name,
      [1] = RomText.plain(Diploma._national and "gText_Diploma_National" or "gText_Diploma_Kanto"),
    }
    Diploma._player = RomText.plain("gText_Diploma_Player", { dynamic = dynamic })
    Diploma._body = RomText.plain("gText_Diploma_ThisDocument", { dynamic = dynamic })
    Diploma._gameFreak = RomText.plain("gText_Diploma_GameFreak")
    Diploma._playerX = 120 - math.floor(FrlgFont.measure(Diploma._player) / 2)
    Diploma._bodyX = 120 - math.floor(FrlgFont.measure(Diploma._body) / 2)
  end
  Diploma.open = true
  Diploma._phase = "in"
  Stack.push(Diploma.ID, Diploma, { hideBelow = true, fullscreen = true })
  local Fade = fade()
  -- pokefirered/src/diploma.c:150
  Fade.begin(Fade.MODE.FROM_BLACK, 1, function()
    if Diploma._phase ~= "in" then return end
    Diploma._phase = "fanfare"
    -- pokefirered/src/diploma.c:158
    require("src.core.game3.audio").playFanfare(Song.MUS_OBTAIN_BADGE)
  end)
  return true
end

local function finish()
  Diploma.open = false
  Diploma._phase = "idle"
  Stack.pop(Diploma.ID)
  local cb = Diploma._onDone
  Diploma._onDone = nil
  -- pokefirered/src/overworld.c:1677
  local Space = package.loaded["src.core.game3.scripting.space"]
  if Space and Space.returnToField then pcall(Space.returnToField) end
  local Fade = fade()
  Fade.begin(Fade.MODE.FROM_BLACK, 1, function() end)
  if cb then cb() end
end

-- pokefirered/src/diploma.c:164
function Diploma.update(_dt)
  if not Diploma.open then return end
  if Diploma._phase == "fanfare" then
    if require("src.core.game3.audio").isFanfareFinished() then
      Diploma._phase = "wait"
    end
  end
end

function Diploma.handleInput(input)
  if not Diploma.open or not input then return end
  if Diploma._phase ~= "wait" then return end
  if input:wasPressed("a") then
    Diploma._phase = "out"
    local Fade = fade()
    -- pokefirered/src/diploma.c:175
    Fade.begin(Fade.MODE.TO_BLACK, 1, function()
      if Diploma._phase == "out" then finish() end
    end)
  end
end

function Diploma.draw()
  if not Diploma.open then return end
  local rse = require("src.core.game3.profile").family() == "rse"
  -- pokefirered/src/diploma.c:138
  local img = image(Diploma._national and "national" or "kanto")
  love.graphics.setColor(1, 1, 1, 1)
  if img then love.graphics.draw(img, 0, 0) end
  if rse then
    -- pokeemerald/src/diploma.c:133-140
    -- pokeemerald/src/diploma.c:181-189
    -- pokeemerald/src/strings.c:1540
    local text = tostring(Diploma._body or "")
    local playerLine, body = text:match("^([^\n]*)\n\n(.*)$")
    if not playerLine then playerLine, body = "", text end
    body = body:gsub("\n\nGAME FREAK%s*$", "", 1)
    local pitch = FrlgFont.linePitch()
    if not pitch or pitch <= 0 then pitch = LINE_PITCH end
    local label, name = playerLine:match("^(PLAYER:)%s*(.*)$")
    if label then
      local red = { colors = FrlgFont.COLOR.RED, linePitch = pitch }
      -- pokeemerald/src/diploma.c:75-80
      -- pokeemerald/src/diploma.c:189
      -- pokeemerald/src/strings.c:1540
      FrlgFont.draw(label, 40, 17, { colors = TEXT_COLORS, linePitch = pitch, maxWidth = 160 })
      -- pokeemerald/src/strings.c:1540
      local nameX = FrlgFont.measure(label) + 16 + 3
      FrlgFont.draw(name, 40 + nameX, 17,
        { colors = red.colors, linePitch = pitch, maxWidth = math.max(0, 160 - nameX) })
    else
      FrlgFont.draw(playerLine, 40, 17,
        { colors = FrlgFont.COLOR.RED, linePitch = pitch, maxWidth = 160 })
    end
    FrlgFont.draw(body, 40, 17 + pitch * 2,
      { colors = TEXT_COLORS, linePitch = pitch, maxWidth = 160 })
    -- pokeemerald/src/strings.c:1540
    -- pokeemerald/src/strings.c:1540
    -- pokeemerald/src/strings.c:1540
    FrlgFont.draw("GAME FREAK", 40 + 66, 17 + pitch * 7,
      { colors = FrlgFont.COLOR.RED, linePitch = pitch, maxWidth = 160 - 66 })
    return
  end
  -- pokefirered/src/diploma.c:269
  local opts = { colors = TEXT_COLORS, linePitch = LINE_PITCH }
  if Diploma._player and Diploma._player ~= "" then
    FrlgFont.draw(Diploma._player, WIN_X + Diploma._playerX, WIN_Y + 4, opts)
  end
  if Diploma._body and Diploma._body ~= "" then
    FrlgFont.draw(Diploma._body, Diploma._bodyX, WIN_Y + 30, opts)
  end
  if Diploma._gameFreak and Diploma._gameFreak ~= "" then
    FrlgFont.draw(Diploma._gameFreak, WIN_X + 120, WIN_Y + 105, opts)
  end
end

return Diploma
