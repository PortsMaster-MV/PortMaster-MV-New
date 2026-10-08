-- Gen 3 Pokémon Release Sequence (emotional upward shrink & float animation).
-- "Release this POKéMON?" -> [YES/NO] -> float/shrink animation -> "<MON> was released." -> "Bye-bye, <MON>!".

local Window = require("src.ui.game3.window")
local FrlgFont = require("src.ui.game3.frlg_font")
local Pokemon = require("src.core.game3.pokemon")
local Storage = require("src.core.game3.storage")
local RomText = require("src.core.game3.rom_text")
local RsStorage = require("src.ui.game3.rs.storage_policy")
local RsRelease = require("src.ui.game3.rs.storage_release")

local ReleaseSeq = {}

ReleaseSeq.active = false
ReleaseSeq.state = "idle" -- idle | confirm | anim | bye | done
ReleaseSeq.mon = nil
ReleaseSeq.boxId = 1
ReleaseSeq.slotIdx = 1
ReleaseSeq.session = nil
ReleaseSeq.onComplete = nil
ReleaseSeq.yesNoCursor = 2 -- default to NO
ReleaseSeq.animT = 0
ReleaseSeq.startX = 0
ReleaseSeq.startY = 0
local SE = require("src.core.game3.se_ids")

local function se(id)
  pcall(function() require("src.core.game3.audio").playSe(id) end)
end

function ReleaseSeq.start(opts)
  opts = opts or {}
  do
    local StayMessage = package.loaded["src.ui.game3.message"]
    if StayMessage and StayMessage.closeStay then StayMessage.closeStay() end
  end
  ReleaseSeq.active = true
  ReleaseSeq.state = "confirm"
  ReleaseSeq.session = opts.session
  ReleaseSeq.mon = opts.mon
  ReleaseSeq.rs = RsStorage.matches(opts.session)
  ReleaseSeq.loc = opts.loc or "box"
  ReleaseSeq.returns = false
  ReleaseSeq.boxId = opts.boxId or 1
  ReleaseSeq.slotIdx = opts.slotIdx or 1
  ReleaseSeq.onComplete = opts.onComplete
  ReleaseSeq.yesNoCursor = 2 -- Default to NO
  ReleaseSeq.animT = 0
  ReleaseSeq.startX = opts.startX or 80
  ReleaseSeq.startY = opts.startY or 60
  if ReleaseSeq.rs then RsRelease.start(ReleaseSeq) end
  se(SE.SE_SELECT)
end

function ReleaseSeq.isActive()
  return ReleaseSeq.active
end

local function anyKey(input)
  return input:wasPressed("a") or input:wasPressed("b") or input:wasPressed("up")
    or input:wasPressed("down") or input:wasPressed("left") or input:wasPressed("right")
end

function ReleaseSeq.handleInput(input)
  if not ReleaseSeq.active then return end
  if ReleaseSeq.rs and RsRelease.handleInput(ReleaseSeq, input) then return end

  if ReleaseSeq.state == "confirm" then
    if input:wasPressed("up") or input:wasPressed("down") then
      if ReleaseSeq.rs then
        ReleaseSeq.yesNoCursor = input:wasPressed("up") and 1 or 2
      else ReleaseSeq.yesNoCursor = (ReleaseSeq.yesNoCursor == 1) and 2 or 1 end
      se(SE.SE_SELECT)
    elseif input:wasPressed("a") then
      se(SE.SE_SELECT) -- pokefirered/src/menu.c:376
      if ReleaseSeq.yesNoCursor == 1 then
        if ReleaseSeq.rs then
          ReleaseSeq.returns = RsStorage.releaseReturns(ReleaseSeq.session, ReleaseSeq.mon, ReleaseSeq.loc, ReleaseSeq.boxId, ReleaseSeq.slotIdx)
        end
        -- Confirmed YES
        ReleaseSeq.state = "anim"
        ReleaseSeq.animT = 0
        if ReleaseSeq.rs then RsRelease.begin(ReleaseSeq) end
      else
        -- Chose NO
        ReleaseSeq.close(false)
      end
    elseif input:wasPressed("b") then
      ReleaseSeq.close(false)
    end
    return
  end

  if ReleaseSeq.state == "released" then
    -- pokefirered/src/pokemon_storage_system_tasks.c:1308
    if ReleaseSeq.rs and (input:wasPressed("a") or input:wasPressed("b")) or not ReleaseSeq.rs and anyKey(input) then
      ReleaseSeq.state = ReleaseSeq.returns and "surprise" or "bye"
    end
    return
  end

  if ReleaseSeq.state == "bye" then
    -- pokefirered/src/pokemon_storage_system_tasks.c:1315
    if ReleaseSeq.rs and (input:wasPressed("a") or input:wasPressed("b")) or not ReleaseSeq.rs and anyKey(input) then
      ReleaseSeq.close(true)
    end
    return
  end
  if ReleaseSeq.state == "surprise" or ReleaseSeq.state == "came_back" or ReleaseSeq.state == "worried" then
    if input:wasPressed("a") or input:wasPressed("b") then
      if ReleaseSeq.state == "surprise" then ReleaseSeq.state = "came_back"
      elseif ReleaseSeq.state == "came_back" then ReleaseSeq.state = "worried"
      else ReleaseSeq.close(false) end
    end
    return
  end
end

function ReleaseSeq.update(dt)
  if not ReleaseSeq.active then return end
  if ReleaseSeq.rs then return RsRelease.update(ReleaseSeq) end

  if ReleaseSeq.state == "anim" then
    ReleaseSeq.animT = ReleaseSeq.animT + (dt or (1 / 60))
    if ReleaseSeq.animT >= 0.8 then
      -- Finalize data deletion in storage
      if not ReleaseSeq.returns and ReleaseSeq.session and ReleaseSeq.boxId and ReleaseSeq.slotIdx then
        if ReleaseSeq.rs and ReleaseSeq.loc == "party" then
          table.remove(ReleaseSeq.session.party, ReleaseSeq.slotIdx)
          Storage.compactParty(ReleaseSeq.session.party)
        else Storage.releaseMon(ReleaseSeq.session, ReleaseSeq.boxId, ReleaseSeq.slotIdx) end
      end
      -- pokefirered/src/pokemon_storage_system_tasks.c:1304
      ReleaseSeq.state = "released"
      se(SE.SE_SELECT)
    end
  end
end

function ReleaseSeq.close(released)
  if ReleaseSeq.rs then RsRelease.close(ReleaseSeq) end
  ReleaseSeq.active = false
  ReleaseSeq.state = "idle"
  local cb = ReleaseSeq.onComplete
  ReleaseSeq.onComplete = nil
  if cb then cb(released) end
end

function ReleaseSeq.draw()
  if not ReleaseSeq.active then return end
  -- pokefirered/src/pokemon_storage_system_tasks.c:2570
  local dynamic = { [0] = Pokemon.displayName(ReleaseSeq.mon) }
  local function message(text)
    if ReleaseSeq.rs then
      Window.userFrame(Window.template(11, 17, 18, 2))
      Window.printPx(text, 88, 136)
    else
      Window.dialogueFrame(); Window.printPx(text, 16, 120)
    end
  end

  if ReleaseSeq.state == "confirm" then
    -- Bottom dialogue box
    message(ReleaseSeq.rs and RsStorage.text("ReleasePoke") or RomText.plain("gText_ReleaseThisPokemon"))

    -- YES/NO Confirmation Box
    if ReleaseSeq.rs then
      Window.userFrame(Window.template(24, 11, 5, 4))
      for i = 0, 1 do Window.printPx(RomText.at("gMenuYesNoItems", i), 192, 88 + i * 16) end
      require("src.ui.game3.rs.menu_cursor").draw(192, 88 + (ReleaseSeq.yesNoCursor - 1) * 16, 40)
    else
      Window.stdFrame(Window.template(21, 8, 6, 4))
      Window.printPx(RomText.plain("gText_Yes"), 184, 68)
      Window.printPx(RomText.plain("gText_No"), 184, 84)
      Window.cursorPx(174, ReleaseSeq.yesNoCursor == 1 and 68 or 84)
    end
    return
  end

  if ReleaseSeq.state == "anim" then
    if ReleaseSeq.rs then return RsRelease.draw(ReleaseSeq) end
    -- Draw upward shrinking sprite
    local progress = math.min(1.0, ReleaseSeq.animT / 0.8)
    local scale = math.max(0.01, 1.0 - progress * 0.85)
    local alpha = math.max(0.0, 1.0 - progress)
    local curX = ReleaseSeq.startX
    local curY = ReleaseSeq.startY - (progress * 40) -- float upward 40px

    local icon = ReleaseSeq.mon and Pokemon.monIcon(ReleaseSeq.mon)
    if icon and icon.image then
      local q = icon.quads and icon.quads[0]
      love.graphics.setColor(1, 1, 1, alpha)
      if q then
        love.graphics.draw(icon.image, q, curX, curY, 0, scale, scale, 16, 16)
      else
        love.graphics.draw(icon.image, curX, curY, 0, scale, scale, 16, 16)
      end
      love.graphics.setColor(1, 1, 1, 1)
    end
    return
  end

  if ReleaseSeq.rs and ReleaseSeq.state == "return_anim" then return RsRelease.draw(ReleaseSeq) end

  if ReleaseSeq.state == "released" then
    message(ReleaseSeq.rs and RsStorage.text("WasReleased", ReleaseSeq.mon) or RomText.plain("gText_PkmnWasReleased", { dynamic = dynamic }))
    return
  end

  if ReleaseSeq.state == "bye" then
    message(ReleaseSeq.rs and RsStorage.text("ByeBye", ReleaseSeq.mon) or RomText.plain("gText_ByeByePkmn", { dynamic = dynamic }))
    return
  end
  local nativeStates = {surprise = "Surprise", came_back = "CameBack", worried = "Worried"}
  if ReleaseSeq.rs and nativeStates[ReleaseSeq.state] then
    message(RsStorage.text(nativeStates[ReleaseSeq.state], ReleaseSeq.mon))
  end
end

return ReleaseSeq
