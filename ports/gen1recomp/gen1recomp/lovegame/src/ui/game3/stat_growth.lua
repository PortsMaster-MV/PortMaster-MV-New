-- Stat growth / level-up window (pokefirered Cmd_drawlvlupbox / DrawLevelUpWindowPg1 & Pg2).
local Window = require("src.ui.game3.window")
local FrlgFont = require("src.ui.game3.frlg_font")
local RomText = require("src.core.game3.rom_text")

local StatGrowth = {}

StatGrowth._open = false
StatGrowth._mon = nil
StatGrowth._oldStats = nil
StatGrowth._newStats = nil
StatGrowth._page = 1
StatGrowth._onDone = nil
StatGrowth._pos = nil


local function play_select_se()
  pcall(function()
    local Audio = require("src.core.game3.audio")
    local SE = require("src.core.game3.se_ids")
    if Audio and Audio.playSe then
      Audio.playSe((SE and SE.SE_SELECT) or 5)
    end
  end)
end

local function uiBlock()
  local ok, P = pcall(function() return require("src.core.game3.profile").forSession(nil) end)
  return ok and P and P.ui or nil
end

function StatGrowth.open(mon, oldStats, newStats, onDone, opts)
  opts = opts or {}
  local ui = uiBlock()
  local box = ui and ui.levelUpBox
  StatGrowth._open = true
  StatGrowth._mon = mon
  StatGrowth._oldStats = oldStats or {}
  StatGrowth._newStats = newStats or {}
  StatGrowth._page = 1
  StatGrowth._onDone = onDone
  StatGrowth._box = box
  StatGrowth._nativePages = nil
  StatGrowth._pos = opts.pos or (box and { x = box.x, y = box.y, w = box.w, h = box.h }) or { x = 19, y = 1, w = 10, h = 11 }
end

function StatGrowth.isOpen()
  return StatGrowth._open
end

--- opts.silent drops the window without firing its onDone callback, for callers
--- tearing down a step that no longer exists (#2324).
function StatGrowth.close(opts)
  local wasOpen = StatGrowth._open
  StatGrowth._open = false
  StatGrowth._mon = nil
  StatGrowth._oldStats = nil
  StatGrowth._newStats = nil
  StatGrowth._page = 1
  StatGrowth._nativePages = nil
  local cb = StatGrowth._onDone
  StatGrowth._onDone = nil
  if wasOpen and cb and not (opts and opts.silent) then cb() end
end

function StatGrowth.handleInput(input)
  if not StatGrowth._open or not input then return false end
  if input:wasPressed("a") or input:wasPressed("b") or input:wasPressed("start") then
    if StatGrowth._page == 1 then
      play_select_se()
      StatGrowth._page = 2
      return true
    else
      play_select_se()
      StatGrowth.close()
      return true
    end
  end
  return false
end

function StatGrowth.draw()
  if not StatGrowth._open or not (love and love.graphics) then return end
  local pos = StatGrowth._pos or { x = 19, y = 1, w = 10, h = 11 }
  local winX = pos.x or 19
  local winY = pos.y or 1
  local winW = pos.w or 10
  local winH = pos.h or 11

  Window.stdFrame(Window.template(winX, winY, winW, winH))

  local oldS = StatGrowth._oldStats or {}
  local newS = StatGrowth._newStats or {}
  local oldList = { oldS.maxHp or 0, oldS.atk or 0, oldS.def or 0, oldS.spa or 0, oldS.spd or 0, oldS.spe or 0 }
  local newList = { newS.maxHp or 0, newS.atk or 0, newS.def or 0, newS.spa or 0, newS.spd or 0, newS.spe or 0 }
  local isPage1 = (StatGrowth._page == 1)

  local box = StatGrowth._box
  if box and box.layout == "rs" then
    -- pokeruby/src/battle_script_commands.c:5777
    local pages = StatGrowth._nativePages
    if not pages then
      pages = {}
      for page = 1, 2 do
        local parts = {}
        for i, key in ipairs(box.stats) do
          parts[#parts + 1] = RomText.at(box.names, i - 1)
          parts[#parts + 1] = string.char(0xFC, 0x13, ((i - 1) % 2) * 72 + 46)
          local value = tonumber(newS[key]) or 0
          if page == 1 then
            value = value - (tonumber(oldS[key]) or 0)
            parts[#parts + 1] = RomText.plain(value < 0 and "BattleText_Dash" or "BattleText_Plus")
          end
          parts[#parts + 1] = string.char(0xFC, 0x14, 6)
          parts[#parts + 1] = string.format(page == 1 and "%2d" or "%3d", page == 1 and math.abs(value) or value)
          parts[#parts + 1] = string.char(0xFC, 0x14, 0)
          parts[#parts + 1] = i % 2 == 0 and "\n" or string.char(0xFC, 0x11, 8)
        end
        pages[page] = table.concat(parts)
      end
      StatGrowth._nativePages = pages
    end
    -- pokeruby/src/battle_bg.c:266
    FrlgFont.draw(pages[StatGrowth._page], winX * 8, winY * 8, {
      font = "native_3", linePitch = 16, maxWidth = winW * 8,
      colors = { fg = { 74 / 255, 74 / 255, 74 / 255, 1 },
        shadow = { 214 / 255, 214 / 255, 206 / 255, 1 }, bg = { 0, 0, 0, 0 } },
    })
    return
  end
  if box then
    local ui = uiBlock()
    local keys = ui and ui.party and ui.party.text and ui.party.text.levelUpStats or {}
    for idx = 1, 6 do
      -- pokeemerald/src/menu_specialized.c:1536
      local rowY = winY * 8 + (idx - 1) * box.pitch
      FrlgFont.draw(RomText.plain(keys[idx]), winX * 8, rowY, { colors = FrlgFont.COLOR.NORMAL })
      if isPage1 then
        local diff = newList[idx] - oldList[idx]
        FrlgFont.draw(diff >= 0 and "+" or "-", winX * 8 + 56, rowY, { colors = FrlgFont.COLOR.NORMAL })
        local x = math.abs(diff) <= 9 and 18 or 12
        FrlgFont.draw(tostring(math.abs(diff)), winX * 8 + 56 + x, rowY, { colors = FrlgFont.COLOR.NORMAL })
      else
        -- pokeemerald/src/menu_specialized.c:1588
        local v = newList[idx]
        local digits = v > 99 and 3 or (v > 9 and 2 or 1)
        FrlgFont.draw(tostring(v), winX * 8 + 56 + 6 * (4 - digits), rowY, { colors = FrlgFont.COLOR.NORMAL })
      end
    end
    return
  end
  for idx = 1, 6 do
    local rowY = winY * 8 + 2 + (idx - 1) * 14
    -- src/pokemon_special_anim_scene.c:1518
    FrlgFont.draw(RomText.at("sLevelUpWindowStatNames", idx - 1), winX * 8 + 2, rowY, { colors = FrlgFont.COLOR.NORMAL })
    if isPage1 then
      local diff = newList[idx] - oldList[idx]
      local sign = (diff >= 0) and "+" or "-"
      local diffStr = string.format("%s%2d", sign, math.abs(diff))
      FrlgFont.draw(diffStr, winX * 8 + 52, rowY, { colors = FrlgFont.COLOR.NORMAL })
    else
      local valStr = string.format("%3d", newList[idx])
      FrlgFont.draw(valStr, winX * 8 + 52, rowY, { colors = FrlgFont.COLOR.NORMAL })
    end
  end
end

return StatGrowth
