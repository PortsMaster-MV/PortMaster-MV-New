local Std = require("src.core.game3.scripting.stdscripts")
local Rse = require("src.core.game3.rse.init")
local Town = require("src.core.game3.rse.town_common")
local OldMan = require("src.core.game3.rse.old_man")
local Bard = require("src.core.game3.rse.bard_music")
local Types = require("src.core.game3.rse.easy_chat_types")

local NativesOldMan = {}

-- pokeemerald/include/constants/vars.h:287
local VAR_0x8004 = 0x8004
local VAR_0x8005 = 0x8005
local VAR_0x8006 = 0x8006
local VAR_RESULT = 0x800D
-- pokeemerald/include/constants/script_menu.h:8
local MENU_B_PRESSED = 127

local function result(ctx, v)
  v = (v == true and 1) or (v == false and 0) or tonumber(v) or 0
  Rse.setSpecialVar(ctx, VAR_RESULT, v)
  return false, v
end

local function text(key, ctx)
  return require("src.core.game3.rom_text").plain(key, ctx)
end

-- pokeemerald/src/easy_chat.c:1479
Types.register(Types.ID.BARD_SONG, {
  words = function(_, sess)
    local b = OldMan.state(sess)
    for i = 1, OldMan.NUM_BARD_SONG_WORDS do b.newSongLyrics[i] = b.songLyrics[i] end
    return Town.copyWords(b.newSongLyrics, OldMan.NUM_BARD_SONG_WORDS)
  end,
  commit = function(_, sess, words)
    local b = OldMan.state(sess)
    for i = 1, OldMan.NUM_BARD_SONG_WORDS do b.newSongLyrics[i] = tonumber(words[i]) or Town.EC_EMPTY_WORD end
  end,
})

local function choose(ctx, adapters, labels, layout, onPick)
  local Natives = require("src.core.game3.scripting.natives")
  return Natives.yieldHost(ctx, adapters, function(done)
    local Choice = require("src.ui.game3.choice")
    Choice.multi(labels, 0, function(sel)
      onPick(sel)
      done()
    end, layout)
  end)
end

local function logf(adapters, fmt, ...)
  local msg = string.format(fmt, ...)
  if adapters and adapters.log then adapters.log(msg) else print(msg) end
end

NativesOldMan.lastBard = nil

-- pokeemerald/src/mauville_old_man.c:604
function NativesOldMan.playBardSong(ctx, adapters, useNew)
  local lyrics = Town.copyWords(OldMan.lyrics(useNew), OldMan.NUM_BARD_SONG_WORDS)
  local sim = Bard.simulate(lyrics)
  local t0 = os.clock()
  local pcm = Bard.bake(sim)
  local info = { lyrics = lyrics, frames = sim.count, singStart = sim.singStart, samples = pcm.samples,
    seconds = pcm.seconds, peak = pcm.peak, phonemes = pcm.songs, bakeSeconds = os.clock() - t0, texts = {} }
  NativesOldMan.lastBard = info
  logf(adapters, "[bard] song rendered: %d samples @%d Hz (%.2fs), peak %.4f, %d phoneme starts, %d task frames, bake %.3fs",
    pcm.samples, pcm.rate, pcm.seconds, pcm.peak, pcm.songs, sim.count, info.bakeSeconds)
  local Audio = require("src.core.game3.audio")
  local Message = require("src.ui.game3.message")
  local frame, shown, finished = 0, nil, false
  local function step()
    frame = frame + 1
    for _, e in ipairs(sim.events[frame] or {}) do
      if e.op == "bgmFadeOut" then
        pcall(Audio.fadeOutBgm, e.speed)
      end
    end
    if frame == sim.singStart then
      pcall(Audio.pauseBgm)
      Bard.stop()
      local ok, src = pcall(Bard.play, pcm)
      Bard.active = { source = ok and src or nil, info = info }
    end
    local txt = sim.frames[frame] or ""
    if txt ~= shown then
      shown = txt
      info.texts[#info.texts + 1] = txt
      Message.show(txt, { stay = true, speed = 0 })
    end
    if frame >= sim.count then
      -- pokeemerald/src/mauville_old_man.c:677
      pcall(Audio.resumeBgm)
      finished = true
    end
  end
  ctx.mode = "native"
  ctx.status = "waiting"
  NativesOldMan.singing = true
  ctx.nativePoll = function()
    if not finished then step() end
    if finished then NativesOldMan.singing = false end
    return finished
  end
  return true
end

local function decorName(decor)
  if decor > OldMan.NUM_DECORATIONS then return text("gText_FiveMarks") end
  local Inv = require("src.core.game3.rse.decoration_inventory")
  local d = Inv.info(decor)
  return d and d.name or ""
end

local function decorInPc(sess, cat, index)
  local ok, Decor = pcall(require, "src.core.game3.rse.decoration")
  if ok and type(Decor) == "table" and Decor.isInPc then
    local ok2, v = pcall(Decor.isInPc, sess, cat, index)
    if ok2 then return v end
  end
  return true
end

-- pokeemerald/src/decoration.c:844
local function chooseDecorationToGive(ctx, adapters, done)
  local Inv = require("src.core.game3.rse.decoration_inventory")
  local Choice = require("src.ui.game3.choice")
  local sess = Rse.session()
  local cats = {}
  for cat = 0, Inv.CATEGORY_COUNT - 1 do cats[#cats + 1] = Inv.categoryName(cat) end
  cats[#cats + 1] = text("gText_Cancel")
  local function pickCategory()
    Choice.multi(cats, 0, function(sel)
      if sel == MENU_B_PRESSED or sel >= Inv.CATEGORY_COUNT then
        -- pokeemerald/src/trader.c:192
        Rse.setSpecialVar(ctx, VAR_0x8006, 0)
        return done()
      end
      local cat = sel
      local items, slots = {}, {}
      for i, d in ipairs(Inv.inventories(sess)[cat]) do
        if d ~= Inv.DECOR_NONE then
          items[#items + 1] = decorName(d)
          slots[#slots + 1] = i
        end
      end
      items[#items + 1] = text("gText_Cancel")
      Choice.multi(items, 0, function(pick)
        if pick == MENU_B_PRESSED or pick >= #slots then return pickCategory() end
        local index = slots[pick + 1]
        local decor = Inv.inventories(sess)[cat][index]
        -- pokeemerald/src/trader.c:176
        if decorInPc(sess, cat, index) then
          Rse.setSpecialVar(ctx, VAR_0x8006, decor)
          Town.setString(ctx, adapters, 3, decorName(Rse.specialVar(ctx, VAR_0x8004)))
          Town.setString(ctx, adapters, 2, decorName(decor))
        else
          Rse.setSpecialVar(ctx, VAR_0x8006, 0xFFFF)
        end
        done()
      end, { left = 1, top = 1 })
    end, { left = 1, top = 1 })
  end
  pickCategory()
end

NativesOldMan.BY_NAME = {
  -- pokeemerald/src/mauville_old_man.c:146
  Script_GetCurrentMauvilleMan = function(ctx) return result(ctx, OldMan.current()) end,
  -- pokeemerald/src/mauville_old_man.c:151
  HasBardSongBeenChanged = function(ctx) return result(ctx, OldMan.state().hasChangedSong == true) end,
  -- pokeemerald/src/mauville_old_man.c:156
  SaveBardSongLyrics = function()
    OldMan.saveBardSongLyrics()
    return false
  end,
  -- pokeemerald/src/mauville_old_man.c:235
  PlayBardSong = function(ctx, adapters)
    return NativesOldMan.playBardSong(ctx, adapters, Rse.specialVar(ctx, VAR_0x8004) ~= 0)
  end,
  -- pokeemerald/src/mauville_old_man.c:241
  HasHipsterTaughtWord = function(ctx) return result(ctx, OldMan.state().taughtWord == true) end,
  -- pokeemerald/src/mauville_old_man.c:246
  SetHipsterTaughtWord = function()
    OldMan.state().taughtWord = true
    return false
  end,
  -- pokeemerald/src/mauville_old_man.c:251
  HipsterTryTeachWord = function(ctx, adapters)
    local word = OldMan.unlockRandomTrendySaying()
    if word == Town.EC_EMPTY_WORD then return result(ctx, false) end
    Town.setString(ctx, adapters, 1, Town.word(word))
    return result(ctx, true)
  end,
  -- pokeemerald/src/mauville_old_man.c:267
  GiddyShouldTellAnotherTale = function(ctx) return result(ctx, OldMan.giddyShouldTellAnotherTale()) end,
  -- pokeemerald/src/mauville_old_man.c:282
  GenerateGiddyLine = function(ctx, adapters)
    Town.setString(ctx, adapters, 4, OldMan.generateGiddyLine())
    return result(ctx, true)
  end,
  -- pokeemerald/src/mauville_old_man.c:1446
  StorytellerGetFreeStorySlot = function(ctx) return result(ctx, OldMan.freeStorySlot()) end,
  -- pokeemerald/src/mauville_old_man.c:1436
  StorytellerStoryListMenu = function(ctx, adapters)
    local labels = OldMan.storyTitles()
    local count = #labels
    labels[#labels + 1] = text("gText_Exit")
    return choose(ctx, adapters, labels, { left = 1, top = 1 }, function(sel)
      if sel == MENU_B_PRESSED or sel == count then
        Rse.setSpecialVar(ctx, VAR_RESULT, 0)
      else
        Rse.setSpecialVar(ctx, VAR_RESULT, 1)
        OldMan.selectedStory = sel
      end
    end)
  end,
  -- pokeemerald/src/mauville_old_man.c:1441
  Script_StorytellerDisplayStory = function(ctx, adapters)
    local story, value, name = OldMan.story(OldMan.selectedStory)
    Town.setString(ctx, adapters, 1, tostring(value))
    Town.setString(ctx, adapters, 2, text(story.action))
    Town.setString(ctx, adapters, 3, name)
    Town.showMessage(ctx, adapters, story.fullText)
    return false
  end,
  -- pokeemerald/src/mauville_old_man.c:1453
  StorytellerUpdateStat = function(ctx, adapters)
    local changed, value, action = OldMan.updateStat()
    if changed then
      Town.setString(ctx, adapters, 1, tostring(value))
      Town.setString(ctx, adapters, 2, text(action))
    end
    return result(ctx, changed)
  end,
  -- pokeemerald/src/mauville_old_man.c:1467
  HasStorytellerAlreadyRecorded = function(ctx) return result(ctx, OldMan.state().alreadyRecorded == true) end,
  -- pokeemerald/src/mauville_old_man.c:1477
  Script_StorytellerInitializeRandomStat = function(ctx, adapters)
    local ok, value, action = OldMan.initializeRandomStat()
    if ok then
      Town.setString(ctx, adapters, 1, tostring(value))
      Town.setString(ctx, adapters, 2, text(action))
    end
    return result(ctx, ok)
  end,
  -- pokeemerald/src/trader.c:139
  GetTraderTradedFlag = function(ctx) return result(ctx, OldMan.state().alreadyTraded == true) end,
  -- pokeemerald/src/trader.c:145
  DoesPlayerHaveNoDecorations = function(ctx)
    local Inv = require("src.core.game3.rse.decoration_inventory")
    for cat = 0, Inv.CATEGORY_COUNT - 1 do
      if Inv.countInCategory(cat) > 0 then return result(ctx, false) end
    end
    return result(ctx, true)
  end,
  -- pokeemerald/src/trader.c:160
  IsDecorationCategoryFull = function(ctx, adapters)
    local Inv = require("src.core.game3.rse.decoration_inventory")
    local want = Inv.categoryOf(Rse.specialVar(ctx, VAR_0x8004))
    local give = Inv.categoryOf(Rse.specialVar(ctx, VAR_0x8006))
    if want ~= give and want and Inv.firstEmptySlot(want) == nil then
      Town.setString(ctx, adapters, 2, Inv.categoryName(want))
      return result(ctx, true)
    end
    return result(ctx, false)
  end,
  -- pokeemerald/src/trader.c:211
  TraderMenuGetDecoration = function(ctx, adapters)
    local t = OldMan.state()
    local labels = {}
    for i = 1, OldMan.NUM_TRADER_ITEMS do labels[i] = decorName(t.decorations[i]) end
    labels[#labels + 1] = text("gText_Exit")
    return choose(ctx, adapters, labels, { left = 1, top = 1 }, function(sel)
      -- pokeemerald/src/trader.c:115
      if sel == MENU_B_PRESSED or sel == OldMan.NUM_TRADER_ITEMS then
        Rse.setSpecialVar(ctx, VAR_0x8004, 0)
        return
      end
      Rse.setSpecialVar(ctx, VAR_0x8005, sel)
      Town.setString(ctx, adapters, 1, t.playerNames[sel + 1])
      local decor = t.decorations[sel + 1]
      Rse.setSpecialVar(ctx, VAR_0x8004, decor > OldMan.NUM_DECORATIONS and 0xFFFF or decor)
    end)
  end,
  -- pokeemerald/src/trader.c:171
  TraderShowDecorationMenu = function(ctx, adapters)
    local menu = Rse.system("decorationMenu")
    local Natives = require("src.core.game3.scripting.natives")
    return Natives.yieldHost(ctx, adapters, function(done)
      if menu and type(menu.chooseForTrade) == "function" then
        menu.chooseForTrade(ctx, done)
      else
        chooseDecorationToGive(ctx, adapters, done)
      end
    end)
  end,
  -- pokeemerald/src/trader.c:199
  TraderDoDecorationTrade = function(ctx)
    OldMan.traderDoTrade(Rse.specialVar(ctx, VAR_0x8004), Rse.specialVar(ctx, VAR_0x8006),
      Rse.specialVar(ctx, VAR_0x8005))
    return false
  end,
}

Std.legacyHandlers(NativesOldMan)

return NativesOldMan
